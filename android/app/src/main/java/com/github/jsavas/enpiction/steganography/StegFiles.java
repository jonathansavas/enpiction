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
import com.github.jsavas.enpiction.steganography.text.Encode;
import com.github.jsavas.enpiction.steganography.text.ImageSteganography;
import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.io.*;
import java.util.Map;

public class StegFiles {

  public static boolean encodeMessagesInFiles(Map<String, String> pathsToMessages, String encryptionKey) {
    for (Map.Entry<String, String> entry : pathsToMessages.entrySet()) {
      String filePath = entry.getKey();

      if (!saveFileToLocation(filePath, encodeMessage(filePath, entry.getValue(), encryptionKey)))
        return false;
    }

    return true;
  }

  public static Bitmap encodeMessage(String filePath, String message, String encryptionKey) {
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
}
