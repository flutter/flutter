// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_mcp/server.dart' as engine_mcp;
import 'package:mcp_dart/mcp_dart.dart';

void main() async {
  final McpServer server = engine_mcp.makeServer();
  server.connect(StdioServerTransport());
}
