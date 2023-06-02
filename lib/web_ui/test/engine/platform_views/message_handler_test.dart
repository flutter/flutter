// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const MethodCodec codec = StandardMethodCodec();

typedef PlatformViewFactoryCall = ({int viewId, Object? params});

void testMain() {
  group('PlatformViewMessageHandler', () {
    group('handlePlatformViewCall', () {
      const String viewType = 'forTest';
      const int viewId = 6;
      late PlatformViewManager contentManager;
      late Completer<ByteData?> completer;
      late Completer<DomElement> contentCompleter;

      setUp(() {
        contentManager = PlatformViewManager();
        completer = Completer<ByteData?>();
        contentCompleter = Completer<DomElement>();
      });

      group('"create" message', () {
        test('unregistered viewType, fails with descriptive exception',
            () async {
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
          );
          final ByteData? message = _getCreateMessage(viewType, viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final ByteData? response = await completer.future;
          try {
            codec.decodeEnvelope(response!);
          } on PlatformException catch (e) {
            expect(e.code, 'unregistered_view_type');
            expect(e.message, contains(viewType));
            expect(e.details, contains('registerViewFactory'));
          }
        });

        test('duplicate viewId, fails with descriptive exception', () async {
          contentManager.registerFactory(
              viewType, (int id) => createDomHTMLDivElement());
          contentManager.renderContent(viewType, viewId, null);
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
          );
          final ByteData? message = _getCreateMessage(viewType, viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final ByteData? response = await completer.future;
          try {
            codec.decodeEnvelope(response!);
          } on PlatformException catch (e) {
            expect(e.code, 'recreating_view');
            expect(e.details, contains('$viewId'));
          }
        });

        test('returns a successEnvelope when the view is created normally',
            () async {
          contentManager.registerFactory(
              viewType, (int id) => createDomHTMLDivElement()..id = 'success');
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
          );
          final ByteData? message = _getCreateMessage(viewType, viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final ByteData? response = await completer.future;
          expect(codec.decodeEnvelope(response!), isNull,
              reason:
                  'The response should be a success envelope, with null in it.');
        });

        test('calls a contentHandler with the result of creating a view',
            () async {
          contentManager.registerFactory(
              viewType, (int id) => createDomHTMLDivElement()..id = 'success');
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
            contentHandler: contentCompleter.complete,
          );
          final ByteData? message = _getCreateMessage(viewType, viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final DomElement contents = await contentCompleter.future;
          final ByteData? response = await completer.future;

          expect(contents.querySelector('div#success'), isNotNull,
              reason:
                  'The element created by the factory should be present in the created view.');
          expect(codec.decodeEnvelope(response!), isNull,
              reason:
                  'The response should be a success envelope, with null in it.');
        });

        test('passes creation params to the factory', () async {
          final List<PlatformViewFactoryCall> factoryCalls = <PlatformViewFactoryCall>[];
          contentManager.registerFactory(viewType, (int viewId, {Object? params}) {
            factoryCalls.add((viewId: viewId, params: params));
            return createDomHTMLDivElement();
          });
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
          );

          final List<Completer<ByteData?>> completers = <Completer<ByteData?>>[];

          completers.add(Completer<ByteData?>());
          messageHandler.handlePlatformViewCall(
            _getCreateMessage(viewType, 111),
            completers.last.complete,
          );

          completers.add(Completer<ByteData?>());
          messageHandler.handlePlatformViewCall(
            _getCreateMessage(viewType, 222, <dynamic, dynamic>{'foo': 'bar'}),
            completers.last.complete,
          );

          completers.add(Completer<ByteData?>());
          messageHandler.handlePlatformViewCall(
            _getCreateMessage(viewType, 333, 'foobar'),
            completers.last.complete,
          );

          completers.add(Completer<ByteData?>());
          messageHandler.handlePlatformViewCall(
            _getCreateMessage(viewType, 444, <dynamic>[1, null, 'str']),
            completers.last.complete,
          );

          final List<ByteData?> responses = await Future.wait(
            completers.map((Completer<ByteData?> c) => c.future),
          );

          for (final ByteData? response in responses) {
            expect(
              codec.decodeEnvelope(response!),
              isNull,
              reason: 'The response should be a success envelope, with null in it.',
            );
          }

          expect(factoryCalls, hasLength(4));
          expect(factoryCalls[0].viewId, 111);
          expect(factoryCalls[0].params, isNull);
          expect(factoryCalls[1].viewId, 222);
          expect(factoryCalls[1].params, <dynamic, dynamic>{'foo': 'bar'});
          expect(factoryCalls[2].viewId, 333);
          expect(factoryCalls[2].params, 'foobar');
          expect(factoryCalls[3].viewId, 444);
          expect(factoryCalls[3].params, <dynamic>[1, null, 'str']);
        });

        test('fails if the factory returns a non-DOM object', () async {
          contentManager.registerFactory(viewType, (int viewId) {
            // Return an object that's not a DOM element.
            return Object();
          });

          final PlatformViewMessageHandler messageHandler =
              PlatformViewMessageHandler(contentManager: contentManager);
          final ByteData? message = _getCreateMessage(viewType, viewId);

          expect(() {
            messageHandler.handlePlatformViewCall(message, (_) {});
          }, throwsA(isA<TypeError>()));
        });
      });

      group('"dispose" message', () {
        late Completer<int> viewIdCompleter;

        setUp(() {
          viewIdCompleter = Completer<int>();
        });

        test('never fails, even for unknown viewIds', () async {
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: contentManager,
          );
          final ByteData? message = _getDisposeMessage(viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final ByteData? response = await completer.future;
          expect(codec.decodeEnvelope(response!), isNull,
              reason:
                  'The response should be a success envelope, with null in it.');
        });

        test('never fails, even for unknown viewIds', () async {
          final PlatformViewMessageHandler messageHandler = PlatformViewMessageHandler(
            contentManager: _FakePlatformViewManager(viewIdCompleter.complete),
          );
          final ByteData? message = _getDisposeMessage(viewId);

          messageHandler.handlePlatformViewCall(message, completer.complete);

          final int disposedViewId = await viewIdCompleter.future;
          expect(disposedViewId, viewId,
              reason:
                  'The viewId to dispose should be passed to the contentManager');
        });
      });
    });
  });
}

class _FakePlatformViewManager extends PlatformViewManager {
  _FakePlatformViewManager(void Function(int) clearFunction)
      : _clearPlatformView = clearFunction;

  final void Function(int) _clearPlatformView;

  @override
  void clearPlatformView(int viewId) {
    return _clearPlatformView(viewId);
  }
}

ByteData? _getCreateMessage(String viewType, int viewId, [Object? params]) {
  return codec.encodeMethodCall(MethodCall(
    'create',
    <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
      if (params != null) 'params': params,
    },
  ));
}

ByteData? _getDisposeMessage(int viewId) {
  return codec.encodeMethodCall(MethodCall(
    'dispose',
    viewId,
  ));
}
