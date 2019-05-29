package com.vungle.creative.vungle_creative_tool;

import android.util.Log;
import android.webkit.ValueCallback;
import android.webkit.WebView;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;

//import com.vungle.warren.ui.VungleWebClient;

@Aspect
public class VungleSDKRespectJ {
    private static final String TAG = VungleSDKRespectJ.class.getSimpleName();

    @After("execution(* com.vungle.warren.ui.VungleWebClient.onPageFinished(..))")
    public void VungleWebViewClient_onPageFinishedAfter(JoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        if(args == null || args.length < 2) {
            return;
        }
        WebView webView = (WebView)args[0];
        //String url = (String )args[1];

        //inject our js
        final ResourceManager resourceManager = App.getResourceManager();
        String injectJs = "javascript:" + resourceManager.getInjectJs();
        //webView.loadUrl(injectJs);
        webView.evaluateJavascript(injectJs, new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                Log.d(TAG, "onReceiveValue" + value);
            }
        });
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
        if(action != null && !action.isEmpty()) {
            String[] prefixes = {"log:", "error:", "trace:"};
            for( String prefix : prefixes) {
                if(action.startsWith(prefix)) {
                    String content = action.substring(prefix.length());
                    if(prefix.equals("log:")) {
                        Log.d(TAG, "JS log:" + content);
                    } else if(prefix.equals("error:")) {
                        Log.d(TAG, "JS error:" + content);
                    } else if(prefix.equals("trace:")) {
                        Log.e(TAG, "JS trace:" + content);
                    }
                    intercept = true;
                }
            }
        }
        if(!intercept) {
            joinPoint.proceed();
        }
    }


 }
