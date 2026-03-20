import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode(debugLabel: 'EditableText Node');
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets(
    'Prevent the last character in obscure text when the obscureText option is toggled',
    (WidgetTester tester) async {
      bool obscureText = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home:  StatefulBuilder(
            builder: (BuildContext context, StateSetter stateSetter) {
              setState = stateSetter;
              return EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                obscuringCharacter: '•',
                style: TextStyle(fontSize: 18),
                cursorColor: Colors.blueAccent,
                obscureText: obscureText,
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.idle();

      await tester.enterText(find.byType(EditableText), 'H');
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'HH');
      await tester.pump();

      expect((findRenderEditable(tester).text! as TextSpan).text, '•H');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect((findRenderEditable(tester).text! as TextSpan).text, '••');

      await tester.enterText(find.byType(EditableText), 'HHH');
      await tester.pump();

      expect((findRenderEditable(tester).text! as TextSpan).text, '••H');

      /// set obscureText = false
      setState(() {
        obscureText = false;
      });
      await tester.pump();
      expect((findRenderEditable(tester).text! as TextSpan).text, 'HHH');

      /// set obscureText = true
      setState(() {
        obscureText = true;
      });
      await tester.pump();
      expect((findRenderEditable(tester).text! as TextSpan).text, '•••');
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.fuchsia,
    }),
  );
}

// Returns the RenderEditable at the given index, or the first if not given.
RenderEditable findRenderEditable(WidgetTester tester, {int index = 0}) {
  final RenderObject root = tester.renderObject(find.byType(EditableText).at(index));
  expect(root, isNotNull);

  late RenderEditable renderEditable;
  void recursiveFinder(RenderObject child) {
    if (child is RenderEditable) {
      renderEditable = child;
      return;
    }
    child.visitChildren(recursiveFinder);
  }

  root.visitChildren(recursiveFinder);
  expect(renderEditable, isNotNull);
  return renderEditable;
}
