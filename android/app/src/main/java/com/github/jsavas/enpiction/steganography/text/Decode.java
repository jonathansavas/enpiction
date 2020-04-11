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
import android.util.Log;

import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Vector;


public class Decode {

  private static final byte[] andByte = {(byte) 0xC0, 0x30, 0x0C, 0x03};

  /**
   * This is the decoding method of 2 bit encoding.
   *
   * @parameter : byte_pixel_array {The byte array image}
   * @parameter : image_columns {Image width}
   * @parameter : image_rows {Image height}
   * @parameter : messageDecodingStatus {object}
   */
  private static void decodeMessage(byte[] byte_pixel_array, MessageDecodingStatus messageDecodingStatus) {

    //encrypted message
    Vector<Byte> byte_encrypted_message = new Vector<>();

    int shiftIndex = 4;

    byte tmp = 0x00;


    for (byte aByte_pixel_array : byte_pixel_array) {


      //get last two bits from byte_pixel_array
      tmp = (byte) (tmp | ((aByte_pixel_array << Utility.toShift[shiftIndex
        % Utility.toShift.length]) & andByte[shiftIndex++ % Utility.toShift.length]));

      if (shiftIndex % Utility.toShift.length == 0) {
        //adding temp byte value
        byte_encrypted_message.addElement(tmp);


        //converting byte value to string
        byte[] nonso = {byte_encrypted_message.elementAt(byte_encrypted_message.size() - 1)};
        String str = new String(nonso, StandardCharsets.ISO_8859_1);

        if (messageDecodingStatus.getMessage().endsWith(Utility.END_MESSAGE_COSTANT)) {

          //Log.i("TEST", "Decoding ended");

          //fixing ISO-8859-1 decoding
          byte[] temp = new byte[byte_encrypted_message.size()];

          for (int index = 0; index < temp.length; index++)
            temp[index] = byte_encrypted_message.get(index);


          String stra = new String(temp, StandardCharsets.ISO_8859_1);


          messageDecodingStatus.setMessage(stra.substring(0, stra.length() - 1));
          //end fixing

          messageDecodingStatus.setEnded();

          break;
        } else {
          //just add the decoded message to the original message
          messageDecodingStatus.setMessage(messageDecodingStatus.getMessage() + str);

          //If there was no message there and only start and end message constant was there
          if (messageDecodingStatus.getMessage().length() == Utility.START_MESSAGE_COSTANT.length()
            && !Utility.START_MESSAGE_COSTANT.equals(messageDecodingStatus.getMessage())) {

            messageDecodingStatus.setMessage("");
            messageDecodingStatus.setEnded();

            break;
          }
        }

        tmp = 0x00;
      }

    }

    if (!Utility.isStringEmpty(messageDecodingStatus.getMessage()))
      //removing start and end constants form message

      try {
        messageDecodingStatus.setMessage(
          messageDecodingStatus.getMessage().substring(
            Utility.START_MESSAGE_COSTANT.length(), messageDecodingStatus.getMessage().length() - Utility.END_MESSAGE_COSTANT.length())
        );
      } catch (Exception e) {
        e.printStackTrace();
      }


  }

  /**
   * This method takes the list of encoded chunk images and decodes it.
   *
   * @return : encrypted message {String}
   * @parameter : encodedImages {list of encode chunk images}
   */

  public static String decodeMessage(List<Bitmap> encodedImages) {

    //Creating object
    MessageDecodingStatus messageDecodingStatus = new MessageDecodingStatus();

    for (Bitmap bit : encodedImages) {
      int[] pixels = new int[bit.getWidth() * bit.getHeight()];

      bit.getPixels(pixels, 0, bit.getWidth(), 0, 0, bit.getWidth(),
        bit.getHeight());

      byte[] b = Utility.convertArray(pixels);

      decodeMessage(b, messageDecodingStatus);

      if (messageDecodingStatus.isEnded())
        break;
    }

    return messageDecodingStatus.getMessage();
  }

  private static class MessageDecodingStatus {
    private String message;
    private boolean ended;

    MessageDecodingStatus() {
      message = "";
      ended = false;
    }

    boolean isEnded() {
      return ended;
    }

    void setEnded() {
      this.ended = true;
    }

    String getMessage() {
      return message;
    }

    void setMessage(String message) {
      this.message = message;
    }
  }

}
