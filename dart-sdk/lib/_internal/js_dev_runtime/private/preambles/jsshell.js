// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// JavaScript preamble, that lets the output of dart2js run on JSShell.

(function(self) {
  // Using strict mode to avoid accidentally defining global variables.
  "use strict"; // Should be first statement of this function.

  // Location (Uri.base)

  var workingDirectory = environment["PWD"];
  self.location = { href: "file://" + workingDirectory + "/" };

  // Global properties. "self" refers to the global object, so adding a
  // property to "self" defines a global variable.
  self.self = self;
})(this)
