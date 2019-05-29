package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class ResourceManager {
    private static final String TAG = ResourceManager.class.getSimpleName();
    private String injectJs;
    private File assetsDir;
    private File uploadDir;

    @Nullable
    public String getInjectJs() {
        return injectJs;
    }

    @Nullable
    public File getAssetsDir() {
        return assetsDir;
    }

    @Nullable
    public File getUploadDir() {
        return uploadDir;
    }

    public ResourceManager() {

    }

    public void init(@NonNull final Context context) {
        //load inject js from raw
        InputStream in = context.getResources().openRawResource(R.raw.injectjs);
        try {
            injectJs = Utils.contentOfInputStream(in);
            in.close();
        } catch (IOException e) {
            Log.e(TAG, "Failed to read content from inject.js");
        }

        //copy assets
        assetsDir = context.getDir("assets", Context.MODE_PRIVATE);
        uploadDir = new File(assetsDir, "upload");
        if(!uploadDir.exists()) {
            if(!uploadDir.mkdir()) {
                Log.e(TAG, "Failed to create upload dir");
                return;
            }
        }

        String[] assets = {"index.html", "main.js", "style.css", "countdown_video.mp4", "endcard.zip"};
        for(String asset : assets) {
            try {
                in = context.getAssets().open(asset);
                File targetFile = new File(assetsDir, asset);
                if(!targetFile.exists()) {
                    OutputStream out = new FileOutputStream(targetFile);
                    Utils.copyFile(in, out);
                }
            } catch (IOException e) {
                Log.e(TAG, "Failed to copy asset", e);
            }
        }
    }
}
