package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.util.LinkedList;
import java.util.List;


public class AppInitializer {
    private static final String TAG = AppInitializer.class.getSimpleName();

    private static boolean initialized = false;

    interface Listener {
        void onInitialized();
    }

    private static List<WeakReference<Listener>> listeners = new LinkedList<>();

    public static void addListener(Listener listener) {
        listeners.add(new WeakReference<>(listener));
    }

    public static void removeListener(Listener listener) {
        for(WeakReference<Listener> ref : listeners) {
            if(ref.get() != null && ref.get() == listener) {
                listeners.remove(ref);
            }
        }
    }

    public static void start(Context context) {
        ResourceManager resourceManager = new ResourceManager();
        resourceManager.init(context);
        int port = 8091;
        File assetsDir = resourceManager.getAssetsDir();
        File uploadDir = resourceManager.getUploadDir();
        WebServer webServer = new WebServer(port, assetsDir, uploadDir, true);
        webServer.setup(context);
        WebServer.setInstance(webServer);
        try {
            webServer.start();
        } catch (IOException e) {
            Log.e(TAG, "Failed to start web server", e);
        }
        Log.d(TAG, "app initialized");
        initialized = true;
        for(WeakReference<Listener> ref : listeners) {
            if(ref.get() != null) {
                ref.get().onInitialized();
            }
        }
    }

    public static boolean isInitialized() {
        return initialized;
    }
}
