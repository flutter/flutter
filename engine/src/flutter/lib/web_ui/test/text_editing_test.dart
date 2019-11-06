// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart' hide window;

import 'package:test/test.dart';

import 'matchers.dart';

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

const MethodCodec codec = JSONMethodCodec();

TextEditingElement editingElement;
EditingState lastEditingState;
String lastInputAction;

final InputConfiguration singlelineConfig = InputConfiguration(
  inputType: EngineInputType.text,
  obscureText: false,
  inputAction: 'TextInputAction.done',
);
final Map<String, dynamic> flutterSinglelineConfig =
    createFlutterConfig('text');

final InputConfiguration multilineConfig = InputConfiguration(
  inputType: EngineInputType.multiline,
  obscureText: false,
  inputAction: 'TextInputAction.newline',
);
final Map<String, dynamic> flutterMultilineConfig =
    createFlutterConfig('multiline');

void trackEditingState(EditingState editingState) {
  lastEditingState = editingState;
}

void trackInputAction(String inputAction) {
  lastInputAction = inputAction;
}

void main() {
  tearDown(() {
    lastEditingState = null;
    lastInputAction = null;
  });

  group('$TextEditingElement', () {
    setUp(() {
      editingElement = TextEditingElement(HybridTextEditing());
    });

    tearDown(() {
      if (editingElement.isEnabled) {
        // Clean up all the DOM elements and event listeners.
        editingElement.disable();
      }
    });

    test('Creates element when enabled and removes it when disabled', () {
      expect(
        document.getElementsByTagName('input'),
        hasLength(0),
      );
      // The focus initially is on the body.
      expect(document.activeElement, document.body);

      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(
        document.getElementsByTagName('input'),
        hasLength(1),
      );
      final InputElement input = document.getElementsByTagName('input')[0];
      // Now the editing element should have focus.
      expect(document.activeElement, input);
      expect(editingElement.domElement, input);
      expect(input.getAttribute('type'), null);

      // Input is appended to the glass pane.
      expect(domRenderer.glassPaneElement.contains(editingElement.domElement),
          isTrue);

      editingElement.disable();
      expect(
        document.getElementsByTagName('input'),
        hasLength(0),
      );
      // The focus is back to the body.
      expect(document.activeElement, document.body);
    });

    test('Knows how to create password fields', () {
      final InputConfiguration config = InputConfiguration(
        inputType: EngineInputType.text,
        inputAction: 'TextInputAction.done',
        obscureText: true,
      );
      editingElement.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.getElementsByTagName('input'), hasLength(1));
      final InputElement input = document.getElementsByTagName('input')[0];
      expect(editingElement.domElement, input);
      expect(input.getAttribute('type'), 'password');

      editingElement.disable();
    });

    test('Can read editing state correctly', () {
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

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

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Can set editing state correctly', () {
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      editingElement.setEditingState(
          EditingState(text: 'foo bar baz', baseOffset: 2, extentOffset: 7));

      checkInputEditingState(editingElement.domElement, 'foo bar baz', 2, 7);

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Re-acquires focus', () async {
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.activeElement, editingElement.domElement);

      editingElement.domElement.blur();
      // The focus remains on [editingElement.domElement].
      expect(document.activeElement, editingElement.domElement);

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Multi-line mode also works', () {
      // The textarea element is created lazily.
      expect(document.getElementsByTagName('textarea'), hasLength(0));
      editingElement.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
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

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Same instance can be re-enabled with different config', () {
      // Make sure there's nothing in the DOM yet.
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Use single-line config and expect an `<input>` to be created.
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.getElementsByTagName('input'), hasLength(1));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Disable and check that all DOM elements were removed.
      editingElement.disable();
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Use multi-line config and expect an `<textarea>` to be created.
      editingElement.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(1));

      // Disable again and check that all DOM elements were removed.
      editingElement.disable();
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Triggers input action', () {
      final InputConfiguration config = InputConfiguration(
        inputType: EngineInputType.text,
        obscureText: false,
        inputAction: 'TextInputAction.done',
      );
      editingElement.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      // No input action so far.
      expect(lastInputAction, isNull);

      dispatchKeyboardEvent(
        editingElement.domElement,
        'keydown',
        keyCode: _kReturnKeyCode,
      );
      expect(lastInputAction, 'TextInputAction.done');
    });

    test('Does not trigger input action in multi-line mode', () {
      final InputConfiguration config = InputConfiguration(
        inputType: EngineInputType.multiline,
        obscureText: false,
        inputAction: 'TextInputAction.done',
      );
      editingElement.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      // No input action so far.
      expect(lastInputAction, isNull);

      final KeyboardEvent event = dispatchKeyboardEvent(
        editingElement.domElement,
        'keydown',
        keyCode: _kReturnKeyCode,
      );

      // Still no input action.
      expect(lastInputAction, isNull);
      // And default behavior of keyboard event shouldn't have been prevented.
      expect(event.defaultPrevented, isFalse);
    });

    group('[persistent mode]', () {
      test('Does not accept dom elements of a wrong type', () {
        // A regular <span> shouldn't be accepted.
        final HtmlElement span = SpanElement();
        expect(
          () => PersistentTextEditingElement(HybridTextEditing(), span),
          throwsAssertionError,
        );
      });

      test('Does not re-acquire focus', () {
        // See [PersistentTextEditingElement._refocus] for an explanation of why
        // re-acquiring focus shouldn't happen in persistent mode.
        final InputElement input = InputElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), input);
        expect(document.activeElement, document.body);

        document.body.append(input);
        persistentEditingElement.enable(
          singlelineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        );
        expect(document.activeElement, input);

        // The input should lose focus now.
        persistentEditingElement.domElement.blur();
        expect(document.activeElement, document.body);

        persistentEditingElement.disable();
      });

      test('Does not dispose and recreate dom elements in persistent mode', () {
        final InputElement input = InputElement();
        final PersistentTextEditingElement persistentEditingElement =
            PersistentTextEditingElement(HybridTextEditing(), input);

        // The DOM element should've been eagerly created.
        expect(input, isNotNull);
        // But doesn't have focus.
        expect(document.activeElement, document.body);

        // Can't enable before the input element is inserted into the DOM.
        expect(
          () => persistentEditingElement.enable(
            singlelineConfig,
            onChange: trackEditingState,
            onAction: trackInputAction,
          ),
          throwsAssertionError,
        );

        document.body.append(input);
        persistentEditingElement.enable(
          singlelineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        );
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
            PersistentTextEditingElement(HybridTextEditing(), input);

        document.body.append(input);
        persistentEditingElement.enable(
          singlelineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        );
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
            PersistentTextEditingElement(HybridTextEditing(), textarea);

        expect(persistentEditingElement.domElement, textarea);
        expect(document.activeElement, document.body);

        // Can't enable before the textarea is inserted into the DOM.
        expect(
          () => persistentEditingElement.enable(
            singlelineConfig,
            onChange: trackEditingState,
            onAction: trackInputAction,
          ),
          throwsAssertionError,
        );

        document.body.append(textarea);
        persistentEditingElement.enable(
          multilineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        );
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

    int clientId = 0;

    /// Sends the necessary platform messages to activate a text field and show
    /// the keyboard.
    ///
    /// Returns the `clientId` used in the platform message.
    int showKeyboard({String inputType, String inputAction}) {
      final MethodCall setClient = MethodCall(
        'TextInput.setClient',
        <dynamic>[
          ++clientId,
          createFlutterConfig(inputType, inputAction: inputAction),
        ],
      );
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      return clientId;
    }

    void hideKeyboard() {
      const MethodCall hide = MethodCall('TextInput.hide');
      textEditing.handleTextInput(codec.encodeMethodCall(hide));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      textEditing.handleTextInput(codec.encodeMethodCall(clearClient));
    }

    String getEditingInputMode() {
      return textEditing.editingElement.domElement.getAttribute('inputmode');
    }

    setUp(() {
      textEditing = HybridTextEditing();
      spy.activate();
    });

    tearDown(() {
      spy.deactivate();
      if (textEditing.isEditing) {
        textEditing.stopEditing();
      }
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

      hideKeyboard();
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
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      textEditing.handleTextInput(codec.encodeMethodCall(setSizeAndTransform));

      final MethodCall setStyle =
          configureSetStyleMethodCall(12, 'sans-serif', 4, 4, 1);
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

    test('input font set succesfully with null fontWeightIndex', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      textEditing.handleTextInput(codec.encodeMethodCall(setSizeAndTransform));

      final MethodCall setStyle = configureSetStyleMethodCall(
          12, 'sans-serif', 4, null /* fontWeightIndex */, 1);
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
      expect(
          textEditing.editingElement.domElement.style.font, '12px sans-serif');

      hideKeyboard();
    });

    test(
        'negative base offset and selection extent values in editing state is handled',
        () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      textEditing.handleTextInput(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': 1,
        'selectionExtent': 2,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      textEditing.handleTextInput(codec.encodeMethodCall(show));

      // Check if the selection range is correct.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 1, 2);

      const MethodCall setEditingState2 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': -1,
        'selectionExtent': -1,
      });
      textEditing.handleTextInput(codec.encodeMethodCall(setEditingState2));

      // The negative offset values are applied to the dom element as 0.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 0, 0);

      hideKeyboard();
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

      hideKeyboard();
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

    test('sets correct input type in Android', () {
      debugOperatingSystemOverride = OperatingSystem.android;

      showKeyboard(inputType: 'text');
      expect(getEditingInputMode(), 'text');

      showKeyboard(inputType: 'number');
      expect(getEditingInputMode(), 'numeric');

      showKeyboard(inputType: 'phone');
      expect(getEditingInputMode(), 'tel');

      showKeyboard(inputType: 'emailAddress');
      expect(getEditingInputMode(), 'email');

      showKeyboard(inputType: 'url');
      expect(getEditingInputMode(), 'url');

      hideKeyboard();

      debugOperatingSystemOverride = null;
    });

    test('sets correct input type in iOS', () {
      debugOperatingSystemOverride = OperatingSystem.iOs;

      showKeyboard(inputType: 'text');
      expect(getEditingInputMode(), 'text');

      showKeyboard(inputType: 'number');
      expect(getEditingInputMode(), 'numeric');

      showKeyboard(inputType: 'phone');
      expect(getEditingInputMode(), 'tel');

      showKeyboard(inputType: 'emailAddress');
      expect(getEditingInputMode(), 'email');

      showKeyboard(inputType: 'url');
      expect(getEditingInputMode(), 'url');

      hideKeyboard();

      debugOperatingSystemOverride = null;
    });

    test('sends the correct input action as a platform message', () {
      final int clientId = showKeyboard(
        inputType: 'text',
        inputAction: 'TextInputAction.next',
      );

      // There should be no input action yet.
      expect(lastInputAction, isNull);

      dispatchKeyboardEvent(
        textEditing.editingElement.domElement,
        'keydown',
        keyCode: _kReturnKeyCode,
      );

      expect(spy.messages, hasLength(1));
      final MethodCall call = spy.messages.first;
      expect(call.method, 'TextInputClient.performAction');
      expect(
        call.arguments,
        <dynamic>[clientId, 'TextInputAction.next'],
      );
    });

    test('does not send input action in multi-line mode', () {
      showKeyboard(
        inputType: 'multiline',
        inputAction: 'TextInputAction.next',
      );

      final KeyboardEvent event = dispatchKeyboardEvent(
        textEditing.editingElement.domElement,
        'keydown',
        keyCode: _kReturnKeyCode,
      );

      // No input action and no platform message have been sent.
      expect(spy.messages, isEmpty);
      // And default behavior of keyboard event shouldn't have been prevented.
      expect(event.defaultPrevented, isFalse);
    });
  });

  group('EditingState', () {
    EditingState _editingState;

    test('Configure input element from the editing state', () {
      final InputElement input = document.getElementsByTagName('input')[0];
      _editingState =
          EditingState(text: 'Test', baseOffset: 1, extentOffset: 2);

      _editingState.applyToDomElement(input);

      expect(input.value, 'Test');
      expect(input.selectionStart, 1);
      expect(input.selectionEnd, 2);
    });

    test('Configure text area element from the editing state', () {
      final TextAreaElement textArea =
          document.getElementsByTagName('textarea')[0];
      _editingState =
          EditingState(text: 'Test', baseOffset: 1, extentOffset: 2);

      _editingState.applyToDomElement(textArea);

      expect(textArea.value, 'Test');
      expect(textArea.selectionStart, 1);
      expect(textArea.selectionEnd, 2);
    });

    test('Get Editing State from input element', () {
      final InputElement input = document.getElementsByTagName('input')[0];
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      _editingState = EditingState.fromDomElement(input);

      expect(_editingState.text, 'Test');
      expect(_editingState.baseOffset, 1);
      expect(_editingState.extentOffset, 2);
    });

    test('Get Editing State from text area element', () {
      final TextAreaElement input =
          document.getElementsByTagName('textarea')[0];
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      _editingState = EditingState.fromDomElement(input);

      expect(_editingState.text, 'Test');
      expect(_editingState.baseOffset, 1);
      expect(_editingState.extentOffset, 2);
    });

    test('Compare two editing states', () {
      final InputElement input = document.getElementsByTagName('input')[0];
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      EditingState editingState1 = EditingState.fromDomElement(input);
      EditingState editingState2 = EditingState.fromDomElement(input);

      input.setSelectionRange(1, 3);

      EditingState editingState3 = EditingState.fromDomElement(input);

      expect(editingState1 == editingState2, true);
      expect(editingState1 != editingState3, true);
    });
  });
}

