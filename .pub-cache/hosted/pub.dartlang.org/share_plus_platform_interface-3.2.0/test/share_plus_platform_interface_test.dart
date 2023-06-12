// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart'
    show TestDefaultBinaryMessengerBinding, TestWidgetsFlutterBinding;
import 'package:mockito/mockito.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:test/test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMethodChannel mockChannel;
  late SharePlatform sharePlatform;

  setUp(() {
    sharePlatform = SharePlatform();
    mockChannel = MockMethodChannel();
    // Re-pipe to mockito for easier verifies.
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelShare.channel,
            (MethodCall call) async {
      // The explicit type can be void as the only method call has a return type of void.
      await mockChannel.invokeMethod<void>(call.method, call.arguments);
      return null;
    });
  });

  test('can set SharePlatform instance', () {
    final currentId = identityHashCode(SharePlatform.instance);

    final newInstance = MethodChannelShare();
    final newInstanceId = identityHashCode(newInstance);

    expect(currentId, isNot(equals(newInstanceId)));
    expect(
      identityHashCode(SharePlatform.instance),
      equals(currentId),
    );
    SharePlatform.instance = newInstance;
    expect(
      identityHashCode(SharePlatform.instance),
      equals(newInstanceId),
    );
  });

  test('sharing empty fails', () {
    expect(
      () => sharePlatform.share(''),
      throwsA(const TypeMatcher<AssertionError>()),
    );
    expect(
      () => SharePlatform.instance.shareWithResult(''),
      throwsA(const TypeMatcher<AssertionError>()),
    );
    verifyZeroInteractions(mockChannel);
  });

  test('sharing origin sets the right params', () async {
    await sharePlatform.share(
      'some text to share',
      subject: 'some subject to share',
      sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
    );
    verify(mockChannel.invokeMethod<void>('share', <String, dynamic>{
      'text': 'some text to share',
      'subject': 'some subject to share',
      'originX': 1.0,
      'originY': 2.0,
      'originWidth': 3.0,
      'originHeight': 4.0,
    }));

    await SharePlatform.instance.shareWithResult(
      'some text to share',
      subject: 'some subject to share',
      sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
    );
    verify(mockChannel.invokeMethod<void>('shareWithResult', <String, dynamic>{
      'text': 'some text to share',
      'subject': 'some subject to share',
      'originX': 1.0,
      'originY': 2.0,
      'originWidth': 3.0,
      'originHeight': 4.0,
    }));

    await withFile('tempfile-83649a.png', (File fd) async {
      await sharePlatform.shareFiles(
        [fd.path],
        subject: 'some subject to share',
        text: 'some text to share',
        sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
      );
      verify(mockChannel.invokeMethod<void>(
        'shareFiles',
        <String, dynamic>{
          'paths': [fd.path],
          'mimeTypes': ['image/png'],
          'subject': 'some subject to share',
          'text': 'some text to share',
          'originX': 1.0,
          'originY': 2.0,
          'originWidth': 3.0,
          'originHeight': 4.0,
        },
      ));

      await SharePlatform.instance.shareFilesWithResult(
        [fd.path],
        subject: 'some subject to share',
        text: 'some text to share',
        sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
      );
      verify(mockChannel.invokeMethod<void>(
        'shareFilesWithResult',
        <String, dynamic>{
          'paths': [fd.path],
          'mimeTypes': ['image/png'],
          'subject': 'some subject to share',
          'text': 'some text to share',
          'originX': 1.0,
          'originY': 2.0,
          'originWidth': 3.0,
          'originHeight': 4.0,
        },
      ));

      await sharePlatform.shareXFiles(
        [XFile(fd.path)],
        subject: 'some subject to share',
        text: 'some text to share',
        sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
      );
      verify(mockChannel.invokeMethod<void>(
        'shareFilesWithResult',
        <String, dynamic>{
          'paths': [fd.path],
          'mimeTypes': ['image/png'],
          'subject': 'some subject to share',
          'text': 'some text to share',
          'originX': 1.0,
          'originY': 2.0,
          'originWidth': 3.0,
          'originHeight': 4.0,
        },
      ));
    });
  });

  test('sharing empty file fails', () {
    expect(
      () => sharePlatform.shareFiles(['']),
      throwsA(const TypeMatcher<AssertionError>()),
    );
    expect(
      () => SharePlatform.instance.shareFilesWithResult(['']),
      throwsA(const TypeMatcher<AssertionError>()),
    );

    verifyZeroInteractions(mockChannel);
  });

  test('sharing file sets correct mimeType', () async {
    await withFile('tempfile-83649b.png', (File fd) async {
      await sharePlatform.shareFiles([fd.path]);
      verify(mockChannel.invokeMethod('shareFiles', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['image/png'],
      }));

      await SharePlatform.instance.shareFilesWithResult([fd.path]);
      verify(mockChannel.invokeMethod('shareFilesWithResult', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['image/png'],
      }));

      await sharePlatform.shareXFiles([XFile(fd.path)]);
      verify(mockChannel.invokeMethod('shareFilesWithResult', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['image/png'],
      }));
    });
  });

  test('sharing file sets passed mimeType', () async {
    await withFile('tempfile-83649c.png', (File fd) async {
      await sharePlatform.shareFiles([fd.path], mimeTypes: ['*/*']);
      verify(mockChannel.invokeMethod('shareFiles', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['*/*'],
      }));

      await SharePlatform.instance
          .shareFilesWithResult([fd.path], mimeTypes: ['*/*']);
      verify(mockChannel.invokeMethod('shareFilesWithResult', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['*/*'],
      }));

      await sharePlatform.shareXFiles([XFile(fd.path, mimeType: '*/*')]);
      verify(mockChannel.invokeMethod('shareFilesWithResult', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['*/*'],
      }));
    });
  });

  test('withResult methods return unavailable on non IOS & Android', () async {
    const resultUnavailable = ShareResult(
      'dev.fluttercommunity.plus/share/unavailable',
      ShareResultStatus.unavailable,
    );

    expect(
      sharePlatform.shareWithResult('some text to share'),
      completion(equals(resultUnavailable)),
    );

    await withFile('tempfile-83649d.png', (File fd) async {
      expect(
        sharePlatform.shareFilesWithResult([fd.path]),
        completion(equals(resultUnavailable)),
      );
    });
  });

  test('withResult methods invoke normal share on non IOS & Android', () async {
    await sharePlatform.shareWithResult(
      'some text to share',
      subject: 'some subject to share',
      sharePositionOrigin: const Rect.fromLTWH(1.0, 2.0, 3.0, 4.0),
    );
    verify(mockChannel.invokeMethod<void>('share', <String, dynamic>{
      'text': 'some text to share',
      'subject': 'some subject to share',
      'originX': 1.0,
      'originY': 2.0,
      'originWidth': 3.0,
      'originHeight': 4.0,
    }));

    await withFile('tempfile-83649e.png', (File fd) async {
      await sharePlatform.shareFilesWithResult([fd.path]);
      verify(mockChannel.invokeMethod('shareFiles', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['image/png'],
      }));
    });

    await withFile('tempfile-83649e.png', (File fd) async {
      await sharePlatform.shareXFiles([XFile(fd.path)]);
      verify(mockChannel.invokeMethod('shareFilesWithResult', <String, dynamic>{
        'paths': [fd.path],
        'mimeTypes': ['image/png'],
      }));
    });
  });
}

/// Execute a block within a context that handles creation and deletion of a helper file
Future<T> withFile<T>(String filename, Future<T> Function(File fd) func) async {
  final file = File(filename);
  try {
    file.createSync();
    return await func(file);
  } finally {
    file.deleteSync();
  }
}

// https://github.com/dart-lang/mockito/issues/316
class MockMethodChannel extends Mock implements MethodChannel {
  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    return super
            .noSuchMethod(Invocation.method(#invokeMethod, [method, arguments]))
        as dynamic;
  }
}
