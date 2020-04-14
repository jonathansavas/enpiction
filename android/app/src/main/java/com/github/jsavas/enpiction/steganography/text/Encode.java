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
import android.graphics.Color;

import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;


public class Encode {
  private static final int[] binary = {16, 8, 0};

  /**
   * This method represent the core of 2 bit Encoding
   *
   * @return : byte encoded pixel array
   * @param  integerPixelArray {The integer RGB array}
   * @param imageColumns {Image width}
   * @param imageRows {Image height}
   * @param status {object}
   */
  private static byte[] encodeMessage(int[] integerPixelArray, int imageColumns, int imageRows,
                                      MessageEncodingStatus status) {

    //denotes RGB channels
    int channels = 3;
    int shiftIndex = 4;

    byte[] result = new byte[imageRows * imageColumns * channels];

    int resultIndex = 0;

    for (int row = 0; row < imageRows; row++) {
      for (int col = 0; col < imageColumns; col++) {

        //2D matrix in 1D
        int element = row * imageColumns + col;

        for (int channelIndex = 0; channelIndex < channels; channelIndex++) {
          if (!status.isMessageEncoded()) {

            // Shifting integer value by 2 in left and replacing the two least significant digits with the message_byte_array values..
            result[resultIndex++] = (byte) ((((integerPixelArray[element] >> binary[channelIndex]) & 0xFF) & 0xFC) | ((status.getByteArrayMessage()[status.getCurrentMessageIndex()] >> Utility.toShift[(shiftIndex++)
              % Utility.toShift.length]) & 0x3));// 6

            if (shiftIndex % Utility.toShift.length == 0) {
              status.incrementMessageIndex();
            }

            if (status.getCurrentMessageIndex() == status.getByteArrayMessage().length) {
              status.setMessageEncoded();
            }
          } else {
            //Simply copy the integer to result array
            result[resultIndex++] = (byte) ((integerPixelArray[element] >> binary[channelIndex]) & 0xFF);
          }
        }
      }
    }

    return result;
  }

  /**
   * This method implements the above method on the list of chunk image list.
   *
   * @return : Encoded list of chunk images
   * @param imageSections {list of chunk images}
   * @param encryptedMessage {string}
   */
  public static List<Bitmap> encodeMessage(List<Bitmap> imageSections,
                                           String encryptedMessage) {

    List<Bitmap> result = new ArrayList<>(imageSections.size());

    MessageEncodingStatus message = new MessageEncodingStatus(
      Utility.START_MESSAGE_COSTANT + encryptedMessage + Utility.END_MESSAGE_COSTANT);

    for (Bitmap bitmap : imageSections) {
      if (!message.isMessageEncoded()) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

        int[] oneD = new int[width * height];
        bitmap.getPixels(oneD, 0, width, 0, 0, width, height);

        int[] oneDMod = Utility.byteArrayToIntArray(encodeMessage(oneD, width, height, message));

        Bitmap encodedBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        encodedBitmap.setDensity(bitmap.getDensity());

        int masterIndex = 0;

        for (int j = 0; j < height; j++)
          for (int i = 0; i < width; i++) {
            encodedBitmap.setPixel(i, j,
              Color.argb(0xFF,
              oneDMod[masterIndex] >> 16 & 0xFF,
              oneDMod[masterIndex] >> 8 & 0xFF,
              oneDMod[masterIndex++] & 0xFF));
          }

        result.add(encodedBitmap);

      } else {
        //Just add the image chunk to the result
        result.add(bitmap.copy(bitmap.getConfig(), false));
      }
    }

    return result;
  }

  private static class MessageEncodingStatus {
    private boolean messageEncoded;
    private int currentMessageIndex;
    private byte[] byteArrayMessage;

    MessageEncodingStatus(String message) {
      this.messageEncoded = false;
      this.currentMessageIndex = 0;
      this.byteArrayMessage = message.getBytes(StandardCharsets.ISO_8859_1);
    }

    void incrementMessageIndex() {
      currentMessageIndex++;
    }

    boolean isMessageEncoded() {
      return messageEncoded;
    }

    void setMessageEncoded() {
      this.messageEncoded = true;
    }

    int getCurrentMessageIndex() {
      return currentMessageIndex;
    }

    byte[] getByteArrayMessage() {
      return byteArrayMessage;
    }

  }

}
