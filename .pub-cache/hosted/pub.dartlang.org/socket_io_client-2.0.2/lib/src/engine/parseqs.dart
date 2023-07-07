///
/// parseqs.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///   26/04/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
///
String encode(Map obj) {
  var str = '';

  for (var i in obj.keys) {
    if (str.isNotEmpty) str += '&';
    str += Uri.encodeComponent('$i') + '=' + Uri.encodeComponent('${obj[i]}');
  }

  return str;
}

///
/// Parses a simple querystring into an object
///
/// @param {String} qs
/// @api private
///
Map decode(qs) {
  var qry = <dynamic, dynamic>{};
  var pairs = qs.split('&');
  for (var i = 0, l = pairs.length; i < l; i++) {
    var pair = pairs[i].split('=');
    qry[Uri.decodeComponent(pair[0])] = Uri.decodeComponent(pair[1]);
  }
  return qry;
}
