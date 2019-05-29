// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script runs in HTML files and loads the corresponding test scripts for
// a JS browser. It's used by "pub serve" and user-authored HTML files;
window.onload = function() {

// Sends an error message to the server indicating that the script failed to
// load.
//
// This mimics a MultiChannel-formatted message.
var sendLoadException = function(message) {
  window.parent.postMessage({
    "href": window.location.href,
    "data": [0, {"type": "loadException", "message": message}],
    "exception": true,
  }, window.location.origin);
}

// Listen for dartLoadException events and forward to the server.
window.addEventListener('dartLoadException', function(e) {
  sendLoadException(e.detail);
});

// The basename of the current page.
var name = window.location.href.replace(/.*\//, '').replace(/#.*/, '');

// Find <link rel="x-dart-test">.
var links = document.getElementsByTagName("link");
var testLinks = [];
var length = links.length;
for (var i = 0; i < length; ++i) {
  if (links[i].rel == "x-dart-test") testLinks.push(links[i]);
}

if (testLinks.length != 1) {
  sendLoadException(
      'Expected exactly 1 <link rel="x-dart-test"> in ' + name + ', found ' +
          testLinks.length + '.');
  return;
}

var link = testLinks[0];

if (link.href == '') {
  sendLoadException(
      'Expected <link rel="x-dart-test"> in ' + name + ' to have an "href" ' +
          'attribute.');
  return;
}

var script = document.createElement('script');

script.src = link.href + '.browser_test.dart.js';

script.onerror = function(event) {
  var message = "Failed to load script at " + script.src +
      (event.message ? ": " + event.message : ".");
  sendLoadException(message);
}

var parent = link.parentNode;
document.currentScript = script;
parent.replaceChild(script, link);

};
