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

final _andBytes = Uint8List.fromList([0xC0, 0x30, 0x0C, 0x03]);
final _endTokenBytes = Uint8List.fromList(endMessageToken.codeUnits);
final _startTokenBytes = Uint8List.fromList(startMessageToken.codeUnits);

String decodeMessage(Image encodedImg) {
  List<Image> encodedImgPieces = splitImage(encodedImg);
  List<int> messageBytes = [];

  for (Image piece in encodedImgPieces) {
    String message = _decodeMessage(_toByteList(piece.data), messageBytes);

    if (message != null)
      return message;
  }

  return null;
}

String _decodeMessage(Uint8List bytes, List<int> messageBytes) {
  int shiftIndex = 0;
  int tmp = 0x00;
  int byteIndex = 0;
  
  while (byteIndex < bytes.length) {
    if (byteIndex % channelShifts.length == 0) {
      byteIndex++;
      continue;
    }

    int b = bytes[byteIndex++];
    
    // get last two bits from b
    tmp |= b << toShift[shiftIndex] & _andBytes[shiftIndex];

    shiftIndex = (shiftIndex + 1) % toShift.length;
    
    if (shiftIndex == 0) {
      if (_isDecodingEnded(messageBytes)) {
        return String.fromCharCodes(
            messageBytes,
            _startTokenBytes.length,
            messageBytes.length - _endTokenBytes.length);
      } else {
        messageBytes.add(tmp);
        tmp = 0x00;
      }
    }
  }

  return null;
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
