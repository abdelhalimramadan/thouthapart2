import 'dart:convert';
import 'dart:io';
void main() {
  var error = false;
  for (var f in ['ar.json', 'en.json']) {
    try {
      var s = File('c:/projects/thouthapart23/flutter_moblie_app/assets/translations/' + f).readAsStringSync();
      jsonDecode(s);
      print(f + ' is valid');
    } catch(e) {
      print(f + ' ERROR: ' + e.toString());
      error = true;
    }
  }
}

