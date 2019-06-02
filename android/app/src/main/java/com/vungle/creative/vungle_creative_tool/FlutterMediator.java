package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.util.Log;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterMediator implements WebServer.Listener{

    private static final String TAG = FlutterMediator.class.getSimpleName();
    private static FlutterMediator sInstance;

    private final MethodChannel webServerCallbackChan;
    private final Context context;
    private final WebServer webServer;

    private Boolean enableVerifyJsCalls = null;


    private FlutterMediator(Context context) {
        this.context = context.getApplicationContext();

        webServer = WebServer.getInstance();
        webServer.setListener(this);

        MethodChannelManager channelManager = MethodChannelManager.getInstance();

        channelManager.createChannel(
                Constants.kWebServerChan,
                this::handleWebServerMethods);

        webServerCallbackChan = channelManager.createChannel(Constants.kWebServerCallbackChan);

        channelManager.createChannel(Constants.kAppChan, this::handleAppMethods);

    }

    public static FlutterMediator getInstance() {
        return sInstance;
    }

    public static FlutterMediator create(Context context) {
        if(sInstance == null) {
            sInstance = new FlutterMediator(context);
        }
        return sInstance;
    }

    private void handleAppMethods(MethodCall methodCall, MethodChannel.Result result) {
        if(Constants.kCloseApp.equals(methodCall.method)) {
            //TODO: to be implemented
        } else {
            result.notImplemented();
        }
    }

    private void handleWebServerMethods(MethodCall methodCall, MethodChannel.Result result) {
        Log.d(TAG, "handleWebServerMethods: " + methodCall.method + "," + methodCall.arguments);
        switch (methodCall.method) {
            case Constants.kServerURL:
                result.success(webServer.getServerUrl(context));
                break;
            case Constants.kLocalhostURL:
                result.success(webServer.getLocalHostUrl());
                break;
            case Constants.kEndCardName:
                result.success(webServer.getEndCardName());
                break;
            case Constants.kEnableVerifyJsCalls:
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
        webServerCallbackChan.invokeMethod(Constants.kEndCardUploaded, zipName);
    }

}
