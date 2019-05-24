import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'sdk_manager.dart';
import 'web_server.dart';


class SettingsView extends StatefulWidget {

  @override
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  bool _inspectJs = false;
  bool _verifyJsCalls;
  final _sdkManager = SDKManager.shared;
  final _webServer = WebServer.shared;

  int _rightBarClicked = 0;
  bool _showVerifyJsCalls = false;

  void _onRightBarTap() {
    _rightBarClicked++;
    if(_rightBarClicked % 5 == 0) {
      setState(() {
        _showVerifyJsCalls = !_showVerifyJsCalls;
      });
    }
  }

  void _onInspectJsChanged(bool newValue) {
    _sdkManager.enableCORs(newValue);
    setState(() {
      _inspectJs = newValue;
    });
  }

  void _onVerifyJsCallsChanged(bool newValue) {
    _webServer.enableVerifyRequiredJsCalls(newValue);
    setState(() {
      _verifyJsCalls = newValue;
    });
  }

  @override
  void initState() {
    super.initState();

    _sdkManager.isCORsEnabled().then((enabled) {
      if(enabled != _inspectJs) {
        setState((){
          _inspectJs = enabled;
        });
      }
    });

    _webServer.verifyRequiredJsCalls().then((enabled){
      if(enabled != _verifyJsCalls) {
        setState(() {
          _verifyJsCalls = enabled;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[
      InspectJsItem(_inspectJs, _onInspectJsChanged),
      Divider(),

    ];

    if (_showVerifyJsCalls) {
      items.addAll([
        VerifyJsCallsItem(_verifyJsCalls, _onVerifyJsCallsChanged),
        Divider(),
      ]);
    }

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Settings'),
          trailing: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onRightBarTap,
            child: SizedBox(width: 80, height: 50),
          ),
        ),
        child: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(
                  top: 5, bottom: 20, left: 12, right: 12),
              child: Column(
                children: <Widget>[
                  ...items,
                  Spacer(),
                  Text(
                    '0.9.7_10',
                    style: TextStyle(color: Colors.blue, fontSize: 18),)
                ],
              )
          ),

        )
    );
  }
}

class VerifyJsCallsItem extends StatelessWidget {
  final bool _verifyJsCalls;
  final Function _onChanged;
  VerifyJsCallsItem(this._verifyJsCalls, this._onChanged);

  @override
  Widget build(BuildContext context) {
    var row = Row(children: <Widget>[
      SizedBox(width: 250,
        child: Text(
            'Verify required javascript calls in customized ads',
            style: TextStyle(fontSize:  18),
        )
      ),
      Spacer(),
    ],);
    if(_verifyJsCalls != null) {
      row.children.add(CupertinoSwitch(value: _verifyJsCalls, onChanged: _onChanged));
    }
    return row;
  }
}

class InspectJsItem extends StatelessWidget {
  final bool _inspectJs;
  final Function _onChanged;

  InspectJsItem(this._inspectJs, this._onChanged);

  @override
  Widget build(BuildContext context) {
    var head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
      Text('Inspect javascript error',
        style: TextStyle(fontSize: 18),),
      Text('(Enable CORs)',
        style: TextStyle(color: Colors.grey),
        ),
    ],);

    var switchCtrl = CupertinoSwitch(value: _inspectJs, onChanged: _onChanged);

    return Row(children: <Widget>[
      head,
      Spacer(),
      switchCtrl,
    ]);
  }
}