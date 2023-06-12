// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;

final _graphReference = js.context[r'$build'];
final _details = document.getElementById('details');

void main() async {
  var filterBox = document.getElementById('filter') as InputElement;
  var searchBox = document.getElementById('searchbox') as InputElement;
  var searchForm = document.getElementById('searchform');
  searchForm.onSubmit.listen((e) {
    e.preventDefault();
    _focus(searchBox.value.trim(),
        filter: filterBox.value.isNotEmpty ? filterBox.value : null);
    return null;
  });
  _graphReference.callMethod('initializeGraph', [_focus]);
}

void _error(String message, [Object error, StackTrace stack]) {
  var msg = [message, error, stack].where((e) => e != null).join('\n');
  _details.innerHtml = '<pre>$msg</pre>';
}

Future _focus(String query, {String filter}) async {
  if (query.isEmpty) {
    _error('Provide content in the query.');
    return;
  }

  Map nodeInfo;
  var queryParams = {'q': query};
  if (filter != null) queryParams['f'] = filter;
  var uri = Uri(queryParameters: queryParams);
  try {
    nodeInfo = json.decode(await HttpRequest.getString(uri.toString()))
        as Map<String, dynamic>;
  } catch (e, stack) {
    var msg = 'Error requesting query "$query".';
    if (e is ProgressEvent) {
      var target = e.target;
      if (target is HttpRequest) {
        msg = [
          msg,
          '${target.status} ${target.statusText}',
          target.responseText
        ].join('\n');
      }
      _error(msg);
    } else {
      _error(msg, e, stack);
    }
    return;
  }

  var graphData = {'edges': nodeInfo['edges'], 'nodes': nodeInfo['nodes']};
  _graphReference.callMethod('setData', [js.JsObject.jsify(graphData)]);
  var primaryNode = nodeInfo['primary'];
  _details.innerHtml = '<strong>ID:</strong> ${primaryNode['id']} <br />'
      '<strong>Type:</strong> ${primaryNode['type']}<br />'
      '<strong>Hidden:</strong> ${primaryNode['hidden']} <br />'
      '<strong>State:</strong> ${primaryNode['state']} <br />'
      '<strong>Was Output:</strong> ${primaryNode['wasOutput']} <br />'
      '<strong>Failed:</strong> ${primaryNode['isFailure']} <br />'
      '<strong>Phase:</strong> ${primaryNode['phaseNumber']} <br />'
      '<strong>Glob:</strong> ${primaryNode['glob']}<br />'
      '<strong>Last Digest:</strong> ${primaryNode['lastKnownDigest']}<br />';
}
