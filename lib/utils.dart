import 'dart:core';

class StringUtils {
  static bool isEmpty(String str) {
    return str == null || str.length == 0;
  }

  static String safe(String str) {
    return str == null ? '' : str;
  }
}