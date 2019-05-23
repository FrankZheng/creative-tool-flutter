import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'sdk_manager.dart';
import 'package:flutter/foundation.dart';


class LogItem {
  final DateTime timestamp;
  final String message;

  LogItem(this.message, this.timestamp);
}

class JSError extends LogItem {
  final String name;
  final List<String> stack;

  JSError(String message, DateTime timestamp, this.name, this.stack) :
        super(message, timestamp);
}

class JSTrace extends LogItem {
  final List<String> stack;
  JSTrace(String message, DateTime timestamp, this.stack) :
        super(message, timestamp);
}

class JSLog extends LogItem {
  JSLog(String message, DateTime timestamp) : super(message, timestamp);
}

class SDKLog extends LogItem {
  SDKLog(String message, DateTime timestamp) : super(message, timestamp);
}

class LogModel with ChangeNotifier implements SDKLogDelegate {
  static final shared = LogModel();
  List<LogItem> _logs = [];

  get logs => _logs;

  LogModel();

  Future<bool> loadLogs() async {
    //load logs from database

    notifyListeners();
    return true;
  }

  clearLogs() {
    _logs = [];
    //delete all logs from the database
  }

  @override
  void onLog(String type, String rawLog) {
    //parse the rawLog, create log objects
    //save to the database
    //fire the listener
    LogItem logItem;
    switch(type) {
      case "log":
        logItem = new JSLog(rawLog, DateTime.now());
        break;
      case "sdk":
        logItem = new SDKLog(rawLog, DateTime.now());
        break;
      case "error":
        logItem = parseJsError(rawLog);
        break;
      case "trace":
        logItem = parseJsTrace(rawLog);
        break;
    }
    _logs.add(logItem);
    notifyListeners();
  }

  LogItem parseJsError(String rawLog) {
    Map<String, dynamic> json = jsonDecode(rawLog);
    String msg = json['msg'] as String;
    String name = json['errName'] as String;
    String stack = json['stack'] as String;
    var stackLines = parseStack(stack);
    return JSError(msg, DateTime.now(), name, stackLines);
  }

  LogItem parseJsTrace(String rawLog) {
    String msg = "Trace";
    var stackLines = parseStack(rawLog);
    if(stackLines.length > 0) {
      stackLines.removeAt(0);
    }
    return JSTrace(msg, DateTime.now(), stackLines);
  }

  List<String> parseStack(String stack) {
    List<String> res = [];
    var lines = stack.split("\n");
    lines.forEach((line) {
      var components = line.split("@");
      if(components.length > 1) {
        var func = components[0];
        var filePath = components[1];
        var filename = basename(filePath);
        res.add("$func -- $filename");
      } else if(components.length == 1) {
        var filePath = components[0];
        var filename = basename(filePath);
        res.add("(anonymous function) -- $filename");
      }
    });
    return res;
  }


}