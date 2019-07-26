// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';

import 'package:fuchsia_services/services.dart';
import 'package:fidl_fuchsia_examples_hello/fidl_async.dart';

class _HelloImpl extends Hello {
  final HelloBinding _binding = HelloBinding();

  void bind(InterfaceRequest<Hello> request) {
    _binding.bind(this, request);
  }

  @override
  Future<String> say(String request) async {
    return request == 'hello' ? 'hola from Dart!' : 'adios from Dart!';
  }
}

void main(List<String> args) {
  StartupContext context = StartupContext.fromStartupInfo();

  context.outgoing
      .addPublicService(_HelloImpl().bind, Hello.$serviceName);
}
