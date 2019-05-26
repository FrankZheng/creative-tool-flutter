import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

const WEB_SERVER_CHAN = "com.vungle.vcltool/webserver";
const SERVER_URL = "serverURL";
const LOCAL_HOST_URL = "localhostURL";
const END_CARD_NAME = "endCardName";
const ENABLE_VERIFY_JS_CALLS = "enableVerifyRequiredJsCalls";

const String WEB_SERVER_CALLBACK_CHAN = "com.vungle.vcltool/webserverCallbacks";
const String END_CARD_UPLOADED = "endcardUploaded";

const PREFS_VERIFY_REQUIRED_JS_CALLS = "VerifyRequiredJsCalls";

abstract class WebServerListener {
  onEndCardUploaded(String zipName);
}

class WebServer {
  String serverURL;
  static final shared = WebServer();
  List<WebServerListener> _listeners = [];

  final webServerChan = MethodChannel(WEB_SERVER_CHAN);
  final webServerCallbackChan = MethodChannel(WEB_SERVER_CALLBACK_CHAN);

  bool _verifyRequiredJsCalls;
  String _endCardName;

  WebServer() {
    webServerCallbackChan.setMethodCallHandler((call) {
      _endCardName = call.arguments;
      _listeners.forEach((listener) {
        listener.onEndCardUploaded(_endCardName);
      });
    });

    _init();
  }

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    _verifyRequiredJsCalls = prefs.getBool(PREFS_VERIFY_REQUIRED_JS_CALLS) ?? true;
    webServerChan.invokeMethod(ENABLE_VERIFY_JS_CALLS, _verifyRequiredJsCalls);
  }

  Future<String> getWebServerURL() async {
    if(serverURL != null) {
      return serverURL;
    }
    serverURL = await webServerChan.invokeMethod(SERVER_URL);
    return serverURL;
  }

  Future<String> getLocalhostURL() async {
    return await webServerChan.invokeMethod(LOCAL_HOST_URL);
  }

  Future<String> getEndCardName() async {
    if( _endCardName != null) {
      return _endCardName;
    }
    _endCardName = await webServerChan.invokeMethod(END_CARD_NAME);
    return _endCardName;
  }

  //if check required js calls in the end card
  void enableVerifyRequiredJsCalls(bool enabled) {
    _verifyRequiredJsCalls = enabled;
    webServerChan.invokeMethod(ENABLE_VERIFY_JS_CALLS, enabled);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(PREFS_VERIFY_REQUIRED_JS_CALLS, enabled);
    });
  }

  addListener(WebServerListener listener) {
    _listeners.add(listener);
  }

  removeListener(WebServerListener listener) {
    _listeners.remove(listener);
  }

  Future<bool> verifyRequiredJsCalls() async {
    if (_verifyRequiredJsCalls == null) {
      final prefs = await SharedPreferences.getInstance();
      _verifyRequiredJsCalls = prefs.getBool(PREFS_VERIFY_REQUIRED_JS_CALLS) ?? true;
    }
    return _verifyRequiredJsCalls;
  }



}