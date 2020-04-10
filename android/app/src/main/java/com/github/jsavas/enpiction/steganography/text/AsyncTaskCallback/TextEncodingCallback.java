package com.github.jsavas.enpiction.steganography.text.AsyncTaskCallback;

import com.github.jsavas.enpiction.steganography.text.ImageSteganography;

public interface TextEncodingCallback {

  void onStartTextEncoding();

  void onCompleteTextEncoding(ImageSteganography result);
}
