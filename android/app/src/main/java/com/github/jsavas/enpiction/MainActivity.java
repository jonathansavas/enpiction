package com.github.jsavas.enpiction;

import android.Manifest;
import android.content.pm.PackageManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.github.jsavas.enpiction.steganography.StegFiles;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class MainActivity extends FlutterActivity {
  private static final String ENCODE_CHANNEL = "com.github.jsavas/encode";
  private static final String DECODE_CHANNEL = "com.github.jsavas/decode";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ENCODE_CHANNEL)
      .setMethodCallHandler(
        (call, result) -> {
          if (call.method.equals("encode")) {

            boolean successfulEncoding = StegFiles.encode(
              (Map<String, String>) call.argument("pathsToMessages"),
              call.argument("encryptionKey"));

            if (successfulEncoding) {
              result.success(successfulEncoding);
            } else {
              result.error("UNAVAILABLE", "Failed to encode messages", false);
            }
          } else {
            result.notImplemented();
          }
        }
      );

    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DECODE_CHANNEL)
      .setMethodCallHandler(
        (call, result) -> {
          if (call.method.equals("decodeAndValidate")) {

            List<String> messages = StegFiles.decodeAndValidate(
              (List<String>) call.argument("filePaths"),
              call.argument("encryptionKey"));

            if (messages != null) {
              result.success(messages);
            } else {
              result.success(new ArrayList<>());
            }

          } else {
            result.notImplemented();
          }
        }
      );

    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

}
