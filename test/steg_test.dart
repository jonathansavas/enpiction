import 'dart:io';
import 'dart:typed_data';

import 'package:enpiction/steganography/crypto.dart';
import 'package:enpiction/steganography/png_hider.dart';
import 'package:enpiction/steganography/steg.dart';
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

// Had to remove 'flutter_test' because of dependency issue with 'image' package,
// so running these tests requires command 'flutter pub run test test/steg_test.dart'
void main() {
  test('Crypto functions', () {
    String message = 'message';
    String key = 'key';
    expect(decryptMessage(encryptMessage(message, key), key), equals(message));
  });

  test('Split/merge image functions', () {
    var pngHider = PngHider();
    Image img = decodeImage(File('test/res/android_screenshot.png').readAsBytesSync());

    Image after = pngHider.mergeImages(pngHider.splitImage(img), img.width, img.height);

    for (int i = 0; i < img.length; i++) {
      expect(after[i], equals(img[i]));
    }
  });

  test('Hide/find messages in PNG', () {
    var pngHider = PngHider();
    String message = 'messagefkgjkjg8*&845jk';
    Image img = decodeImage(File('test/res/android_screenshot.png').readAsBytesSync());

    expect(pngHider.findMessage(pngHider.hideMessage(img, message)), equals(message));
  });

  test('PNG change minimum number of pixels', () {
    var pngHider = PngHider();
    var tokLengths = pngHider.getMsgTokenLengths();
    String message = 'msgxyz65*&';
    int expectedChanges = ((message.length + tokLengths[0] + tokLengths[1]) * 4 / 3).ceil();

    Image img = decodeImage(File('test/res/android_screenshot.png').readAsBytesSync());
    Image after = decodePng(pngHider.hideMessage(img, message));

    int numChanges = 0;
    for (int i = 0; i < img.length; i++) {
      if (img[i] != after[i]) {
        numChanges++;
      }
    }

    expect(numChanges, equals(expectedChanges));
  });

  test('Validate message set', () {
    final msgHider = MessageHider();

    final messages = ['A', 'B', 'C', 'D'];

    String uuid = Uuid().v4();
    String prefix = uuid + messages.length.toString();
    String invalidPrefix = Uuid().v4();

    List<String> prefixedMessages = messages.map((m) => prefix + m).toList();
    expect(msgHider.validateMessageSet(prefixedMessages), equals(true));

    List<String> invalid = [prefix + messages[0], prefix + messages[1], prefix + messages[2]];
    expect(msgHider.validateMessageSet(invalid), equals(false));

    invalid.add(invalidPrefix + messages[3]);
    expect(msgHider.validateMessageSet(invalid), equals(false));
  });

  test('File sizes', () {
    var msg = "let's hide this test message within the images we are testing to determine the file sizes after compressing with hidden data!!";

    var pngs = ['fb_icon_325x325.png', 'android_screenshot.png', 'large-png-img.png'];
    var pngHider = PngHider();

    for (String png in pngs) {
      Uint8List bytes = File('test/res/$png').readAsBytesSync();
      print('$png without hidden: ' + bytes.length.toString() + ' bytes');
      print('$png with    hidden: ' + pngHider.hideMessage(PngDecoder().decodeImage(bytes), msg).length.toString() + ' bytes');
      print('\n');
    }

    var jpegs = ['fb_screenshot.jpg', 'minnewaska.jpg', 'waterfall.jpg'];
    var jpegHider = JpegHider();

    var qualities = [50, 60, 70, 80, 90, 100];

    for (String jpeg in jpegs) {
      Uint8List bytes = File('test/res/$jpeg').readAsBytesSync();
      print('$jpeg without hidden     : ' + bytes.length.toString() + ' bytes');
      for (int qual in qualities) {
        jpegHider.setQuality(qual);
        print('$jpeg with hidden qual $qual: ' + jpegHider.hideMessage(JpegDecoder().decodeImage(bytes), msg).length.toString() + ' bytes');
      }
      print('\n');
    }
  });
}
