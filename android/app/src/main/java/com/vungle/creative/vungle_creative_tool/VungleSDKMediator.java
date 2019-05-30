package com.vungle.creative.vungle_creative_tool;

import android.content.Context;
import android.util.Log;

import com.vungle.warren.AdConfig;
import com.vungle.warren.InitCallback;
import com.vungle.warren.LoadAdCallback;
import com.vungle.warren.PlayAdCallback;
import com.vungle.warren.Vungle;
import com.vungle.warren.error.VungleError;
import com.vungle.warren.network.VungleApiClient;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

public class VungleSDKMediator {
    private static VungleSDKMediator sInstance = null;
    private static final String TAG = VungleSDKMediator.class.getSimpleName();
    private static final String PLACEMENT_ID = "placementId";
    private static final String SDK_VERSION = "6.3.24";

    private MethodChannel sdkCallbackChan;
    private Context context;
    private boolean enableCORs = false;

    public static VungleSDKMediator getInstance(Context context) {
        if(sInstance == null) {
            sInstance = new VungleSDKMediator(context);
        }
        return sInstance;
    }

    public static VungleSDKMediator getInstance() {
        return sInstance;
    }

    private VungleSDKMediator(Context context) {
        this.context = context.getApplicationContext();
    }

    public void init(FlutterView flutterView) {
        sdkCallbackChan = new MethodChannel(flutterView, FlutterChannelDefines.kSDKCallbackChan);
        final MethodChannel sdkChan = new MethodChannel(flutterView, FlutterChannelDefines.kSDKChan);
        sdkChan.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                handleSDKMethods(methodCall, result);
            }
        });
    }

    public void onJsLog(String type, String rawLog) {
        Map<String, String> map = new HashMap<>();
        map.put("type", type);
        map.put("rawLog", rawLog);
        sdkCallbackChan.invokeMethod(FlutterChannelDefines.kOnLog, map);
    }

    public boolean isCORsEnabled() {
        return enableCORs;
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
        String serverUrl = methodCall.argument("serverURL");
        //String sdkVersion = methodCall.argument("sdkVersion");
        //List<String> placementds = methodCall.argument("placements");

        setSDKAPIEndpoint(serverUrl);

        Vungle.init(appId, context, new InitCallback() {
            @Override
            public void onSuccess() {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kSDKDidInitialized, null);
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

    private void loadAd(String placementId, MethodChannel.Result result) {
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
        result.success(toSuccessMap());
    }

    private void playAd(String placementId, MethodChannel.Result result) {
        AdConfig config = new AdConfig();
        config.setAutoRotate(true);
        Vungle.playAd(placementId, config, new PlayAdCallback() {
            @Override
            public void onAdStart(String pId) {
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdWillShow, pId);
            }

            @Override
            public void onAdEnd(String pId, boolean completed, boolean didDownload) {
                Map<String, Object> args = new HashMap<>();
                args.put(PLACEMENT_ID, pId);
                args.put("completed", completed);
                args.put("didDownload", didDownload);
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdWillClose, args);
                sdkCallbackChan.invokeMethod(FlutterChannelDefines.kAdDidClose, args);
            }

            @Override
            public void onError(String s, Throwable throwable) {
                //TODO: add a failed to play callback later
            }
        });
        result.success(toSuccessMap());
    }

    private void handleSDKMethods(MethodCall methodCall, MethodChannel.Result result) {
        Log.d(TAG, "handleSDKMethods: " + methodCall.method + "," + methodCall.arguments);
        String placementId;
        switch (methodCall.method) {
            case FlutterChannelDefines.kSDKVersion:
                result.success(SDK_VERSION);
                break;
            case FlutterChannelDefines.kSDKVersionList:
                List<String> versions = new ArrayList<>();
                versions.add(SDK_VERSION);
                result.success(versions);
                break;
            case FlutterChannelDefines.kStartApp:
                startSDK(methodCall, result);
                break;
            case FlutterChannelDefines.kIsCached:
                placementId = (String)methodCall.arguments;
                result.success(Vungle.canPlayAd(placementId));
                break;
            case FlutterChannelDefines.kLoadAd:
                placementId = (String)methodCall.arguments;
                loadAd(placementId, result);
                break;
            case FlutterChannelDefines.kPlayAd:
                Boolean enabled = methodCall.argument("isCORs");
                if(enabled != null) {
                    enableCORs = enabled;
                }
                placementId = methodCall.argument(PLACEMENT_ID);
                playAd(placementId, result);
                break;
            case FlutterChannelDefines.kClearCache:
                placementId = (String)methodCall.arguments;
                clearCache(placementId);
                result.success(toSuccessMap());
                break;
            case FlutterChannelDefines.kForceCloseAd:
                VungleSDKRespectJ.forceCloseAd();
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

    private void clearCache(String placementId) {
        //Android SDK only support clear all cache
        try {
            Method m = Vungle.class.getDeclaredMethod("clearCache");
            m.setAccessible(true);
            m.invoke(null);
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }



}
