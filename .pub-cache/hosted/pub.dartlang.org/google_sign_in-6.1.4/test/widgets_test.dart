// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A instantiable class that extends [GoogleIdentity]
class _TestGoogleIdentity extends GoogleIdentity {
  _TestGoogleIdentity({
    required this.id,
    required this.email,
    this.photoUrl,
  });

  @override
  final String id;
  @override
  final String email;

  @override
  final String? photoUrl;

  @override
  String? get displayName => null;

  @override
  String? get serverAuthCode => null;
}

/// A mocked [HttpClient] which always returns a [_MockHttpRequest].
class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future<HttpClientRequest>.value(_MockHttpRequest());
  }
}

/// A mocked [HttpClientRequest] which always returns a [_MockHttpClientResponse].
class _MockHttpRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() {
    return Future<HttpClientResponse>.value(_MockHttpResponse());
  }
}

/// Arbitrary valid image returned by the [_MockHttpResponse].
///
/// This is an transparent 1x1 gif image.
/// It doesn't have to match the placeholder used in [GoogleUserCircleAvatar].
///
/// Those bytes come from `resources/transparentImage.gif`.
final Uint8List _transparentImage = Uint8List.fromList(
  <int>[
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, //
    0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21, 0xf9, 0x04, 0x01, 0x00, //
    0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, //
    0x00, 0x02, 0x01, 0x44, 0x00, 0x3B
  ],
);

/// A mocked [HttpClientResponse] which is empty and has a [statusCode] of 200
/// and returns valid image.
class _MockHttpResponse extends Fake implements HttpClientResponse {
  final Stream<Uint8List> _delegate =
      Stream<Uint8List>.value(_transparentImage);

  @override
  int get contentLength => -1;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _delegate.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  int get statusCode => 200;
}

void main() {
  testWidgets('It should build the GoogleUserCircleAvatar successfully',
      (WidgetTester tester) async {
    final GoogleIdentity identity = _TestGoogleIdentity(
      email: 'email@email.com',
      id: 'userId',
      photoUrl: 'photoUrl',
    );

    // TODO(pdblasi-google): Update `window` usages to new API after 3.9.0 is in stable. https://github.com/flutter/flutter/issues/122912
    // ignore: deprecated_member_use
    tester.binding.window.physicalSizeTestValue = const Size(100, 100);

    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            height: 100,
            width: 100,
            child: GoogleUserCircleAvatar(
              identity: identity,
            ),
          ),
        ));
      },
      createHttpClient: (SecurityContext? c) => _MockHttpClient(),
    );
  });
}
