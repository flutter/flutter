// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome || safari || firefox')

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart' hide window;
import 'package:ui/ui.dart' as ui;

import 'semantics_tester.dart';

final InputConfiguration singlelineConfig = InputConfiguration(
  inputType: EngineInputType.text,
);

final InputConfiguration multilineConfig = InputConfiguration(
  inputType: EngineInputType.multiline,
  inputAction: 'TextInputAction.newline',
);

EngineSemanticsOwner semantics() => EngineSemanticsOwner.instance;

const MethodCodec codec = JSONMethodCodec();

DateTime _testTime = DateTime(2021, 4, 16);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  ensureFlutterViewEmbedderInitialized();

  setUp(() {
    EngineSemanticsOwner.debugResetSemantics();
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
    });

  test('renders a text field', () async {
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    createTextFieldSemantics(value: 'hello');

    expectSemanticsTree('''
<sem style="$rootSemanticStyle">
  <input value="hello" />
</sem>''');

    semantics().semanticsEnabled = false;
  });

  // TODO(yjbanov): this test will need to be adjusted for Safari when we add
  //                Safari testing.
  test('sends a tap action when browser requests focus', () async {
    final SemanticsActionLogger logger = SemanticsActionLogger();
    semantics()
      ..debugOverrideTimestampFunction(() => _testTime)
      ..semanticsEnabled = true;

    createTextFieldSemantics(value: 'hello');

    final DomElement textField = appHostNode
        .querySelector('input[data-semantics-role="text-field"]')!;

    expect(appHostNode.activeElement, isNot(textField));

    textField.focus();

    expect(appHostNode.activeElement, textField);
    expect(await logger.idLog.first, 0);
    expect(await logger.actionLog.first, ui.SemanticsAction.tap);

    semantics().semanticsEnabled = false;
  },  // TODO(yjbanov): https://github.com/flutter/flutter/issues/46638
      // TODO(yjbanov): https://github.com/flutter/flutter/issues/50590
      // TODO(yjbanov): https://github.com/flutter/flutter/issues/50754
      skip: browserEngine != BrowserEngine.blink);

    test('Syncs editing state from framework', () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);

      int changeCount = 0;
      int actionCount = 0;
      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {
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

      final TextField textField = textFieldSemantics.debugRoleManagerFor(Role.textField)! as TextField;
      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);
      expect(textField.editableElement, strategy.domElement);
      expect((textField.editableElement as dynamic).value, 'hello');
      expect(textField.editableElement.getAttribute('aria-label'), 'greeting');
      expect(textField.editableElement.style.width, '10px');
      expect(textField.editableElement.style.height, '15px');

      // Update
      createTextFieldSemantics(
        value: 'bye',
        label: 'farewell',
        isFocused: false,
        rect: const ui.Rect.fromLTWH(0, 0, 12, 17),
      );

      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);
      expect(strategy.domElement, null);
      expect((textField.editableElement as dynamic).value, 'bye');
      expect(textField.editableElement.getAttribute('aria-label'), 'farewell');
      expect(textField.editableElement.style.width, '12px');
      expect(textField.editableElement.style.height, '17px');

      strategy.disable();
      semantics().semanticsEnabled = false;

      // There was no user interaction with the <input> element,
      // so we should expect no engine-to-framework feedback.
      expect(changeCount, 0);
      expect(actionCount, 0);
    });

    test('Gives up focus after DOM blur', () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );

      final TextField textField = textFieldSemantics.debugRoleManagerFor(Role.textField)! as TextField;
      expect(textField.editableElement, strategy.domElement);
      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);

      // The input should not refocus after blur.
      textField.editableElement.blur();
      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);
      strategy.disable();
      semantics().semanticsEnabled = false;
    });

    test('Does not dispose and recreate dom elements in persistent mode', () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );

      // It doesn't create a new DOM element.
      expect(strategy.domElement, isNull);

      // During the semantics update the DOM element is created and is focused on.
      final SemanticsObject textFieldSemantics = createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );
      expect(strategy.domElement, isNotNull);
      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);

      strategy.disable();
      expect(strategy.domElement, isNull);

      // It doesn't remove the DOM element.
      final TextField textField = textFieldSemantics.debugRoleManagerFor(Role.textField)! as TextField;
      expect(appHostNode.contains(textField.editableElement), isTrue);
      // Editing element is not enabled.
      expect(strategy.isEnabled, isFalse);
      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);
      semantics().semanticsEnabled = false;
    });

    test('Refocuses when setting editing state', () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );

      createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );
      expect(strategy.domElement, isNotNull);
      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);

      // Blur the element without telling the framework.
      strategy.activeDomElement.blur();
      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);

      // The input will have focus after editing state is set and semantics updated.
      strategy.setEditingState(EditingState(text: 'foo'));

      // NOTE: at this point some browsers, e.g. some versions of Safari will
      //       have set the focus on the editing element as a result of setting
      //       the test selection range. Other browsers require an explicit call
      //       to `element.focus()` for the element to acquire focus. So far,
      //       this discrepancy hasn't caused issues, so we're not checking for
      //       any particular focus state between setEditingState and
      //       createTextFieldSemantics. However, this is something for us to
      //       keep in mind in case this causes issues in the future.

      createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
      );
      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);

      strategy.disable();
      semantics().semanticsEnabled = false;
    });

    test('Works in multi-line mode', () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      strategy.enable(
        multilineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );
      createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
        isMultiline: true,
      );

      final DomHTMLTextAreaElement textArea = strategy.domElement! as DomHTMLTextAreaElement;

      expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
      expect(appHostNode.activeElement, strategy.domElement);

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );

      textArea.blur();
      expect(domDocument.activeElement, domDocument.body);
      expect(appHostNode.activeElement, null);

      strategy.disable();
      // It doesn't remove the textarea from the DOM.
      expect(appHostNode.contains(textArea), isTrue);
      // Editing element is not enabled.
      expect(strategy.isEnabled, isFalse);
      semantics().semanticsEnabled = false;
    });

    test('Does not position or size its DOM element', () {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );

      // Send width and height that are different from semantics values on
      // purpose.
      final EditableTextGeometry geometry = EditableTextGeometry(
        height: 12,
        width: 13,
        globalTransform: Matrix4.translationValues(14, 15, 0).storage,
      );
      const ui.Rect semanticsRect = ui.Rect.fromLTRB(0, 0, 100, 50);

      testTextEditing.acceptCommand(
        TextInputSetEditableSizeAndTransform(geometry: geometry),
        () {},
      );

      createTextFieldSemantics(
        value: 'hello',
        isFocused: true,
        rect: semanticsRect,
      );

      // Checks that the placement attributes come from semantics and not from
      // EditableTextGeometry.
      void checkPlacementIsSetBySemantics() {
        expect(strategy.activeDomElement.style.transform, '');
        expect(strategy.activeDomElement.style.width, '${semanticsRect.width}px');
        expect(strategy.activeDomElement.style.height, '${semanticsRect.height}px');
      }

      checkPlacementIsSetBySemantics();
      strategy.placeElement();
      checkPlacementIsSetBySemantics();
      semantics().semanticsEnabled = false;
    });

    Map<int, SemanticsObject> createTwoFieldSemantics(SemanticsTester builder, { int? focusFieldId }) {
      builder.updateNode(
        id: 0,
        children: <SemanticsNodeUpdate>[
          builder.updateNode(
            id: 1,
            isTextField: true,
            value: 'Hello',
            isFocused: focusFieldId == 1,
            rect: const ui.Rect.fromLTRB(0, 0, 50, 10),
          ),
          builder.updateNode(
            id: 2,
            isTextField: true,
            value: 'World',
            isFocused: focusFieldId == 2,
            rect: const ui.Rect.fromLTRB(0, 20, 50, 10),
          ),
        ],
      );
      return builder.apply();
    }

    test('Changes focus from one text field to another through a semantics update', () async {
      semantics()
        ..debugOverrideTimestampFunction(() => _testTime)
        ..semanticsEnabled = true;

      strategy.enable(
        singlelineConfig,
        onChange: (_, __) {},
        onAction: (_) {},
      );

      // Switch between the two fields a few times.
      for (int i = 0; i < 5; i++) {
        final SemanticsTester tester = SemanticsTester(semantics());
        createTwoFieldSemantics(tester, focusFieldId: 1);
        expect(tester.apply().length, 3);

        expect(domDocument.activeElement, flutterViewEmbedder.glassPaneElement);
        expect(appHostNode.activeElement, tester.getTextField(1).editableElement);
        expect(strategy.domElement, tester.getTextField(1).editableElement);

        createTwoFieldSemantics(tester, focusFieldId: 2);
        expect(tester.apply().length, 3);
        expect(appHostNode.activeElement, tester.getTextField(2).editableElement);
        expect(strategy.domElement, tester.getTextField(2).editableElement);
      }

      semantics().semanticsEnabled = false;
    });
  },
  // TODO(mdebbar): https://github.com/flutter/flutter/issues/50769
  skip: browserEngine == BrowserEngine.edge);
}

SemanticsObject createTextFieldSemantics({
  required String value,
  String label = '',
  bool isFocused = false,
  bool isMultiline = false,
  ui.Rect rect = const ui.Rect.fromLTRB(0, 0, 100, 50),
}) {
  final SemanticsTester tester = SemanticsTester(semantics());
  tester.updateNode(
    id: 0,
    label: label,
    value: value,
    isTextField: true,
    isFocused: isFocused,
    isMultiline: isMultiline,
    hasTap: true,
    rect: rect,
    textDirection: ui.TextDirection.ltr,
  );
  tester.apply();
  return tester.getSemanticsObject(0);
}
