import 'dart:convert';
import 'dart:io';

///
/// Small script to convert the .csv file to dart code to replace the internal object identifier database
///
void main(List<String> args) {
  var f = File('script/object_identifiers.csv');
  var list = <Map<String, Object>>[];
  var added = <String>[];
  for (var l in f.readAsLinesSync()) {
    var splitted = l.split(',');
    var s = splitted.elementAt(0);
    var splittedInts = s.split('.');
    var asInt = <int>[];
    for (var i in splittedInts) {
      asInt.add(int.parse(i));
    }
    var identifierString = splitted.elementAt(0);
    var readableName = splitted.elementAt(1);
    if (added.contains(identifierString)) {
      print('already added $identifierString ($readableName)');
    } else {
      added.add(splitted.elementAt(0));
    }
    list.add({
      'identifierString': identifierString,
      'readableName': readableName,
      'identifier': asInt
    });
  }
  print(json.encode(list));
}
