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

import android.app.Activity;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.util.Log;
import com.github.jsavas.enpiction.steganography.text.AsyncTaskCallback.TextDecodingCallback;
import com.github.jsavas.enpiction.steganography.utils.Utility;

import java.util.List;


public class TextDecoding extends AsyncTask<ImageSteganography, Void, ImageSteganography> {
  //Tag for Log
  private final static String TAG = TextDecoding.class.getName();

  private final ImageSteganography result;
  //Callback interface for AsyncTask
  private final TextDecodingCallback textDecodingCallback;
  private ProgressDialog progressDialog;

  public TextDecoding(Activity activity, TextDecodingCallback textDecodingCallback) {
    super();
    this.progressDialog = new ProgressDialog(activity);
    this.textDecodingCallback = textDecodingCallback;
    //making result object
    this.result = new ImageSteganography();
  }

  //setting progress dialog if wanted
  public void setProgressDialog(ProgressDialog progressDialog) {
    this.progressDialog = progressDialog;
  }

  //pre execution of method
  @Override
  protected void onPreExecute() {
    super.onPreExecute();

    //setting parameters of progress dialog
    if (progressDialog != null) {
      progressDialog.setMessage("Loading, Please Wait...");
      progressDialog.setTitle("Decoding Message");
      progressDialog.setIndeterminate(true);
      progressDialog.setCancelable(false);
      progressDialog.show();

    }
  }

  @Override
  protected void onPostExecute(ImageSteganography imageSteganography) {
    super.onPostExecute(imageSteganography);

    //dismiss progress dialog
    if (progressDialog != null)
      progressDialog.dismiss();

    //sending result to callback
    textDecodingCallback.onCompleteTextEncoding(result);
  }

  @Override
  protected ImageSteganography doInBackground(ImageSteganography... imageSteganographies) {

    //If it is not already decoded
    if (imageSteganographies.length > 0) {

      ImageSteganography imageSteganography = imageSteganographies[0];

      //getting bitmap image from file
      Bitmap bitmap = imageSteganography.getImage();

      //return null if bitmap is null
//            if (bitmap == null)
//                return null;

      //splitting images
      List<Bitmap> srcEncodedList = Utility.splitImage(bitmap);

      //decoding encrypted zipped message
      String decoded_message = Decode.decodeMessage(srcEncodedList);

      //Log.d(TAG, "Decoded_Message : " + decoded_message);

      //text decoded = true
      if (!Utility.isStringEmpty(decoded_message)) {
        result.setDecoded(true);
      }

      //decrypting the encoded message
      String decrypted_message = ImageSteganography.decryptMessage(decoded_message, imageSteganography.getSecret_key());
      //Log.d(TAG, "Decrypted message : " + decrypted_message);

      //If decrypted_message is null it means that the secret key is wrong otherwise secret key is right.
      if (!Utility.isStringEmpty(decrypted_message)) {

        //secret key provided is right
        result.setSecretKeyWrong(false);

        // Set Results

        result.setMessage(decrypted_message);


        //free memory
        for (Bitmap bitm : srcEncodedList)
          bitm.recycle();

        //Java Garbage Collector
        System.gc();
      }
    }

    return result;
  }
}
