package com.vungle.creative.vungle_creative_tool;


import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;
import org.nanohttpd.protocols.http.IHTTPSession;
import org.nanohttpd.protocols.http.request.Method;
import org.nanohttpd.protocols.http.response.Response;
import org.nanohttpd.protocols.http.response.Status;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;


public class WebServer extends SimpleWebServer {
    public static final String LOCAL_HOST_URL = "http://127.0.0.1";
    private static final String TAG = WebServer.class.getSimpleName();
    private static final String MIME_TYPE_JSON = "application/json";
    private static final int PORT = 8091;

    private String localHostUrl;
    private JSONObject configTemplate;
    private String adsTemplate;
    private File uploadDir;
    private String endCardName;
    private boolean verifyRequiredJsCalls = true;
    private String serverUrl; //for external users to upload creative

    public interface Listener {
        void onEndCardUploaded(String zipName);
    }

    private Listener listener;

    private static WebServer sInstance;

    public static WebServer getInstance() {
        return sInstance;
    }


    public static WebServer create(File rootDir, File uploadDir, boolean quiet) {
        if(sInstance == null) {
            sInstance = new WebServer(PORT, rootDir, uploadDir, quiet);
        }
        return sInstance;
    }

    private WebServer(int port, File rootDir, File uploadDir, boolean quiet) {
        super(null, port, rootDir, quiet);
        localHostUrl = LOCAL_HOST_URL + ":" + port;
        this.uploadDir = uploadDir;
    }

    @NonNull
    public String getLocalHostUrl() {
        return localHostUrl;
    }

    @Nullable
    public String getServerUrl(Context ctx) {
        if(serverUrl == null) {
            Context context = ctx.getApplicationContext();
            WifiManager wifiMan = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            if(wifiMan != null) {
                WifiInfo wifiInf = wifiMan.getConnectionInfo();
                int ipAddress = wifiInf.getIpAddress();
                String ip = String.format(Locale.getDefault(), "%d.%d.%d.%d",
                        (ipAddress & 0xff), (ipAddress >> 8 & 0xff), (ipAddress >> 16 & 0xff), (ipAddress >> 24 & 0xff));
                serverUrl = "http://" + ip + ":" + myPort;
            }
        }
        return serverUrl;
    }

    @Nullable
    public String getEndCardName() {
        return endCardName;
    }

    public void setVerifyRequiredJsCalls(Boolean enabled) {
        if(enabled != null) {
            verifyRequiredJsCalls = enabled;
        }
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void setup(@NonNull final Context context) {
        try {
            String configStr = contentOfAsset(context,"config.json");
            configTemplate = new JSONObject(configStr);
            JSONObject endpoints = configTemplate.optJSONObject("endpoints");
            if(endpoints != null) {
                final String okUrl = localUrlWithPath("ok");
                endpoints.put("new", okUrl);
                endpoints.put("report_ad", okUrl);
                endpoints.put("ads", localUrlWithPath("ads"));
                endpoints.put( "will_play_ad", okUrl);
                endpoints.put( "log", okUrl);
                endpoints.put( "ri", okUrl);
            }
            adsTemplate = contentOfAsset(context,"ads.json");
        } catch (IOException e) {
            Log.e(TAG, "Failed to load template json file for SDK API", e);
        } catch (JSONException e) {
            Log.e(TAG, "Failed to parse config json", e);
        }

        File[] uploadedFiles = uploadDir.listFiles();
        if(uploadedFiles != null && uploadedFiles.length > 0) {
            for(File file : uploadedFiles) {
                if(file.isFile() && file.getName().toLowerCase().endsWith(".zip")) {
                    endCardName = file.getName();
                    break;
                }
            }
        }
    }

    @Override
    public Response serve(IHTTPSession session) {
        Log.d(TAG, "serve: " + session.getUri());
        //intercept sdk api request
        Method method = session.getMethod();
        String uri = session.getUri();
        if(Method.POST.equals(method)) {
            //for post method
            Map<String, String> files = new HashMap<>();
            try {
                session.parseBody(files);
            } catch (ResponseException e) {
                Log.e(TAG, "Failed to parse body for session", e);
            } catch (IOException e) {
                Log.e(TAG, "Failed to parse body for session", e);
            }
            if("/config".equals(uri)) {
                return handleConfig(session);
            } else if("/ads".equals(uri)) {
                return handleAds(session);
            } else if("/ok".equals(uri)) {
                return handleOK(session);
            } else if("/upload".equals(uri)) {
                return handleUpload(session, files);
            } else {
                //not supported
                Log.e(TAG, "not supported uri:" + uri);
            }
        }

        return super.serve(session);
    }

    private Response handleUpload(IHTTPSession session, Map<String, String> files) {

        Map<String, List<String>> params = session.getParameters();
        List<String> filename = params.get("bundle");
        String tmpFilePath = files.get("bundle");
        if(filename == null || filename.isEmpty() || tmpFilePath == null) {
            return null;
        }

        String name = filename.get(0);
        File dst = new File(uploadDir, name);
        if (dst.exists()) {
            // Response for confirm to overwrite
            //TODO: need remove the end card
        }
        File src = new File(tmpFilePath);

        //TODO: need verify end card later
        try {
            InputStream in = new FileInputStream(src);
            OutputStream out = new FileOutputStream(dst);
            Utils.copyFile(in, out);
        } catch (IOException e) {
            e.printStackTrace();
        }
        //save the end card name
        endCardName = name;

        if(listener != null) {
            listener.onEndCardUploaded(name);
        }

        String res = "{\"msg\": \"Upload successfully\", \"code\":0, \"data\": \"\"}";
        return newFixedLengthResponse(Status.OK, MIME_TYPE_JSON, res);
    }

    private Response handleConfig(IHTTPSession session) {
        if(configTemplate != null) {
            return newFixedLengthResponse(Status.OK, MIME_TYPE_JSON, configTemplate.toString());
        }
        return null;
    }

    private Response handleAds(IHTTPSession session) {
        String res = adsTemplate;
        Calendar cal = Calendar.getInstance();
        cal.setTime(new Date());
        cal.add(Calendar.DATE, 14);
        long expiry = cal.getTimeInMillis();

        Map<String, String> vars = new HashMap<>();
        vars.put("${postBundle}", endCardURL());
        vars.put("${videoURL}", localUrlWithPath("countdown_video.mp4"));
        vars.put("${expiry}", String.valueOf(expiry));
        for(String target : vars.keySet()) {
            String replacement = vars.get(target);
            if(replacement != null) {
                res = res.replace(target, replacement);
            }
        }
        return newFixedLengthResponse(Status.OK, MIME_TYPE_JSON, res);
    }

    private Response handleOK(IHTTPSession session) {
        String res = "{\"msg\": \"ok\", \"code\":200 }";
        return newFixedLengthResponse(Status.OK, MIME_TYPE_JSON, res);
    }

    private String contentOfAsset(@NonNull Context context, String assetName) throws IOException  {
        InputStream in = context.getAssets().open(assetName);
        return Utils.contentOfInputStream(in);
    }

    private String localUrlWithPath(String path) {
        return localHostUrl + "/" + path;
    }

    private String endCardURL() {
        if(endCardName != null) {
            String uploadURL = localUrlWithPath(uploadDir.getName());
            return uploadURL + "/" + endCardName;
        } else {
            return localUrlWithPath("endcard.zip");
        }
    }


}
