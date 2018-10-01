package com.q.ml.cordova.plugin;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Point;
import android.support.annotation.NonNull;
import android.util.Base64;
import android.util.Log;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.FirebaseApp;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.text.FirebaseVisionTextRecognizer;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;

public class QMLCordova extends CordovaPlugin {
    private final String TAG = "FirebasePlugin";

    @Override
    protected void pluginInitialize() {
        final Context context = this.cordova.getActivity().getApplicationContext();
        this.cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                Log.d(TAG, "Starting Firebase plugin");
                FirebaseApp.initializeApp(context);
            }
        });
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("ocr")) {
            this.ocr(callbackContext, args.getString(0), args.getBoolean(1));
            return true;
        } else if (action.equals("logError")) {
            this.logError(callbackContext, args.getString(0));
            return true;
        }

        return false;
    }

    private void ocr(final CallbackContext callbackContext,final String image,final Boolean isCloud) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                if (image == null) {
                    callbackContext.error("Image has invalid format");
                }

                Bitmap imageBitmap = null;
                if (image.contains("file://")) {
                    File imgFile = new File(image.replace("file://", ""));
                    if (imgFile.exists()) {
                        imageBitmap = BitmapFactory.decodeFile(imgFile.getAbsolutePath());
                    }
                } else {
                    byte[] decodedString = Base64.decode(image, Base64.DEFAULT);
                    imageBitmap = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
                }
                if (imageBitmap == null) {
                    callbackContext.error("Image has invalid format");
                }
                FirebaseVisionImage firebaseImage = FirebaseVisionImage.fromBitmap(imageBitmap);

                FirebaseVisionTextRecognizer textRecognizer = FirebaseVision.getInstance().getOnDeviceTextRecognizer();
                if(isCloud) {
                    textRecognizer = FirebaseVision.getInstance().getCloudTextRecognizer();
                }

                textRecognizer.processImage(firebaseImage)
                        .addOnSuccessListener(new OnSuccessListener<FirebaseVisionText>() {
                            @Override
                            public void onSuccess(FirebaseVisionText result) {
                                JSONArray results = new JSONArray();

                                for (FirebaseVisionText.TextBlock block: result.getTextBlocks()) {
                                    JSONArray lineArray = new JSONArray();
                                    for (FirebaseVisionText.Line line: block.getLines()) {
                                        JSONObject jsonLine = new JSONObject();
                                        try {
                                            jsonLine.put("text", line.getText());
                                            jsonLine.put("language", (line.getRecognizedLanguages().isEmpty()) ? "":line.getRecognizedLanguages().get(0).getLanguageCode());

                                            JSONArray cornerPoints = new JSONArray();
                                            if(line.getCornerPoints() != null && line.getCornerPoints().length > 0) {
                                                for (Point point : line.getCornerPoints()) {
                                                    JSONObject tempObject = new JSONObject();
                                                    tempObject.put("x", point.x);
                                                    tempObject.put("y", point.y);
                                                    cornerPoints.put(tempObject);
                                                }
                                            }
                                            jsonLine.put("cornerPoints", cornerPoints);
                                            lineArray.put(jsonLine);
                                        } catch (JSONException e) {
                                            e.printStackTrace();
                                        }
                                    }
                                    results.put(lineArray);
                                }


                                callbackContext.success(results);
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                                    @Override
                                    public void onFailure(@NonNull Exception e) {
                                        callbackContext.error(e.getLocalizedMessage());
                                    }
                                });
            }
        });
    }

    private void logError(final CallbackContext callbackContext, final String message) throws JSONException {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    callbackContext.success(1);
                } catch (Exception e) {
                    e.printStackTrace();
                    callbackContext.error(e.getMessage());
                }
            }
        });
    }
}
