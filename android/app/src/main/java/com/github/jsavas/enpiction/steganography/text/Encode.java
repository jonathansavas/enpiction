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
import android.util.Log;

import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;


public class Encode {

  private static final String TAG = Encode.class.getName();

  private static final int[] binary = {16, 8, 0};

  /**
   * This method represent the core of 2 bit Encoding
   *
   * @return : byte encoded pixel array
   * @param  integer_pixel_array {The integer RGB array}
   * @param image_columns {Image width}
   * @param image_rows {Image height}
   * @param messageEncodingStatus {object}
   * @param progressHandler {A handler interface, for the progress bar}
   */

  private static byte[] encodeMessage(int[] integer_pixel_array, int image_columns, int image_rows,
                                      MessageEncodingStatus messageEncodingStatus, ProgressHandler progressHandler) {

    //denotes RGB channels
    int channels = 3;

    int shiftIndex = 4;

    //creating result byte_array
    byte[] result = new byte[image_rows * image_columns * channels];

    int resultIndex = 0;

    for (int row = 0; row < image_rows; row++) {

      for (int col = 0; col < image_columns; col++) {

        //2D matrix in 1D
        int element = row * image_columns + col;

        byte tmp;

        for (int channelIndex = 0; channelIndex < channels; channelIndex++) {

          if (!messageEncodingStatus.isMessageEncoded()) {

            // Shifting integer value by 2 in left and replacing the two least significant digits with the message_byte_array values..
            tmp = (byte) ((((integer_pixel_array[element] >> binary[channelIndex]) & 0xFF) & 0xFC) | ((messageEncodingStatus.getByteArrayMessage()[messageEncodingStatus.getCurrentMessageIndex()] >> Utility.toShift[(shiftIndex++)
              % Utility.toShift.length]) & 0x3));// 6

            if (shiftIndex % Utility.toShift.length == 0) {
              messageEncodingStatus.incrementMessageIndex();

              if (progressHandler != null)
                progressHandler.increment(1);
            }

            if (messageEncodingStatus.getCurrentMessageIndex() == messageEncodingStatus.getByteArrayMessage().length) {

              messageEncodingStatus.setMessageEncoded();

              if (progressHandler != null)
                progressHandler.finished();

            }
          } else {
            //Simply copy the integer to result array
            tmp = (byte) ((((integer_pixel_array[element] >> binary[channelIndex]) & 0xFF)));
          }

          result[resultIndex++] = tmp;
        }
      }
    }

    return result;

  }

  /**
   * This method implements the above method on the list of chunk image list.
   *
   * @return : Encoded list of chunk images
   * @param splitted_images {list of chunk images}
   * @param encrypted_message {string}
   * @param progressHandler {Progress bar handler}
   */
  public static List<Bitmap> encodeMessage(List<Bitmap> splitted_images,
                                           String encrypted_message, ProgressHandler progressHandler) {

    //Making result method

    List<Bitmap> result = new ArrayList<>(splitted_images.size());


    //Adding start and end message constants to the encrypted message
    encrypted_message = encrypted_message + Utility.END_MESSAGE_COSTANT;
    encrypted_message = Utility.START_MESSAGE_COSTANT + encrypted_message;


    //getting byte array from string
    byte[] byte_encrypted_message = encrypted_message.getBytes(StandardCharsets.ISO_8859_1);

    //Message Encoding Status
    MessageEncodingStatus message = new MessageEncodingStatus(byte_encrypted_message, encrypted_message);

    //Progress Handler
    if (progressHandler != null) {
      progressHandler.setTotal(encrypted_message.getBytes(StandardCharsets.ISO_8859_1).length);
    }

    //Just a log to get the byte message length
    Log.i(TAG, "Message length " + byte_encrypted_message.length);

    for (Bitmap bitmap : splitted_images) {

      if (!message.isMessageEncoded()) {

        //getting bitmap height and width
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();

        //Making 1D integer pixel array
        int[] oneD = new int[width * height];
        bitmap.getPixels(oneD, 0, width, 0, 0, width, height);

        //getting bitmap density
        int density = bitmap.getDensity();

        //encoding image
        byte[] encodedImage = encodeMessage(oneD, width, height, message, progressHandler);

        //converting byte_image_array to integer_array
        int[] oneDMod = Utility.byteArrayToIntArray(encodedImage);

        //creating bitmap from encrypted_image_array
        Bitmap encoded_Bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

        encoded_Bitmap.setDensity(density);

        int masterIndex = 0;

        //setting pixel values of above bitmap
        for (int j = 0; j < height; j++)
          for (int i = 0; i < width; i++) {

            encoded_Bitmap.setPixel(i, j, Color.argb(0xFF,
              oneDMod[masterIndex] >> 16 & 0xFF,
              oneDMod[masterIndex] >> 8 & 0xFF,
              oneDMod[masterIndex++] & 0xFF));

          }

        result.add(encoded_Bitmap);

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
    private String message;

    MessageEncodingStatus(byte[] byteArrayMessage, String message) {
      this.messageEncoded = false;
      this.currentMessageIndex = 0;
      this.byteArrayMessage = byteArrayMessage;
      this.message = message;
    }

    void incrementMessageIndex() {
      currentMessageIndex++;
    }

    public String getMessage() {
      return message;
    }

    public void setMessage(String message) {
      this.message = message;
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

    public void setCurrentMessageIndex(int currentMessageIndex) {
      this.currentMessageIndex = currentMessageIndex;
    }

    byte[] getByteArrayMessage() {
      return byteArrayMessage;
    }

    public void setByteArrayMessage(byte[] byteArrayMessage) {
      this.byteArrayMessage = byteArrayMessage;
    }
  }

}
