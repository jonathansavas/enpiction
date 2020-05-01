import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:enpiction/steganography/crypto.dart';
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';

const endMessageToken = "#!@";
const startMessageToken = "@!#";
const msgByteShifts = [6, 4, 2, 0];
const channelShifts = [24, 16, 8, 0];
const _squareBlockSize = 512;

final _uuid = Uuid();
final int _uuidLength = _uuid.v4().length;

class MessageHider {

  bool _isFinished = false;
  int _msgIndex = 0;
  int _shiftIndex = 0;
  Uint8List _msgBytes;

  Future<bool> hideMessagesInFiles(Iterable<MapEntry<String, String>> pathsToMessages, String key) async {
    if (pathsToMessages == null)
      return false;

    for (MapEntry<String, String> m in pathsToMessages) {
      if (path.extension(m.key).toLowerCase() != '.png')
        throw ArgumentError('Only support PNG files at this time');
    }

    int groupSize = pathsToMessages.length;

    if (groupSize == 0 || groupSize > 9)
      return false;

    String prefix = _uuid.v4() + groupSize.toString();

    for (MapEntry<String, String> entry in pathsToMessages) {
      String filePath = entry.key;
      String msg = prefix + entry.value;
      Image img = hideMessage(
          decodePng(File(filePath).readAsBytesSync()),
          encryptMessage(msg, key)
      );

      if (! _savePngToLocation(filePath, img))
        return false;
    }

    return true;
  }

  void _init(String msg) {
    _isFinished = false;
    _msgIndex = 0;
    _shiftIndex = 0;
    _msgBytes = Uint8List.fromList(msg.codeUnits);
  }

  Image hideMessage(Image img, String msg) {
    _init(startMessageToken + msg + endMessageToken);

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

    return mergeImages(results, img.width, img.height);
  }

  Uint8List _hideMessage(Uint32List pixels, int imgCols, int imgRows) {
    int bytesIndex = 0;

    Uint8List bytes = Uint8List(imgRows * imgCols * channelShifts.length);

    for (int row = 0; row < imgRows; row++) {
      for (int col = 0; col < imgCols; col++) {
        int element = row * imgCols + col;

        for (int channel = 0; channel < channelShifts.length; channel++) {
          if (!_isFinished && channel != 0) {
            bytes[bytesIndex++] =
            (pixels[element] >> channelShifts[channel] & 0xFC) | (_msgBytes[_msgIndex] >> msgByteShifts[_shiftIndex] & 0x3);

            _updateShiftIndex();
          } else {
            bytes[bytesIndex++] =
            pixels[element] >> channelShifts[channel] & 0xFF;
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

  bool _savePngToLocation(String filePath, Image img) {
    if (path.extension(filePath).toLowerCase() != '.png')
      throw ArgumentError('Only support PNG files at this time');

    File f = File(filePath);

    DateTime lastMod = _getLastModified(f);
    DateTime lastAccess = _getLastAccessed(f);

    try {
      f.writeAsBytesSync(encodePng(img));
    } on FileSystemException catch (e) {
      print(e.message);
      return false;
    }

    if (lastMod != null)
      _setLastModified(lastMod, f);

    if (lastAccess != null)
      _setLastAccessed(lastAccess, f);

    return true;
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
    _shiftIndex = (_shiftIndex + 1) % msgByteShifts.length;

    if (_shiftIndex == 0)
      _msgIndex++;

    if (_msgIndex >= _msgBytes.length)
      _isFinished = true;
  }
}

class MessageFinder {
  final _endTokenBytes = Uint8List.fromList(endMessageToken.codeUnits);
  final _startTokenBytes = Uint8List.fromList(startMessageToken.codeUnits);

  int _shiftIndex;

  String findMessage(Image img) {
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
      if (byteIndex % channelShifts.length == 0) {
        byteIndex++;
        continue;
      }

      // get last two bits and shift to appropriate bit position
      tmp |= (imgBytes[byteIndex++] & 0x3) << msgByteShifts[_shiftIndex];

      _shiftIndex = (_shiftIndex + 1) % msgByteShifts.length;

      if (_shiftIndex == 0) {
        if (_isSearchEnded(msgBytes)) {
          return String.fromCharCodes(
              msgBytes,
              _startTokenBytes.length,
              msgBytes.length - _endTokenBytes.length);
        } else {
          msgBytes.add(tmp);
          tmp = 0x00;
        }
      }
    }

    return null;
  }

  bool _isSearchEnded(List<int> msgBytes) {
    int tokenSize = _endTokenBytes.length;
    int msgSize = msgBytes.length;

    if (msgSize < tokenSize)
      return false;

    for (int i = 1; i <= tokenSize; i++) {
      if (_endTokenBytes[tokenSize - i] != msgBytes[msgSize - i])
        return false;
    }

    return true;
  }

  Uint8List _toByteList(Uint32List ints) {
    return Uint8List.fromList(
        ints.expand((i) => channelShifts.map((c) => (i >> c) & 0xFF)).toList()
    );
  }

  Future<List<String>> findAndValidate(List<String> filePaths, String key) async {
    if (filePaths == null)
      return [];

    List<String> decodedMessages = findMessagesInFiles(filePaths, key);

    if (!validateMessageSet(decodedMessages)) {
      return [];
    } else {
      return decodedMessages.map((m) => _extractOriginalMessage(m)).toList();
    }
  }

  List<String> findMessagesInFiles(List<String> filePaths, String key) {
    List<String> messages = [];

    for (String filePath in filePaths) {
      File f = File(filePath);
      DateTime lastAccess = _getLastAccessed(f);

      String msg = decryptMessage(
          findMessage(decodeNamedImage(f.readAsBytesSync(), filePath)),
          key);

      _setLastAccessed(lastAccess, f);

      if (msg.isEmpty)
        return [];

      messages.add(msg);
    }

    return messages;
  }

  bool validateMessageSet(List<String> messages) {
    if (messages == null || messages.isEmpty)
      return false;

    int expectedSize = _extractGroupSize(messages.first);
    int actualSize = messages.length;

    if (actualSize != expectedSize)
      return false;

    String expectedUUID = _extractUUID(messages.first);

    for (int i = 1; i < actualSize; i++) {
      if (!messages.elementAt(i).startsWith(expectedUUID))
        return false;
    }

    return true;
  }

  String _extractUUID(String msg) {
    return msg.substring(0, _uuidLength);
  }

  int _extractGroupSize(String msg) {
    try {
      return int.parse(msg.substring(_uuidLength, _uuidLength + 1));
    } on FormatException {
      return -1;
    }
  }

  String _extractOriginalMessage(String msg) {
    return msg.substring(_uuidLength + 1);
  }

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



DateTime _getLastModified(File f) {
  try {
    return f.lastModifiedSync();
  } on FileSystemException {
    return null;
  }
}

void _setLastModified(DateTime dt, File f) {
  if (dt != null) {
    try {
      f.setLastModifiedSync(dt);
    } on FileSystemException {}
  }
}

DateTime _getLastAccessed(File f) {
  try {
    return f.lastAccessedSync();
  } on FileSystemException {
    return null;
  }
}

void _setLastAccessed(DateTime dt, File f) {
  if (dt != null) {
    try {
      f.setLastAccessedSync(dt);
    } on FileSystemException {}
  }
}
