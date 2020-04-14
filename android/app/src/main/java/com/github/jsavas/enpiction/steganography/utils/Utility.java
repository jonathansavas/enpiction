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

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;

import java.util.ArrayList;
import java.util.List;

public class Utility {
  public static final int SQUARE_BLOCK_SIZE = 512;

  public static final String END_MESSAGE_COSTANT = "#!@";
  public static final String START_MESSAGE_COSTANT = "@!#";
  public static final int[] toShift = {6, 4, 2, 0};

  public static List<Bitmap> splitImage(Bitmap bitmap) {
    ArrayList<Bitmap> chunkedImages = new ArrayList<>();

    int rows = bitmap.getHeight() / SQUARE_BLOCK_SIZE;
    int cols = bitmap.getWidth() / SQUARE_BLOCK_SIZE;

    int chunkHeightMod = bitmap.getHeight() % SQUARE_BLOCK_SIZE;
    int chunkWidthMod = bitmap.getWidth() % SQUARE_BLOCK_SIZE;

    if (chunkHeightMod > 0)
      rows++;

    if (chunkWidthMod > 0)
      cols++;

    //x_coordinate and y_coordinate are the pixel positions of the image chunks
    int yCoordinate = 0;

    for (int x = 0; x < rows; x++) {
      int xCoordinate = 0;

      for (int y = 0; y < cols; y++) {

        int chunkHeight = SQUARE_BLOCK_SIZE;
        int chunkWidth = SQUARE_BLOCK_SIZE;

        if (y == cols - 1 && chunkWidthMod > 0)
          chunkWidth = chunkWidthMod;

        if (x == rows - 1 && chunkHeightMod > 0)
          chunkHeight = chunkHeightMod;

        chunkedImages.add(Bitmap.createBitmap(bitmap, xCoordinate, yCoordinate, chunkWidth, chunkHeight));
        xCoordinate += SQUARE_BLOCK_SIZE;
      }

      yCoordinate += SQUARE_BLOCK_SIZE;

    }

    return chunkedImages;
  }

  public static Bitmap mergeImage(List<Bitmap> images, int originalHeight, int originalWidth) {
    int rows = originalHeight / SQUARE_BLOCK_SIZE;
    int cols = originalWidth / SQUARE_BLOCK_SIZE;

    int chunkHeightMod = originalHeight % SQUARE_BLOCK_SIZE;
    int chunkWidthMod = originalWidth % SQUARE_BLOCK_SIZE;

    if (chunkHeightMod > 0)
      rows++;

    if (chunkWidthMod > 0)
      cols++;

    //create a bitmap of a size which can hold the complete image after merging
    Bitmap bitmap = Bitmap.createBitmap(originalWidth, originalHeight, Bitmap.Config.ARGB_4444);

    Canvas canvas = new Canvas(bitmap);

    int count = 0;

    for (int irows = 0; irows < rows; irows++) {
      for (int icols = 0; icols < cols; icols++) {
        canvas.drawBitmap(images.get(count), (SQUARE_BLOCK_SIZE * icols), (SQUARE_BLOCK_SIZE * irows), new Paint());
        count++;
      }
    }

    return bitmap;
  }


  public static int[] byteArrayToIntArray(byte[] b) {
    int size = b.length / 3;

    int[] result = new int[size];
    int offset = 0;
    int index = 0;

    while (offset < b.length) {
      result[index++] = byteArrayToInt(b, offset);
      offset = offset + 3;
    }

    return result;
  }

  /**
   * Convert the byte array to an int starting from the given offset.
   *
   * @return  Integer
   * @param  b {the byte array}, offset {integer}
   */
  private static int byteArrayToInt(byte[] b, int offset) {
    int value = 0x00000000;

    for (int i = 0; i < 3; i++) {
      int shift = (3 - 1 - i) * 8;
      value |= (b[i + offset] & 0x000000FF) << shift;
    }

    return value & 0x00FFFFFF;
  }

  /**
   * Convert integer array representing [argb] values to byte array
   * representing [rgb] values
   *
   * @return byte Array representing [rgb] values.
   * @param  array representing [argb] values.
   */
  public static byte[] convertArray(int[] array) {

    byte[] newarray = new byte[array.length * 3];

    for (int i = 0; i < array.length; i++) {

      newarray[i * 3] = (byte) ((array[i] >> 16) & 0xFF);
      newarray[i * 3 + 1] = (byte) ((array[i] >> 8) & 0xFF);
      newarray[i * 3 + 2] = (byte) ((array[i]) & 0xFF);

    }

    return newarray;
  }

  public static boolean isStringEmpty(String str) {
    return str == null || str.isEmpty();
  }
}
