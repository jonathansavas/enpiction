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

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:enpiction/steganography/crypto.dart';
import 'package:enpiction/steganography/decode.dart';
import 'package:image/image.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();
int _uuidLength = _uuid.v4().length;

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

List<String> decodeAndValidate(List<String> filePaths, String key) {
  if (filePaths == null)
    return [];

  List<String> decodedMessages = decodeMessagesFromFiles(filePaths, key);

  if (!validateDecodedSet(decodedMessages)) {
    return [];
  } else {
    return decodedMessages.map((m) => _extractOriginalMessage(m)).toList();
  }
}

List<String> decodeMessagesFromFiles(List<String> filePaths, String key) {
  List<String> messages = [];

  for (String filePath in filePaths) {
    File f = File(filePath);
    DateTime lastAccess = _getLastAccessed(f);

    String msg = decryptMessage(
        decodeMessage(decodeNamedImage(f.readAsBytesSync(), filePath)),
        key);

    _setLastAccessed(lastAccess, f);

    if (msg.isEmpty)
      return [];

    messages.add(msg);
  }

  return messages;
}

bool validateDecodedSet(List<String> decodedMessages) {
  if (decodedMessages == null || decodedMessages.isEmpty)
    return false;

  int expectedSize = _extractGroupSize(decodedMessages.first);
  int actualSize = decodedMessages.length;

  if (actualSize != expectedSize)
    return false;

  String expectedUUID = _extractUUID(decodedMessages.first);

  for (int i = 1; i < actualSize; i++) {
    if (!decodedMessages.elementAt(i).startsWith(expectedUUID))
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
