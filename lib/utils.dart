import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:math';


class StringUtils {
  static bool isEmpty(String str) {
    return str == null || str.length == 0;
  }

  static String safe(String str) {
    return str == null ? '' : str;
  }
}

class NoScaleTextWidget extends StatelessWidget {
  final Widget child;

  const NoScaleTextWidget({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaxScaleTextWidget(
      max: 1.0,
      child: child,
    );
  }
}

class MaxScaleTextWidget extends StatelessWidget {
  final double max;
  final Widget child;

  const MaxScaleTextWidget({
    Key key,
    this.max = 1.2,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var data = MediaQuery.of(context);
    var scale = min(max, data.textScaleFactor);
    return MediaQuery(
      data: data.copyWith(textScaleFactor: scale),
      child: child,
    );
  }
}