/*
 * Apache License
 * Version 2.0, January 2004
 * http://www.apache.org/licenses/
 *
 * Copyright 2017 Patrick Favre-Bulle
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * THIS FILE HAS BEEN MODIFIED FROM THE ORIGINAL SOURCE AT:
 *
 *    https://github.com/patrickfav/armadillo/blob/master/armadillo/src/main/java/at/favre/lib/armadillo/AesGcmEncryption.java
 *    commit 1782bd7847943fca749590852596e2cbecd2dc22
 */

package com.github.jsavas.enpiction.steganography.utils;

import android.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

public class Crypto {

  private static final String TRANSFORMATION = "AES/GCM/NoPadding";
  private static final String ALGORITHM = "AES";
  private static final int IV_LENGTH = 12;
  private static final int TAG_LEN_BITS = 128;

  private static final SecureRandom secureRandom = new SecureRandom();

  private static Cipher cipher;

  public static String encryptMessage(String message, String key) {
    if (message == null)
      return "";

    if (Utility.isStringEmpty(key))
      return message;

    byte[] iv = new byte[IV_LENGTH];
    secureRandom.nextBytes(iv);
    byte[] cipherText = null;

    try {
      instantiateCipher();
      cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key.getBytes(), ALGORITHM), new GCMParameterSpec(TAG_LEN_BITS, iv));
      cipherText = cipher.doFinal(message.getBytes());

      return Base64.encodeToString(
        ByteBuffer.allocate(1 + iv.length + cipherText.length)
          .put((byte) iv.length)
          .put(iv)
          .put(cipherText)
          .array(), 0);

    } catch (Exception e) {
      return "";
    } finally {
      overwriteBytes(iv);
      overwriteBytes(cipherText);
    }
  }

  public static String decryptMessage(String message, String key) {
    if (message == null)
      return "";

    if (Utility.isStringEmpty(key))
      return message;

    byte[] iv = null;
    byte[] cipherText = null;

    try {
      ByteBuffer buffer = ByteBuffer.wrap(Base64.decode(message.getBytes(), 0));

      int ivLen = buffer.get();
      if (ivLen < 12 || ivLen >= 16)
        return "";

      iv = new byte[ivLen];
      buffer.get(iv);

      cipherText = new byte[buffer.remaining()];
      buffer.get(cipherText);

      instantiateCipher();
      cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key.getBytes(), ALGORITHM), new GCMParameterSpec(TAG_LEN_BITS, iv));

      return new String(cipher.doFinal(cipherText));
    } catch (Exception e) {
      return "";
    } finally {
      overwriteBytes(iv);
      overwriteBytes(cipherText);
    }
  }

  private static void overwriteBytes(byte[] bytes) {
    if (bytes != null && bytes.length > 0)
      secureRandom.nextBytes(bytes);
  }

  private static void instantiateCipher() throws NoSuchPaddingException, NoSuchAlgorithmException {
    if (cipher == null)
      cipher = Cipher.getInstance(TRANSFORMATION);
  }

}
