import 'package:test/test.dart';
import 'dart:convert';

void main() {
  test('sample test', () {
    //print('hello test');
    var jsonStr = '["a", "b", "c"]';
    List<String> strs = jsonDecode(jsonStr).cast<String>();
    print(strs);

    var res = jsonEncode({'list': strs});
    print(res);



  });
}