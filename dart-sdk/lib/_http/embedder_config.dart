// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

/// Embedder-specific `dart:_http` configuration.

/// Embedder hook for intercepting HTTP connections.
///
/// The [HttpClient] will call this function as a connection to a given [Uri]
/// is being established.
///
/// The embedder can provide its own implementation to,
/// for example, confirm whether such a connection should be allowed.
/// If the connection is not allowed, this method can throw an [Error],
/// which should then provide enough information to say why the connection
/// was refused.
/// If this function returns normally, the connection attempt will proceed.
@pragma('vm:entry-point')
void Function(Uri) _httpConnectionHook = (_) {};
