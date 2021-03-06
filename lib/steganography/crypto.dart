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
