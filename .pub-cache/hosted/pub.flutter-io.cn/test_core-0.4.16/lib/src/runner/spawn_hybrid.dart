// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:async/async.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart' show RemoteException;
import 'package:test_api/src/backend/suite.dart'; // ignore: implementation_imports

import '../util/dart.dart' as dart;
import '../util/package_config.dart';
import 'package_version.dart';

/// Spawns a hybrid isolate from [url] with the given [message], and returns a
/// [StreamChannel] that communicates with it.
///
/// This connects the main isolate to the hybrid isolate, whereas
/// `lib/src/frontend/spawn_hybrid.dart` connects the test isolate to the main
/// isolate.
///
/// If [uri] is relative, it will be interpreted relative to the `file:` URL
/// for [suite]. If it's root-relative (that is, if it begins with `/`) it will
/// be interpreted relative to the root of the package (the directory that
/// contains `pubspec.yaml`, *not* the `test/` directory). If it's a `package:`
/// URL, it will be resolved using the current package's dependency
/// constellation.
StreamChannel spawnHybridUri(String url, Object? message, Suite suite) {
  return StreamChannelCompleter.fromFuture(() async {
    url = await _normalizeUrl(url, suite);
    var port = ReceivePort();
    var onExitPort = ReceivePort();
    try {
      var code = '''
        ${await _languageVersionCommentFor(url)}

        import "package:test_core/src/runner/hybrid_listener.dart";

        import "${url.replaceAll(r'$', '%24')}" as lib;

        void main(_, List data) => listen(() => lib.hybridMain, data);
      ''';

      var isolate = await dart.runInIsolate(code, [port.sendPort, message],
          onExit: onExitPort.sendPort);

      // Ensure that we close [port] and [channel] when the isolate exits.
      var disconnector = Disconnector();
      onExitPort.listen((_) {
        disconnector.disconnect();
        port.close();
        onExitPort.close();
      });

      return IsolateChannel.connectReceive(port)
          .transform(disconnector)
          .transformSink(StreamSinkTransformer.fromHandlers(handleDone: (sink) {
        // If the user closes the stream channel, kill the isolate.
        isolate.kill();
        port.close();
        onExitPort.close();
        sink.close();
      }));
    } catch (error, stackTrace) {
      port.close();
      onExitPort.close();

      // Make sure any errors in spawning the isolate are forwarded to the test.
      return StreamChannel(
          Stream.fromFuture(Future.value({
            'type': 'error',
            'error': RemoteException.serialize(error, stackTrace)
          })),
          NullStreamSink());
    }
  }());
}

/// Normalizes [url] to an absolute url, resolving `package:` urls with the
/// current package config.
///
/// If [url] has a scheme other than `package:`, then it is returned as is.
///
/// Follows the rules for relative/absolute paths outlined in [spawnHybridUri].
Future<String> _normalizeUrl(String url, Suite suite) async {
  final parsedUri = Uri.parse(url);

  switch (parsedUri.scheme) {
    case '':
      var isRootRelative = parsedUri.path.startsWith('/');

      if (isRootRelative) {
        // We assume that the current path is the package root. `pub run`
        // enforces this currently, but at some point it would probably be good
        // to pass in an explicit root.
        return p.url
            .join(p.toUri(p.current).toString(), parsedUri.path.substring(1));
      } else {
        var suitePath = suite.path!;
        return p.url.join(
            p.url.dirname(p.toUri(p.absolute(suitePath)).toString()),
            parsedUri.toString());
      }
    case 'package':
      final resolvedUri = await Isolate.resolvePackageUri(parsedUri);
      if (resolvedUri == null) {
        throw ArgumentError.value(
            url, 'uri', 'Could not resolve the package URI');
      }
      return resolvedUri.toString();
    default:
      return url;
  }
}

/// Computes the a language version comment for the library at [uri].
///
/// If there is a language version comment in the file, that is returned.
///
/// If the URI has a `data` scheme, a comment representing the language version of
/// the current package is returned.
///
/// Otherwise a comment representing the default version from the
/// [currentPackageConfig] is returned.
///
/// If no default language version is known (the URI scheme is not recognized
/// for instance), then an empty string is returned.
Future<String> _languageVersionCommentFor(String url) async {
  var parsedUri = Uri.parse(url);

  // Returns the explicit language version comment if one exists.
  var result = parseString(
      content: await _readUri(parsedUri),
      path: parsedUri.scheme == 'data' ? null : p.fromUri(parsedUri),
      throwIfDiagnostics: false);
  var languageVersionComment = result.unit.languageVersionToken?.value();
  if (languageVersionComment != null) return languageVersionComment.toString();

  // Returns the default language version for the package if one exists.
  if (parsedUri.scheme.isEmpty || parsedUri.scheme == 'file') {
    var packageConfig = await currentPackageConfig;
    var package = packageConfig.packageOf(parsedUri);
    var version = package?.languageVersion;
    if (version != null) return '// @dart=$version';
  }

  // Returns the root package language version for `data` URIs. These are
  // assumed to be from `spawnHybridCode` calls.
  if (parsedUri.scheme == 'data') {
    return await rootPackageLanguageVersionComment;
  }

  // Fall back on no language comment.
  return '';
}

Future<String> _readUri(Uri uri) async {
  switch (uri.scheme) {
    case '':
    case 'file':
      return File.fromUri(uri).readAsString();
    case 'data':
      return uri.data!.contentAsString();
    default:
      throw ArgumentError.value(uri, 'uri',
          'Only data and file uris (as well as relative paths) are supported');
  }
}
