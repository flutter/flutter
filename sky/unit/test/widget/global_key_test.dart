import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Global keys notify add and remove', () {
    GlobalKey globalKey = new GlobalKey();
    Container container;

    bool syncListenerCalled = false;
    bool removeListenerCalled = false;

    void syncListener(GlobalKey key, Widget widget) {
      syncListenerCalled = true;
      expect(key, equals(globalKey));
      expect(container, isNotNull);
      expect(widget, equals(container));
    }

    void removeListener(GlobalKey key) {
      removeListenerCalled = true;
      expect(key, equals(globalKey));
    }

    WidgetTester tester = new WidgetTester();

    GlobalKey.registerSyncListener(globalKey, syncListener);
    GlobalKey.registerRemoveListener(globalKey, removeListener);
    tester.pumpFrame(() {
      container = new Container(key: globalKey);
      return container;
    });
    expect(syncListenerCalled, isTrue);
    expect(removeListenerCalled, isFalse);

    syncListenerCalled = false;
    removeListenerCalled = false;
    tester.pumpFrame(() => new Container());
    expect(syncListenerCalled, isFalse);
    expect(removeListenerCalled, isTrue);

    syncListenerCalled = false;
    removeListenerCalled = false;
    GlobalKey.unregisterSyncListener(globalKey, syncListener);
    GlobalKey.unregisterRemoveListener(globalKey, removeListener);
    tester.pumpFrame(() {
      container = new Container(key: globalKey);
      return container;
    });
    expect(syncListenerCalled, isFalse);
    expect(removeListenerCalled, isFalse);

    tester.pumpFrame(() => new Container());
    expect(syncListenerCalled, isFalse);
    expect(removeListenerCalled, isFalse);
  });

  test('Global key reparenting', () {
    GlobalKey globalKey = new GlobalKey();

    bool syncListenerCalled = false;
    bool removeListenerCalled = false;

    void syncListener(GlobalKey key, Widget widget) {
      syncListenerCalled = true;
    }

    void removeListener(GlobalKey key) {
      removeListenerCalled = true;
    }

    GlobalKey.registerSyncListener(globalKey, syncListener);
    GlobalKey.registerRemoveListener(globalKey, removeListener);
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          key: globalKey
        )
      );
    });
    expect(syncListenerCalled, isTrue);
    expect(removeListenerCalled, isFalse);

    tester.pumpFrame(() {
      return new Container(
        key: globalKey,
        child: new Container()
      );
    });
    expect(syncListenerCalled, isTrue);
    expect(removeListenerCalled, isFalse);

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          key: globalKey
        )
      );
    });
    expect(syncListenerCalled, isTrue);
    expect(removeListenerCalled, isFalse);

    GlobalKey.unregisterSyncListener(globalKey, syncListener);
    GlobalKey.unregisterRemoveListener(globalKey, removeListener);
  });

  test('Global key mutate during iteration', () {
    GlobalKey globalKey = new GlobalKey();

    bool syncListenerCalled = false;
    bool removeListenerCalled = false;

    void syncListener(GlobalKey key, Widget widget) {
      GlobalKey.unregisterSyncListener(globalKey, syncListener);
      syncListenerCalled = true;
    }

    void removeListener(GlobalKey key) {
      GlobalKey.unregisterRemoveListener(globalKey, removeListener);
      removeListenerCalled = true;
    }

    GlobalKey.registerSyncListener(globalKey, syncListener);
    GlobalKey.registerRemoveListener(globalKey, removeListener);
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Container(key: globalKey);
    });
    expect(syncListenerCalled, isTrue);
    expect(removeListenerCalled, isFalse);

    syncListenerCalled = false;
    removeListenerCalled = false;
    tester.pumpFrame(() {
      return new Container();
    });
    expect(syncListenerCalled, isFalse);
    expect(removeListenerCalled, isTrue);

    syncListenerCalled = false;
    removeListenerCalled = false;
    tester.pumpFrame(() {
      return new Container(key: globalKey);
    });
    expect(syncListenerCalled, isFalse);
    expect(removeListenerCalled, isFalse);

  });
}
