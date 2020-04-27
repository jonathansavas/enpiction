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
import 'dart:math';
import 'dart:typed_data';

import 'package:steel_crypt/PointyCastleN/api.dart';
import 'package:steel_crypt/PointyCastleN/block/aes_fast.dart';
import 'package:steel_crypt/PointyCastleN/block/modes/gcm.dart';

const _ivLen = 12;

final _cipher = GCMBlockCipher(AESFastEngine());
final _secureRan = Random.secure();

String encryptMessage(String msg, String key) {
  if (msg == null)
    return "";

  if (key == null)
    key = "";

  Uint8List iv;
  Uint8List cipherText;
  try {
    iv = getSecureBytes(_ivLen);

    _cipher.init(
        true,
        ParametersWithIV<KeyParameter>(
            KeyParameter(Uint8List.fromList(_padKey(key).codeUnits)),
            iv
        ));

    cipherText = _cipher.process(
        Uint8List.fromList(msg.codeUnits));

    return base64.encode(
        Uint8List(1 + iv.length + cipherText.length)
          ..setAll(0, [iv.length])..setAll(1, iv)..setAll(
            1 + iv.length, cipherText)
    );
  } on Exception {
    return "";
  } finally {
    overwriteBytes(iv);
    overwriteBytes(cipherText);
  }
}

String decryptMessage(String msg, String key) {
  if (msg == null)
    return "";

  if (key == null)
    key = "";

  Uint8List bytes;
  try {
    bytes = base64.decode(msg);
    int ivLen = bytes[0];
    
    _cipher.init(
        false,
        ParametersWithIV<KeyParameter>(
          KeyParameter(Uint8List.fromList(_padKey(key).codeUnits)),
          Uint8List.view(bytes.buffer, 1, ivLen)
        ));

    Uint8List plainText = _cipher.process(
      Uint8List.view(bytes.buffer, 1 + ivLen)
    );

    return String.fromCharCodes(plainText);
  } on Exception {
    return "";
  } finally {
    overwriteBytes(bytes);
  }
}

String _padKey(String key) {
  return key.padRight(16, '0');
}

Uint8List getSecureBytes(int length) {
  return Uint8List.fromList(
      List<int>.generate(length, (i) => _secureRan.nextInt(256))
  );
}

void overwriteBytes(List<int> bytes) {
  if (bytes != null && bytes.isNotEmpty) {
    for (int i = 0; i < bytes.length; i++)
      bytes[i] = _secureRan.nextInt(256);
  }
}
