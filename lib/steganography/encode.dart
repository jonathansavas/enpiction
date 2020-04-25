/*
 * MIT License
 *
 * Copyright (c) 2020 Jonathan Savas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:typed_data';

import 'package:enpiction/steganography/common.dart';
import 'package:image/image.dart';

Image encodeMessage(Image img, String msg) {
  List<Image> imgPieces = splitImage(img);
  List<Image> results = [];

  _MessageEncodingStatus status = _MessageEncodingStatus(startMessageToken + msg + endMessageToken);

  for (Image piece in imgPieces) {
    if (!status.isEncoded()) {
      Uint32List pixels = _toIntList(_encodeMessage(piece.data, piece.width, piece.height, status));
      Image encodedImg = Image.fromBytes(piece.width, piece.height, pixels);

      results.add(encodedImg);
    } else {
      results.add(Image.from(piece));
    }
  }

  return mergeImages(results, img.width, img.height);
}

Uint8List _encodeMessage(Uint32List pixels, int imgCols, int imgRows, _MessageEncodingStatus status) {
  int shiftIndex = 0;
  int bytesIndex = 0;

  Uint8List bytes = Uint8List(imgRows * imgCols * channelShifts.length);

  for (int row = 0; row < imgRows; row++) {
    for (int col = 0; col < imgCols; col++) {
      int element = row * imgCols + col;

      for (int channel = 0; channel < channelShifts.length; channel++) { // TODO: this ignores the A channel, which is later added as 'ff'. Make this get the A channel and add
        if (!status.isEncoded()) {
          if (channel == 0) {
            bytes[bytesIndex++] = (pixels[element] >> channelShifts[channel]) & 0xFF;
            continue;
          }
          bytes[bytesIndex++] = ((pixels[element] >> channelShifts[channel]) & 0xFC) | ((status.getMessageBytes()[status.getMessageIndex()] >> toShift[shiftIndex]) & 0x3);

          shiftIndex = (shiftIndex + 1) % toShift.length;

          if (shiftIndex == 0)
            status.incrementMessageIndex();

          if (status.getMessageIndex() == status.getMessageBytes().length)
            status.setEncoded();
        } else {
          bytes[bytesIndex++] = (pixels[element] >> channelShifts[channel]) & 0xFF;
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

class _MessageEncodingStatus {
  bool _isEncoded = false;
  int _messageIndex = 0;
  Uint8List _messageBytes;

  _MessageEncodingStatus(String message) {
    this._messageBytes = Uint8List.fromList(message.codeUnits);
  }

  void incrementMessageIndex() {
    _messageIndex++;
  }

  bool isEncoded() {
    return _isEncoded;
  }

  void setEncoded() {
    this._isEncoded = true;
  }

  int getMessageIndex() {
    return _messageIndex;
  }

  Uint8List getMessageBytes() {
    return _messageBytes;
  }
}
