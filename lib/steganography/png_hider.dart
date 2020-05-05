import 'dart:typed_data';

import 'package:image/image.dart';

class PngHider {
  static const _endMessageToken = '`|!';
  static const _startMessageToken = '!|`';
  static const _msgByteShifts = [6, 4, 2, 0];
  static const _channelShifts = [24, 16, 8, 0];
  static const _squareBlockSize = 512;

  bool _isFinished = false;
  int _msgIndex = 0;
  int _shiftIndex = 0;
  Uint8List _msgBytes;

  void _init(String msg) {
    _isFinished = false;
    _msgIndex = 0;
    _shiftIndex = 0;
    _msgBytes = Uint8List.fromList(msg.codeUnits);
  }

  List<int> hideMessage(Image img, String msg) {
    _init(_startMessageToken + msg + _endMessageToken);

    List<Image> imgPieces = splitImage(img);
    List<Image> results = [];

    for (Image piece in imgPieces) {
      if (!_isFinished) {
        Uint32List pixels = _toIntList(
            _hideMessage(piece.data, piece.width, piece.height));
        Image alteredImg = Image.fromBytes(piece.width, piece.height, pixels);

        results.add(alteredImg);
      } else {
        results.add(Image.from(piece));
      }
    }

    return encodePng(mergeImages(results, img.width, img.height));
  }

  Uint8List _hideMessage(Uint32List pixels, int imgCols, int imgRows) {
    int bytesIndex = 0;

    Uint8List bytes = Uint8List(imgRows * imgCols * _channelShifts.length);

    for (int row = 0; row < imgRows; row++) {
      for (int col = 0; col < imgCols; col++) {
        int element = row * imgCols + col;

        for (int channel = 0; channel < _channelShifts.length; channel++) {
          if (!_isFinished && channel != 0) {
            bytes[bytesIndex++] =
            (pixels[element] >> _channelShifts[channel] & 0xFC) | (_msgBytes[_msgIndex] >> _msgByteShifts[_shiftIndex] & 0x3);

            _updateShiftIndex();
          } else {
            bytes[bytesIndex++] =
            pixels[element] >> _channelShifts[channel] & 0xFF;
          }
        }
      }
    }

    return bytes;
  }

  Uint32List _toIntList(Uint8List bytes) {
    List<int> ints = [];

    int offset = 0;

    while (offset < bytes.length) {
      ints.add(_toInt(bytes, offset));
      offset += 4;
    }

    return Uint32List.fromList(ints);
  }

  int _toInt(Uint8List bytes, int offset) {
    int value = 0x00000000;

    for (int i = 0; i < 4; i++) {
      int shift = (3 - i) * 8;
      value |= (bytes[i + offset] & 0x000000FF) << shift;
    }

    return value;
  }

  void _updateShiftIndex() {
    _shiftIndex = (_shiftIndex + 1) % _msgByteShifts.length;

    if (_shiftIndex == 0)
      _msgIndex++;

    if (_msgIndex >= _msgBytes.length)
      _isFinished = true;
  }

  String findMessage(List<int> bytes) {
    Image img = decodePng(bytes);
    _shiftIndex = 0;

    List<Image> imgPieces = splitImage(img);
    List<int> msgBytes = [];

    for (Image piece in imgPieces) {
      String msg = _findMessage(_toByteList(piece.data), msgBytes);

      if (msg != null)
        return msg;
    }

    return null;
  }

  String _findMessage(Uint8List imgBytes, List<int> msgBytes) {
    int tmp = 0x00;
    int byteIndex = 0;

    while (byteIndex < imgBytes.length) {
      if (byteIndex % _channelShifts.length == 0) {
        byteIndex++;
        continue;
      }

      // get last two bits and shift to appropriate bit position
      tmp |= (imgBytes[byteIndex++] & 0x3) << _msgByteShifts[_shiftIndex];

      _shiftIndex = (_shiftIndex + 1) % _msgByteShifts.length;

      if (_shiftIndex == 0) {
        if (_isSearchEnded(msgBytes)) {
          return String.fromCharCodes(
              msgBytes,
              _startMessageToken.length,
              msgBytes.length - _endMessageToken.length);
        } else {
          msgBytes.add(tmp);
          tmp = 0x00;
        }
      }
    }

    return null;
  }

  bool _isSearchEnded(List<int> msgBytes) {
    int tokenSize = _endMessageToken.length;
    int msgSize = msgBytes.length;

    if (msgSize < tokenSize)
      return false;

    for (int i = 1; i <= tokenSize; i++) {
      if (_endMessageToken.codeUnitAt(tokenSize - i) != msgBytes[msgSize - i])
        return false;
    }

    return true;
  }

  Uint8List _toByteList(Uint32List ints) {
    return Uint8List.fromList(
        ints.expand((i) => _channelShifts.map((c) => (i >> c) & 0xFF)).toList()
    );
  }

  List<Image> splitImage(Image img) {
    final int rows = (img.height / _squareBlockSize).ceil();
    final int cols = (img.width / _squareBlockSize).ceil();

    final int chunkHeightMod = img.height % _squareBlockSize;
    final int chunkWidthMod = img.width % _squareBlockSize;

    List<Image> images = [];

    for (int x = 0; x < rows; x++) {
      for (int y = 0; y < cols; y++) {
        final int chunkHeight = (x == rows - 1 && chunkHeightMod > 0) ? chunkHeightMod : _squareBlockSize;
        final int chunkWidth = (y == cols - 1 && chunkWidthMod > 0) ? chunkWidthMod : _squareBlockSize;

        images.add(copyCrop(img, y * _squareBlockSize, x * _squareBlockSize, chunkWidth, chunkHeight));
      }
    }

    return images;
  }

  Image mergeImages(List<Image> images, int originalWidth, int originalHeight) {
    final int rows = (originalHeight / _squareBlockSize).ceil();
    final int cols = (originalWidth / _squareBlockSize).ceil();

    Image img = Image(originalWidth, originalHeight);

    int count = 0;

    for (int x = 0; x < rows; x++) {
      for (int y = 0; y < cols; y++) {
        copyInto(img, images[count],
            dstX: y * _squareBlockSize,
            dstY:  x * _squareBlockSize,
            blend: false);

        count++;
      }
    }

    return img;
  }

  List<int> getMsgTokenLengths() {
    return [_startMessageToken.length, _endMessageToken.length];
  }
}