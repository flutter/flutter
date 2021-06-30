// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart' show domRenderer;
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/src/engine/services.dart';
import 'package:ui/src/engine/text_editing/autofill_hint.dart';
import 'package:ui/src/engine/text_editing/input_type.dart';
import 'package:ui/src/engine/text_editing/text_editing.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/src/engine/vector_math.dart';

import 'spy.dart';

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

const MethodCodec codec = JSONMethodCodec();

/// Add unit tests for [FirefoxTextEditingStrategy].
/// TODO(nurhan): https://github.com/flutter/flutter/issues/46891

DefaultTextEditingStrategy? editingStrategy;
EditingState? lastEditingState;
String? lastInputAction;

final InputConfiguration singlelineConfig = InputConfiguration(
  inputType: EngineInputType.text,
);
final Map<String, dynamic> flutterSinglelineConfig =
    createFlutterConfig('text');

final InputConfiguration multilineConfig = InputConfiguration(
  inputType: EngineInputType.multiline,
  inputAction: 'TextInputAction.newline',
);
final Map<String, dynamic> flutterMultilineConfig =
    createFlutterConfig('multiline');

void trackEditingState(EditingState? editingState) {
  lastEditingState = editingState;
}

void trackInputAction(String? inputAction) {
  lastInputAction = inputAction;
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  tearDown(() {
    lastEditingState = null;
    lastInputAction = null;
    cleanTextEditingStrategy();
    cleanTestFlags();
    clearBackUpDomElementIfExists();
  });

  group('$GloballyPositionedTextEditingStrategy', () {
    late HybridTextEditing testTextEditing;

    setUp(() {
      testTextEditing = HybridTextEditing();
      editingStrategy = GloballyPositionedTextEditingStrategy(testTextEditing);
      testTextEditing.debugTextEditingStrategyOverride = editingStrategy;
      testTextEditing.configuration = singlelineConfig;
      // Ensure the glass-pane and its shadow root exist.
      domRenderer.reset();
    });

    test('Creates element when enabled and removes it when disabled', () {
      expect(
        document.getElementsByTagName('input'),
        hasLength(0),
      );
      // The focus initially is on the body.
      expect(document.activeElement, document.body);
      expect(defaultTextEditingRoot.activeElement, null);

      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      expect(
        defaultTextEditingRoot.querySelectorAll('input'),
        hasLength(1),
      );
      final Element input = defaultTextEditingRoot.querySelector('input')!;
      // Now the editing element should have focus.

      expect(document.activeElement, domRenderer.glassPaneElement);
      expect(defaultTextEditingRoot.activeElement, input);

      expect(editingStrategy!.domElement, input);
      expect(input.getAttribute('type'), null);

      // Input is appended to the right point of the DOM.
      expect(defaultTextEditingRoot.contains(editingStrategy!.domElement), isTrue);

      editingStrategy!.disable();
      expect(
        defaultTextEditingRoot.querySelectorAll('input'),
        hasLength(0),
      );
      // The focus is back to the body.
      expect(document.activeElement, document.body);
      expect(defaultTextEditingRoot.activeElement, null);
    });

    test('Respects read-only config', () {
      final InputConfiguration config = InputConfiguration(
        readOnly: true,
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(1));
      final Element input = defaultTextEditingRoot.querySelector('input')!;
      expect(editingStrategy!.domElement, input);
      expect(input.getAttribute('readonly'), 'readonly');

      editingStrategy!.disable();
    });

    test('Knows how to create password fields', () {
      final InputConfiguration config = InputConfiguration(
        obscureText: true,
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(1));
      final Element input = defaultTextEditingRoot.querySelector('input')!;
      expect(editingStrategy!.domElement, input);
      expect(input.getAttribute('type'), 'password');

      editingStrategy!.disable();
    });

    test('Knows to turn autocorrect off', () {
      final InputConfiguration config = InputConfiguration(
        autocorrect: false,
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(1));
      final Element input = defaultTextEditingRoot.querySelector('input')!;
      expect(editingStrategy!.domElement, input);
      expect(input.getAttribute('autocorrect'), 'off');

      editingStrategy!.disable();
    });

    test('Knows to turn autocorrect on', () {
      final InputConfiguration config = InputConfiguration(
        autocorrect: true,
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(1));
      final Element input = defaultTextEditingRoot.querySelector('input')!;
      expect(editingStrategy!.domElement, input);
      expect(input.getAttribute('autocorrect'), 'on');

      editingStrategy!.disable();
    });

    test('Can read editing state correctly', () {
      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      final InputElement input = editingStrategy!.domElement as InputElement;
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
      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      editingStrategy!.setEditingState(
          EditingState(text: 'foo bar baz', baseOffset: 2, extentOffset: 7));

      checkInputEditingState(editingStrategy!.domElement!, 'foo bar baz', 2, 7);

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Multi-line mode also works', () {
      // The textarea element is created lazily.
      expect(document.getElementsByTagName('textarea'), hasLength(0));
      editingStrategy!.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(1));

      final TextAreaElement textarea =
          defaultTextEditingRoot.querySelector('textarea') as TextAreaElement;
      // Now the textarea should have focus.
      expect(defaultTextEditingRoot.activeElement, textarea);
      expect(editingStrategy!.domElement, textarea);

      textarea.value = 'foo\nbar';
      textarea.dispatchEvent(Event.eventType('Event', 'input'));
      textarea.setSelectionRange(4, 6);
      document.dispatchEvent(Event.eventType('Event', 'selectionchange'));
      // Can read textarea state correctly (and preserves new lines).
      expect(
        lastEditingState,
        EditingState(text: 'foo\nbar', baseOffset: 4, extentOffset: 6),
      );

      // Can set textarea state correctly (and preserves new lines).
      editingStrategy!.setEditingState(
          EditingState(text: 'bar\nbaz', baseOffset: 2, extentOffset: 7));
      checkTextAreaEditingState(textarea, 'bar\nbaz', 2, 7);

      editingStrategy!.disable();
      // The textarea should be cleaned up.
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(0));
      // The focus is back to the body.
      expect(defaultTextEditingRoot.activeElement, null);

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Same instance can be re-enabled with different config', () {
      // Make sure there's nothing in the DOM yet.
      expect(document.getElementsByTagName('input'), hasLength(0));
      expect(document.getElementsByTagName('textarea'), hasLength(0));

      // Use single-line config and expect an `<input>` to be created.
      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(1));
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(0));

      // Disable and check that all DOM elements were removed.
      editingStrategy!.disable();
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(0));
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(0));

      // Use multi-line config and expect an `<textarea>` to be created.
      editingStrategy!.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(0));
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(1));

      // Disable again and check that all DOM elements were removed.
      editingStrategy!.disable();
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(0));
      expect(defaultTextEditingRoot.querySelectorAll('textarea'), hasLength(0));

      // There should be no input action.
      expect(lastInputAction, isNull);
    });

    test('Triggers input action', () {
      final InputConfiguration config = InputConfiguration(
        inputAction: 'TextInputAction.done',
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      // No input action so far.
      expect(lastInputAction, isNull);

      dispatchKeyboardEvent(
        editingStrategy!.domElement!,
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
        inputAction: 'TextInputAction.done',
      );
      editingStrategy!.enable(
        config,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      // No input action so far.
      expect(lastInputAction, isNull);

      final KeyboardEvent event = dispatchKeyboardEvent(
        editingStrategy!.domElement!,
        'keydown',
        keyCode: _kReturnKeyCode,
      );

      // Still no input action.
      expect(lastInputAction, isNull);
      // And default behavior of keyboard event shouldn't have been prevented.
      expect(event.defaultPrevented, isFalse);
    });

    test('globally positions and sizes its DOM element', () {
      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
      expect(editingStrategy!.isEnabled, isTrue);

      // No geometry should be set until setEditableSizeAndTransform is called.
      expect(editingStrategy!.domElement!.style.transform, '');
      expect(editingStrategy!.domElement!.style.width, '');
      expect(editingStrategy!.domElement!.style.height, '');

      testTextEditing.acceptCommand(TextInputSetEditableSizeAndTransform(geometry: EditableTextGeometry(
        width: 13,
        height: 12,
        globalTransform: Matrix4.translationValues(14, 15, 0).storage,
      )), () {});

      // setEditableSizeAndTransform calls placeElement, so expecting geometry to be applied.
      expect(editingStrategy!.domElement!.style.transform,
          'matrix(1, 0, 0, 1, 14, 15)');
      expect(editingStrategy!.domElement!.style.width, '13px');
      expect(editingStrategy!.domElement!.style.height, '12px');
    });
  });

  group('$HybridTextEditing', () {
    HybridTextEditing? textEditing;
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    int clientId = 0;

    /// Emulates sending of a message by the framework to the engine.
    void sendFrameworkMessage(dynamic message) {
      textEditing!.channel.handleTextInput(message, (ByteData? data) {});
    }

    /// Sends the necessary platform messages to activate a text field and show
    /// the keyboard.
    ///
    /// Returns the `clientId` used in the platform message.
    int showKeyboard({
      required String inputType,
      String? inputAction,
      bool decimal = false,
    }) {
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
      return textEditing!.strategy.domElement!.getAttribute('inputmode')!;
    }

    setUp(() {
      textEditing = HybridTextEditing();
      spy.setUp();
    });

    tearDown(() {
      spy.tearDown();
      if (textEditing!.isEditing) {
        textEditing!.stopEditing();
      }
      textEditing = null;
    });

    test('TextInput.requestAutofill', () async {
      final MethodCall requestAutofill = MethodCall('TextInput.requestAutofill');
      sendFrameworkMessage(codec.encodeMethodCall(requestAutofill));

      //No-op and without crashing.
    });

    test('setClient, show, setEditingState, hide', () {
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, flutterSinglelineConfig]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      // Editing shouldn't have started yet.
      expect(document.activeElement, document.body);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(textEditing!.strategy.domElement, '', 0, 0);

      const MethodCall setEditingState =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'abcd',
        'selectionBase': 2,
        'selectionExtent': 3,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

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
          textEditing!.strategy.domElement, 'abcd', 2, 3);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      expect(document.activeElement, document.body);

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('setClient, setEditingState, show, updateConfig, clearClient', () {
      final MethodCall setClient = MethodCall('TextInput.setClient', <dynamic>[
        123,
        createFlutterConfig('text', readOnly: true),
      ]);
      sendFrameworkMessage(codec.encodeMethodCall(setClient));

      const MethodCall setEditingState = MethodCall(
        'TextInput.setEditingState',
        <String, dynamic>{
          'text': 'abcd',
          'selectionBase': 2,
          'selectionExtent': 3,
        },
      );
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState));

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      final Element element = textEditing!.strategy.domElement!;
      expect(element.getAttribute('readonly'), 'readonly');

      // Update the read-only config.
      final MethodCall updateConfig = MethodCall(
        'TextInput.updateConfig',
        createFlutterConfig('text', readOnly: false),
      );
      sendFrameworkMessage(codec.encodeMethodCall(updateConfig));

      expect(element.hasAttribute('readonly'), isFalse);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test('focus and connection with blur', () async {
      // In all the desktop browsers we are keeping the connection
      // open, keep the text editing element focused if it receives a blur
      // event.
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
      expect(defaultTextEditingRoot.activeElement, null);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);
      expect(textEditing!.isEditing, isTrue);

      // DOM element is blurred.
      textEditing!.strategy.domElement!.blur();

      // For ios-safari the connection is closed.
      if (browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs) {
        expect(spy.messages, hasLength(1));
        expect(spy.messages[0].channel, 'flutter/textinput');
        expect(
            spy.messages[0].methodName, 'TextInputClient.onConnectionClosed');
        await Future<void>.delayed(Duration.zero);
        // DOM element loses the focus.
        expect(defaultTextEditingRoot.activeElement, null);
      } else {
        // No connection close message sent.
        expect(spy.messages, hasLength(0));
        await Future<void>.delayed(Duration.zero);
        // DOM element still keeps the focus.
        expect(defaultTextEditingRoot.activeElement,
            textEditing!.strategy.domElement);
      }
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

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
      expect(defaultTextEditingRoot.activeElement, null);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

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
      expect(defaultTextEditingRoot.querySelectorAll('input'), hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

    test('finishAutofillContext removes form from DOM', () async {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> flutterMultiAutofillElementConfig =
          createFlutterConfig(
            'text',
            autofillHint: 'username',
            autofillHintsForFields: [
              'username',
              'email',
              'name',
              'telephoneNumber'
            ],
          );
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

      // The transform is changed. For example after a validation error, red
      // line appeared under the input field.
      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // Form is added to DOM.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));

      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', false);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      // Form element is removed from DOM.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isEmpty);
      expect(formsOnTheDom, hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

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

      // The transform is changed. For example after a validation error, red
      // line appeared under the input field.
      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // Form is added to DOM.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      FormElement formElement = defaultTextEditingRoot.querySelector('form') as FormElement;
      final Completer<bool> submittedForm = Completer<bool>();
      formElement.addEventListener(
          'submit', (event) => submittedForm.complete(true));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      const MethodCall finishAutofillContext =
          MethodCall('TextInput.finishAutofillContext', true);
      sendFrameworkMessage(codec.encodeMethodCall(finishAutofillContext));

      // `submit` action is called on form.
      await expectLater(await submittedForm.future, isTrue);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

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

      // The transform is changed. For example after a validation error, red
      // line appeared under the input field.
      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // Form is added to DOM.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      FormElement formElement = defaultTextEditingRoot.querySelector('form') as FormElement;
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
      await expectLater(await submittedForm.future, isTrue);
      // Form element is removed from DOM.
      expect(defaultTextEditingRoot.querySelectorAll('form'), hasLength(0));
      expect(formsOnTheDom, hasLength(0));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50769
        skip: browserEngine == BrowserEngine.edge);

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
          textEditing!.strategy.domElement, 'abcd', 2, 3);

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
          textEditing!.strategy.domElement, 'xyz', 0, 2);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
    });

    test(
        'singleTextField Autofill: setClient, setEditingState, show, '
        'setSizeAndTransform, setEditingState, clearClient', () {
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

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

      final FormElement formElement = defaultTextEditingRoot.querySelector('form') as FormElement;
      // The form has one input element and one submit button.
      expect(formElement.childNodes, hasLength(2));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test(
        'singleTextField Autofill setEditableSizeAndTransform preserves'
        'editing state', () {
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

      final InputElement inputElement =
          textEditing!.strategy.domElement as InputElement;
      expect(inputElement.value, 'abcd');
      if (!(browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.macOs)) {
        // In Safari Desktop Autofill menu appears as soon as an element is
        // focused, therefore the input element is only focused after the
        // location is received.
        expect(defaultTextEditingRoot.activeElement, inputElement);
        expect(inputElement.selectionStart, 2);
        expect(inputElement.selectionEnd, 3);
      }

      // The transform is changed. For example after a validation error, red
      // line appeared under the input field.
      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // Check the element still has focus. User can keep editing.
      expect(defaultTextEditingRoot.activeElement,
          textEditing!.strategy.domElement);

      // Check the cursor location is the same.
      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test(
        'multiTextField Autofill: setClient, setEditingState, show, '
        'setSizeAndTransform setEditingState, clearClient', () {
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

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

      final FormElement formElement = defaultTextEditingRoot.querySelector('form') as FormElement;
      // The form has 4 input elements and one submit button.
      expect(formElement.childNodes, hasLength(5));

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));

      // Confirm that [HybridTextEditing] didn't send any messages.
      expect(spy.messages, isEmpty);
      // Form stays on the DOM until autofill context is finalized.
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test('No capitalization: setClient, setEditingState, show', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> capitalizeWordsConfig = createFlutterConfig(
          'text',
          textCapitalization: 'TextCapitalization.none');
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, capitalizeWordsConfig]);
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
            textEditing!.strategy.domElement!
                .getAttribute('autocapitalize'),
            'off');
      } else {
        expect(
            textEditing!.strategy.domElement!
                .getAttribute('autocapitalize'),
            isNull);
      }

      spy.messages.clear();
      hideKeyboard();
    });

    test('All characters capitalization: setClient, setEditingState, show', () {
      // Create a configuration with an AutofillGroup of four text fields.
      final Map<String, dynamic> capitalizeWordsConfig = createFlutterConfig(
          'text',
          textCapitalization: 'TextCapitalization.characters');
      final MethodCall setClient = MethodCall(
          'TextInput.setClient', <dynamic>[123, capitalizeWordsConfig]);
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
            textEditing!.strategy.domElement!
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

      final Element domElement = textEditing!.strategy.domElement!;

      checkInputEditingState(domElement, 'abcd', 2, 3);

      // Check if the location and styling is correct.
      expect(
          domElement.getBoundingClientRect(),
          Rectangle<double>.fromPoints(const Point<double>(10.0, 20.0),
              const Point<double>(160.0, 70.0)));
      expect(domElement.style.transform,
          'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1)');
      expect(textEditing!.strategy.domElement!.style.font,
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

      final HtmlElement domElement = textEditing!.strategy.domElement!;

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
        textEditing!.strategy.domElement!.style.font,
        '500 12px sans-serif',
      );

      // For `blink` and `webkit` browser engines the overlay would be hidden.
      if (browserEngine == BrowserEngine.blink ||
          browserEngine == BrowserEngine.samsung ||
          browserEngine == BrowserEngine.webkit) {
        expect(textEditing!.strategy.domElement!.classes,
            contains('transparentTextEditing'));
      } else {
        expect(
            textEditing!.strategy.domElement!.classes.any(
                (element) => element.toString() == 'transparentTextEditing'),
            isFalse);
      }

      const MethodCall clearClient = MethodCall('TextInput.clearClient');
      sendFrameworkMessage(codec.encodeMethodCall(clearClient));
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test('input font set successfully with null fontWeightIndex', () {
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

      final HtmlElement domElement = textEditing!.strategy.domElement!;

      checkInputEditingState(domElement, 'abcd', 2, 3);

      // Check if the location and styling is correct.
      expect(
          domElement.getBoundingClientRect(),
          Rectangle<double>.fromPoints(const Point<double>(10.0, 20.0),
              const Point<double>(160.0, 70.0)));
      expect(domElement.style.transform,
          'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1)');
      expect(
          textEditing!.strategy.domElement!.style.font, '12px sans-serif');

      hideKeyboard();
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test('Canonicalizes font family', () {
      showKeyboard(inputType: 'text');

      final HtmlElement input = textEditing!.strategy.domElement!;

      MethodCall setStyle;

      setStyle = configureSetStyleMethodCall(12, 'sans-serif', 4, 4, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));
      expect(input.style.fontFamily, canonicalizeFontFamily('sans-serif'));

      setStyle = configureSetStyleMethodCall(12, '.SF Pro Text', 4, 4, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));
      expect(input.style.fontFamily, canonicalizeFontFamily('.SF Pro Text'));

      setStyle = configureSetStyleMethodCall(12, 'foo bar baz', 4, 4, 1);
      sendFrameworkMessage(codec.encodeMethodCall(setStyle));
      expect(input.style.fontFamily, canonicalizeFontFamily('foo bar baz'));

      hideKeyboard();
    });

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
          textEditing!.strategy.domElement, 'xyz', 1, 2);

      const MethodCall setEditingState2 =
          MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'xyz',
        'selectionBase': -1,
        'selectionExtent': -1,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState2));

      // The negative offset values are applied to the dom element as 0.
      checkInputEditingState(
          textEditing!.strategy.domElement, 'xyz', 0, 0);

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

      final InputElement input = textEditing!.strategy.domElement as InputElement;

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
        textEditing!.strategy.domElement!.dispatchEvent(keyup);
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

      final MethodCall setSizeAndTransform =
          configureSetSizeAndTransformMethodCall(150, 50,
              Matrix4.translationValues(10.0, 20.0, 30.0).storage.toList());
      sendFrameworkMessage(codec.encodeMethodCall(setSizeAndTransform));

      // The second [setEditingState] should override the first one.
      checkInputEditingState(
          textEditing!.strategy.domElement, 'abcd', 2, 3);

      final FormElement formElement = defaultTextEditingRoot.querySelector('form') as FormElement;
      // The form has 4 input elements and one submit button.
      expect(formElement.childNodes, hasLength(5));

      // Autofill one of the form elements.
      InputElement element = formElement.childNodes.first as InputElement;
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
      expect(defaultTextEditingRoot.activeElement, null);

      const MethodCall show = MethodCall('TextInput.show');
      sendFrameworkMessage(codec.encodeMethodCall(show));

      final TextAreaElement textarea = textEditing!.strategy.domElement as TextAreaElement;
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
        textEditing!.strategy.domElement!
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

      showKeyboard(inputType: 'none');
      expect(getEditingInputMode(), 'none');

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

        showKeyboard(inputType: 'none');
        expect(getEditingInputMode(), 'none');

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
        textEditing!.strategy.domElement!,
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
        textEditing!.strategy.domElement!,
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
              createAutofillInfo('username', 'field1'), fields)!;

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

      final InputElement firstElement = form.childNodes.first as InputElement;
      // Autofill value is applied to the element.
      expect(firstElement.name,
          BrowserAutofillHints.instance.flutterToEngine('password'));
      expect(firstElement.id,
          BrowserAutofillHints.instance.flutterToEngine('password'));
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

      // For `blink` and `webkit` browser engines the overlay would be hidden.
      if (browserEngine == BrowserEngine.blink ||
          browserEngine == BrowserEngine.samsung ||
          browserEngine == BrowserEngine.webkit) {
        expect(firstElement.classes, contains('transparentTextEditing'));
      } else {
        expect(
            firstElement.classes.any(
                (element) => element.toString() == 'transparentTextEditing'),
            isFalse);
      }
    });

    test('validate multi element form ids sorted for form id', () {
      final List<dynamic> fields = createFieldValues(
          ['username', 'password', 'newPassword'],
          ['zzyyxx', 'aabbcc', 'jjkkll']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields)!;

      expect(autofillForm.formIdentifier, 'aabbcc*jjkkll*zzyyxx');
    });

    test('place and store form', () {
      expect(defaultTextEditingRoot.querySelectorAll('form'), isEmpty);

      final List<dynamic> fields = createFieldValues(
          ['username', 'password', 'newPassword'],
          ['field1', 'fields2', 'field3']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields)!;

      final InputElement testInputElement = InputElement();
      autofillForm.placeForm(testInputElement);

      // The focused element is appended to the form, form also has the button
      // so in total it shoould have 4 elements.
      final FormElement form = autofillForm.formElement;
      expect(form.childNodes, hasLength(4));

      final FormElement formOnDom = defaultTextEditingRoot.querySelector('form') as FormElement;
      // Form is attached to the DOM.
      expect(form, equals(formOnDom));

      autofillForm.storeForm();
      expect(defaultTextEditingRoot.querySelectorAll('form'), isNotEmpty);
      expect(formsOnTheDom, hasLength(1));
    });

    test('Validate single element form', () {
      final List<dynamic> fields = createFieldValues(['username'], ['field1']);
      final EngineAutofillForm autofillForm =
          EngineAutofillForm.fromFrameworkMessage(
              createAutofillInfo('username', 'field1'), fields)!;

      // The focused element is the only field. Form should be empty after
      // the initialization (focus element is appended later).
      expect(autofillForm.elements, isEmpty);
      expect(autofillForm.items, isEmpty);
      expect(autofillForm.formElement, isNotNull);

      final FormElement form = autofillForm.formElement;
      // Submit button is added to the form.
      expect(form.childNodes, isNotEmpty);
      final InputElement inputElement = form.childNodes.first as InputElement;
      expect(inputElement.type, 'submit');

      // The submit button should have class `submitBtn`.
      expect(inputElement.className, 'submitBtn');
    });

    test('Return null if no focused element', () {
      final List<dynamic> fields = createFieldValues(['username'], ['field1']);
      final EngineAutofillForm? autofillForm =
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
      editingStrategy =
          GloballyPositionedTextEditingStrategy(HybridTextEditing());
      editingStrategy!.enable(
        singlelineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );
    });

    test('Fix flipped base and extent offsets', () {
      expect(
        EditingState(baseOffset: 10, extentOffset: 4),
        EditingState(baseOffset: 4, extentOffset: 10),
      );

      expect(
        EditingState.fromFrameworkMessage(<String, dynamic>{
          'selectionBase': 10,
          'selectionExtent': 4,
        }),
        EditingState.fromFrameworkMessage(<String, dynamic>{
          'selectionBase': 4,
          'selectionExtent': 10,
        }),
      );
    });

    test('Configure input element from the editing state', () {
      final InputElement input = defaultTextEditingRoot.querySelector('input') as InputElement;
      _editingState =
          EditingState(text: 'Test', baseOffset: 1, extentOffset: 2);

      _editingState.applyToDomElement(input);

      expect(input.value, 'Test');
      expect(input.selectionStart, 1);
      expect(input.selectionEnd, 2);
    });

    test('Configure text area element from the editing state', () {
      cleanTextEditingStrategy();
      editingStrategy!.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      final TextAreaElement textArea =
          defaultTextEditingRoot.querySelector('textarea') as TextAreaElement;
      _editingState =
          EditingState(text: 'Test', baseOffset: 1, extentOffset: 2);

      _editingState.applyToDomElement(textArea);

      expect(textArea.value, 'Test');
      expect(textArea.selectionStart, 1);
      expect(textArea.selectionEnd, 2);
    });

    test('Get Editing State from input element', () {
      final InputElement input = defaultTextEditingRoot.querySelector('input') as InputElement;
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      _editingState = EditingState.fromDomElement(input);

      expect(_editingState.text, 'Test');
      expect(_editingState.baseOffset, 1);
      expect(_editingState.extentOffset, 2);
    });

    test('Get Editing State from text area element', () {
      cleanTextEditingStrategy();
      editingStrategy!.enable(
        multilineConfig,
        onChange: trackEditingState,
        onAction: trackInputAction,
      );

      final TextAreaElement input = defaultTextEditingRoot.querySelector('textarea') as TextAreaElement;
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      _editingState = EditingState.fromDomElement(input);

      expect(_editingState.text, 'Test');
      expect(_editingState.baseOffset, 1);
      expect(_editingState.extentOffset, 2);
    });

    test('Compare two editing states', () {
      final InputElement input = defaultTextEditingRoot.querySelector('input') as InputElement;
      input.value = 'Test';
      input.selectionStart = 1;
      input.selectionEnd = 2;

      EditingState editingState1 = EditingState.fromDomElement(input);
      EditingState editingState2 = EditingState.fromDomElement(input);

      input.setSelectionRange(1, 3);

      EditingState editingState3 = EditingState.fromDomElement(input);

      expect(editingState1 == editingState2, isTrue);
      expect(editingState1 != editingState3, isTrue);
    });
  });
}

