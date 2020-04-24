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

import 'package:image/image.dart';
import 'package:uuid/uuid.dart';

const _squareBlockSize = 512;
final _uuid = Uuid();
int _uuidLength = _uuid.v4().length;

List<Image> _splitImage(Image img) {
  final int rows = (img.height / _squareBlockSize).ceil();
  final int cols = (img.width / _squareBlockSize).ceil();

  final int chunkHeightMod = img.height % _squareBlockSize;
  final int chunkWidthMod = img.width % _squareBlockSize;

  List<Image> images = [];

  for (int x = 0; x < rows; x++) {
    for (int y = 0; y < cols; y++) {
      final int chunkHeight = (x == rows - 1 && chunkHeightMod > 0) ? chunkHeightMod : _squareBlockSize;
      final int chunkWidth = (y == cols - 1 && chunkWidthMod > 0) ? chunkWidthMod : _squareBlockSize;

      images.add(copyCrop(img, y * _squareBlockSize, x * _squareBlockSize, chunkWidth, chunkHeight));
    }
  }

  return images;
}

Image _mergeImages(List<Image> images, int originalHeight, int originalWidth) {
  final int rows = (originalHeight ~/ _squareBlockSize).ceil();
  final int cols = (originalWidth ~/ _squareBlockSize).ceil();

  final int chunkHeightMod = originalHeight % _squareBlockSize;
  final int chunkWidthMod = originalWidth % _squareBlockSize;

  Image img = Image(originalWidth, originalHeight);

  int count = 0;

  for (int x = 0; x < rows; x++) {
    for (int y = 0; y < cols; y++) {
      copyInto(img, images[count],
          dstX: y * _squareBlockSize,
          dstY:  x * _squareBlockSize,
          blend: false);

      count++;
    }
  }

  return img;
}