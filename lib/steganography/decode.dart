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

import 'dart:convert';
import 'dart:typed_data';

import 'package:enpiction/steganography/constants.dart';
import 'package:image/image.dart';

const _ascii = AsciiCodec();
final _andBytes = Uint8List.fromList([0xC0, 0x30, 0x0C, 0x03]);
final _endTokenBytes = _ascii.encode(endMessageToken);
final _startTokenBytes = _ascii.encode(startMessageToken);

String decodeMessage(List<Image> encodedImages) {
  _MessageDecodingStatus status = _MessageDecodingStatus();

  for (Image img in encodedImages) {
    _decodeMessage(_toByteList(img.data), status);

    if (status.getMessage() != null)
      break;
  }

  return status.getMessage();
}

_decodeMessage(Uint8List bytes, _MessageDecodingStatus status) {
  List<int> messageBytes = status.getMessageBytes();
  
  int shiftIndex = 4;
  int tmp = 0x00;
  int byteIndex = 0;
  
  while (status.getMessage() == null && byteIndex < bytes.length) {
    int b = bytes[byteIndex++];
    
    // get last two bits from b
    tmp = tmp | ((b << toShift[shiftIndex % toShift.length]) & _andBytes[shiftIndex++ % toShift.length]);
    
    if (shiftIndex % toShift.length == 0) {
      if (_isDecodingEnded(messageBytes)) {
        status.setMessage(String.fromCharCodes(
            messageBytes,
            _startTokenBytes.length,
            messageBytes.length - _endTokenBytes.length)
        );
      } else {
        messageBytes.add(tmp);
      }

      tmp = 0x00;
    }
  }
}

bool _isDecodingEnded(List<int> messageBytes) {
  int constantSize = _endTokenBytes.length;
  int messageSize = messageBytes.length;
  
  if (messageSize < constantSize)
    return false;

  for (int i = 1; i <= constantSize; i++) {
    if (_endTokenBytes[constantSize - i] != messageBytes[messageSize - i])
      return false;
  }
  
  return true;
}

Uint8List _toByteList(Uint32List ints) {
  return Uint8List.fromList(
      ints.expand((i) => channelShifts.map((c) => (i >> c) & 0xFF)).toList()
  );
}

class _MessageDecodingStatus {
  String _message;
  List<int> _messageBytes = [];

  String getMessage() {
    return _message;
  }

  void setMessage(String message) {
    this._message = message;
  }

  List<int> getMessageBytes() {
    return _messageBytes;
  }
}
