// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnmanagedRestorationScope', () {
    testWidgets('makes bucket available to descendants', (WidgetTester tester) async {
      final RestorationBucket bucket1 = RestorationBucket.empty(
        id: const RestorationId('foo'),
        debugOwner: 'owner',
      );

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: bucket1,
          child: _BucketSpy(),
        ),
      );

      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket, bucket1);

      // Notifies when bucket changes.
      final RestorationBucket bucket2 = RestorationBucket.empty(
        id: const RestorationId('foo2'),
        debugOwner: 'owner',
      );
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: bucket2,
          child: _BucketSpy(),
        ),
      );
      expect(state.bucket, bucket2);
    });

    testWidgets('null bucket disables restoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: null,
          child: _BucketSpy(),
        ),
      );
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket, isNull);
    });
  });

  group('RestorationScope', () {
    testWidgets('makes bucket available to descendants', (WidgetTester tester) async {
      const RestorationId id = RestorationId('hello world 1234');
      final MockManager manager = MockManager();
      final Map<String, dynamic> rawData = <String, dynamic>{};
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);
      expect(rawData, isEmpty);

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: id,
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();

      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket.id, id);
      expect(rawData[childrenMapKey].containsKey(id.value), isTrue);
    });

    testWidgets('bucket for descendants contains data claimed from parent', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: _createRawDataSet());

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('child1'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();

      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket.id, const RestorationId('child1'));
      expect(state.bucket.get<int>(const RestorationId('foo')), 22);
    });

    testWidgets('renames existing bucket when new ID is provided', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: _createRawDataSet());

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('child1'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();

      // Claimed existing bucket with data.
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket.id, const RestorationId('child1'));
      expect(state.bucket.get<int>(const RestorationId('foo')), 22);
      final RestorationBucket bucket = state.bucket;

      // Rename the existing bucket.
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('something else'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();

      expect(state.bucket.id, const RestorationId('something else'));
      expect(state.bucket.get<int>(const RestorationId('foo')), 22);
      expect(state.bucket, same(bucket));
    });

    testWidgets('Disposing a scope removes its data', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      final Map<String, dynamic> rawData = _createRawDataSet();
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

      expect(rawData[childrenMapKey].containsKey('child1'), isTrue);
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('child1'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();
      expect(rawData[childrenMapKey].containsKey('child1'), isTrue);

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: Container(),
        ),
      );
      manager.runFinalizers();

      expect(rawData[childrenMapKey].containsKey('child1'), isFalse);
    });

    testWidgets('no bucket for descendants when id is null', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: <String, dynamic>{});

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: null,
            child: _BucketSpy(),
          ),
        ),
      );
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket, isNull);

      // Change id to non-null.
      // Move it under a valid scope.
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('foo'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();
      expect(state.bucket, isNotNull);
      expect(state.bucket.id, const RestorationId('foo'));
    });

    testWidgets('no bucket for descendants when scope is null', (WidgetTester tester) async {
      final Key scopeKey = GlobalKey();

      await tester.pumpWidget(
        RestorationScope(
          key: scopeKey,
          restorationId: const RestorationId('foo'),
          child: _BucketSpy(),
        ),
      );
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket, isNull);

      // Move it under a valid scope.
      final MockManager manager = MockManager();
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: <String, dynamic>{});
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            key: scopeKey,
            restorationId: const RestorationId('foo'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();
      expect(state.bucket, isNotNull);
      expect(state.bucket.id, const RestorationId('foo'));
    });

    testWidgets('no bucket for descendants when scope and id are null', (WidgetTester tester) async {
      await tester.pumpWidget(
        RestorationScope(
          restorationId: null,
          child: _BucketSpy(),
        ),
      );
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket, isNull);
    });

    testWidgets('moving scope moves its data', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      final Map<String, dynamic> rawData = <String, dynamic>{};
      final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);
      final Key scopeKey = GlobalKey();

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: Row(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              RestorationScope(
                restorationId: const RestorationId('fixed'),
                child: RestorationScope(
                  key: scopeKey,
                  restorationId: const RestorationId('moving-child'),
                  child: _BucketSpy(),
                ),
              ),
            ],
          ),
        ),
      );
      manager.runFinalizers();
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket.id, const RestorationId('moving-child'));
      expect(rawData[childrenMapKey]['fixed'][childrenMapKey].containsKey('moving-child'), isTrue);
      final RestorationBucket bucket = state.bucket;

      state.bucket.put(const RestorationId('value'), 11);
      manager.runFinalizers();

      // Move scope.
      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: Row(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              RestorationScope(
                restorationId: const RestorationId('fixed'),
                child: Container(),
              ),
              RestorationScope(
                key: scopeKey,
                restorationId: const RestorationId('moving-child'),
                child: _BucketSpy(),
              ),
            ],
          ),
        ),
      );
      manager.runFinalizers();
      expect(state.bucket.id, const RestorationId('moving-child'));
      expect(state.bucket, same(bucket));
      expect(state.bucket.get<int>(const RestorationId('value')), 11);

      expect(rawData[childrenMapKey]['fixed'], isEmpty);
      expect(rawData[childrenMapKey].containsKey('moving-child'), isTrue);
    });

    testWidgets('decommission claims new bucket with data', (WidgetTester tester) async {
      final MockManager manager = MockManager();
      RestorationBucket root = RestorationBucket.root(manager: manager, rawData: <String, dynamic>{});

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('child1'),
            child: _BucketSpy(),
          ),
        ),
      );
      manager.runFinalizers();
      final _BucketSpyState state = tester.state(find.byType(_BucketSpy));
      expect(state.bucket.id, const RestorationId('child1'));
      expect(state.bucket.get<int>(const RestorationId('foo')), isNull); // Does not exist.
      final RestorationBucket bucket = state.bucket;

      // Replace root bucket.
      root..decommission()..dispose();
      root = RestorationBucket.root(manager: manager, rawData: _createRawDataSet());

      await tester.pumpWidget(
        UnmanagedRestorationScope(
          bucket: root,
          child: RestorationScope(
            restorationId: const RestorationId('child1'),
            child: _BucketSpy(),
          ),
        ),
      );

      // Bucket has been replaced.
      expect(state.bucket, isNot(same(bucket)));
      expect(state.bucket.id, const RestorationId('child1'));
      expect(state.bucket.get<int>(const RestorationId('foo')), 22);
    });
  });
}

