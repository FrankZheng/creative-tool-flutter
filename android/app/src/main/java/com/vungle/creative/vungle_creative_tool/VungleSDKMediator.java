package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.renderscript.Allocation;

import com.vungle.warren.AdConfig;
import com.vungle.warren.InitCallback;
import com.vungle.warren.LoadAdCallback;
import com.vungle.warren.PlayAdCallback;
import com.vungle.warren.Vungle;
import com.vungle.warren.error.VungleError;
import com.vungle.warren.network.VungleApiClient;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.FlutterException;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class VungleSDKMediator {
    private static VungleSDKMediator sInstance = null;
    private static final String TAG = VungleSDKMediator.class.getSimpleName();

    private MethodChannel sdkCallbackChan;
    private MethodChannel sdkChan;
    private Context context;
    private LinkedList<String> queue = new LinkedList<>();

    public static VungleSDKMediator getInstance(Context context) {
        if(sInstance == null) {
            sInstance = new VungleSDKMediator(context);
        }
        return sInstance;
    }

    private VungleSDKMediator(Context context) {
        this.context = context.getApplicationContext();
    }


    public void init(FlutterView flutterView) {
        sdkCallbackChan = new MethodChannel(flutterView, FlutterChannelDefines.kSDKCallbackChan);
        sdkChan = new MethodChannel(flutterView, FlutterChannelDefines.kSDKChan);
        sdkChan.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                handleSDKMethods(methodCall, result);
            }
        });
    }

    private Map<String, Object> toErrorMap(Throwable e) {
        Map<String, Object> map = new HashMap<>();
        if(e != null) {
            VungleError err = e instanceof VungleError ? (VungleError)e : null;
            map.put(FlutterChannelDefines.kErrCode, err != null ? err.getErrorCode() : 0);
            map.put(FlutterChannelDefines.kErrMsg, e.getLocalizedMessage());
        }
        return map;
    }

    private Map<String, Object> toSuccessMap() {
        Map<String, Object> map = new HashMap<>();
        map.put(FlutterChannelDefines.kReturnValue, true);
        return map;
    }

    private void startSDK(MethodCall methodCall, MethodChannel.Result result) {
        String appId = methodCall.argument("appId");
        //List<String> placementds = methodCall.argument("placements");
        String serverUrl = methodCall.argument("serverURL");
        //String sdkVersion = methodCall.argument("sdkVersion");

        setSDKAPIEndpoint(serverUrl);

        Vungle.init(appId, context, new InitCallback() {
            @Override
            public void onSuccess() {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kSDKDidInitialized, null);
                if(!queue.isEmpty()) {
                    doLoadAd(queue.poll());
                }
            }

            @Override
            public void onError(Throwable throwable) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kSDKFailedToInitialize, toErrorMap(throwable));
            }

            @Override
            public void onAutoCacheAdAvailable(String s) {

            }
        });
        result.success(toSuccessMap());
    }

    private void doLoadAd(String placementId) {
        Vungle.loadAd(placementId, new LoadAdCallback() {
            @Override
            public void onAdLoad(String s) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdLoaded, placementId);
            }

            @Override
            public void onError(String s, Throwable throwable) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdLoadFailed, toErrorMap(throwable));
            }
        });
    }

    private void loadAd(String placementId, MethodChannel.Result result) {
        if(Vungle.isInitialized()) {

            if(Vungle.canPlayAd(placementId)) {
                //TODO: clear cache
            }
            doLoadAd(placementId);
        } else {
            queue.offer(placementId);
        }

        result.success(toSuccessMap());
    }

    private void playAd(String placementId, MethodChannel.Result result) {
        AdConfig config = new AdConfig();
        config.setAutoRotate(true);
        Vungle.playAd(placementId, config, new PlayAdCallback() {
            @Override
            public void onAdStart(String s) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdWillShow, placementId);
            }

            @Override
            public void onAdEnd(String s, boolean b, boolean b1) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdWillClose, placementId);
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdDidClose, placementId);
            }

            @Override
            public void onError(String s, Throwable throwable) {
                //TODO: add a failed to play callback later
            }
        });
        result.success(toSuccessMap());
    }

    private void handleSDKMethods(MethodCall methodCall, MethodChannel.Result result) {
        String placementId = methodCall.argument("placementId");
        switch (methodCall.method) {
            case FlutterChannelDefines.kSDKVersion:
                result.success("6.3.24");
                break;
            case FlutterChannelDefines.kSDKVersionList:
                result.success(Collections.singleton("6.3.24"));
                break;
            case FlutterChannelDefines.kStartApp:
                startSDK(methodCall, result);
                break;
            case FlutterChannelDefines.kIsCached:
                result.success(Vungle.canPlayAd(placementId));
                break;
            case FlutterChannelDefines.kLoadAd:
                loadAd(placementId, result);
                break;
            case FlutterChannelDefines.kPlayAd:
                playAd(placementId, result);
                break;
            case FlutterChannelDefines.kClearCache:
                //TODO: to implement
                result.success(toSuccessMap());
                break;
            case FlutterChannelDefines.kForceCloseAd:
                //TODO: to implement
                result.success(toSuccessMap());
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void setSDKAPIEndpoint(String endpoint) {
        try {
            Field field = VungleApiClient.class.getDeclaredField("BASE_URL");
            field.setAccessible(true);
            field.set(null, endpoint);
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }



}
