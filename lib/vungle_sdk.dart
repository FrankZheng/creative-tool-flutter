import 'package:flutter/services.dart';

const SDK_CHANNEL_NAME = 'com.vungle.vcltool/vungleSDK';
const SDK_CALLBACKS_CHANNEL_NAME = 'com.vungle.vcltool/vungleSDKCallbacks';
const SDK_VERSION = 'sdkVersion';
const START_APP = 'startApp';
const LOAD_AD = 'loadAd';
const PLAY_AD = 'playAd';
const IS_CACHED = 'isCached';
const CLEAR_CACHE = 'clearCache';
const FORCE_CLOSE_AD = 'forceCloseAd';

const SDK_INITIALIZED = 'sdkDidInitialized';
const SDK_INITIALIZE_FAILED = 'sdkFailedToInitialize';
const AD_LOADED = 'adLoaded';
const AD_LOAD_FAILED = 'adLoadFailed';
const AD_WILL_SHOW = 'adWillShow';
const AD_WILL_CLOSE = 'adWillClose';
const AD_DID_CLOSE = 'adDidClose';
const ON_LOG = 'onLog';

const PLACEMENT_ID = "placementId";
const METHOD_RETURN_VALUE = "return";
const ERROR_CODE = "errCode";
const ERROR_MESSAGE = "errMsg";

class VungleException implements Exception {
  final int code;
  final String message;
  VungleException(this.message, [this.code = 0]);
}

abstract class VungleSDKListener {
  void onSDKInitialized(VungleException e);

  void onAdLoaded(String placementId, VungleException e);

  void onAdWillPlay(String placementId, VungleException e);

  void onAdWillClose(String placementId, bool completed, bool isCTAClicked);

  void onAdDidClose(String placementId, bool completed, bool isCTAClicked);

  void onLog(String type, String rawLog);
}

class VungleSDK {
  final VungleSDKListener listener;
  var _initialized = false;

  bool get isInitialized => _initialized;

  VungleSDK(this.listener);

  final channel = MethodChannel(SDK_CHANNEL_NAME);
  final callbackChannel = MethodChannel(SDK_CALLBACKS_CHANNEL_NAME);

  //start sdk
  start(String appId, List<String> placements, String serverURL) async {
    //register callbacks
    callbackChannel.setMethodCallHandler(_onCallback);
    final Map<String, dynamic> params = {
      'appId': appId,
      'placements': placements,
      'serverURL': serverURL
    };

    final result = await channel.invokeMethod(START_APP, params);
    final error = _parseMethodResult(result);
    if (error != null) {
      listener.onSDKInitialized(error);
    }
  }

  //load ad
  Future<VungleException> loadAd(String placementId) async {
    final result = await channel.invokeMethod(LOAD_AD, placementId);
    return _parseMethodResult(result);
  }

  //play ad
  Future<VungleException> playAd(String placementId, bool isCORs) async {
    final Map<String, dynamic> params = {
      PLACEMENT_ID: placementId,
      'isCORs': isCORs
    };
    final result = await channel.invokeMethod(PLAY_AD, params);
    return _parseMethodResult(result);
  }

  //is ad cached
  Future<bool> isCached(String placementId) async {
    return await channel.invokeMethod(IS_CACHED, placementId);
  }

  //clear cache
  Future<VungleException> clearCache(String placementId) async {
    final result = await channel.invokeMethod(CLEAR_CACHE, placementId);
    return _parseMethodResult(result);
  }

  Future<void> forceCloseAd() async {
    channel.invokeMethod(FORCE_CLOSE_AD, null);
  }

  Future<String> getSDKVersion() async {
    return channel.invokeMethod(SDK_VERSION);
  }

  //handle callbacks
  Future<dynamic> _onCallback(MethodCall call) async {
    print('_onCallback, method:${call.method}, arguments:${call.arguments}');
    switch (call.method) {
      case SDK_INITIALIZED:
        _initialized = true;
        listener.onSDKInitialized(null);
        break;
      case SDK_INITIALIZE_FAILED:
        _initialized = false;
        listener.onSDKInitialized(_parseError(call.arguments));
        break;
      case AD_LOADED:
        listener.onAdLoaded(call.arguments as String, null);
        break;
      case AD_LOAD_FAILED:
        listener.onAdLoaded(_parsePlacementId(call.arguments), _parseError(call.arguments));
        break;
      case AD_WILL_SHOW:
        listener.onAdWillPlay(call.arguments, null);
        break;
      case AD_WILL_CLOSE:
        _onAdClose(call.arguments, false);
        break;
      case AD_DID_CLOSE:
        _onAdClose(call.arguments, true);
        break;
      case ON_LOG:
        listener.onLog(call.arguments['type'] as String, call.arguments['rawLog'] as String);
        break;
      default:
        throw new MissingPluginException("Method not implemented");
    }
    return null;
  }
  
  void _onAdClose(Map<dynamic, dynamic> args, bool didClose) {
    String pID = _parsePlacementId(args);
    bool completed = false;
    bool didDownload = false;
    if(args.containsKey('completed')) {
      completed = args['completed'];
    }
    if(args.containsKey('didDownload')) {
      didDownload = args['didDownload'];
    }
    if(didClose) {
      listener.onAdDidClose(pID, completed, didDownload);
    } else {
      listener.onAdWillClose(pID, completed, didDownload);
    }
  }

  VungleException _parseError(Map<dynamic, dynamic> params) {
    //try to get error code and error msg
    VungleException e;
    if (params.containsKey(ERROR_MESSAGE)) {
      final errorMsg = params[ERROR_MESSAGE] as String;
      if (params.containsKey(ERROR_CODE)) {
        final errorCode = params[ERROR_CODE] as int;
        e = VungleException(errorMsg, errorCode);
      } else {
        e = VungleException(errorMsg);
      }
    } else {
      e = VungleException("unknown error");
    }
    return e;
  }

  VungleException _parseMethodResult(Map<dynamic, dynamic> result) {
    VungleException e;
    if (result.containsKey(METHOD_RETURN_VALUE)) {
      bool returned = result[METHOD_RETURN_VALUE] as bool;
      if (!returned) {
        //try to get error code and error msg
        e = _parseError(result);
      }
    }
    return e;
  }

  String _parsePlacementId(Map<dynamic, dynamic> params) {
    return params[PLACEMENT_ID];
  }
}
