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

package com.github.jsavas.enpiction.steganography.text;

import android.graphics.Bitmap;

import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;


public class Decode {

  private static final byte[] andByte = {(byte) 0xC0, 0x30, 0x0C, 0x03};

  private static final byte[] endConstantBytes = Utility.END_MESSAGE_COSTANT.getBytes(StandardCharsets.ISO_8859_1);
  private static final byte[] startConstantBytes = Utility.START_MESSAGE_COSTANT.getBytes(StandardCharsets.ISO_8859_1);
  /**
   * This is the decoding method of 2 bit encoding.
   *
   * @param bytePixelArray {The byte array image}
   * @param status {MessageDecodingStatus}
   */
  private static void decodeMessage(byte[] bytePixelArray, MessageDecodingStatus status) {
    List<Byte> encryptedMessageBytes = status.getMessageBytes();

    int shiftIndex = 4;
    byte tmp = 0x00;
    int pixelIndex = 0;

    while (status.getMessage() == null && pixelIndex < bytePixelArray.length) {
      byte b = bytePixelArray[pixelIndex++];

      //get last two bits from b
      tmp = (byte) (tmp | ((b << Utility.toShift[shiftIndex
        % Utility.toShift.length]) & andByte[shiftIndex++ % Utility.toShift.length]));

      if (shiftIndex % Utility.toShift.length == 0) {
        if (isDecodingEnded(encryptedMessageBytes)) {

          int startConstantLength = startConstantBytes.length;
          int endConstantLength = endConstantBytes.length;

          byte[] temp = new byte[encryptedMessageBytes.size() - startConstantLength - endConstantLength];

          for (int byteIndex = startConstantLength, tempIndex = 0; tempIndex < temp.length; byteIndex++, tempIndex++)
            temp[tempIndex] = encryptedMessageBytes.get(byteIndex);

          status.setMessage(new String(temp, StandardCharsets.ISO_8859_1));
        } else {
          encryptedMessageBytes.add(tmp);

          // No message in this image
          if (encryptedMessageBytes.size() == startConstantBytes.length) {
            for (int i = 0; i < startConstantBytes.length; i++) {
              if (startConstantBytes[i] != encryptedMessageBytes.get(i)) {
                status.setMessage("");
                break;
              }
            }
          }
        }

        tmp = 0x00;
      }
    }
  }

  private static boolean isDecodingEnded(List<Byte> messageBytes) {
    int constantSize = endConstantBytes.length;
    int messageSize = messageBytes.size();

    if (messageSize < constantSize)
      return false;

    for (int i = 1; i <= constantSize; i++) {
      if (endConstantBytes[constantSize - i] != messageBytes.get(messageSize - i))
        return false;
    }

    return true;
  }

  /**
   * This method takes the list of encoded chunk images and decodes it.
   *
   * @return : encrypted message {String}
   * @parameter : encodedImages {list of encode chunk images}
   */

  public static String decodeMessage(List<Bitmap> encodedImages) {
    MessageDecodingStatus messageDecodingStatus = new MessageDecodingStatus();

    for (Bitmap bit : encodedImages) {
      int[] pixels = new int[bit.getWidth() * bit.getHeight()];
      bit.getPixels(pixels, 0, bit.getWidth(), 0, 0, bit.getWidth(), bit.getHeight());

      decodeMessage(Utility.convertArray(pixels), messageDecodingStatus);

      if (messageDecodingStatus.getMessage() != null)
        break;
    }

    return messageDecodingStatus.getMessage();
  }

  private static class MessageDecodingStatus {
    private String message = null;
    private List<Byte> messageBytes = new ArrayList<>();

    String getMessage() {
      return message;
    }

    void setMessage(String message) {
      this.message = message;
    }

    public List<Byte> getMessageBytes() {
      return messageBytes;
    }
  }

}
