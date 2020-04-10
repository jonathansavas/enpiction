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

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

public class Zipping {

  final static String TAG = Zipping.class.getName();

  public static byte[] compress(String string) throws Exception {

    ByteArrayOutputStream os = new ByteArrayOutputStream(string.length());

    GZIPOutputStream gos = new GZIPOutputStream(os);

    gos.write(string.getBytes());
    gos.close();

    byte[] compressed = os.toByteArray();
    os.close();

    return compressed;
  }

  public static String decompress(byte[] compressed) throws Exception {

    ByteArrayInputStream bis = new ByteArrayInputStream(compressed);

    GZIPInputStream gis = new GZIPInputStream(bis);

    BufferedReader br = new BufferedReader(new InputStreamReader(gis, StandardCharsets.ISO_8859_1));

    StringBuilder sb = new StringBuilder();

    String line;

    while ((line = br.readLine()) != null) {
      sb.append(line);
    }

    br.close();
    gis.close();
    bis.close();

    return sb.toString();
  }
}
