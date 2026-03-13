import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders child widget', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RawAvatar(child: Text('AB')),
      ),
    );

    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('applies background color', (tester) async {
    const color = Color(0xFF123456);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RawAvatar(backgroundColor: color),
      ),
    );

    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );

    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, color);
  });

  testWidgets('renders icon with iconTheme', (tester) async {
    const iconTheme = IconThemeData(size: 32);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RawAvatar(iconTheme: iconTheme, child: Icon(IconData(0xe491))),
      ),
    );

    final IconTheme iconThemeWidget = tester.widget<IconTheme>(find.byType(IconTheme));

    expect(iconThemeWidget.data.size, 32);
  });
}
