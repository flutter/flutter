// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_embedder_packages;

// We import these here so they are slurped up into the snapshot. Only packages
// copied by the "dart_embedder_packages" rule can be imported here.

// dart:_* libraries can only be imported by other 'dart:' libraries. The
// file system path of these libraries is provided by passing --url_mapping
// arguments to gen_snapshot. If you need to add new embedder packages,
// you must also change the snapshot generation rule. See HACKING.md for more
// information.

// DO NOT export anything from this library.

import 'dart:_mojo/application.dart';
import 'dart:_mojo/bindings.dart';
import 'dart:_mojo/core.dart';
import 'dart:_mojom/mojo/host_resolver.mojom.dart';
import 'dart:_mojom/mojo/net_address.mojom.dart';
import 'dart:_mojom/mojo/network_error.mojom.dart';
import 'dart:_mojom/mojo/network_service.mojom.dart';
import 'dart:_mojom/mojo/tcp_bound_socket.mojom.dart';
import 'dart:_mojom/mojo/tcp_connected_socket.mojom.dart';
import 'dart:_mojom/mojo/tcp_server_socket.mojom.dart';
