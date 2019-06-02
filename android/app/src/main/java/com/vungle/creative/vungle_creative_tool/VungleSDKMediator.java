package com.vungle.creative.vungle_creative_tool;

import android.app.AlertDialog;
import android.content.Context;
import android.util.Log;

import com.vungle.warren.AdConfig;
import com.vungle.warren.InitCallback;
import com.vungle.warren.LoadAdCallback;
import com.vungle.warren.PlayAdCallback;
import com.vungle.warren.Vungle;
import com.vungle.warren.error.VungleError;
import com.vungle.warren.network.VungleApiClient;
import com.vungle.warren.ui.VungleActivity;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class VungleSDKMediator {
    private static VungleSDKMediator sInstance = null;
    private static final String TAG = VungleSDKMediator.class.getSimpleName();
    private static final String PLACEMENT_ID = "placementId";
    private static final String SDK_VERSION = "6.3.24";

    private final MethodChannel sdkCallbackChan;
    private final Context context;
    private boolean enableCORs = false;

    public static VungleSDKMediator create(Context context) {
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
        MethodChannelManager channelManager = MethodChannelManager.getInstance();
        sdkCallbackChan = channelManager.createChannel(Constants.kSDKCallbackChan);
        channelManager.createChannel(Constants.kSDKChan, this::handleSDKMethods);
    }

    public void onJsLog(String type, String rawLog) {
        Map<String, String> map = new HashMap<>();
        map.put("type", type);
        map.put("rawLog", rawLog);
        sdkCallbackChan.invokeMethod(Constants.kOnLog, map);

        if(type.equals("error")) {
            //show dialog to let user choose if force close ad?
            //TODO: make the dialog looks better
            VungleActivity vungleActivity = VungleSDKRespectJ.getCurrentVungleActivity();
            if(vungleActivity != null) {
                final AlertDialog.Builder alert = new AlertDialog.Builder(vungleActivity);
                alert.setTitle("Confirm Close Ad")
                        .setMessage("Some JS error happened, close ad?")
                        .setPositiveButton("YES", (dialogInterface, i) -> {
                            forceCloseAd();
                        });
                alert.setNegativeButton("NO", null);
                alert.show();
            }
        }
    }

    public boolean isCORsEnabled() {
        return enableCORs;
    }

    public void forceCloseAd() {
        VungleSDKRespectJ.forceCloseAd();
    }

    private Map<String, Object> toErrorMap(Throwable e) {
        Map<String, Object> map = new HashMap<>();
        if(e != null) {
            VungleError err = e instanceof VungleError ? (VungleError)e : null;
            map.put(Constants.kErrCode, err != null ? err.getErrorCode() : 0);
            map.put(Constants.kErrMsg, e.getLocalizedMessage());
        }
        return map;
    }

    private Map<String, Object> toSuccessMap() {
        Map<String, Object> map = new HashMap<>();
        map.put(Constants.kReturnValue, true);
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
                sdkCallbackChan.invokeMethod(Constants.kSDKDidInitialized, null);
            }

            @Override
            public void onError(Throwable throwable) {
                sdkCallbackChan.invokeMethod(Constants.kSDKFailedToInitialize, toErrorMap(throwable));
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
                sdkCallbackChan.invokeMethod(Constants.kAdLoaded, placementId);
            }

            @Override
            public void onError(String s, Throwable throwable) {
                sdkCallbackChan.invokeMethod(Constants.kAdLoadFailed, toErrorMap(throwable));
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
                sdkCallbackChan.invokeMethod(Constants.kAdWillShow, pId);
            }

            @Override
            public void onAdEnd(String pId, boolean completed, boolean didDownload) {
                Map<String, Object> args = new HashMap<>();
                args.put(PLACEMENT_ID, pId);
                args.put("completed", completed);
                args.put("didDownload", didDownload);
                sdkCallbackChan.invokeMethod(Constants.kAdWillClose, args);
                sdkCallbackChan.invokeMethod(Constants.kAdDidClose, args);
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
            case Constants.kSDKVersion:
                result.success(SDK_VERSION);
                break;
            case Constants.kSDKVersionList:
                List<String> versions = new ArrayList<>();
                versions.add(SDK_VERSION);
                result.success(versions);
                break;
            case Constants.kStartApp:
                startSDK(methodCall, result);
                break;
            case Constants.kIsCached:
                placementId = (String)methodCall.arguments;
                result.success(Vungle.canPlayAd(placementId));
                break;
            case Constants.kLoadAd:
                placementId = (String)methodCall.arguments;
                loadAd(placementId, result);
                break;
            case Constants.kPlayAd:
                Boolean enabled = methodCall.argument("isCORs");
                if(enabled != null) {
                    enableCORs = enabled;
                }
                placementId = methodCall.argument(PLACEMENT_ID);
                playAd(placementId, result);
                break;
            case Constants.kClearCache:
                placementId = (String)methodCall.arguments;
                clearCache(placementId);
                result.success(toSuccessMap());
                break;
            case Constants.kForceCloseAd:
                forceCloseAd();
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
