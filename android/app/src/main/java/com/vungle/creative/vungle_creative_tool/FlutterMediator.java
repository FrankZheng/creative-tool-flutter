package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.support.annotation.NonNull;
import android.util.Log;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class FlutterMediator implements WebServer.Listener, AppInitializer.Listener {
    private static final String TAG = FlutterMediator.class.getSimpleName();
    private static FlutterMediator sInstance;

    private MethodChannel webServerCallbackChan;
    private Context context;
    private WebServer webServer;
    private Boolean enableVerifyJsCalls = null;

    private FlutterMediator(Context context) {
        this.context = context.getApplicationContext();
    }

    public static FlutterMediator getInstance(Context context) {
        if(sInstance == null) {
            sInstance = new FlutterMediator(context);
        }
        return sInstance;
    }

    public void init(@NonNull FlutterView flutterView) {
        if(AppInitializer.isInitialized()) {
            webServer = WebServer.getInstance();
            webServer.setListener(this);
        } else {
            AppInitializer.addListener(this);
        }

        final MethodChannel webServerChan = new MethodChannel(flutterView, FlutterChannelDefines.kWebServerChan);
        webServerChan.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                handleWebServerMethods(methodCall, result);
            }
        });
        webServerCallbackChan = new MethodChannel(flutterView, FlutterChannelDefines.kWebServerCallbackChan);

        //TODO: app channel
        final MethodChannel appChan = new MethodChannel(flutterView, FlutterChannelDefines.kAppChan);
        appChan.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                handleAppMethods(methodCall, result);
            }
        });
    }

    private void handleAppMethods(MethodCall methodCall, MethodChannel.Result result) {
        if(FlutterChannelDefines.kInitialize.equals(methodCall.method)) {
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    AppInitializer.start(context);
                    result.success(null);
                }
            });
            t.start();
        } else if(FlutterChannelDefines.kCloseApp.equals(methodCall.method)) {
            //TODO: to be implemented
        } else {
            result.notImplemented();
        }
    }

    private void handleWebServerMethods(MethodCall methodCall, MethodChannel.Result result) {
        Log.d(TAG, "handleWebServerMethods: " + methodCall.method + "," + methodCall.arguments);
        switch (methodCall.method) {
            case FlutterChannelDefines.kServerURL:
                result.success(webServer.getServerUrl(context));
                break;
            case FlutterChannelDefines.kLocalhostURL:
                result.success(webServer.getLocalHostUrl());
                break;
            case FlutterChannelDefines.kEndCardName:
                result.success(webServer.getEndCardName());
                break;
            case FlutterChannelDefines.kEnableVerifyJsCalls:
                Boolean enabled = (Boolean)methodCall.arguments;
                assert enabled != null;
                if(webServer != null) {
                    webServer.setVerifyRequiredJsCalls(enabled);
                } else {
                    enableVerifyJsCalls = enabled;
                }

                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onEndCardUploaded(String zipName) {
        webServerCallbackChan.invokeMethod(FlutterChannelDefines.kEndcardUploaded, zipName);
    }

    @Override
    public void onInitialized() {
        webServer = WebServer.getInstance();
        webServer.setListener(this);
        if(enableVerifyJsCalls != null) {
            webServer.setVerifyRequiredJsCalls(enableVerifyJsCalls);
        }
    }
}
