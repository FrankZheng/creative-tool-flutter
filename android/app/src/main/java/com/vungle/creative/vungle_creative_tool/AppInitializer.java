package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.app.FlutterApplication;


public class AppInitializer extends FlutterApplication  {
    private static final String TAG = AppInitializer.class.getSimpleName();

    private static AtomicBoolean initialized = new AtomicBoolean(false);

    interface CompletionListener {
        void onComplete();
    }


    private static List<WeakReference<CompletionListener>> listeners = new LinkedList<>();

    synchronized public static void addCompletionListener(CompletionListener listener) {
        if(initialized.get()) {
            if(listener != null) {
                listener.onComplete();
            }
        } else {
            listeners.add(new WeakReference<>(listener));
        }
    }

    synchronized public static void start(Context context, CompletionListener listener) {
        if(listener != null) {
            listeners.add(new WeakReference<>(listener));
        }

        ExecutorService executor = Executors.newFixedThreadPool(3);

        executor.execute(() -> {
            //create folders
            File assetsDir = context.getDir("assets", Context.MODE_PRIVATE);
            File uploadDir = new File(assetsDir, "upload");
            if(!uploadDir.exists()) {
                if(!uploadDir.mkdir()) {
                    Log.e(TAG, "Failed to create upload dir");
                    return;
                }
            }

            //step 1
            Callable<Void> op1 = () -> {
                ResourceManager.create(assetsDir, uploadDir).init(context);
                return null;
            };

            //step 2
            Callable<Void> op2 = () -> {
                WebServer webServer = WebServer.create(assetsDir, uploadDir, true);
                webServer.setup(context);
                try {
                    webServer.start();
                } catch (IOException e) {
                    Log.e(TAG, "Failed to start web server", e);
                }
                return null;
            };

            List<Callable<Void>> operations = Arrays.asList(op1, op2);
            List<Future<Void>> futures = new ArrayList<>(operations.size());
            for(Callable<Void> op : operations) {
                futures.add(executor.submit(op));
            }

            for(Future<Void> future : futures) {
                try {
                    future.get();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (ExecutionException e) {
                    e.printStackTrace();
                }
            }

            Log.d(TAG, "app initialized");


            initialized.set(true);
            for(WeakReference<CompletionListener> ref : listeners) {
                if(ref.get() != null) {
                    ref.get().onComplete();
                }
            }
        });

    }

    public static boolean isInitialized() {
        return initialized.get();
    }

    @Override
    public void onCreate() {
        super.onCreate();

        AppInitializer.start(this, null);
    }
}
