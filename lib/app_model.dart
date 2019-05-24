import 'package:flutter/services.dart';

const APP_CHAN = 'com.vungle.vcltool/app';
const CLOSE_APP = 'closeApp';


class AppModel {
  static final AppModel shared = AppModel();
  final chan = new MethodChannel(APP_CHAN);

  AppModel();

  void closeApp() {
    chan.invokeMethod(CLOSE_APP);
  }

}