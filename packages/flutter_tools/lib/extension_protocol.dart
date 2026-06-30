// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter Extension Protocol.
///
/// This protocol provides a mechanism for external extensions to communicate
/// with the Flutter tool. It defines communication primitives (requests,
/// responses, notifications) and manager/provider interfaces to facilitate
/// bi-directional communication.
library;

export 'src/extension_protocol/manager.dart' show RpcException, ToolExtensionManager;
export 'src/extension_protocol/messages.dart'
    show Message, Notification, Request, Response, RpcError;
export 'src/extension_protocol/provider.dart' show ToolExtensionProvider;
export 'src/extension_protocol/service.dart' show RpcRegistrar, ToolExtensionService;
