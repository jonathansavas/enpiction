import 'dart:io';
import 'dart:typed_data';

import 'package:enpiction/steganography/crypto.dart';
import 'package:enpiction/steganography/steg.dart';
import 'package:image/image.dart' show JpegHider, Image, decodeImage, decodeJpg, JpegData;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  test('Crypto functions', () {
    String message = 'message';
    String key = 'key';
    expect(decryptMessage(encryptMessage(message, key), key), equals(message));
  });

  test('Split/merge image functions', () {
    Image img = decodeImage(File('test/clean_image.png').readAsBytesSync());

    Image after = mergeImages(splitImage(img), img.width, img.height);

    for (int i = 0; i < img.length; i++) {
      expect(after[i], equals(img[i]));
    }
  });

  test('Hide/find messages in image', () {
    String message = 'messagefkgjkjg8*&845jk';
    Image img = decodeImage(File('test/clean_image.png').readAsBytesSync());

    expect(MessageFinder().findMessage(MessageHider().hideMessage(img, message)), equals(message));
  });

  test('Do not change more pixels than necessary', () {
    String message = 'msgxyz65*&';
    int expectedChanges = ((message.length + startMessageToken.length + endMessageToken.length) * 4 / 3).ceil();

    Image img = decodeImage(File('test/clean_image.png').readAsBytesSync());
    Image after = MessageHider().hideMessage(img, message);

    int numChanges = 0;
    for (int i = 0; i < img.length; i++) {
      if (img[i] != after[i]) {
        numChanges++;
      }
    }

    expect(numChanges, equals(expectedChanges));
  });

  test('Validate message set', () {
    final messageFinder = MessageFinder();

    final messages = ['A', 'B', 'C', 'D'];

    String uuid = Uuid().v4();
    String prefix = uuid + messages.length.toString();
    String invalidPrefix = Uuid().v4();

    List<String> prefixedMessages = messages.map((m) => prefix + m).toList();
    expect(messageFinder.validateMessageSet(prefixedMessages), equals(true));

    List<String> invalid = [prefix + messages[0], prefix + messages[1], prefix + messages[2]];
    expect(messageFinder.validateMessageSet(invalid), equals(false));

    invalid.add(invalidPrefix + messages[3]);
    expect(messageFinder.validateMessageSet(invalid), equals(false));
  });
}
