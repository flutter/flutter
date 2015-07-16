// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of sky_shell_dart_controller_service_isolate;

_processLoadRequest(request) {
  var sp = request[0];
  var uri = Uri.parse(request[1]);
  sp.send('Service isolate loading not supported by embedder (uri = $uri).');
}
