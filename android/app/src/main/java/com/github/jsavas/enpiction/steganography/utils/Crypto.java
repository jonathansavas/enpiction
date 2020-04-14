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

package com.github.jsavas.enpiction.steganography.utils;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.security.GeneralSecurityException;

public class Crypto {

  private static final String TRANSFORMATION = "AES/ECB/PKCS5Padding";
  private static final String ALGORITHM = "AES";

  public static String encryptMessage(String message, String encryptionKey) {
    if (message == null)
      return "";

    if (Utility.isStringEmpty(encryptionKey))
      return message;

    try {
      SecretKeySpec aesKey = new SecretKeySpec(encryptionKey.getBytes(), ALGORITHM);
      Cipher cipher = Cipher.getInstance(TRANSFORMATION);
      cipher.init(Cipher.ENCRYPT_MODE, aesKey);

      return android.util.Base64.encodeToString(cipher.doFinal(message.getBytes()), 0);
    } catch (GeneralSecurityException e) {
      e.printStackTrace();
      return "";
    }
  }

  public static String decryptMessage(String message, String encryptionKey) {
    if (message == null)
      return "";

    if (Utility.isStringEmpty(encryptionKey))
      return message;

    try {
      SecretKeySpec aesKey = new SecretKeySpec(encryptionKey.getBytes(), ALGORITHM);
      Cipher cipher = Cipher.getInstance(TRANSFORMATION);
      cipher.init(Cipher.DECRYPT_MODE, aesKey);
      byte[] decoded = android.util.Base64.decode(message.getBytes(), 0);

      return new String(cipher.doFinal(decoded));
    } catch (GeneralSecurityException e) {
      e.printStackTrace();
      return "";
    }
  }

}