class MockManager implements RestorationManager {
  final Set<VoidCallback> _finalizers = <VoidCallback>{};
  bool get updateScheduled => _updateScheduled;
  bool _updateScheduled = false;

  @override
  void scheduleUpdate({VoidCallback finalizer}) {
    _updateScheduled = true;
    if (finalizer != null) {
      _finalizers.add(finalizer);
    }
  }

  void runFinalizers() {
    _updateScheduled = false;
    for (final VoidCallback finalizer in _finalizers) {
      finalizer();
    }
    _finalizers.clear();
  }

  @override
  Future<RestorationBucket> get rootBucket => throw UnimplementedError('unimplemented in mock');

  @override
  Future<void> sendToEngine(Map<String, dynamic> rawData) {
    throw UnimplementedError('unimplemented in mock');
  }

  @override
  Future<Map<String, dynamic>> retrieveFromEngine() {
    throw UnimplementedError('unimplemented in mock');
  }

  @override
  String toString() => 'MockManager';
}

const String childrenMapKey = 'c';
const String valuesMapKey = 'v';

Map<String, dynamic> _createRawDataSet() {
  return <String, dynamic>{
    valuesMapKey: <String, dynamic>{
      'value1' : 10,
      'value2' : 'Hello',
    },
    childrenMapKey: <String, dynamic>{
      'child1' : <String, dynamic>{
        valuesMapKey : <String, dynamic>{
          'foo': 22,
        }
      },
      'child2' : <String, dynamic>{
        valuesMapKey : <String, dynamic>{
          'bar': 33,
        }
      },
    },
  };
}

class _BucketSpy extends StatefulWidget {
  @override
  State<_BucketSpy> createState() => _BucketSpyState();
}

class _BucketSpyState extends State<_BucketSpy> {
  RestorationBucket bucket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bucket = RestorationScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
