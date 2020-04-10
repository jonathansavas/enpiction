package com.github.jsavas.enpiction.steganography.text;

public interface ProgressHandler {

  void setTotal(int tot);

  void increment(int inc);

  void finished();
}
