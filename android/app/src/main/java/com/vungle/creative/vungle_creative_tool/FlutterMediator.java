package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.support.annotation.NonNull;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class FlutterMediator implements WebServer.Listener {
    private static FlutterMediator sInstance;

    private MethodChannel webServerCallbackChan;
    private MethodChannel webServerChan;
    private Context context;

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
        final WebServer webServer = App.getWebServer();
        webServer.listener = this;

        webServerChan = new MethodChannel(flutterView, FlutterChannelDefines.kWebServerChan);
        webServerChan.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                handleWebServerMethods(methodCall, result);
            }
        });
        webServerCallbackChan = new MethodChannel(flutterView, FlutterChannelDefines.kWebServerCallbackChan);

        //TODO: app channel
    }

    private void handleWebServerMethods(MethodCall methodCall, MethodChannel.Result result) {
        final WebServer webServer = App.getWebServer();
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
                webServer.setVerifyRequiredJsCalls(enabled);
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
}
