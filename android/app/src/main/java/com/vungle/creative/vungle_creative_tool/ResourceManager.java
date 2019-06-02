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
    private static ResourceManager sInstance = null;
    private String injectJs;
    private final File assetsDir;
    private final File uploadDir;

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

    private ResourceManager(File assetsDir, File uploadDir) {
        this.assetsDir = assetsDir;
        this.uploadDir = uploadDir;
    }

    public static ResourceManager create(File assetsDir, File uploadDir) {
        sInstance = new ResourceManager(assetsDir, uploadDir);
        return sInstance;
    }

    public static ResourceManager getInstance() {
        return sInstance;
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
