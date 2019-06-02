package com.vungle.creative.vungle_creative_tool;

import android.os.Looper;
import android.util.Log;
import android.webkit.WebView;

import com.vungle.warren.ui.VungleActivity;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;

import java.lang.ref.WeakReference;
import java.lang.reflect.Field;


@Aspect
public class VungleSDKRespectJ {
    private static final String TAG = VungleSDKRespectJ.class.getSimpleName();

    private static WeakReference<WebView> currentWebViewRef;
    private static WeakReference<VungleActivity> currentVungleActivityRef;

    @After("execution(* com.vungle.warren.ui.VungleWebClient.onPageFinished(..))")
    public void VungleWebViewClient_onPageFinishedAfter(JoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        if(args == null || args.length < 2) {
            return;
        }
        WebView webView = (WebView)args[0];
        //String url = (String )args[1];
        currentWebViewRef = new WeakReference<>(webView);
        //inject our js
        final ResourceManager resourceManager = ResourceManager.getInstance();
        String injectJs = "javascript:" + resourceManager.getInjectJs();
        //webView.loadUrl(injectJs);
        webView.evaluateJavascript(injectJs, null);
    }

    @Around("execution(* com.vungle.warren.ui.JavascriptBridge.performAction(..))")
    public void JavascriptBridge_onPerformActionAround(ProceedingJoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        if(args == null || args.length < 1) {
            joinPoint.proceed();
            return;
        }
        boolean intercept = false;
        String action = (String)args[0];
        Log.d(TAG, "JavascriptBridge_onPerformActionAround, action: " + action);
        if(action != null && !action.isEmpty()) {
            String[] prefixes = {"log:", "error:", "trace:"};
            for( String prefix : prefixes) {
                if(action.startsWith(prefix)) {
                    String content = action.substring(prefix.length());
                    String type = prefix.substring(0, prefix.length()-1); //remove ":"
                    VungleSDKMediator.getInstance().onJsLog(type, content);
                    intercept = true;
                }
            }
        }
        if(!intercept) {
            if("close".equals(action)) {
                currentWebViewRef = null;
                currentVungleActivityRef = null;
            }
            joinPoint.proceed();
        }
    }

    @After("execution(* com.vungle.warren.ui.VungleActivity.prepare(..))")
    public void VungleActivity_onPrepareAfter(JoinPoint joinPoint) throws Throwable {
        Log.d(TAG, "VungleActivity_onPrepareAfter" );
        VungleActivity vungleActivity = (VungleActivity)joinPoint.getTarget();
        currentVungleActivityRef = new WeakReference<>(vungleActivity);
        if(VungleSDKMediator.getInstance().isCORsEnabled()) {
            VungleActivity activity = (VungleActivity)joinPoint.getTarget();
            try {
                Field field = VungleActivity.class.getDeclaredField("webView");
                field.setAccessible(true);
                WebView webView = (WebView)field.get(activity);
                webView.getSettings().setAllowFileAccessFromFileURLs(true);
                webView.getSettings().setAllowUniversalAccessFromFileURLs(true);
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            } catch (NoSuchFieldException e) {
                e.printStackTrace();
            }
        }
    }

    public static void forceCloseAd() {
        if(currentWebViewRef != null && currentWebViewRef.get() != null) {
            WebView webView = currentWebViewRef.get();
            webView.post(() -> {
                String js = "javascript:Android.performAction('close');";
                webView.evaluateJavascript(js, null);
            });
        }
    }

    public static VungleActivity getCurrentVungleActivity() {
        return currentVungleActivityRef != null ? currentVungleActivityRef.get() : null;
    }




 }
