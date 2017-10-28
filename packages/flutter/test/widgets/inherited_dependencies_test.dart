import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class ConditionInherited extends InheritedWidget {
  const ConditionInherited({this.value, Key key, Widget child}) : super(key: key, child: child);

  final bool value;

  static bool valueOf(BuildContext context) {
    final ConditionInherited widget = context.inheritFromWidgetOfExactType(ConditionInherited);
    return widget?.value ?? true;
  }

  @override
  bool updateShouldNotify(ConditionInherited oldWidget) => value != oldWidget.value;
}

class StringInherited extends InheritedWidget {
  const StringInherited({this. value, Key key, Widget child}) : super(key: key, child: child);

  final String value;

  static String valueOf(BuildContext context) {
    final StringInherited widget = context.inheritFromWidgetOfExactType(StringInherited);
    return widget?.value ?? 'Missing string value';
  }

  @override
  bool updateShouldNotify(StringInherited oldWidget) => value != oldWidget.value;
}

class ConditionalText extends StatefulWidget {
  const ConditionalText({this.textKey, this.logger, Key key}) : super(key: key);

  final Key textKey;
  final Logger logger;

  @override
  ConditionalTextElement createElement() => new ConditionalTextElement(this);

  @override
  ConditionalTextState createState() => new ConditionalTextState();
}

class ConditionalTextElement extends StatefulElement {
  ConditionalTextElement(ConditionalText widget) : super(widget);

  @override
  ConditionalText get widget => super.widget;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.logger('Element.didChangeDependencies');
  }
}

class ConditionalTextState extends State<ConditionalText> {
  @override
  Widget build(BuildContext context) {
    widget.logger('build');
    final bool condition = ConditionInherited.valueOf(context);
    if (condition) {
      final String string = StringInherited.valueOf(context);
      return new Text(string, key: widget.textKey, textDirection: TextDirection.ltr);
    }
    return new Text('No Text', key: widget.textKey, textDirection: TextDirection.ltr);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.logger('State.didChangeDependencies');
  }
}

typedef void Logger(String s);

Logger newLogger(List<String> log, {String prefix = '', List<String> excludes = const <String>[]}) {
  if (prefix != '')
    prefix = prefix + ' ';
  return (String s) {
    if (excludes.contains(s)) {
      return;
    }
    log.add(prefix + s);
  };
}

Widget buildHierarchicalInheritedWidgetTree({bool condition, String text, Widget child}) {
  return new StringInherited(
      value: text,
      child: new ConditionInherited(
        value: condition,
        child: child,
      )
  );
}

void main() {
  testWidgets('State.didChangeDependencies is called before first build', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new ConditionalText(logger: newLogger(log, excludes: <String>['Element.didChangeDependencies'])));
    expect(log, <String>['State.didChangeDependencies', 'build']);
  });

  testWidgets('State.didChangeDependencies is not called for elements about to unmount', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget widget = new ConditionalText(logger: newLogger(log, excludes: <String>['Element.didChangeDependencies']));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
        condition: true,
        text: 'Foo',
        child: widget,
    ));

    log.clear();
    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
        condition: false,
        text: 'Bar',
        child: const Text('text', textDirection: TextDirection.ltr),
    ));
    expect(log, <String>[]);
  });

  testWidgets('State.didChangeDependencies is called only once if multiple dependencies changed', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget widget = new ConditionalText(logger: newLogger(log, excludes: <String>['Element.didChangeDependencies']));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
        condition: true,
        text: 'Foo',
        child: widget,
    ));

    log.clear();
    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
        condition: false,
        text: 'Bar',
        child: widget,
    ));
    expect(log, <String>['State.didChangeDependencies', 'build']);
  });

  testWidgets('Element.didChangeDependencies is not called in first build', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(new ConditionalText(logger: newLogger(log, excludes: <String>['State.didChangeDependencies'])));
    expect(log, <String>['build']);
  });

  testWidgets('Element.didChangeDependencies is not called for elements about to unmount', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget widget = new ConditionalText(logger: newLogger(log, excludes: <String>['State.didChangeDependencies']));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: true,
      text: 'Foo',
      child: widget,
    ));

    log.clear();
    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: false,
      text: 'Bar',
      child: const Text('text', textDirection: TextDirection.ltr),
    ));
    expect(log, <String>[]);
  });

  testWidgets('Element.didChangeDependencies is called only once if multiple dependencies changed', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget widget = new ConditionalText(logger: newLogger(log, excludes: <String>['State.didChangeDependencies']));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: true,
      text: 'Foo',
      child: widget,
    ));

    log.clear();
    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: false,
      text: 'Bar',
      child: widget,
    ));
    expect(log, <String>['Element.didChangeDependencies', 'build']);
  });

  testWidgets('didChangeDependencies is not called due to outdated dependency change', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget widget = new ConditionalText(logger: newLogger(log));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: true,
      text: 'Foo',
      child: widget,
    ));

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: false,
      text: 'Bar',
      child: widget,
    ));

    log.clear();
    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: false,
      text: 'FooBar',
      child: widget,
    ));
    expect(log, <String>[]);
  });

  testWidgets('InheritedElement.dispatchDidChangeDependencies is allowed to call outside build phase', (WidgetTester tester) async {
    InheritedElement inheritedElement;
    bool rebuild;

    final Widget widget = new Builder(builder: (BuildContext context) {
      rebuild = true;
      context.inheritFromWidgetOfExactType(ConditionInherited);
      inheritedElement = context.ancestorInheritedElementForWidgetOfExactType(ConditionInherited);
      return const Text('text', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(buildHierarchicalInheritedWidgetTree(
      condition: true,
      text: 'Foo',
      child: widget,
    ));

    rebuild = false;
    inheritedElement.dispatchDidChangeDependencies();
    await tester.pump();
    expect(rebuild, true);
  });
}