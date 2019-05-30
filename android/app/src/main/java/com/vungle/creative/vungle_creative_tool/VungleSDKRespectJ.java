package com.vungle.creative.vungle_creative_tool;

import android.webkit.WebView;

import com.vungle.warren.ui.VungleActivity;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;

import java.lang.reflect.Field;


@Aspect
public class VungleSDKRespectJ {
    private static final String TAG = VungleSDKRespectJ.class.getSimpleName();

    private static WebView currentWebView;

    @After("execution(* com.vungle.warren.ui.VungleWebClient.onPageFinished(..))")
    public void VungleWebViewClient_onPageFinishedAfter(JoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        if(args == null || args.length < 2) {
            return;
        }
        WebView webView = (WebView)args[0];
        //String url = (String )args[1];
        currentWebView = webView;
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
        if(action != null && !action.isEmpty()) {
            String[] prefixes = {"log:", "error:", "trace:"};
            for( String prefix : prefixes) {
                if(action.startsWith(prefix)) {
                    String content = action.substring(prefix.length());
                    VungleSDKMediator.getInstance().onJsLog(prefix, content);
                    intercept = true;
                }
            }
        }
        if(!intercept) {
            if("close".equals(action)) {
                currentWebView = null;
            }
            joinPoint.proceed();
        }
    }

    @After("execution(* com.vungle.warren.ui.VungleActivity.prepare())")
    public void VungleActivity_onPrepareAfter(JoinPoint joinPoint) throws Throwable {
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
        if(currentWebView != null) {
            String js = "javascript:Android.performAction('close');";
            currentWebView.evaluateJavascript(js, null);
        }
    }




 }