KeyboardEvent dispatchKeyboardEvent(
  EventTarget target,
  String type, {
  int keyCode,
}) {
  final Function jsKeyboardEvent = js_util.getProperty(window, 'KeyboardEvent');
  final List<dynamic> eventArgs = <dynamic>[
    type,
    <String, dynamic>{
      'keyCode': keyCode,
      'cancelable': true,
    }
  ];
  final KeyboardEvent event =
      js_util.callConstructor(jsKeyboardEvent, js_util.jsify(eventArgs));
  target.dispatchEvent(event);

  return event;
}

MethodCall configureSetStyleMethodCall(int fontSize, String fontFamily,
    int textAlignIndex, int fontWeightIndex, int textDirectionIndex) {
  return MethodCall('TextInput.setStyle', <String, dynamic>{
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'textAlignIndex': textAlignIndex,
    'fontWeightIndex': fontWeightIndex,
    'textDirectionIndex': textDirectionIndex,
  });
}

MethodCall configureSetSizeAndTransformMethodCall(
    int width, int height, List<double> transform) {
  return MethodCall('TextInput.setEditableSizeAndTransform', <String, dynamic>{
    'width': width,
    'height': height,
    'transform': transform
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

Map<String, dynamic> createFlutterConfig(
  String inputType, {
  bool obscureText = false,
  String inputAction,
}) {
  return <String, dynamic>{
    'inputType': <String, String>{
      'name': 'TextInputType.$inputType',
    },
    'obscureText': obscureText,
    'inputAction': inputAction ?? 'TextInputAction.done',
  };
}
