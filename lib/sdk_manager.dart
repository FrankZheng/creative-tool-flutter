import 'dart:async';
import 'log_model.dart';
import 'vungle_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

const APP_ID = 'CreativeTool';
const PID = 'LOCAL01';

//keys for preferences
const PREFS_SDK_VERSION = "ActiveSDKVerison";
const PREFS_IS_CORS_ENABLED = "IsCORsEnabled";
const PREFS_VERIFY_REQUIRED_JS_CALLS = "VerifyRequiredJsCalls";

abstract class SDKDelegate {
  void onAdLoaded();
  void onAdDidPlay();
  void onAdDidClose();
}

abstract class SDKLogDelegate {
  void onLog(String type, String rawLog);
}

class SDKManager implements VungleSDKListener {
  static final shared = SDKManager();
  VungleSDK _sdk;
  bool _isCORsEnabled;

  var _delegates = <SDKDelegate>[];
  SDKLogDelegate _logDelegate;

  var _queue = <String>[];


  SDKManager() {
    //register log model as log listener
    //it's not a good place here
    _sdk = VungleSDK(this);

    _logDelegate = LogModel.shared;
  }

  Future<SharedPreferences> _prefs;

  get prefs {
    if(_prefs == null) {
      _prefs = SharedPreferences.getInstance();  
    }
    return _prefs;
  }


  void addDelegate(SDKDelegate delegate) {
    _delegates.add(delegate);
  }

  void removeDelegate(SDKDelegate delegate) {
    _delegates.remove(delegate);
  }

  Future<bool> start(String serverURL) async {
    final p = await prefs;
    var sdkVersion = p.getString(PREFS_SDK_VERSION) ?? '';
    return _sdk.start(APP_ID, [PID], serverURL, sdkVersion);
  }

  void loadAd() {
    if(_sdk.isInitialized) {
      print('sdk did initialized, start to load ad');
      _loadAd(PID);
    } else {
      print('sdk did NOT initialized, add PID to the queue');
      _queue.add(PID);
    }
  }

  void _loadAd(String placementId) {
    print('_loadAd, $placementId');
    _clearCache(placementId).then((error) {
      if(error != null) {
        print('Failed to clear cache for $PID, ${error.message}');
        return;
      }

      new Timer(Duration(microseconds:100), () {
        _sdk.loadAd(placementId).then((error) {
          if(error != null) {
            print('Failed to load ad for $PID, ${error.message}');
          }
        });
      });
    });
  }

  Future<VungleException> _clearCache(String placementId) async {
    var cached = await _sdk.isCached(placementId);
    if(cached) {
      return _sdk.clearCache(placementId);
    } else {
      return null;
    }
  }

  Future<bool> playAd() async {
    var error = await _sdk.playAd(PID, await isCORsEnabled());
    if (error != null) {
      print('Failed to play $PID, ${error.message}');
    }
    return error == null;
  }

  void forceCloseAd() {
    _sdk.forceCloseAd();
  }

  Future<String> getSDKVersion() async {
    return _sdk.getSDKVersion();
  }

  bool isInitialized() {
    return _sdk.isInitialized;
  }

  Future<bool> switchSDKVersion(String version) async {
    final p = await prefs;
    return p.setString(PREFS_SDK_VERSION, version);
  }

  Future<List<String>> getSDKVersions() async {
    return _sdk.getSDKVersionList();
  }

  Future<bool> isCORsEnabled() async {
    if(_isCORsEnabled == null) {
      final p = await prefs;
      _isCORsEnabled = p.getBool(PREFS_IS_CORS_ENABLED) ?? false;
    }
    return _isCORsEnabled;
  }

  void enableCORs(bool enabled) async {
    _isCORsEnabled = enabled;
    final p = await prefs;
    p.setBool(PREFS_IS_CORS_ENABLED, enabled);
  }

  @override
  void onSDKInitialized(VungleException e) {
    print('onSDKInitialized, ${e == null ? 'no error' : e.message}');
    if(e == null) {

      if(_queue.length > 0) {
        _loadAd(_queue.first);
        _queue = [];
      }
    } else {
      print('SDK failed to initialize, ${e.message}');
    }

  }

  @override
  void onAdLoaded(String placementId, VungleException e) {
    if(e == null) {
      //auto cached ad will be loaded before sdk initialized
      if(_sdk.isInitialized && placementId == PID) {
        _delegates.forEach((delegate) {
          delegate.onAdLoaded();
        });
      }
    } else {
      print('Failed to load ad for $placementId, ${e.message}');
    }
  }

  @override
  void onAdWillPlay(String placementId, VungleException e) {
    if(e == null) {
      _delegates.forEach((delegate) {
        delegate.onAdDidPlay();
      });
    } else {
      print('Failed to play ad for $placementId, ${e.message}');
    }
  }

  @override
  void onAdWillClose(String placementId, bool completed, bool isCTAClicked) {
    print('onAdWillClose, $placementId, $completed, $isCTAClicked');
  }

  @override
  void onAdDidClose(String placementId, bool completed, bool isCTAClicked) {
    print('onAdDidClose, $placementId, $completed, $isCTAClicked');
    _delegates.forEach((delegate) {
      delegate.onAdDidClose();
    });
  }

  @override
  void onLog(String type, String rawLog) {
    _logDelegate.onLog(type, rawLog);
  }


}