KeyboardEvent dispatchKeyboardEvent(
  EventTarget target,
  String type, {
  required int keyCode,
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
    int textAlignIndex, int? fontWeightIndex, int textDirectionIndex) {
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
void cleanTextEditingStrategy() {
  if (editingStrategy != null && editingStrategy!.isEnabled) {
    // Clean up all the DOM elements and event listeners.
    editingStrategy!.disable();
  }
}

void cleanTestFlags() {
  debugBrowserEngineOverride = null;
  debugOperatingSystemOverride = null;
}

void checkInputEditingState(
    Element? element, String text, int start, int end) {
  expect(element, isNotNull);
  expect(element, isA<InputElement>());
  final InputElement input = element as InputElement;
  expect(defaultTextEditingRoot.activeElement, input);
  expect(input.value, text);
  expect(input.selectionStart, start);
  expect(input.selectionEnd, end);
}

/// In case of an exception backup DOM element(s) can still stay on the DOM.
void clearBackUpDomElementIfExists() {
  List<Node> domElementsToRemove = <Node>[];
  if (defaultTextEditingRoot.querySelectorAll('input').length > 0) {
    domElementsToRemove..addAll(defaultTextEditingRoot.querySelectorAll('input'));
  }
  if (defaultTextEditingRoot.querySelectorAll('textarea').length > 0) {
    domElementsToRemove..addAll(defaultTextEditingRoot.querySelectorAll('textarea'));
  }
  domElementsToRemove.forEach((Node n) => n.remove());
}

void checkTextAreaEditingState(
  TextAreaElement textarea,
  String text,
  int start,
  int end,
) {
  expect(defaultTextEditingRoot.activeElement, textarea);
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
  bool readOnly = false,
  bool obscureText = false,
  bool autocorrect = true,
  String textCapitalization = 'TextCapitalization.none',
  String? inputAction,
  String? autofillHint,
  List<String>? autofillHintsForFields,
  bool decimal = false,
}) {
  return <String, dynamic>{
    'inputType': <String, dynamic>{
      'name': 'TextInputType.$inputType',
      if (decimal) 'decimal': true,
    },
    'readOnly': readOnly,
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
  while (defaultTextEditingRoot.querySelectorAll('form').length > 0) {
    defaultTextEditingRoot.querySelectorAll('form').last.remove();
  }
  formsOnTheDom.clear();
}
