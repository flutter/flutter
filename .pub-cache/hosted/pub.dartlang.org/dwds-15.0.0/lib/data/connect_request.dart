// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'connect_request.g.dart';

/// A request to open DevTools.
abstract class ConnectRequest
    implements Built<ConnectRequest, ConnectRequestBuilder> {
  static Serializer<ConnectRequest> get serializer =>
      _$connectRequestSerializer;

  factory ConnectRequest([Function(ConnectRequestBuilder) updates]) =
      _$ConnectRequest;

  ConnectRequest._();

  /// Identifies a given application, across tabs/windows.
  String get appId;

  /// Identifies a given instance of an application, unique per tab/window.
  String get instanceId;

  /// The entrypoint for the Dart application.
  String get entrypointPath;
}
