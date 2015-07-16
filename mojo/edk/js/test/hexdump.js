// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

define(function() {
  function hexify(value, length) {
    var hex = value.toString(16);
    while (hex.length < length)
      hex = "0" + hex;
    return hex;
  }

  function dumpArray(bytes) {
    var dumped = "";
    for (var i = 0; i < bytes.length; ++i) {
      dumped += hexify(bytes[i], 2);

      if (i % 16 == 15) {
        dumped += "\n";
        continue;
      }

      if (i % 2 == 1)
        dumped += " ";
      if (i % 8 == 7)
        dumped += " ";
    }
    return dumped;
  }

  var exports = {};
  exports.dumpArray = dumpArray;
  return exports;
});
