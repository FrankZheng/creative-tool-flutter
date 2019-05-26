import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'sdk_manager.dart';
import 'package:flutter/foundation.dart';
import 'web_server.dart';
import 'package:sqflite/sqflite.dart';
import 'utils.dart';


const DB_NAME = 'app.db';
const LOG_TABLE_NAME = "logs";


class LogItem {
  int id;
  final String type;
  final DateTime timestamp;
  final String message;
  final String bundleZipName;
  final int version;

  LogItem(this.id, this.type, this.timestamp,
          this.message, this.bundleZipName, this.version);

  String extra() { return ''; }

  Map<String, dynamic> toMap() {
    return {
      //'id': id,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'message': message,
      'extra': extra(),
      'bundleZipName': bundleZipName,
      'version': version,
    };
  }

}

class JSError extends LogItem {
  final String name;
  final List<String> stack;

  JSError(DateTime timestamp, String message, String bundleZipName,
      this.name, this.stack,
      {int id = 0, int version = 0}
      ) : super(id, "error", timestamp, message, bundleZipName, version);

  @override
  String extra() {
    return jsonEncode({'name':name, 'stack': stack});
  }

}

class JSTrace extends LogItem {
  final List<String> stack;
  JSTrace(DateTime timestamp, String message, String bundleZipName,
      this.stack, {int id = 0, int version = 0}
      ) : super(id, "trace", timestamp, message, bundleZipName, version);

  @override
  String extra() {
    return jsonEncode({'stack': stack});
  }
}

class JSLog extends LogItem {
  JSLog(DateTime timestamp, String message, String bundleZipName,
        {int id = 0, int version = 0}
      ) : super(id, 'log', timestamp, message, bundleZipName, version);
}

class SDKLog extends LogItem {
  SDKLog(DateTime timestamp, String message, String bundleZipName,
      {int id = 0, int version = 0}
      ) : super(id, 'sdk', timestamp, message, bundleZipName, version);
}

class LogModel with ChangeNotifier implements SDKLogDelegate {
  static final shared = LogModel();
  List<LogItem> _logs = [];

  get logs => _logs;

  LogModel();

  final _webServer = WebServer.shared;

  Future<Database> _database;

  get database async {
    if (_database != null) {
      return _database;
    }
    _database = openDatabase(
        join(await getDatabasesPath(), DB_NAME),
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE $LOG_TABLE_NAME(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type INTEGER,
            timestamp INTEGER, 
            message TEXT, 
            extra TEXT,
            bundleZipName TEXT,
            version INTEGER) 
            ''');
        },
        version: 1
    );
    return _database;
  }

  Future<bool> loadLogs() async {
    //load logs from database
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(LOG_TABLE_NAME);
    //print('${maps.length} raw logs loaded');
    maps.forEach((map) {
      String type = map['type'];
      int id = map['id'];
      int ts = map['timestamp'];
      var timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
      String message = map['message'];
      String bundleZipName = map['bundleZipName'];
      int version = map['version'];
      String extra = map['extra'];
      Map<String, dynamic> json;
      List<String> stack;
      if(extra.isNotEmpty) {
        json = jsonDecode(extra);
        stack = json['stack'].cast<String>();
      }
      LogItem logItem;
      switch(type) {
        case 'log':
          logItem = new JSLog(timestamp, message, bundleZipName, version: version, id:id);
          break;
        case 'sdk':
          logItem = new SDKLog(timestamp, message, bundleZipName, version:version, id:id);
          break;
        case 'error':
          String name = json['name'];
          logItem = new JSError(timestamp, message, bundleZipName, name, stack, version: version, id:id);
          break;
        case 'trace':
          logItem = new JSTrace(timestamp, message, bundleZipName, stack, version: version, id:id);
          break;
        default:
          break;
      }
      if(logItem != null) {
        //print('new log.id:${logItem.id}');
        _logs.add(logItem);
      }
    });

    print('${_logs.length} logs loaded');
    notifyListeners();
    return true;
  }

  clearLogs() async{
    _logs = [];
    notifyListeners();

    //delete all logs from the database
    final db = await database;
    db.delete(LOG_TABLE_NAME);
  }

  void _onLog(String type, String rawLog) async {
    String endCardName = await _webServer.getEndCardName();
    LogItem logItem;
    switch(type) {
      case "log":
        logItem = new JSLog(DateTime.now(), rawLog, endCardName);
        break;
      case "sdk":
        //logItem = new SDKLog(DateTime.now(), rawLog, endCardName);
        break;
      case "error":
        logItem = parseJsError(rawLog, endCardName);
        break;
      case "trace":
        logItem = parseJsTrace(rawLog, endCardName);
        break;
    }
    if(logItem != null) {
      _logs.add(logItem);
      notifyListeners();
      //insert to db
      final db = await database;
      logItem.id = await db.insert(
        LOG_TABLE_NAME,
        logItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  void onLog(String type, String rawLog) {
    _onLog(type, rawLog);
  }

  LogItem parseJsError(String rawLog, String endCardName) {
    Map<String, dynamic> json = jsonDecode(rawLog);
    String msg = json['msg'] as String;
    String name = json['errName'] as String;
    String stack = json['stack'] as String;
    var stackLines = StringUtils.isEmpty(stack) ? <String>[] : parseStack(stack);
    return JSError(DateTime.now(), msg, endCardName, name, stackLines);
  }

  LogItem parseJsTrace(String rawLog, String endCardName) {
    String msg = "Trace";
    var stackLines = StringUtils.isEmpty(rawLog) ? <String>[] :  parseStack(rawLog);
    if(stackLines.length > 0) {
      stackLines.removeAt(0);
    }
    return JSTrace(DateTime.now(), msg, endCardName, stackLines);
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