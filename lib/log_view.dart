import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'log_model.dart';
import 'package:provider/provider.dart';

class LogItemRow extends StatelessWidget {
  final LogItem logItem;
  LogItemRow(this.logItem);

  static const ROW_PADDING = EdgeInsets.only(
      left: 0,
      right: 0,
      top: 2.0,
      bottom: 2.0
  );
  static const JS_LOG_COLOR = Color(0xFFB206B0);
  static const JS_ERROR_COLOR = Color(0xFFE41749);
  static const JS_TRACE_COLOR = Color(0xFFF5587B);
  static const SDK_LOG_COLOR = Color(0xFFFF8A5C);

  @override
  Widget build(BuildContext context) {
    if (logItem is JSLog || logItem is SDKLog) {
      return Padding(
          padding: ROW_PADDING,
          child: Text(
            logItem.message,
            style: TextStyle(
              color: logItem is JSLog ? JS_LOG_COLOR : SDK_LOG_COLOR,
              fontSize: 14,
            ),
          )
      );
    }
    else if(logItem is JSError || logItem is JSTrace) {
      final msg = logItem.message;
      final List<String> stack = logItem is JSTrace ? (logItem as JSTrace).stack : (logItem as JSError).stack;
      final textColor = logItem is JSTrace ? JS_TRACE_COLOR : JS_ERROR_COLOR;
      return Padding(
        padding: ROW_PADDING,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(msg, style: TextStyle(color: textColor, fontSize: 14),),
            Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(stack.join("\n"), style: TextStyle(color: textColor, fontSize: 14))),
          ],
        ),
      );
    }
    return null;
  }
}

class LogView extends StatefulWidget {
  @override
  _LogViewState createState() => _LogViewState();
}


class _LogViewState extends State<LogView> {
  final _model = LogModel.shared;

  void _onDelete() {
    showCupertinoDialog<bool>(context: context, builder: (context) {
      return CupertinoAlertDialog(
        title: Text("Confirm To Delete"),
        content: Text("Do you really want to delete logs?"),
        actions: <Widget>[
          CupertinoDialogAction(child: Text("YES"), isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context, true);
            },),
          CupertinoDialogAction(child: Text("NO"),
              isDefaultAction: true, onPressed: () {
                Navigator.pop(context, false);
              }),
        ],
      );
    }).then((ret) {
      if(ret) {
        _model.clearLogs();
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _model.loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LogModel>(
      builder: (context) => _model,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Log'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(Icons.delete_forever),
            onPressed: _onDelete,
          ),
        ),
        child: LogListView(),
      ),
    );
  }
}

class LogListView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var logModel = Provider.of<LogModel>(context);
    var logs = logModel.logs;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: logs.length * 2,
            itemBuilder: (context, index) {
              if (index % 2 != 0) {
                //divider
                return Divider();
              }
              index = index~/2;
              final item = logs[index];
              return LogItemRow(item);
            }
        ),
      ),
    );
  }
}