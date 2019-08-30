// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

import 'package:test/test.dart';

import 'matchers.dart';

const MethodCodec codec = JSONMethodCodec();

TextEditingElement editingElement;
EditingState lastEditingState;

final InputConfiguration singlelineConfig =
    InputConfiguration(inputType: InputType.text);
final Map<String, dynamic> flutterSinglelineConfig = <String, dynamic>{
  'inputType': <String, String>{
    'name': 'TextInputType.text',
  },
  'obscureText': false,
};

final InputConfiguration multilineConfig =
    InputConfiguration(inputType: InputType.multiline);
final Map<String, dynamic> flutterMultilineConfig = <String, dynamic>{
  'inputType': <String, String>{
    'name': 'TextInputType.multiline',
  },
  'obscureText': false,
};

void trackEditingState(EditingState editingState) {
  lastEditingState = editingState;
}

void main() {
  group('$TextEditingElement', () {
    setUp(() {
      editingElement = TextEditingElement(HybridTextEditing());
    });

    tearDown(() {
      try {
        editingElement.disable();
      } catch (e) {
        if (e is AssertionError) {
          // This is fine. It just means the test itself disabled the editing element.
        } else {
          rethrow;
        }
      }
    });

    test('Creates element when enabled and removes it when disabled', () {
      expect(
        document.getElementsByTagName('input'),
        hasLength(0),
      );
      // The focus initially is on the body.
      expect(document.activeElement, document.body);

      editingElement.enable(singlelineConfig, onChange: trackEditingState);
      expect(
        document.getElementsByTagName('input'),
        hasLength(1),
      );
      final InputElement input = document.getElementsByTagName('input')[0];
      // Now the editing element should have focus.
      expect(document.activeElement, input);
      expect(editingElement.domElement, input);

      editingElement.disable();
      expect(
        document.getElementsByTagName('input'),
        hasLength(0),
      );
      // The focus is back to the body.
      expect(document.activeElement, document.body);
    });

    test('Can read editing state correctly', () {
      editingElement.enable(singlelineConfig, onChange: trackEditingState);

      final InputElement input = editingElement.domElement;
      input.value = 'foo bar';
      input.dispatchEvent(Event.eventType('Event', 'input'));
      expect(
        lastEditingState,
        EditingState(text: 'foo bar', baseOffset: 7, extentOffset: 7),
      );

      input.setSelectionRange(4, 6);
      document.dispatchEvent(Event.eventType('Event', 'selectionchange'));
      expect(
        lastEditingState,
        EditingState(text: 'foo bar', baseOffset: 4, extentOffset: 6),
      );
    });

    test('Can set editing state correctly', () {
      editingElement.enable(singlelineConfig, onChange: trackEditingState);
      editingElement.setEditingState(
          EditingState(text: 'foo bar baz', baseOffset: 2, extentOffset: 7));

      checkInputEditingState(editingElement.domElement, 'foo bar baz', 2, 7);
    });

    test('Re-acquires focus', () async {
      editingElement.enable(singlelineConfig, onChange: trackEditingState);
      expect(document.activeElement, editingElement.domElement);

      editingElement.domElement.blur();
      // The focus remains on [editingElement.domElement].
      expect(document.activeElement, editingElement.domElement);
    });

    test('Multi-line mode also works', () {
      // The textarea element is created lazily.
      expect(document.getElementsByTagName('textarea'), hasLength(0));
      editingElement.enable(multilineConfig, onChange: trackEditingState);
      expect(document.getElementsByTagName('textarea'), hasLength(1));

      final TextAreaElement textarea =
          document.getElementsByTagName('textarea')[0];
      // Now the textarea should have focus.
      expect(document.activeElement, textarea);
      expect(editingElement.domElement, textarea);

      textarea.value = 'foo\nbar';
      textarea.dispatchEvent(Event.eventType('Event', 'input'));
      textarea.setSelectionRange(4, 6);
      textarea.dispatchEvent(Event.eventType('Event', 'selectionchange'));
      // Can read textarea state correctly (and preserves new lines).
      expect(
        lastEditingState,
        EditingState(text: 'foo\nbar', baseOffset: 4, extentOffset: 6),
      );

      // Can set textarea state correctly (and preserves new lines).
      editingElement.setEditingState(
          EditingState(text: 'bar\nbaz', baseOffset: 2, extentOffset: 7));
      checkTextAreaEditingState(textarea, 'bar\nbaz', 2, 7);

      // Re-acquires focus.
      textarea.blur();
      expect(document.activeElement, textarea);

      editingElement.disable();
      // The textarea should be cleaned up.
      expect(document.getElementsByTagName('textarea'), hasLength(0));
      // The focus is back to the body.
      expect(document.activeElement, document.body);
    });

    test('Same instance can be re-enabled with different config', () {
      // Make sure there's nothing in the DOM yet.
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Use single-line config and expect an `<input>` to be created.
      editingElement.enable(singlelineConfig, onChange: trackEditingState);
      expect(document.getElementsByTagName('input'), hasLength(1));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Disable and check that all DOM elements were removed.
      editingElement.disable();
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Use multi-line config and expect an `<textarea>` to be created.
      editingElement.enable(multilineConfig, onChange: trackEditingState);
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(1));

      // Disable again and check that all DOM elements were removed.
      editingElement.disable();
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));
    });

    test('Can swap backing elements on the fly', () {
      // TODO(mdebbar): implement.
    });

    group('[persistent mode]', () {
      test('Does not accept dom elements of a wrong type', () {
        // A regular <span> shouldn't be accepted.
        final HtmlElement span = SpanElement();
        expect(
          () => PersistentTextEditingElement(HybridTextEditing(), span,
              onDomElementSwap: null),
          throwsAssertionError,
        );
      });

      test('Does not re-acquire focus', () {
        // See [PersistentTextEditingElement._refocus] for an explanation of why
        // re-acquiring focus shouldn't happen in persistent mode.
        final InputElement input = InputElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), input,
                onDomElementSwap: () {});
        expect(document.activeElement, document.body);

        document.body.append(input);
        persistentEditingElement.enable(singlelineConfig,
            onChange: trackEditingState);
        expect(document.activeElement, input);

        // The input should lose focus now.
        persistentEditingElement.domElement.blur();
        expect(document.activeElement, document.body);

        persistentEditingElement.disable();
      });

      test('Does not dispose and recreate dom elements in persistent mode', () {
        final InputElement input = InputElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), input,
                onDomElementSwap: () {});

        // The DOM element should've been eagerly created.
        expect(input, isNotNull);
        // But doesn't have focus.
        expect(document.activeElement, document.body);

        // Can't enable before the input element is inserted into the DOM.
        expect(
          () => persistentEditingElement.enable(singlelineConfig,
              onChange: trackEditingState),
          throwsAssertionError,
        );

        document.body.append(input);
        persistentEditingElement.enable(singlelineConfig,
            onChange: trackEditingState);
        expect(document.activeElement, persistentEditingElement.domElement);
        // It doesn't create a new DOM element.
        expect(persistentEditingElement.domElement, input);

        persistentEditingElement.disable();
        // It doesn't remove the DOM element.
        expect(persistentEditingElement.domElement, input);
        expect(document.body.contains(persistentEditingElement.domElement),
            isTrue);
        // But the DOM element loses focus.
        expect(document.activeElement, document.body);
      });

      test('Refocuses when setting editing state', () {
        final InputElement input = InputElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), input,
                onDomElementSwap: () {});

        document.body.append(input);
        persistentEditingElement.enable(singlelineConfig,
            onChange: trackEditingState);
        expect(document.activeElement, input);

        persistentEditingElement.domElement.blur();
        expect(document.activeElement, document.body);

        // The input should regain focus now.
        persistentEditingElement.setEditingState(EditingState(text: 'foo'));
        expect(document.activeElement, input);

        persistentEditingElement.disable();
      });

      test('Works in multi-line mode', () {
        final TextAreaElement textarea = TextAreaElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), textarea,
                onDomElementSwap: () {});

        expect(persistentEditingElement.domElement, textarea);
        expect(document.activeElement, document.body);

        // Can't enable before the textarea is inserted into the DOM.
        expect(
          () => persistentEditingElement.enable(singlelineConfig,
              onChange: trackEditingState),
          throwsAssertionError,
        );

        document.body.append(textarea);
        persistentEditingElement.enable(multilineConfig,
            onChange: trackEditingState);
        // Focuses the textarea.
        expect(document.activeElement, textarea);

        // Doesn't re-acquire focus.
        textarea.blur();
        expect(document.activeElement, document.body);

        // Re-focuses when setting editing state
        persistentEditingElement.setEditingState(EditingState(text: 'foo'));
        expect(document.activeElement, textarea);

        persistentEditingElement.disable();
        // It doesn't remove the textarea from the DOM.
        expect(persistentEditingElement.domElement, textarea);
        expect(document.body.contains(persistentEditingElement.domElement),
            isTrue);
        // But the textarea loses focus.
        expect(document.activeElement, document.body);
      });
    });
  });

  group('$HybridTextEditing', () {
    HybridTextEditing textEditing;
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    setUp(() {
      textEditing = HybridTextEditing();
      spy.activate();
    });

    tearDown(() {
      // TODO(mdebbar): clean-up stuff that HybridTextEditing registered on the page
      spy.deactivate();
    });

    test('setClient, show, setEditingState, hide', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      checkInputEditingState(textEditing.editingElement.domElement, '', 0, 0);

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      const MethodCall hide = MethodCall('TextInput.hide');
      textEditing.handleTextInput(codec.encodeMethodCall(hide));

      // Text editing should've stopped.
      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('setClient, setEditingState, show, clearClient', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      textEditing.handleTextInput(codec.encodeMethodCall(clearClient));

      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('setClient, setEditingState, show, setClient', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      final MethodCall setClient2 = MethodCall(
          'TextInput.setClient', <dynamic>[567, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient2));

      // Receiving another client via setClient should stop editing, hence
      // should remove the previous active element.
      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('setClient, setEditingState, show, setEditingState, clearClient', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      const MethodCall setEditingState2 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': 0,
        'selectionExtent': 2,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState2));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 0, 2);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      textEditing.handleTextInput(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test(
        'setClient, setLocationSize, setStyle, setEditingState, show, clearClient',
        () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      final MethodCall setSizeAndTransform =
          MethodCall('TextInput.setEditableSizeAndTransform', <String, dynamic>{
        'width': 150,
        'height': 50,
        'transform':
            Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList()
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setSizeAndTransform));

      const MethodCall setStyle =
          MethodCall('TextInput.setStyle', <String, dynamic>{
        'fontSize': 12,
        'fontFamily': 'sans-serif',
        'textAlignIndex': 4,
        'fontWeightIndex': 4,
        'textDirectionIndex': 1,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setStyle));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      final HtmlElement domElement = textEditing.editingElement.domElement;

      checkInputEditingState(domElement, 'abcd', 2, 3);

      // Check if the location and styling is correct.
      expect(
          domElement.getBoundingClientRect(),
          Rectangle<double>.fromPoints(const Point<double>(10.0, 20.0),
              const Point<double>(160.0, 70.0)));
      expect(domElement.style.transform,
          'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1)');
      expect(textEditing.editingElement.domElement.style.font,
          '500 12px sans-serif');

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      textEditing.handleTextInput(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('Syncs the editing state back to Flutter', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      final InputElement input = textEditing.editingElement.domElement;

      input.value = 'something';
      input.dispatchEvent(Event.eventType('Event', 'input'));

      expect(spy.messages, hasLength(1));
      MethodCall call = spy.messages[0];
      spy.messages.clear();
      expect(call.method, 'TextInputClient.updateEditingState');
      expect(
        call.arguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something',
            'selectionBase': 9,
            'selectionExtent': 9
          }
        ],
      );

      input.setSelectionRange(2, 5);
      document.dispatchEvent(Event.eventType('Event', 'selectionchange'));

      expect(spy.messages, hasLength(1));
      call = spy.messages[0];
      spy.messages.clear();
      expect(call.method, 'TextInputClient.updateEditingState');
      expect(
        call.arguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something',
            'selectionBase': 2,
            'selectionExtent': 5
          }
        ],
      );

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      textEditing.handleTextInput(codec.encodeMethodCall(clearClient));
    });

    test('Multi-line mode also works', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterMultilineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      final TextAreaElement textarea = textEditing.editingElement.domElement;
      checkTextAreaEditingState(textarea, '', 0, 0);

      // Can set editing state and preserve new lines.
      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'foo\nbar',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState));
      checkTextAreaEditingState(textarea, 'foo\nbar', 2, 3);

      // Sends the changes back to Flutter.
      textarea.value = 'something\nelse';
      textarea.dispatchEvent(Event.eventType('Event', 'input'));
      textarea.setSelectionRange(2, 5);
      document.dispatchEvent(Event.eventType('Event', 'selectionchange'));

      // Two messages should've been sent. One for the 'input' event and one for
      // the 'selectionchange' event.
      expect(spy.messages, hasLength(2));
      final MethodCall call = spy.messages.last;
      spy.messages.clear();
      expect(call.method, 'TextInputClient.updateEditingState');
      expect(
        call.arguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something\nelse',
            'selectionBase': 2,
            'selectionExtent': 5
          }
        ],
      );

      const MethodCall hide = MethodCall('TextInput.hide');
      textEditing.handleTextInput(codec.encodeMethodCall(hide));

      // Text editing should've stopped.
      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any more messages.
      expect(spy.messages, isEmpty);
    });
  });
}

void checkInputEditingState(
    InputElement input, String text, int start, int end) {
  expect(document.activeElement, input);
  expect(input.value, text);
  expect(input.selectionStart, start);
  expect(input.selectionEnd, end);
}

void checkTextAreaEditingState(
  TextAreaElement textarea,
  String text,
  int start,
  int end,
) {
  expect(document.activeElement, textarea);
  expect(textarea.value, text);
  expect(textarea.selectionStart, start);
  expect(textarea.selectionEnd, end);
}

class PlatformMessagesSpy {
  bool _isActive = false;
  ui.PlatformMessageCallback _backup;

  final List<MethodCall> messages = <MethodCall>[];

  void activate() {
    assert(!_isActive);
    _isActive = true;
    _backup = ui.window.onPlatformMessage;
    ui.window.onPlatformMessage = (String channel, ByteData data,
        ui.PlatformMessageResponseCallback callback) {
      messages.add(codec.decodeMethodCall(data));
    };
  }

  void deactivate() {
    assert(_isActive);
    _isActive = false;
    messages.clear();
    ui.window.onPlatformMessage = _backup;
  }
}
