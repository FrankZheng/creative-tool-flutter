import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'web_server.dart';
import 'sdk_manager.dart';
import 'utils.dart';

class HomeView extends StatefulWidget {

  @override
  HomeViewState createState() => HomeViewState();
}


class HomeViewState extends State<HomeView> implements WebServerListener, SDKDelegate {
  final WebServer _webServer = WebServer.shared;
  final SDKManager _sdkManager = SDKManager.shared;

  String _serverURL;
  String _sdkVersion;
  bool _playBtnEnabled = false;
  String _endCardName;
  bool _playingAd = false;

  //for switch sdk version
  void _onSwitchSDKVersion() {

  }

  //for play ad
  void _onPlayAd() {
    _sdkManager.playAd();
  }

  void init() async {
    _sdkManager.addDelegate(this);
    var sdkVersion = await _sdkManager.getSDKVersion();
    _webServer.addListener(this);
    var endCardName = await _webServer.getEndCardName();
    if(endCardName != null) {
      _sdkManager.loadAd();
    }
    var serverURL = await _webServer.getWebServerURL();
    //update UI
    setState((){
      _sdkVersion = sdkVersion;
      if(endCardName != null) {
        _endCardName = endCardName;
      }
      if(serverURL != null) {
        _serverURL = serverURL;
      }
    });
  }


  @override
  void onAdLoaded() {
    setState(() {
      _playBtnEnabled = true;
    });
  }

  @override
  void onAdDidPlay() {
    _playingAd = true;
  }

  @override
  void onAdDidClose() {
    _playingAd = false;
    setState(() {
      _playBtnEnabled = false;
    });

    new Timer(Duration(seconds: 1), () {
      _sdkManager.loadAd();
    });
  }

  @override
  onEndCardUploaded(String zipName) {
    if (!_playingAd) {

      new Timer(Duration(microseconds: 100), () {
        _sdkManager.loadAd();
      });

      setState(() {
        _endCardName = zipName;
        _playBtnEnabled = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }


  @override
  void dispose() {
    super.dispose();
    _webServer.removeListener(this);
    _sdkManager.removeDelegate(this);
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      GuidanceBox(),
      BrowserBox(_serverURL),
      SDKVersionBox(_sdkVersion, _onSwitchSDKVersion),

    ];

    if(_endCardName != null) {
      children.addAll([
        Expanded(
            child: BundleIconBox(_playBtnEnabled)
        ),
        BundleNameBox(_endCardName, _playBtnEnabled),
        SizedBox(height: 5,),
        BottomButtonBox(_playBtnEnabled, _onPlayAd),
      ]);
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Vungle Creative QA'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12, left: 1, right: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }

}

class GuidanceBox extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.only(left: 20, right: 20),
      padding: EdgeInsets.only(left: 20, right: 5, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/tooltip-bubble.png'),
          fit: BoxFit.fill,
        ),
        //color: Colors.grey,
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image(
            image: AssetImage('assets/upload-icon.png'),
          ),
          SizedBox(width: 15,),
          Expanded(
            child: Text(
              "Open browser and upload your playable via the URL below",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class BrowserBox extends StatelessWidget {
  final String _serverURL;
  BrowserBox(this._serverURL);

  @override
  Widget build(BuildContext context) {
    var url = StringUtils.safe(_serverURL);
    if(url.endsWith("/")) {
      url = url.substring(0, url.length-1);
    }
    return Container(
      height: 100,
      margin: EdgeInsets.only(left: 20, right: 20),
      padding: EdgeInsets.only(left: 20, right: 5, bottom: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/enter-address-bg.png'),
          fit: BoxFit.fill,
        ),
        //color: Colors.grey,
      ),
      child:  Row(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left:50, top: 50, right: 20),
              //color: Colors.yellow,
              child: Text(
                url,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),

    );
  }
}


class SDKVersionBox extends StatelessWidget {
  final String _sdkVersion;
  final Function _onPressed;
  SDKVersionBox(this._sdkVersion, this._onPressed);


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1,
          )
      ),
      child: Row(
        children: <Widget>[
          Text('SDK VERSION'),
          Spacer(),
          RaisedButton(
              color: Colors.white,
              textColor: Colors.blue,
              onPressed: _onPressed,
              child: Text(StringUtils.safe(_sdkVersion)),
              shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(4.0), )
          )
        ],
      ),
    );
  }
}

class BundleIconBox extends StatelessWidget {
  final bool enabled;
  BundleIconBox(this.enabled);

  @override
  Widget build(BuildContext context) {
    final src = 'assets/Vungle-phone-bundle-icon.png';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: enabled ? Image.asset(src) : Image.asset(src,
        color: Color.fromRGBO(255, 255, 255, 0.5),
        colorBlendMode: BlendMode.modulate,)
    );
  }
}

class BundleNameBox extends StatelessWidget {
  final bool enabled;
  final String _endCardName;
  BundleNameBox(this._endCardName, this.enabled);

  @override
  Widget build(BuildContext context) {
    return Text(
        StringUtils.safe(_endCardName),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Color.fromRGBO(0, 0, 0, 0.5),
        )
    );
  }
}

class BottomButtonBox extends StatelessWidget {
  final bool _playBtnEnabled;
  final Function _onPressed;

  BottomButtonBox(this._playBtnEnabled, this._onPressed);

  void _emptyOnPressed() {
    //do nothing
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if(_playBtnEnabled) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('TEST', style: TextStyle(fontSize:18, fontWeight: FontWeight.w600),),
          SizedBox(width: 5,),
          Image.asset('assets/play-icon.png', width: 20, height: 20,),
        ],
      );
    } else {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('LOADING ...', style: TextStyle(fontSize:18, fontWeight: FontWeight.w600),),
        ],
      );
    }

    var button = RaisedButton(
        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
        color: Colors.blue,
        textColor: Colors.white,
        onPressed: _playBtnEnabled ? _onPressed : _emptyOnPressed,
        child: child,
        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0), )
    );
    return !_playBtnEnabled ? Opacity(opacity: 0.5, child: button) : button;
  }
}
