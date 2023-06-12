// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  // This function looks up the URL this script was loaded in and finds the
  // name of the callback function to call when the library is read.
  // The URL of the script load looks like:
  //    http://localhost:8080/folder/file?onload=dartGapiLoaded
  function findDartOnLoadCallback() {
    var scripts = document.getElementsByTagName('script');
    var self = scripts[scripts.length - 1];

    var equalsSign = self.src.indexOf('=');
    if (equalsSign <= 0) throw new Error('error');

    var callbackName = self.src.substring(equalsSign + 1);
    if (callbackName.length <= 0) throw new Error('error');

    var dartFunction = window[callbackName];
    if (dartFunction == null) throw new Error('error');

    return dartFunction;
  }

  function GapiAuth() {}
  GapiAuth.prototype.init = function(doneCallback) {
    doneCallback();
  };
  GapiAuth.prototype.authorize = function(json, doneCallback) {
    var client_id = json['client_id'];
    var response_type = json['response_type'];
    var scope = json['scope'];

    if (client_id == 'foo_client' &&
        response_type == 'code token' &&
        scope == 'scope1 scope2') {
      doneCallback({
        'token_type' : 'Bearer',
        'access_token' : 'foo_token',
        'expires_at' : Date.now() + 1000 * 3210,
        'code' : 'mycode'
      });
    } else {
      throw new Error('error');
    }
  };

  // Initialize the gapi.auth mock.
  window.gapi = new Object();
  window.gapi.auth2 = new GapiAuth();

  // Call the dart function. This signals that gapi.auth was loaded.
  var dartFunction = findDartOnLoadCallback();
  dartFunction();
})();
