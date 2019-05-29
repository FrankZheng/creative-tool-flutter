package com.vungle.creative.vungle_creative_tool;

import android.support.annotation.NonNull;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class FlutterMediator implements WebServer.Listener {
    private static final FlutterMediator sInstance = new FlutterMediator();

    private MethodChannel webServerCallbackChan;

    private FlutterMediator() {

    }

    public static FlutterMediator getInstance() {
        return sInstance;
    }

    public void init(@NonNull FlutterView flutterView) {
        final WebServer webServer = App.getWebServer();
        webServer.listener = this;

        new MethodChannel(flutterView, FlutterChannelDefines.kWebServerChan).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
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
                result.success(webServer.getServerUrl());
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
