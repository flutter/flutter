// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:ui/src/engine.dart' hide window;

import 'package:test/test.dart';

import 'matchers.dart';
import 'spy.dart';

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

const MethodCodec codec = JSONMethodCodec();

/// Add unit tests for [FirefoxTextEditingStrategy].
/// TODO(nurhan): https://github.com/flutter/flutter/issues/46891

DefaultTextEditingStrategy editingElement;
EditingState lastEditingState;
String lastInputAction;

final InputConfiguration singlelineConfig = InputConfiguration(
  inputType: EngineInputType.text,
  obscureText: false,
  inputAction: 'TextInputAction.done',
  autocorrect: true,
  textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
      'TextCapitalization.none'),
);
final Map<String, dynamic> flutterSinglelineConfig =
    createFlutterConfig('text');

final InputConfiguration multilineConfig = InputConfiguration(
    inputType: EngineInputType.multiline,
    obscureText: false,
    inputAction: 'TextInputAction.newline',
    autocorrect: true,
    textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
        'TextCapitalization.none'));
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
    cleanTextEditingElement();
    cleanTestFlags();
    clearBackUpDomElementIfExists();
  });

  group('$GloballyPositionedTextEditingStrategy', () {
    HybridTextEditing testTextEditing;

    setUp(() {
      testTextEditing = HybridTextEditing();
      editingElement = GloballyPositionedTextEditingStrategy(testTextEditing);
      testTextEditing.useCustomEditableElement(editingElement);
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
          autocorrect: true,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
              'TextCapitalization.none'));
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

    test('Knows to turn autocorrect off', () {
      final InputConfiguration config = InputConfiguration(
          inputType: EngineInputType.text,
          inputAction: 'TextInputAction.done',
          obscureText: false,
          autocorrect: false,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
              'TextCapitalization.none'));
      editingElement.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.getElementsByTagName('input'), hasLength(1));
      final InputElement input = document.getElementsByTagName('input')[0];
      expect(editingElement.domElement, input);
      expect(input.getAttribute('autocorrect'), 'off');

      editingElement.disable();
    });

    test('Knows to turn autocorrect on', () {
      final InputConfiguration config = InputConfiguration(
          inputType: EngineInputType.text,
          inputAction: 'TextInputAction.done',
          obscureText: false,
          autocorrect: true,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
              'TextCapitalization.none'));
      editingElement.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.getElementsByTagName('input'), hasLength(1));
      final InputElement input = document.getElementsByTagName('input')[0];
      expect(editingElement.domElement, input);
      expect(input.getAttribute('autocorrect'), 'on');

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
          autocorrect: true,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
              'TextCapitalization.none'));
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
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

    test('Does not trigger input action in multi-line mode', () {
      final InputConfiguration config = InputConfiguration(
          inputType: EngineInputType.multiline,
          obscureText: false,
          inputAction: 'TextInputAction.done',
          autocorrect: true,
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
              'TextCapitalization.none'));
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

    test('globally positions and sizes its DOM element', () {
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(editingElement.isEnabled, isTrue);

      // No geometry should be set until setEditableSizeAndTransform is called.
      expect(editingElement.domElement.style.transform, '');
      expect(editingElement.domElement.style.width, '');
      expect(editingElement.domElement.style.height, '');

      testTextEditing.setEditableSizeAndTransform(EditableTextGeometry(
        width: 13,
        height: 12,
        globalTransform: Matrix4.translationValues(14, 15, 0).storage,
      ));

      // setEditableSizeAndTransform calls placeElement, so expecting geometry to be applied.
      expect(editingElement.domElement.style.transform,
          'matrix(1, 0, 0, 1, 14, 15)');
      expect(editingElement.domElement.style.width, '13px');
      expect(editingElement.domElement.style.height, '12px');
    });
  });

  group('$SemanticsTextEditingStrategy', () {
    InputElement testInputElement;
    HybridTextEditing testTextEditing;

    setUp(() {
      testInputElement = InputElement();
      testTextEditing = HybridTextEditing();
      editingElement = GloballyPositionedTextEditingStrategy(testTextEditing);
    });

    tearDown(() {
      testInputElement = null;
    });

    test('Does not accept dom elements of a wrong type', () {
      // A regular <span> shouldn't be accepted.
      final HtmlElement span = SpanElement();
      expect(
        () => SemanticsTextEditingStrategy(HybridTextEditing(), span),
        throwsAssertionError,
      );
    });

    test('Re-acquire focus', () {
      editingElement =
          SemanticsTextEditingStrategy(HybridTextEditing(), testInputElement);

      expect(document.activeElement, document.body);

      document.body.append(testInputElement);
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.activeElement, testInputElement);

      // The input should refocus after blur.
      editingElement.domElement.blur();
      expect(document.activeElement, editingElement.domElement);

      editingElement.disable();
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.firefox));

    test('Does not dispose and recreate dom elements in persistent mode', () {
      editingElement =
          SemanticsTextEditingStrategy(HybridTextEditing(), testInputElement);

      // The DOM element should've been eagerly created.
      expect(testInputElement, isNotNull);
      // But doesn't have focus.
      expect(document.activeElement, document.body);

      // Can't enable before the input element is inserted into the DOM.
      expect(
        () => editingElement.enable(
          singlelineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        ),
        throwsAssertionError,
      );

      document.body.append(testInputElement);
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(document.activeElement, editingElement.domElement);
      // It doesn't create a new DOM element.
      expect(editingElement.domElement, testInputElement);

      editingElement.disable();
      // It doesn't remove the DOM element.
      expect(editingElement.domElement, testInputElement);
      expect(document.body.contains(editingElement.domElement), isTrue);
      // The textArea does not lose focus.
      // Even though this passes on manual tests it does not work on
      // Firefox automated unit tests.
      if (browserEngine != BrowserEngine.firefox) {
        expect(document.activeElement, editingElement.domElement);
      }
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('Refocuses when setting editing state', () {
      editingElement =
          SemanticsTextEditingStrategy(HybridTextEditing(), testInputElement);

      document.body.append(testInputElement);
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      // The input will have focus after editing state is set.
      editingElement.setEditingState(EditingState(text: 'foo'));
      expect(document.activeElement, testInputElement);

      editingElement.disable();
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('Works in multi-line mode', () {
      final TextAreaElement textarea = TextAreaElement();
      editingElement =
          SemanticsTextEditingStrategy(HybridTextEditing(), textarea);

      expect(editingElement.domElement, textarea);
      expect(document.activeElement, document.body);

      // Can't enable before the textarea is inserted into the DOM.
      expect(
        () => editingElement.enable(
          singlelineConfig,
          onChange: trackEditingState,
          onAction: trackInputAction,
        ),
        throwsAssertionError,
      );

      document.body.append(textarea);
      editingElement.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      // Focuses the textarea.
      expect(document.activeElement, textarea);

      textarea.blur();
      // The textArea does not lose focus.
      // Even though this passes on manual tests it does not work on
      // Firefox automated unit tests.
      if (browserEngine != BrowserEngine.firefox) {
        expect(document.activeElement, textarea);
      }

      editingElement.disable();
      // It doesn't remove the textarea from the DOM.
      expect(document.body.contains(editingElement.domElement), isTrue);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('Does not position or size its DOM element', () {
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      testTextEditing.setEditableSizeAndTransform(EditableTextGeometry(
        height: 12,
        width: 13,
        globalTransform: Matrix4.translationValues(14, 15, 0).storage,
      ));

      void checkPlacementIsEmpty() {
        expect(editingElement.domElement.style.transform, '');
        expect(editingElement.domElement.style.width, '');
        expect(editingElement.domElement.style.height, '');
      }

      checkPlacementIsEmpty();
      editingElement.placeElement();
      checkPlacementIsEmpty();
    });
  });

  group('$HybridTextEditing', () {
    HybridTextEditing textEditing;
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    int clientId = 0;

    /// Emulates sending of a message by the framework to the engine.
    void sendFrameworkMessage(dynamic message) {
      textEditing.channel.handleTextInput(message, (ByteData data) {});
    }

    /// Sends the necessary platform messages to activate a text field and show
    /// the keyboard.
    ///
    /// Returns the `clientId` used in the platform message.
    int showKeyboard(
        {String inputType, String inputAction, bool decimal = false}) {
      final MethodCall setClient = MethodCall(
        'TextInput.setClient',
        <dynamic>[
          ++clientId,
          createFlutterConfig(inputType,
              inputAction: inputAction, decimal: decimal),
        ],
      );
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      return clientId;
    }

    void hideKeyboard() {
      const MethodCall hide = MethodCall('TextInput.hide');
      sendFrameworkMessage(codec.encodeMethodCall(hide));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));
    }

    String getEditingInputMode() {
      return textEditing.editingElement.domElement.getAttribute('inputmode');
    }

    setUp(() {
      textEditing = HybridTextEditing();
      spy.setUp();
    });

    tearDown(() {
      spy.tearDown();
      if (textEditing.isEditing) {
        textEditing.stopEditing();
      }
      textEditing = null;
    });

    test('setClient, show, setEditingState, hide', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(textEditing.editingElement.domElement, '', 0, 0);

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      const MethodCall hide = MethodCall('TextInput.hide');
      sendFrameworkMessage(codec.encodeMethodCall(hide));

      // Text editing should've stopped.
      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('setClient, setEditingState, show, clearClient', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('do not close connection on blur', () async {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      // DOM element is blurred.
      textEditing.editingElement.domElement.blur();

      expect(spy.messages, hasLength(0));

      // DOM element still has focus.
      // Even though this passes on manual tests it does not work on
      // Firefox automated unit tests.
      if (browserEngine != BrowserEngine.firefox) {
        expect(document.activeElement, textEditing.editingElement.domElement);
      }
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('finishAutofillContext closes connection no autofill element',
        () async {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', false);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.onConnectionClosed');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[
          123, // Client ID
        ],
      );
      spy.messages.clear();
      // Input element is removed from DOM.
      expect(document.getElementsByTagName('input'), hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('finishAutofillContext removes form from DOM', () async {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig('text',
              autofillHint: 'username',
              autofillHintsForFields: [
            'username',
            'email',
            'name',
            'telephoneNumber'
          ]);
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterMultiAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // Form is added to DOM.
      expect(document.getElementsByTagName('form'), isNotEmpty);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(document.getElementsByTagName('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));

      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', false);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      // Form element is removed from DOM.
      expect(document.getElementsByTagName('form'), hasLength(0));
      expect(formsOnTheDom, hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('finishAutofillContext with save submits forms', () async {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig('text',
              autofillHint: 'username',
              autofillHintsForFields: [
            'username',
            'email',
            'name',
            'telephoneNumber'
          ]);
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterMultiAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // Form is added to DOM.
      expect(document.getElementsByTagName('form'), isNotEmpty);
      FormElement formElement = document.getElementsByTagName('form')[0];
      final Completer<bool> submittedForm = Completer<bool>();
      formElement.addEventListener(
          'submit', (event) => submittedForm.complete(true));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', true);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      // `submit` action is called on form.
      await expectLater(await submittedForm.future, true);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('forms submits for focused input', () async {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig('text',
              autofillHint: 'username',
              autofillHintsForFields: [
            'username',
            'email',
            'name',
            'telephoneNumber'
          ]);
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterMultiAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // Form is added to DOM.
      expect(document.getElementsByTagName('form'), isNotEmpty);
      FormElement formElement = document.getElementsByTagName('form')[0];
      final Completer<bool> submittedForm = Completer<bool>();
      formElement.addEventListener(
          'submit', (event) => submittedForm.complete(true));

      // Clear client is not called. The used requested context to be finalized.
      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', true);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      // Connection is closed by the engine.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.onConnectionClosed');

      // `submit` action is called on form.
      await expectLater(await submittedForm.future, true);
      // Form element is removed from DOM.
      expect(document.getElementsByTagName('form'), hasLength(0));
      expect(formsOnTheDom, hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: (browserEngine == BrowserEngine.webkit ||
            browserEngine == BrowserEngine.edge));

    test('setClient, setEditingState, show, setClient', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      final MethodCall setClient2 = MethodCall(
          'TextInput.setClient', <dynamic>[567, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient2));

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
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      const MethodCall setEditingState2 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': 0,
        'selectionExtent': 2,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState2));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 0, 2);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test(
        'singleTextField Autofill: setClient, setEditingState, show, '
        'setEditingState, clearClient', () {
      // Create a configuration with focused element has autofil hint.
      final Map<String, dynamic> flutterSingleAutofillElementConfig =
          createFlutterConfig('text', autofillHint: 'username');
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterSingleAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      final FormElement formElement = document.getElementsByTagName('form')[0];
      // The form has one input element and one submit button.
      expect(formElement.childNodes, hasLength(2));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(document.getElementsByTagName('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test(
        'multiTextField Autofill: setClient, setEditingState, show, '
        'setEditingState, clearClient', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig('text',
              autofillHint: 'username',
              autofillHintsForFields: [
            'username',
            'email',
            'name',
            'telephoneNumber'
          ]);
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterMultiAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      final FormElement formElement = document.getElementsByTagName('form')[0];
      // The form has 4 input elements and one submit button.
      expect(formElement.childNodes, hasLength(5));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(document.getElementsByTagName('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test('No capitilization: setClient, setEditingState, show', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> capitilizeWordsConfig = createFlutterConfig(
          'text',
          textCapitalization: 'TextCapitalization.none');
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, capitilizeWordsConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': '',
        'selectionBase': 0,
        'selectionExtent': 0,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));
      spy.messages.clear();

      // Test for mobile Safari. `sentences` is the default attribute for
      // mobile browsers. Check if `off` is added to the input element.
      if (browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs) {
        expect(
            textEditing.editingElement.domElement
                .getAttribute('autocapitalize'),
            'off');
      } else {
        expect(
            textEditing.editingElement.domElement
                .getAttribute('autocapitalize'),
            isNull);
      }

      spy.messages.clear();
      hideKeyboard();
    });

    test('All characters capitilization: setClient, setEditingState, show', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> capitilizeWordsConfig = createFlutterConfig(
          'text',
          textCapitalization: 'TextCapitalization.characters');
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, capitilizeWordsConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': '',
        'selectionBase': 0,
        'selectionExtent': 0,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));
      spy.messages.clear();

      // Test for mobile Safari.
      if (browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs) {
        expect(
            textEditing.editingElement.domElement
                .getAttribute('autocapitalize'),
            'characters');
      }

      spy.messages.clear();
      hideKeyboard();
    });

    test(
        'setClient, setEditableSizeAndTransform, setStyle, setEditingState, show, clearClient',
        () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      final MethodCall setStyle =
          configureSetStyleMethodCall(12, 'sans-serif', 4, 4, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

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
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test(
        'setClient, show, setEditableSizeAndTransform, setStyle, setEditingState, clearClient',
        () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(
              150,
              50,
              Matrix4.translationValues(
                10.0,
                20.0,
                30.0,
              ).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      final MethodCall setStyle =
          configureSetStyleMethodCall(12, 'sans-serif', 4, 4, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      final HtmlElement domElement = textEditing.editingElement.domElement;

      checkInputEditingState(domElement, 'abcd', 2, 3);

      // Check if the position is correct.
      expect(
        domElement.getBoundingClientRect(),
        Rectangle<double>.fromPoints(
            const Point<double>(10.0, 20.0), const Point<double>(160.0, 70.0)),
      );
      expect(
        domElement.style.transform,
        'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1)',
      );
      expect(
        textEditing.editingElement.domElement.style.font,
        '500 12px sans-serif',
      );

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test('input font set succesfully with null fontWeightIndex', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      final MethodCall setStyle = configureSetStyleMethodCall(
          12, 'sans-serif', 4, null /* fontWeightIndex */, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

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
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test(
        'negative base offset and selection extent values in editing state is handled',
        () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': 1,
        'selectionExtent': 2,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // Check if the selection range is correct.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 1, 2);

      const MethodCall setEditingState2 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': -1,
        'selectionExtent': -1,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState2));

      // The negative offset values are applied to the dom element as 0.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'xyz', 0, 0);

      hideKeyboard();
    });

    test('Syncs the editing state back to Flutter', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      final InputElement input = textEditing.editingElement.domElement;

      input.value = 'something';
      input.dispatchEvent(Event.eventType('Event', 'input'));

      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.updateEditingState');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something',
            'selectionBase': 9,
            'selectionExtent': 9
          }
        ],
      );
      spy.messages.clear();

      input.setSelectionRange(2, 5);
      if (browserEngine == BrowserEngine.firefox) {
        Event keyup = KeyboardEvent('keyup');
        textEditing.editingElement.domElement.dispatchEvent(keyup);
      } else {
        document.dispatchEvent(Event.eventType('Event', 'selectionchange'));
      }

      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.updateEditingState');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something',
            'selectionBase': 2,
            'selectionExtent': 5
          }
        ],
      );
      spy.messages.clear();

      hideKeyboard();
    });

    test('multiTextField Autofill sync updates back to Flutter', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final String hintForFirstElement = 'familyName';
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig('text',
              autofillHint: 'email',
              autofillHintsForFields: [
            hintForFirstElement,
            'email',
            'givenName',
            'telephoneNumber'
          ]);
      final MethodCall setClient = MethodCall('TextInput.setClient',
          <dynamic>[123, flutterMultiAutofillElementConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState1 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState1));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing.editingElement.domElement, 'abcd', 2, 3);

      final FormElement formElement = document.getElementsByTagName('form')[0];
      // The form has 4 input elements and one submit button.
      expect(formElement.childNodes, hasLength(5));

      // Autofill one of the form elements.
      InputElement element = formElement.childNodes.first;
      if (browserEngine == BrowserEngine.firefox) {
        expect(element.name,
            BrowserAutofillHints.instance.flutterToEngine(hintForFirstElement));
      } else {
        expect(element.autocomplete,
            BrowserAutofillHints.instance.flutterToEngine(hintForFirstElement));
      }
      element.value = 'something';
      element.dispatchEvent(Event.eventType('Event', 'input'));

      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName,
          'TextInputClient.updateEditingStateWithTag');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[
          0, // Client ID
          <String, dynamic>{
            hintForFirstElement: <String, dynamic>{
              'text': 'something',
              'selectionBase': 9,
              'selectionExtent': 9
            }
          },
        ],
      );

      spy.messages.clear();
      hideKeyboard();
    });

    test('Multi-line mode also works', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterMultilineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      final TextAreaElement textarea = textEditing.editingElement.domElement;
      checkTextAreaEditingState(textarea, '', 0, 0);

      // Can set editing state and preserve new lines.
      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'foo\nbar',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));
      checkTextAreaEditingState(textarea, 'foo\nbar', 2, 3);

      textarea.value = 'something\nelse';

      textarea.dispatchEvent(Event.eventType('Event', 'input'));
      textarea.setSelectionRange(2, 5);
      if (browserEngine == BrowserEngine.firefox) {
        textEditing.editingElement.domElement
            .dispatchEvent(KeyboardEvent('keyup'));
      } else {
        document.dispatchEvent(Event.eventType('Event', 'selectionchange'));
      }

      // Two messages should've been sent. One for the 'input' event and one for
      // the 'selectionchange' event.
      expect(spy.messages, hasLength(2));

      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.updateEditingState');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something\nelse',
            'selectionBase': 14,
            'selectionExtent': 14,
          }
        ],
      );

      expect(spy.messages[1].channel, 'flutter/textinput');
      expect(spy.messages[1].methodName, 'TextInputClient.updateEditingState');
      expect(
        spy.messages[1].methodArguments,
        <dynamic>[
          123, // Client ID
          <String, dynamic>{
            'text': 'something\nelse',
            'selectionBase': 2,
            'selectionExtent': 5,
          }
        ],
      );
      spy.messages.clear();

      const MethodCall hide = MethodCall('TextInput.hide');
      sendFrameworkMessage(codec.encodeMethodCall(hide));

      // Text editing should've stopped.
      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any more messages.
      expect(spy.messages, isEmpty);
    });

    test('sets correct input type in Android', () {
      debugOperatingSystemOverride = OperatingSystem.android;
      debugBrowserEngineOverride = BrowserEngine.blink;

      /// During initialization [HybridTextEditing] will pick the correct
      /// text editing strategy for [OperatingSystem.android].
      textEditing = HybridTextEditing();

      showKeyboard(inputType: 'text');
      expect(getEditingInputMode(), 'text');

      showKeyboard(inputType: 'number');
      expect(getEditingInputMode(), 'numeric');

      showKeyboard(inputType: 'number', decimal: false);
      expect(getEditingInputMode(), 'numeric');

      showKeyboard(inputType: 'number', decimal: true);
      expect(getEditingInputMode(), 'decimal');

      showKeyboard(inputType: 'phone');
      expect(getEditingInputMode(), 'tel');

      showKeyboard(inputType: 'emailAddress');
      expect(getEditingInputMode(), 'email');

      showKeyboard(inputType: 'url');
      expect(getEditingInputMode(), 'url');

      hideKeyboard();
    });

    test('sets correct input type in iOS', () {
      // Test on ios-safari only.
      if (browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs) {
        /// During initialization [HybridTextEditing] will pick the correct
        /// text editing strategy for [OperatingSystem.iOs].
        textEditing = HybridTextEditing();

        showKeyboard(inputType: 'text');
        expect(getEditingInputMode(), 'text');

        showKeyboard(inputType: 'number');
        expect(getEditingInputMode(), 'numeric');

        showKeyboard(inputType: 'number', decimal: false);
        expect(getEditingInputMode(), 'numeric');

        showKeyboard(inputType: 'number', decimal: true);
        expect(getEditingInputMode(), 'decimal');

        showKeyboard(inputType: 'phone');
        expect(getEditingInputMode(), 'tel');

        showKeyboard(inputType: 'emailAddress');
        expect(getEditingInputMode(), 'email');

        showKeyboard(inputType: 'url');
        expect(getEditingInputMode(), 'url');

        hideKeyboard();
      }
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
      expect(spy.messages[0].channel, 'flutter/textinput');
      expect(spy.messages[0].methodName, 'TextInputClient.performAction');
      expect(
        spy.messages[0].methodArguments,
        <dynamic>[clientId, 'TextInputAction.next'],
      );
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

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

    tearDown(() {
      clearForms();
    });
  });

  group('EngineAutofillForm', () {
    test('validate multi element form', () {
      final List<dynamic> fields = createFieldValues(
          ['username', 'password', 'newPassword'],
          ['field1', 'field2', 'field3']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields);

      // Number of elements if number of fields sent to the constructor minus
      // one (for the focused text element).
      expect(autofillForm.elements, hasLength(2));
      expect(autofillForm.items, hasLength(2));
      expect(autofillForm.formElement, isNotNull);

      expect(autofillForm.formIdentifier, 'field1*field2*field3');

      final FormElement form = autofillForm.formElement;
      // Note that we also add a submit button. Therefore the form element has
      // 3 child nodes.
      expect(form.childNodes, hasLength(3));

      final InputElement firstElement = form.childNodes.first;
      // Autofill value is applied to the element.
      expect(firstElement.name,
          BrowserAutofillHints.instance.flutterToEngine('password'));
      expect(firstElement.id, BrowserAutofillHints.instance.flutterToEngine('password'));
      expect(firstElement.type, 'password');
      if (browserEngine == BrowserEngine.firefox) {
        expect(firstElement.name,
            BrowserAutofillHints.instance.flutterToEngine('password'));
      } else {
        expect(firstElement.autocomplete,
            BrowserAutofillHints.instance.flutterToEngine('password'));
      }

      // Editing state is applied to the element.
      expect(firstElement.value, 'Test');
      expect(firstElement.selectionStart, 0);
      expect(firstElement.selectionEnd, 0);

      // Element is hidden.
      final CssStyleDeclaration css = firstElement.style;
      expect(css.color, 'transparent');
      expect(css.backgroundColor, 'transparent');
    });

    test('validate multi element form ids sorted for form id', () {
      final List<dynamic> fields = createFieldValues(
          ['username', 'password', 'newPassword'],
          ['zzyyxx', 'aabbcc', 'jjkkll']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields);


      expect(autofillForm.formIdentifier, 'aabbcc*jjkkll*zzyyxx');
    });

    test('place and store form', () {
      expect(document.getElementsByTagName('form'), isEmpty);

      final List<dynamic> fields = createFieldValues(
          ['username', 'password', 'newPassword'],
          ['field1', 'fields2', 'field3']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields);

      final InputElement testInputElement = InputElement();
      autofillForm.placeForm(testInputElement);

      // The focused element is appended to the form, form also has the button
      // so in total it shoould have 4 elements.
      final FormElement form = autofillForm.formElement;
      expect(form.childNodes, hasLength(4));

      final FormElement formOnDom = document.getElementsByTagName('form')[0];
      // Form is attached to the DOM.
      expect(form, equals(formOnDom));

      autofillForm.storeForm();
      expect(document.getElementsByTagName('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test('Validate single element form', () {
      final List<dynamic> fields = createFieldValues(['username'], ['field1']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields);

      // The focused element is the only field. Form should be empty after
      // the initialization (focus element is appended later).
      expect(autofillForm.elements, isEmpty);
      expect(autofillForm.items, isEmpty);
      expect(autofillForm.formElement, isNotNull);

      final FormElement form = autofillForm.formElement;
      // Submit button is added to the form.
      expect(form.childNodes, isNotEmpty);
      final InputElement inputElement = form.childNodes.first;
      expect(inputElement.type, 'submit');

      // The submit button should have class `submitBtn`.
      expect(inputElement.className, 'submitBtn');
    });

    test('Return null if no focused element', () {
      final List<dynamic> fields = createFieldValues(['username'], ['field1']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(null, fields);

      expect(autofillForm, isNull);
    });

    tearDown(() {
      clearForms();
    });
  });

  group('AutofillInfo', () {
    const String testHint = 'streetAddressLine2';
    const String testId = 'EditableText-659836579';
    const String testPasswordHint = 'password';

    test('autofill has correct value', () {
      final AutofillInfo autofillInfo = AutofillInfo.fromFrameworkMessage(
          createAutofillInfo(testHint, testId));

      // Hint sent from the framework is converted to the hint compatible with
      // browsers.
      expect(autofillInfo.hint,
          BrowserAutofillHints.instance.flutterToEngine(testHint));
      expect(autofillInfo.uniqueIdentifier, testId);
    });

    test('input with autofill hint', () {
      final AutofillInfo autofillInfo = AutofillInfo.fromFrameworkMessage(
          createAutofillInfo(testHint, testId));

      final InputElement testInputElement = InputElement();
      autofillInfo.applyToDomElement(testInputElement);

      // Hint sent from the framework is converted to the hint compatible with
      // browsers.
      expect(testInputElement.name,
          BrowserAutofillHints.instance.flutterToEngine(testHint));
      expect(testInputElement.id,
          BrowserAutofillHints.instance.flutterToEngine(testHint));
      expect(testInputElement.type, 'text');
      if (browserEngine == BrowserEngine.firefox) {
        expect(testInputElement.name,
            BrowserAutofillHints.instance.flutterToEngine(testHint));
      } else {
        expect(testInputElement.autocomplete,
            BrowserAutofillHints.instance.flutterToEngine(testHint));
      }
    });

    test('textarea with autofill hint', () {
      final AutofillInfo autofillInfo = AutofillInfo.fromFrameworkMessage(
          createAutofillInfo(testHint, testId));

      final TextAreaElement testInputElement = TextAreaElement();
      autofillInfo.applyToDomElement(testInputElement);

      // Hint sent from the framework is converted to the hint compatible with
      // browsers.
      expect(testInputElement.name,
          BrowserAutofillHints.instance.flutterToEngine(testHint));
      expect(testInputElement.id,
          BrowserAutofillHints.instance.flutterToEngine(testHint));
      expect(testInputElement.getAttribute('autocomplete'),
          BrowserAutofillHints.instance.flutterToEngine(testHint));
    });

    test('password autofill hint', () {
      final AutofillInfo autofillInfo = AutofillInfo.fromFrameworkMessage(
          createAutofillInfo(testPasswordHint, testId));

      final InputElement testInputElement = InputElement();
      autofillInfo.applyToDomElement(testInputElement);

      // Hint sent from the framework is converted to the hint compatible with
      // browsers.
      expect(testInputElement.name,
          BrowserAutofillHints.instance.flutterToEngine(testPasswordHint));
      expect(testInputElement.id,
          BrowserAutofillHints.instance.flutterToEngine(testPasswordHint));
      expect(testInputElement.type, 'password');
      expect(testInputElement.getAttribute('autocomplete'),
          BrowserAutofillHints.instance.flutterToEngine(testPasswordHint));
    });
  });

  group('EditingState', () {
    EditingState _editingState;

    setUp(() {
      editingElement =
          GloballyPositionedTextEditingStrategy(HybridTextEditing());
      editingElement.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
    });

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
      cleanTextEditingElement();
      editingElement.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

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
      cleanTextEditingElement();
      editingElement.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

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

/// Will disable editing element which will also clean the backup DOM
/// element from the page.
void cleanTextEditingElement() {
  if (editingElement != null && editingElement.isEnabled) {
    // Clean up all the DOM elements and event listeners.
    editingElement.disable();
  }
}

void cleanTestFlags() {
  debugBrowserEngineOverride = null;
  debugOperatingSystemOverride = null;
}

void checkInputEditingState(
    InputElement input, String text, int start, int end) {
  expect(document.activeElement, input);
  expect(input.value, text);
  expect(input.selectionStart, start);
  expect(input.selectionEnd, end);
}

/// In case of an exception backup DOM element(s) can still stay on the DOM.
void clearBackUpDomElementIfExists() {
  List<Node> domElementsToRemove = List<Node>();
  if (document.getElementsByTagName('input').length > 0) {
    domElementsToRemove..addAll(document.getElementsByTagName('input'));
  }
  if (document.getElementsByTagName('textarea').length > 0) {
    domElementsToRemove..addAll(document.getElementsByTagName('textarea'));
  }
  domElementsToRemove.forEach((Node n) => n.remove());
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

/// Creates an [InputConfiguration] for using in the tests.
///
/// For simplicity this method is using `autofillHint` as the `uniqueId` for
/// simplicity.
Map<String, dynamic> createFlutterConfig(
  String inputType, {
  bool obscureText = false,
  bool autocorrect = true,
  String textCapitalization = 'TextCapitalization.none',
  String inputAction,
  String autofillHint,
  List<String> autofillHintsForFields,
  bool decimal = false,
}) {
  return <String, dynamic>{
    'inputType': <String, dynamic>{
      'name': 'TextInputType.$inputType',
      if (decimal) 'decimal': true,
    },
    'obscureText': obscureText,
    'autocorrect': autocorrect,
    'inputAction': inputAction ?? 'TextInputAction.done',
    'textCapitalization': textCapitalization,
    if (autofillHint != null)
      'autofill': createAutofillInfo(autofillHint, autofillHint),
    if (autofillHintsForFields != null)
      'fields':
          createFieldValues(autofillHintsForFields, autofillHintsForFields),
  };
}

Map<String, dynamic> createAutofillInfo(String hint, String uniqueId) =>
    <String, dynamic>{
      'uniqueIdentifier': uniqueId,
      'hints': [hint],
      'editingValue': {
        'text': 'Test',
        'selectionBase': 0,
        'selectionExtent': 0,
        'selectionAffinity': 'TextAffinity.downstream',
        'selectionIsDirectional': false,
        'composingBase': -1,
        'composingExtent': -1,
      },
    };

List<dynamic> createFieldValues(List<String> hints, List<String> uniqueIds) {
  final List<dynamic> testFields = <dynamic>[];

  expect(hints.length, equals(uniqueIds.length));

  for (int i = 0; i < hints.length; i++) {
    testFields.add(createOneFieldValue(hints[i], uniqueIds[i]));
  }

  return testFields;
}

Map<String, dynamic> createOneFieldValue(String hint, String uniqueId) =>
    <String, dynamic>{
      'inputType': {
        'name': 'TextInputType.text',
        'signed': null,
        'decimal': null
      },
      'textCapitalization': 'TextCapitalization.none',
      'autofill': createAutofillInfo(hint, uniqueId)
    };

/// In order to not leak test state, clean up the forms from dom if any remains.
void clearForms() {
  while (document.getElementsByTagName('form').length > 0) {
    document.getElementsByTagName('form').last.remove();
  }
  formsOnTheDom.clear();
}
