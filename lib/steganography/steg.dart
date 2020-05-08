import 'dart:io';

import 'package:enpiction/steganography/png_hider.dart';
import 'package:path/path.dart' as path;
import 'package:enpiction/steganography/crypto.dart';
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();
final int _uuidLength = _uuid.v4().length;

class MessageHider {
  static const _png = '.png';
  static const _jpg = '.jpg';
  static const _jpeg = '.jpeg';
  static final _allowedExtensions = Set.of([_png, _jpg, _jpeg]);
  final _pngHider = PngHider();
  final _jpegHider = JpegHider(quality: 85);

  Future<bool> hideMessagesInFiles(Iterable<MapEntry<String, String>> pathsToMessages, String key) async {
    if (pathsToMessages == null)
      return false;

    for (MapEntry<String, String> m in pathsToMessages) {
      if (!_allowedExtensions.contains(path.extension(m.key).toLowerCase()))
        throw ArgumentError('Only support PNG and JPEG files at this time');
    }

    int groupSize = pathsToMessages.length;

    if (groupSize == 0 || groupSize > 9)
      return false;

    String prefix = _uuid.v4() + groupSize.toString();

    for (MapEntry<String, String> entry in pathsToMessages) {
      String filePath = entry.key;
      String msg = prefix + entry.value;
      List<int> bytes = _getHider(filePath).hideMessage(
          decodeNamedImage(File(filePath).readAsBytesSync(), filePath),
          encryptMessage(msg, key),
      );

      if (! _writeImageToFile(filePath, bytes))
        return false;
    }

    return true;
  }

  bool _writeImageToFile(String filePath, List<int> bytes) {
    File f = File(filePath);

    DateTime lastMod = _getLastModified(f);
    DateTime lastAccess = _getLastAccessed(f);

    try {
      f.writeAsBytesSync(bytes);
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
          _getHider(filePath).findMessage(f.readAsBytesSync()),
          key,
      );

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

  dynamic _getHider(String filePath) {
    return (path.extension(filePath).toLowerCase() == _png) ? _pngHider : _jpegHider;
  }
}
