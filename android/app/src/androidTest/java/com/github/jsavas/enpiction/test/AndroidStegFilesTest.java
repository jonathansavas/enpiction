/*
 * MIT License
 *
 * Copyright (c) 2020 Jonathan Savas
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

package com.github.jsavas.enpiction.test;

import androidx.test.filters.SmallTest;
import com.github.jsavas.enpiction.steganography.StegFiles;
import org.junit.Assert;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;

@SmallTest
public class AndroidStegFilesTest {
  private static final String RESOURCES_DIR = "./src/androidTest/resources";
  private static final String FRESH_IMAGE = RESOURCES_DIR + "/sample.png";
  private static final String TEST_IMAGE = RESOURCES_DIR + "/sample_copy.png";

  private static final String AVD_FRESH_IMAGE = "/storage/emulated/0/Download/sample_copy.png";
  private static final String AVD_TEST_IMAGE = "/storage/emulated/0/Download/sample_test.png";

  public void createFreshTestImage() throws IOException {
    Files.copy(Paths.get(AVD_FRESH_IMAGE), Paths.get(AVD_TEST_IMAGE), StandardCopyOption.REPLACE_EXISTING);
  }

  @Test
  public void testEncodeDecode() throws IOException {

    createFreshTestImage();
    String message = "MESSAGE";
    String key = "key";
    Map<String, String> pathsToMessage = new HashMap<String, String>() {{
      put(AVD_TEST_IMAGE, message);
    }};

    StegFiles.encode(pathsToMessage, key);
    List<String> decodedMessages = StegFiles.decodeAndValidate(Collections.singletonList(AVD_TEST_IMAGE), key);

    Assert.assertNotNull(decodedMessages);
    Assert.assertEquals(message, decodedMessages.get(0));
  }
}
