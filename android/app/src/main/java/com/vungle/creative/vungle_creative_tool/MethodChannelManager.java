package com.vungle.creative.vungle_creative_tool;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

public class MethodChannelManager {
    private static MethodChannelManager sInstance;


    public static MethodChannelManager getInstance() {
        return sInstance;
    }

    private final BinaryMessenger messenger;

    private MethodChannelManager(BinaryMessenger messenger) {
        this.messenger = messenger;
    }

    public static MethodChannelManager create(BinaryMessenger messenger) {
        if(sInstance == null) {
            sInstance = new MethodChannelManager(messenger);
        }
        return sInstance;
    }


    public MethodChannel createChannel(String name, MethodChannel.MethodCallHandler handler) {
        MethodChannel chan = new MethodChannel(messenger, name);
        if(handler != null) {
            chan.setMethodCallHandler((call, result) -> {
                AppInitializer.addCompletionListener(() -> {
                    handler.onMethodCall(call, result);
                });
            });
        }
        return chan;
    }

    public MethodChannel createChannel(String name) {
        return createChannel(name, null);
    }




}
