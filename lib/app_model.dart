import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';


const APP_CHAN = 'com.vungle.vcltool/app';
const INITIALIZE = "initialize";
const CLOSE_APP = 'closeApp';


class AppModel {
  static final AppModel shared = AppModel();
  final chan = new MethodChannel(APP_CHAN);
  String _appVersion;

  AppModel();

  Future<void> init() async{
    return await chan.invokeMethod(INITIALIZE);
  }

  void closeApp() {
    chan.invokeMethod(CLOSE_APP);
  }

  Future<String> appVersion() async {
    if(_appVersion != null) {
      return _appVersion;
    }
    var packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}_${packageInfo.buildNumber}';
    return _appVersion;
  }



}