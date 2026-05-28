// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' hide window;
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../../common/spy.dart';
import '../../common/test_initialization.dart';
import 'semantics_tester.dart';

final InputConfiguration singlelineConfig = InputConfiguration(viewId: kImplicitViewId);

final InputConfiguration multilineConfig = InputConfiguration(
  viewId: kImplicitViewId,
  inputType: EngineInputType.multiline,
  inputAction: 'TextInputAction.newline',
);

EngineSemantics semantics() => EngineSemantics.instance;
EngineFlutterView get flutterView => EnginePlatformDispatcher.instance.implicitView!;
EngineSemanticsOwner owner() => flutterView.semantics;

const MethodCodec codec = JSONMethodCodec();

DateTime _testTime = DateTime(2021, 4, 16);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpImplicitView();

  setUp(() {
    EngineSemantics.debugResetSemantics();
  });

  group('$SemanticsTextEditingStrategy pre-initialization tests', () {
    setUp(() {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;
    });

    tearDown(() {
      semantics().semanticsEnabled = false;
    });

    test('Calling dispose() pre-initialization will not throw an error', () {
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hi',
        isFocused: true,
      );
      final textField = textFieldSemantics.semanticRole! as SemanticTextField;

      // ensureInitialized() isn't called prior to calling dispose() here.
      // Since we are conditionally calling dispose() on our
      // SemanticsTextEditingStrategy._instance, we shouldn't expect an error.
      // ref: https://github.com/flutter/engine/pull/40146
      expect(() => textField.dispose(), returnsNormally);
    });
  });

  group('$SemanticsTextEditingStrategy', () {
    late HybridTextEditing testTextEditing;
    late SemanticsTextEditingStrategy strategy;

    setUp(() {
      testTextEditing = HybridTextEditing();
      SemanticsTextEditingStrategy.ensureInitialized(testTextEditing);
      strategy = SemanticsTextEditingStrategy.instance;
      testTextEditing.debugTextEditingStrategyOverride = strategy;
      testTextEditing.configuration = singlelineConfig;
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;
    });

    tearDown(() {
      semantics().semanticsEnabled = false;
      // Most tests in this file expect to start with nothing focused.
      domDocument.activeElement?.blur();
    });

    test('renders a text field', () {
      createTextFieldSemantics(value: 'hello');

      expectSemanticsTree(owner(), '<sem><input type="text" /></sem>');

      // TODO(yjbanov): this used to attempt to test that value="hello" but the
      //                test was a false positive. We should revise this test and
      //                make sure it tests the right things:
      //                https://github.com/flutter/flutter/issues/147200
      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textFieldRole = node.semanticRole! as SemanticTextField;
      final inputElement = textFieldRole.editableElement as DomHTMLInputElement;
      expect(inputElement.tagName.toLowerCase(), 'input');
      expect(inputElement.value, '');
      expect(inputElement.disabled, isFalse);
      expect(inputElement.getAttribute('aria-required'), isNull);
    });

    test('renders a password field', () {
      createTextFieldSemantics(value: 'secret', isObscured: true);

      expectSemanticsTree(owner(), '<sem><input type="password" /></sem>');

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textFieldRole = node.semanticRole! as SemanticTextField;
      final inputElement = textFieldRole.editableElement as DomHTMLInputElement;
      expect(inputElement.disabled, isFalse);
    });

    test('renders text fields with input types', () {
      const inputTypeEnumToString = <ui.SemanticsInputType, String>{
        ui.SemanticsInputType.none: 'text',
        ui.SemanticsInputType.text: 'text',
        ui.SemanticsInputType.url: 'url',
        ui.SemanticsInputType.phone: 'tel',
        ui.SemanticsInputType.search: 'search',
        // Email uses type="text" to preserve selection APIs under semantics.
        ui.SemanticsInputType.email: 'text',
      };
      for (final ui.SemanticsInputType type in ui.SemanticsInputType.values) {
        createTextFieldSemantics(value: 'text', inputType: type);

        expectSemanticsTree(owner(), '<sem><input type="${inputTypeEnumToString[type]}" /></sem>');
      }
    });

    test('email input uses type=text with inputmode=email and autocomplete=email', () {
      createTextFieldSemantics(value: 'text', inputType: ui.SemanticsInputType.email);

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textFieldRole = node.semanticRole! as SemanticTextField;
      final inputElement = textFieldRole.editableElement as DomHTMLInputElement;

      expect(inputElement.type, 'text');
      expect(inputElement.getAttribute('inputmode'), 'email');
      expect(inputElement.getAttribute('autocapitalize'), 'none');
      expect(inputElement.autocomplete, 'email');
    });

    test('renders a disabled text field', () {
      createTextFieldSemantics(isEnabled: false, value: 'hello');
      expectSemanticsTree(owner(), '''<sem><input /></sem>''');
      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textFieldRole = node.semanticRole! as SemanticTextField;
      final inputElement = textFieldRole.editableElement as DomHTMLInputElement;
      expect(inputElement.tagName.toLowerCase(), 'input');
      expect(inputElement.disabled, isTrue);
    });

    test('sends a SemanticsAction.focus action when browser requests focus', () async {
      final logger = SemanticsActionLogger();
      createTextFieldSemantics(value: 'hello');

      final DomElement textField = owner().semanticsHost.querySelector(
        'input[data-semantics-role="text-field"]',
      )!;

      expect(owner().semanticsHost.ownerDocument?.activeElement, isNot(textField));

      textField.focusWithoutScroll();

      expect(owner().semanticsHost.ownerDocument?.activeElement, textField);
      expect(await logger.idLog.first, 0);
      expect(await logger.actionLog.first, ui.SemanticsAction.focus);

      textField.blur();

      expect(owner().semanticsHost.ownerDocument?.activeElement, isNot(textField));
    });

    test('Syncs semantic state from framework', () async {
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);

      var changeCount = 0;
      var actionCount = 0;
      strategy.enable(
        singlelineConfig,
        onChange: (_, _) {
          changeCount++;
        },
        onAction: (_) {
          actionCount++;
        },
      );

      // Create
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        label: 'greeting',
        isFocused: true,
        rect: const ui.Rect.fromLTWH(0, 0, 10, 15),
      );

      final textField = textFieldSemantics.semanticRole! as SemanticTextField;
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);
      expect(textField.editableElement, strategy.domElement);
      expect(textField.editableElement.getAttribute('aria-label'), 'greeting');
      expect(textField.editableElement.style.width, '10px');
      expect(textField.editableElement.style.height, '15px');

      // Update
      createTextFieldSemantics(
        value: 'bye',
        label: 'farewell',
        rect: const ui.Rect.fromLTWH(0, 0, 12, 17),
      );

      // The web engine used to explicitly blur() elements when the framework
      // sent an node update with isFocused == false. This is no longer done, as
      // blurring an element without focusing on another element confuses screen
      // readers. However, if another element gains focus (e.g. because the
      // framework focuses on a different widget), then the current element will
      // be blurred automatically, without needing to call DomElement.blur().
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);
      expect(textField.editableElement.getAttribute('aria-label'), 'farewell');
      expect(textField.editableElement.style.width, '12px');
      expect(textField.editableElement.style.height, '17px');

      strategy.disable();
      expect(strategy.domElement, null);

      // Transitively disabling the strategy calls
      // DefaultTextEditingStrategy.scheduleFocusFlutterView, which uses a timer
      // before shifting focus. So initially the editable DOM element should be
      // in place, and is cleared after the timer fires.
      expect(owner().semanticsHost.ownerDocument?.activeElement, textField.editableElement);
      await Future<void>.delayed(Duration.zero);
      expect(
        owner().semanticsHost.ownerDocument?.activeElement,
        flutterView.dom.rootElement,
        reason:
            'Focus should be returned to the root element of the Flutter view '
            'after housekeeping DOM operations (blur/remove)',
      );

      // There was no user interaction with the <input> element,
      // so we should expect no engine-to-framework feedback.
      expect(changeCount, 0);
      expect(actionCount, 0);
    });

    test('Does not overwrite text value and selection editing state on semantic updates', () {
      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        textSelectionBase: 1,
        textSelectionExtent: 3,
        isFocused: true,
        rect: const ui.Rect.fromLTWH(0, 0, 10, 15),
      );

      final textField = textFieldSemantics.semanticRole! as SemanticTextField;
      final editableElement = textField.editableElement as DomHTMLInputElement;

      expect(editableElement, strategy.domElement);
      expect(editableElement.value, '');
      expect(editableElement.selectionStart, 0);
      expect(editableElement.selectionEnd, 0);

      strategy.disable();
    });

    test('Updates editing state when receiving framework messages from the text input channel', () {
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);

      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        textSelectionBase: 1,
        textSelectionExtent: 3,
        isFocused: true,
        rect: const ui.Rect.fromLTWH(0, 0, 10, 15),
      );

      final textField = textFieldSemantics.semanticRole! as SemanticTextField;
      final editableElement = textField.editableElement as DomHTMLInputElement;

      // No updates expected on semantic updates
      expect(editableElement, strategy.domElement);
      expect(editableElement.value, '');
      expect(editableElement.selectionStart, 0);
      expect(editableElement.selectionEnd, 0);

      // Update from framework
      const setEditingState = MethodCall('TextInput.setEditingState', <String, dynamic>{
        'text': 'updated',
        'selectionBase': 2,
        'selectionExtent': 3,
        'composingBase': -1,
        'composingExtent': -1,
      });
      sendFrameworkMessage(codec.encodeMethodCall(setEditingState), testTextEditing);

      // Editing state should now be updated
      expect(editableElement.value, 'updated');
      expect(editableElement.selectionStart, 2);
      expect(editableElement.selectionEnd, 3);

      strategy.disable();
    });

    test('Gives up focus after DOM blur', () {
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);

      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );

      final textField = textFieldSemantics.semanticRole! as SemanticTextField;
      expect(textField.editableElement, strategy.domElement);
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);

      // The input should not refocus after blur.
      textField.editableElement.blur();
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);
      strategy.disable();
    });

    test('Does not dispose and recreate dom elements in persistent mode', () async {
      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      // It doesn't create a new DOM element.
      expect(strategy.domElement, isNull);

      // During the semantics update the DOM element is created and is focused on.
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );
      expect(strategy.domElement, isNotNull);
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);

      strategy.disable();
      expect(strategy.domElement, isNull);

      // It doesn't remove the DOM element.
      final textField = textFieldSemantics.semanticRole! as SemanticTextField;
      expect(owner().semanticsHost.contains(textField.editableElement), isTrue);
      // Editing element is not enabled.
      expect(strategy.isEnabled, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(
        owner().semanticsHost.ownerDocument?.activeElement,
        flutterView.dom.rootElement,
        reason:
            'Focus should be returned to the root element of the Flutter view '
            'after housekeeping DOM operations (blur/remove)',
      );
    });

    test('Refocuses when setting editing state', () {
      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      createTextFieldSemantics(value: 'hello', isFocused: true);
      expect(strategy.domElement, isNotNull);
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);

      // Blur the element without telling the framework.
      strategy.activeDomElement.blur();
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);

      // The input will have focus after editing state is set and semantics updated.
      strategy.setEditingState(EditingState(text: 'foo', baseOffset: 0, extentOffset: 0));

      // NOTE: at this point some browsers, e.g. some versions of Safari will
      //       have set the focus on the editing element as a result of setting
      //       the test selection range. Other browsers require an explicit call
      //       to `element.focus()` for the element to acquire focus. So far,
      //       this discrepancy hasn't caused issues, so we're not checking for
      //       any particular focus state between setEditingState and
      //       createTextFieldSemantics. However, this is something for us to
      //       keep in mind in case this causes issues in the future.

      createTextFieldSemantics(value: 'hello', isFocused: true);
      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);

      strategy.disable();
    });

    test('Works in multi-line mode', () {
      strategy.enable(multilineConfig, onChange: (_, _) {}, onAction: (_) {});
      createTextFieldSemantics(value: 'hello', isFocused: true, isMultiline: true);

      final textArea = strategy.domElement! as DomHTMLTextAreaElement;
      expect(textArea.style.getPropertyValue('-webkit-text-security'), '');

      expect(owner().semanticsHost.ownerDocument?.activeElement, strategy.domElement);

      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      textArea.blur();
      expect(owner().semanticsHost.ownerDocument?.activeElement, domDocument.body);

      strategy.disable();
      // It doesn't remove the textarea from the DOM.
      expect(owner().semanticsHost.contains(textArea), isTrue);
      // Editing element is not enabled.
      expect(strategy.isEnabled, isFalse);
    });

    test('multi-line and obscured', () {
      strategy.enable(multilineConfig, onChange: (_, _) {}, onAction: (_) {});
      createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
        isMultiline: true,
        isObscured: true,
      );

      expectSemanticsTree(
        owner(),
        '<sem><textarea style="-webkit-text-security: circle"></textarea></sem>',
      );

      strategy.disable();
      // Firefox strips out `-webkit-text-security` from outerHTML.
    }, skip: ui_web.browser.browserEngine == ui_web.BrowserEngine.firefox);

    test('Does not position or size its DOM element', () {
      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      // Send width and height that are different from semantics values on
      // purpose.
      final geometry = EditableTextGeometry(
        height: 12,
        width: 13,
        globalTransform: Matrix4.translationValues(14, 15, 0).storage,
      );

      testTextEditing.acceptCommand(
        TextInputSetEditableSizeAndTransform(geometry: geometry),
        () {},
      );

      createTextFieldSemantics(value: 'hello', isFocused: true);

      // Checks that the placement attributes come from semantics and not from
      // EditableTextGeometry.
      void checkPlacementIsSetBySemantics() {
        expect(strategy.activeDomElement.style.transform, '');
        expect(strategy.activeDomElement.style.width, '100px');
        expect(strategy.activeDomElement.style.height, '50px');
      }

      checkPlacementIsSetBySemantics();
      strategy.placeElement();
      checkPlacementIsSetBySemantics();
    });

    Map<int, SemanticsObject> createTwoFieldSemantics(
      SemanticsTester builder, {
      int? focusFieldId,
    }) {
      builder.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          builder.updateNode(
            id: 1,
            flags: ui.SemanticsFlags(
              isEnabled: ui.Tristate.isTrue,
              isTextField: true,
              isFocused: focusFieldId == 1 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
            ),
            value: 'Hello',

            rect: const ui.Rect.fromLTRB(0, 0, 50, 10),
          ),
          builder.updateNode(
            id: 2,
            flags: ui.SemanticsFlags(
              isEnabled: ui.Tristate.isTrue,
              isTextField: true,
              isFocused: focusFieldId == 2 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
            ),
            value: 'World',
            rect: const ui.Rect.fromLTRB(0, 20, 50, 10),
          ),
        ],
      );
      return builder.apply();
    }

    test('Changes focus from one text field to another through a semantics update', () {
      strategy.enable(singlelineConfig, onChange: (_, _) {}, onAction: (_) {});

      // Switch between the two fields a few times.
      for (var i = 0; i < 5; i++) {
        final tester = SemanticsTester(owner());
        createTwoFieldSemantics(tester, focusFieldId: 1);
        expect(tester.apply().length, 3);

        expect(
          owner().semanticsHost.ownerDocument?.activeElement,
          tester.getTextField(1).editableElement,
        );
        expect(strategy.domElement, tester.getTextField(1).editableElement);

        createTwoFieldSemantics(tester, focusFieldId: 2);
        expect(tester.apply().length, 3);
        expect(
          owner().semanticsHost.ownerDocument?.activeElement,
          tester.getTextField(2).editableElement,
        );
        expect(strategy.domElement, tester.getTextField(2).editableElement);
      }
    });

    test('renders a required text field', () {
      createTextFieldSemantics(isRequired: true, value: 'hello');
      expectSemanticsTree(owner(), '''<sem><input aria-required="true" /></sem>''');
    });

    test('renders a not required text field', () {
      createTextFieldSemantics(isRequired: false, value: 'hello');
      expectSemanticsTree(owner(), '''<sem><input aria-required="false" /></sem>''');
    });

    test('renders hint as aria-description on input element', () {
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: '',
        label: 'Email',
        hint: 'Enter your email address',
      );
      final textField = textFieldSemantics.semanticRole! as SemanticTextField;

      expect(textField.editableElement.getAttribute('aria-label'), 'Email');
      expect(
        textField.editableElement.getAttribute('aria-description'),
        'Enter your email address',
      );
    });

    test('hint updates when semantics change', () {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'Password',
        hint: 'Enter your password',
        value: '',
        flags: const ui.SemanticsFlags(isTextField: true),
        hasTap: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        textDirection: ui.TextDirection.ltr,
      );
      tester.apply();

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textField = node.semanticRole! as SemanticTextField;

      expect(textField.editableElement.getAttribute('aria-description'), 'Enter your password');

      // Update to show error message (simulates validation error)
      tester.updateNode(
        id: 0,
        label: 'Password',
        hint: 'Password is required',
        value: '',
        flags: const ui.SemanticsFlags(isTextField: true),
        hasTap: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        textDirection: ui.TextDirection.ltr,
      );
      tester.apply();

      expect(textField.editableElement.getAttribute('aria-description'), 'Password is required');
    });

    test('empty hint removes aria-description', () {
      final tester = SemanticsTester(owner());
      tester.updateNode(
        id: 0,
        label: 'Email',
        hint: 'Enter email',
        value: '',
        flags: const ui.SemanticsFlags(isTextField: true),
        hasTap: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        textDirection: ui.TextDirection.ltr,
      );
      tester.apply();

      final SemanticsObject node = owner().debugSemanticsTree![0]!;
      final textField = node.semanticRole! as SemanticTextField;

      expect(textField.editableElement.getAttribute('aria-description'), 'Enter email');

      // Remove hint (omitting it uses the default null value)
      tester.updateNode(
        id: 0,
        label: 'Email',
        value: '',
        flags: const ui.SemanticsFlags(isTextField: true),
        hasTap: true,
        rect: const ui.Rect.fromLTRB(0, 0, 100, 50),
        textDirection: ui.TextDirection.ltr,
      );
      tester.apply();

      expect(textField.editableElement.getAttribute('aria-description'), isNull);
    });
  });

  // Group autofill in semantics mode. See https://github.com/flutter/flutter/issues/180652
  group('$SemanticsTextEditingStrategy autofill group', () {
    late HybridTextEditing testTextEditing;
    late SemanticsTextEditingStrategy strategy;

    setUp(() {
      testTextEditing = HybridTextEditing();
      SemanticsTextEditingStrategy.ensureInitialized(testTextEditing);
      strategy = SemanticsTextEditingStrategy.instance;
      testTextEditing.debugTextEditingStrategyOverride = strategy;
      testTextEditing.configuration = singlelineConfig;
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;
    });

    tearDown(() {
      if (strategy.isEnabled) {
        strategy.disable();
      }
      cleanForms();
      semantics().semanticsEnabled = false;
      domDocument.activeElement?.blur();
    });

    // Builds a focused-username + password autofill group and drives the
    // semantics path so the focused field is activated.
    ({EngineAutofillForm form, SemanticTextField textField}) activateGroup() {
      final List<Map<String, Object?>> fields = _autofillFields(
        <String>['username', 'password'],
        <String>['field1', 'field2'],
      );
      final focusedMap = fields.first['autofill']! as Map<String, Object?>;
      final EngineAutofillForm form = EngineAutofillForm.fromFrameworkMessage(
        kImplicitViewId,
        focusedMap,
        fields,
      )!;
      final config = InputConfiguration(
        viewId: kImplicitViewId,
        autofill: AutofillInfo.fromFrameworkMessage(focusedMap),
        autofillGroup: form,
      );
      strategy.enable(config, onChange: (_, _) {}, onAction: (_) {});
      final SemanticsObject semanticsObject = createTextFieldSemantics(value: '', isFocused: true);
      return (form: form, textField: semanticsObject.semanticRole! as SemanticTextField);
    }

    test('builds the form and links the focused field by attribute', () {
      final (form: EngineAutofillForm form, textField: SemanticTextField textField) =
          activateGroup();
      final DomHTMLFormElement formElement = form.formElement!;

      // Form is inserted into the text-editing host with the stable id used
      // for the form= association.
      expect(flutterView.dom.textEditingHost.contains(formElement), isTrue);
      expect(formElement.id, form.formDomId);
      expect(formElement.getElementsByClassName('submitBtn'), hasLength(1));

      // The non-focused member is a synthetic placeholder inside the form.
      final DomHTMLElement password = form.elements['field2']!;
      expect(formElement.contains(password), isTrue);
      expect((password as DomHTMLInputElement).name, 'current-password');

      // The focused member is NOT synthesized into the form (would be
      // submitted twice), it is linked by attribute instead.
      expect(form.elements['field1'], isNull);
      expect(textField.editableElement.getAttribute('form'), form.formDomId);

      // Regression guard for the 2021 tab-traversal regression
      // (flutter/engine#25797): the editing element must stay in the
      // semantics host and must NOT be moved into the form / text-editing
      // host.
      expect(flutterView.dom.semanticsHost.contains(textField.editableElement), isTrue);
      expect(formElement.contains(textField.editableElement), isFalse);

      // Autofill hint is applied and not clobbered back to 'off' by
      // _updateInputType during the same semantics update.
      expect((textField.editableElement as DomHTMLInputElement).autocomplete, 'username');
    });

    test('autocomplete survives a later semantics update', () {
      final (form: EngineAutofillForm form, textField: SemanticTextField textField) =
          activateGroup();
      expect((textField.editableElement as DomHTMLInputElement).autocomplete, 'username');

      // A second semantics update re-runs _updateInputType; it must not stomp
      // the autofill hint while the field is the active group member.
      createTextFieldSemantics(value: '', isFocused: true);
      expect((textField.editableElement as DomHTMLInputElement).autocomplete, 'username');
      expect(textField.editableElement.getAttribute('form'), form.formDomId);
    });

    test('autofill on a synthetic sibling propagates to the framework', () {
      final spy = PlatformMessagesSpy()..setUp();
      try {
        final (form: EngineAutofillForm form, textField: _) = activateGroup();
        final password = form.elements['field2']! as DomHTMLInputElement;

        // Simulate the browser autofilling the (non-focused) password field.
        password.value = 'p4ssw0rd';
        password.dispatchEvent(createDomEvent('Event', 'input'));

        final Iterable<PlatformMessage> tagged = spy.messages.where(
          (m) =>
              m.channel == 'flutter/textinput' &&
              m.methodName == 'TextInputClient.updateEditingStateWithTag',
        );
        expect(tagged, isNotEmpty);
        final args = tagged.last.methodArguments as List<dynamic>;
        expect(args[1], isA<Map<dynamic, dynamic>>());
        expect((args[1] as Map<dynamic, dynamic>).containsKey('field2'), isTrue);
      } finally {
        spy.tearDown();
      }
    });

    test('demotes the focused field to a synthetic placeholder on blur', () {
      final (form: EngineAutofillForm form, textField: SemanticTextField textField) =
          activateGroup();
      expect(textField.editableElement.getAttribute('form'), form.formDomId);

      strategy.disable();

      // The real element is detached from the form...
      expect(textField.editableElement.getAttribute('form'), isNull);
      // ...and replaced by a synthetic placeholder so the field still submits
      // for credential save, and the form is kept dormant in the DOM.
      final DomHTMLElement? placeholder = form.elements['field1'];
      expect(placeholder, isNotNull);
      expect(form.formElement!.contains(placeholder), isTrue);
      expect(dormantForms[form.formIdentifier], form);
    });

    // Focus A, autofill A, focus B, autofill a different credential, focus A
    // again, then assert each field is represented in the form exactly once
    // with its latest value and the focused field is linked by attribute (not
    // duplicated). This is the property that makes TextInput.finishAutofillContext
    // submit correct values. Exercises wakeUp dormant-reuse, demote, and promote
    // together. See https://github.com/flutter/flutter/issues/180652
    test('promote/demote keeps each field represented once across A->B->A', () {
      // Each focus change arrives as a fresh InputConfiguration whose `autofill`
      // is the focused field and whose group shares the same formIdentifier, so
      // it reuses the dormant form. `values` mirrors how the framework re-sends
      // the config with each field's current editing value after an autofilled
      // value has propagated back. Non-focused synthetic values come from this
      // editing state via _updateFieldValues, not from DOM scraping, so this is
      // the faithful way to simulate autofill.
      InputConfiguration configFor(int focusedIndex, List<String> values) {
        final List<Map<String, Object?>> f = _autofillFields(
          <String>['username', 'password'],
          <String>['field1', 'field2'],
          values: values,
        );
        final focusedMap = f[focusedIndex]['autofill']! as Map<String, Object?>;
        return InputConfiguration(
          viewId: kImplicitViewId,
          autofill: AutofillInfo.fromFrameworkMessage(focusedMap),
          autofillGroup: EngineAutofillForm.fromFrameworkMessage(kImplicitViewId, focusedMap, f),
        );
      }

      final tester = SemanticsTester(owner());
      void focusNode(int nodeId) {
        tester.updateNode(
          id: 0,
          children: <SemanticsNodeUpdate>[
            tester.updateNode(
              id: 1,
              flags: ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isTextField: true,
                isFocused: nodeId == 1 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
              ),
              value: '',
              rect: const ui.Rect.fromLTRB(0, 0, 50, 10),
            ),
            tester.updateNode(
              id: 2,
              flags: ui.SemanticsFlags(
                isEnabled: ui.Tristate.isTrue,
                isTextField: true,
                isFocused: nodeId == 2 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
              ),
              value: '',
              rect: const ui.Rect.fromLTRB(0, 20, 50, 10),
            ),
          ],
        );
        tester.apply();
      }

      // Node 1 == field1 (username/A), node 2 == field2 (password/B).
      // Focus A. Nothing autofilled yet.
      strategy.enable(configFor(0, <String>['', '']), onChange: (_, _) {}, onAction: (_) {});
      focusNode(1);
      final EngineAutofillForm formA = strategy.inputConfiguration.autofillGroup!;
      // Browser autofills the focused field A. Its live value is what save
      // submits for the focused, form-associated element.
      (tester.getTextField(1).editableElement as DomHTMLInputElement).value = 'userA';

      // Focus B. The framework now knows A's value and re-sends the config.
      strategy.enable(configFor(1, <String>['userA', '']), onChange: (_, _) {}, onAction: (_) {});
      focusNode(2);
      (tester.getTextField(2).editableElement as DomHTMLInputElement).value = 'passB';

      // Focus A again. The framework now knows both values.
      strategy.enable(
        configFor(0, <String>['userA', 'passB']),
        onChange: (_, _) {},
        onAction: (_) {},
      );
      focusNode(1);

      final EngineAutofillForm group = strategy.inputConfiguration.autofillGroup!;
      final DomHTMLFormElement formElement = group.formElement!;

      // Same DOM form reused across every wake/dormant cycle.
      expect(formElement, formA.formElement);

      // A is focused: real element linked by attribute, never moved into or
      // duplicated in the form.
      expect(tester.getTextField(1).editableElement.getAttribute('form'), group.formDomId);
      expect(formElement.contains(tester.getTextField(1).editableElement), isFalse);
      expect((tester.getTextField(1).editableElement as DomHTMLInputElement).value, 'userA');

      // B is not focused: exactly one synthetic carrying its latest value, no
      // stale/duplicate synthetic for either field, B's real element released.
      final List<DomHTMLInputElement> synthetics = formElement
          .querySelectorAll('input')
          .cast<DomHTMLInputElement>()
          .where((DomHTMLInputElement e) => e.type != 'submit')
          .toList();
      expect(synthetics, hasLength(1));
      expect(synthetics.single.name, 'current-password');
      expect(synthetics.single.value, 'passB');
      expect(group.elements.length, 1);
      expect(group.elements['field2'], synthetics.single);
      expect(group.elements.containsKey('field1'), isFalse);
      expect(tester.getTextField(2).editableElement.getAttribute('form'), isNull);
    });
  });
}

