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

import com.github.jsavas.enpiction.steganography.StegFiles;
import org.junit.Assert;
import org.junit.Test;

import java.util.*;
import java.util.stream.Collectors;

public class StegFilesTest {

  @Test
  public void testValidateDecodedSet() {
    List<String> messages = Arrays.asList("A", "B", "C", "D");

    String uuid = UUID.randomUUID().toString();

    String prefix = uuid + messages.size();
    String invalidPrefix = UUID.randomUUID().toString();

    List<String> prefixedMessages = messages.stream()
      .map(m -> prefix + m)
      .collect(Collectors.toList());

    Assert.assertTrue(StegFiles.validateDecodedSet(prefixedMessages));

    for (int i = 0; i < messages.size(); i++) {
      Assert.assertEquals(messages.get(i), StegFiles.extractOriginalMessage(prefixedMessages.get(i)));
    }

    List<String> invalid = new ArrayList<>();

    for (int i = 0; i < messages.size() - 1; i++) {
      invalid.add(prefix + messages.get(i));
    }

    Assert.assertFalse(StegFiles.validateDecodedSet(invalid));

    invalid.add(invalidPrefix + messages.get(messages.size() - 1));

    Assert.assertFalse(StegFiles.validateDecodedSet(invalid));
  }
}