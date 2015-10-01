import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';
import 'test_widgets.dart';

class ProbeWidget extends StatefulComponent {
  ProbeWidgetState createState() => new ProbeWidgetState();
}

class ProbeWidgetState extends State<ProbeWidget> {
  static int buildCount = 0;

  void initState() {
    super.initState();
    setState(() {});
  }

  void didUpdateConfig(ProbeWidget oldConfig) {
    setState(() {});
  }

  Widget build(BuildContext context) {
    setState(() {});
    buildCount++;
    return new Container();
  }
}

class BadWidget extends StatelessComponent {
  BadWidget(this.parentState);

  final State parentState;

  Widget build(BuildContext context) {
    parentState.setState(() {});
    return new Container();
  }
}

class BadWidgetParent extends StatefulComponent {
  BadWidgetParentState createState() => new BadWidgetParentState();
}

class BadWidgetParentState extends State<BadWidgetParent> {
  Widget build(BuildContext context) {
    return new BadWidget(this);
  }
}

class BadDisposeWidget extends StatefulComponent {
  BadDisposeWidgetState createState() => new BadDisposeWidgetState();
}

class BadDisposeWidgetState extends State<BadDisposeWidget> {
  Widget build(BuildContext context) {
    return new Container();
  }

  void dispose() {
    setState(() {});
    super.dispose();
  }
}

void main() {
  dynamic cachedException;

  setUp(() {
    assert(cachedException == null);
    debugWidgetsExceptionHandler = (String context, dynamic exception, StackTrace stack) {
      cachedException = exception;
    };
  });

  tearDown(() {
    assert(cachedException == null);
    cachedException = null;
    debugWidgetsExceptionHandler = null;
  });

  test('Legal times for setState', () {
    WidgetTester tester = new WidgetTester();

    GlobalKey flipKey = new GlobalKey();
    expect(ProbeWidgetState.buildCount, equals(0));
    tester.pumpFrame(new ProbeWidget());
    expect(ProbeWidgetState.buildCount, equals(1));
    tester.pumpFrame(new ProbeWidget());
    expect(ProbeWidgetState.buildCount, equals(2));
    tester.pumpFrame(new FlipComponent(
      key: flipKey,
      left: new Container(),
      right: new ProbeWidget()
    ));
    expect(ProbeWidgetState.buildCount, equals(2));
    (flipKey.currentState as FlipComponentState).flip();
    tester.pumpFrameWithoutChange();
    expect(ProbeWidgetState.buildCount, equals(3));
    (flipKey.currentState as FlipComponentState).flip();
    tester.pumpFrameWithoutChange();
    expect(ProbeWidgetState.buildCount, equals(3));
    tester.pumpFrame(new Container());
    expect(ProbeWidgetState.buildCount, equals(3));
  });

  test('Setting parent state during build is forbidden', () {
    WidgetTester tester = new WidgetTester();

    expect(cachedException, isNull);
    tester.pumpFrame(new BadWidgetParent());
    expect(cachedException, isNotNull);
    cachedException = null;
    tester.pumpFrame(new Container());
    expect(cachedException, isNull);
  });

  test('Setting state during dispose is forbidden', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new BadDisposeWidget());
    expect(() {
      tester.pumpFrame(new Container());
    }, throws);
  });
}
