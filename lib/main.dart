import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_view.dart';
import 'ui_defines.dart';
import 'settings_view.dart';

void main() {
  var app = MyApp();
  runApp(app);
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        barBackgroundColor: Palette.backColor,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Vungle', color: Colors.black87),
          navTitleTextStyle: TextStyle(
              fontFamily: 'Vungle',
              fontSize: 18,
              color: Palette.foreColor,
              fontWeight: FontWeight.w700
          ),
          tabLabelTextStyle: TextStyle(
              fontFamily: 'Vungle',
              color: Palette.foreColor,
          ),
        ),
      ),
      home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.slideshow),
                  title: Text('QA'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_headline),
                  title: Text('Log'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ]
          ),
          tabBuilder: (BuildContext context, int index) {
            switch(index) {
              case 0:
                return CupertinoTabView(builder: (context) {
                  return HomeView();
                });
              case 1:
                return CupertinoTabView(builder: (context) {
                  return Center(
                    child: Text('page 2'),
                  );
                });
              case 2:
                return CupertinoTabView(builder: (context) {
                  return Center(
                    child: SettingsView()
                  );
                });
            }
          }
      ),
    );
  }
}
