package com.vungle.creative.vungle_creative_tool;

import android.app.Application;
import android.support.annotation.NonNull;
import android.util.Log;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.app.FlutterApplication;


public class App extends FlutterApplication {
    private static final String TAG = App.class.getSimpleName();
    private static WebServer webServer;
    private static ResourceManager resourceManager;

    private static AtomicBoolean initialized = new AtomicBoolean(false);

    public interface listener {
        void onAppInitialized();
    }

    @Override
    public void onCreate() {
        super.onCreate();

        Thread thread = new Thread(new Runnable() {
            @Override
            public void run() {
                resourceManager = new ResourceManager();
                resourceManager.init(App.this);
                int port = 8091;
                webServer = new WebServer(port, resourceManager.getAssetsDir(), resourceManager.getUploadDir(), true);
                webServer.setup(App.this);
                try {
                    webServer.start();
                } catch (IOException e) {
                    Log.e(TAG, "Failed to start web server", e);
                }
                Log.d(TAG, "app initialized");
                initialized.set(true);
            }
        }, "app_init_thread");
        thread.start();
    }

    @NonNull
    public static WebServer getWebServer() {
        return webServer;
    }

    @NonNull
    public static ResourceManager getResourceManager() {
        return resourceManager;
    }

    public static boolean isInitialized() {
        return initialized.get();
    }
}
