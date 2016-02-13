// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:mojo_services/mojo/service_registry.mojom.dart';
import 'package:mojo/core.dart' as core;

ServiceRegistryProxy _initServiceRegistryProxy() {
  core.MojoHandle serviceRegistryHandle = new core.MojoHandle(ui.takeServiceRegistry());
  if (!serviceRegistryHandle.isValid)
    return null;
  return new ServiceRegistryProxy.fromHandle(serviceRegistryHandle);
}

final ServiceRegistryProxy _serviceRegistryProxy = _initServiceRegistryProxy();
final ServiceRegistry serviceRegistry = _serviceRegistryProxy?.ptr;
