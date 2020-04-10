/*
 * MIT License
 *
 * Copyright (c) 2018 Ayush Agarwal
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

package com.github.jsavas.enpiction.steganography;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import com.github.jsavas.enpiction.steganography.text.Decode;
import com.github.jsavas.enpiction.steganography.text.Encode;
import com.github.jsavas.enpiction.steganography.text.ImageSteganography;
import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class StegFiles {
  private static final int UUID_LENGTH = UUID.randomUUID().toString().length();

  public static boolean encode(Map<String, String> pathsToMessages, String encryptionKey) {
    if (pathsToMessages == null) return false;
    int size = pathsToMessages.size();

    if (size == 0 || size > 9) return false;

    String prefix = UUID.randomUUID().toString() + size;

    for (Map.Entry<String, String> entry : pathsToMessages.entrySet()) {
      String filePath = entry.getKey();
      String message = prefix + entry.getValue();

      if (!saveFileToLocation(filePath, encode(filePath, message, encryptionKey)))
        return false;
    }

    return true;
  }

  public static Bitmap encode(String filePath, String message, String encryptionKey) {
    Bitmap bitmap = getImageBitmap(filePath);

    int originalHeight = bitmap.getHeight();
    int originalWidth = bitmap.getWidth();

    return Utility.mergeImage(
      Encode.encodeMessage(Utility.splitImage(bitmap), ImageSteganography.encryptMessage(message, encryptionKey), null),
      originalHeight, originalWidth);
  }

  public static Bitmap getImageBitmap(String filePath) {
    return BitmapFactory.decodeFile(filePath);
  }

  private static boolean saveFileToLocation(String filePath, Bitmap bitmap) {
    try (OutputStream fOut = new FileOutputStream(filePath)) {
      bitmap.compress(Bitmap.CompressFormat.PNG, 100, fOut);
    } catch (IOException e) {
      e.printStackTrace();
      return false;
    }

    return true;
  }

  public static List<String> decodeAndValidate(List<String> filePaths, String encryptionKey) {
    if (filePaths == null) return null;

    List<String> decodedMessages = decode(filePaths, encryptionKey);

    if (!validateDecodedSet(decodedMessages)) {
      return null;
    } else {
      List<String> originalMessages = new ArrayList<>();

      for (String message : decodedMessages) {
        originalMessages.add(extractOriginalMessage(message));
      }

      return originalMessages;
    }
  }

  public static List<String> decode(List<String> filePaths, String encryptionKey) {
    List<String> messages = new ArrayList<>();

    for (String filepath : filePaths) {
      String message = decode(filepath, encryptionKey);

      if (message == null) return null;

      messages.add(message);
    }

    return messages;
  }

  public static String decode(String filePath, String encryptionKey) {
    Bitmap bitmap = getImageBitmap(filePath);

    String message = ImageSteganography.decryptMessage(Decode.decodeMessage(Utility.splitImage(bitmap)), encryptionKey);

    return Utility.isStringEmpty(message) ? null : message;
  }

  public static boolean validateDecodedSet(List<String> decodedMessages) {
    if (decodedMessages == null) return false;

    int expectedSize = extractSize(decodedMessages.get(0));
    int actualSize = decodedMessages.size();

    if (actualSize != expectedSize) return false;

    String expectedUUID = extractUUID(decodedMessages.get(0));

    for (int i = 1; i < actualSize; i++) {
      if (!decodedMessages.get(i).startsWith(expectedUUID))
        return false;
    }

    return true;
  }

  private static String extractUUID(String message) {
    return message.substring(0, UUID_LENGTH);
  }

  private static int extractSize(String message) {
    try {
      return Integer.parseInt(message.substring(UUID_LENGTH, UUID_LENGTH + 1));
    } catch (NumberFormatException ex) {
      return -1;
    }
  }

  public static String extractOriginalMessage(String message) {
    return message.substring(UUID_LENGTH + 1);
  }
}
