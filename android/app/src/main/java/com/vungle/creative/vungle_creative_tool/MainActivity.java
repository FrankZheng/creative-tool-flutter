package com.vungle.creative.vungle_creative_tool;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    FlutterMediator.getInstance(this).init(getFlutterView());
    VungleSDKMediator.getInstance(this).init(getFlutterView());
  }
}