/// Builds the `fields` list of a `TextInputConfiguration` autofill group, the
/// same shape the framework sends over the `flutter/textinput` channel.
List<Map<String, Object?>> _autofillFields(
  List<String> hints,
  List<String> uniqueIds, {
  List<String>? values,
}) {
  assert(hints.length == uniqueIds.length);
  assert(values == null || values.length == hints.length);
  return <Map<String, Object?>>[
    for (var i = 0; i < hints.length; i++)
      <String, Object?>{
        'inputType': <String, Object?>{
          'name': 'TextInputType.text',
          'signed': null,
          'decimal': null,
        },
        'textCapitalization': 'TextCapitalization.none',
        'autofill': <String, dynamic>{
          'uniqueIdentifier': uniqueIds[i],
          'hints': <String>[hints[i]],
          'editingValue': <String, dynamic>{
            'text': values?[i] ?? '',
            'selectionBase': 0,
            'selectionExtent': 0,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': -1,
            'composingExtent': -1,
          },
        },
      },
  ];
}

SemanticsObject createTextFieldSemantics({
  required String value,
  String label = '',
  String? hint,
  bool isEnabled = true,
  bool isFocused = false,
  bool isMultiline = false,
  bool isObscured = false,
  bool? isRequired,
  ui.Rect rect = const ui.Rect.fromLTRB(0, 0, 100, 50),
  int textSelectionBase = 0,
  int textSelectionExtent = 0,
  ui.SemanticsInputType inputType = ui.SemanticsInputType.text,
}) {
  final tester = SemanticsTester(owner());
  tester.updateNode(
    id: 0,
    label: label,
    hint: hint,
    value: value,
    flags: ui.SemanticsFlags(
      isEnabled: isEnabled ? ui.Tristate.isTrue : ui.Tristate.none,
      isTextField: true,
      isFocused: isFocused ? ui.Tristate.isTrue : ui.Tristate.isFalse,
      isMultiline: isMultiline,
      isObscured: isObscured,
      isRequired: isRequired == null
          ? ui.Tristate.none
          : (isRequired ? ui.Tristate.isTrue : ui.Tristate.isFalse),
    ),
    hasTap: true,
    rect: rect,
    textDirection: ui.TextDirection.ltr,
    textSelectionBase: textSelectionBase,
    textSelectionExtent: textSelectionExtent,
    inputType: inputType,
  );
  tester.apply();
  return tester.getSemanticsObject(0);
}

/// Emulates sending of a message by the framework to the engine.
void sendFrameworkMessage(ByteData? message, HybridTextEditing testTextEditing) {
  testTextEditing.channel.handleTextInput(message, (ByteData? data) {});
}
