// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'restoration.dart';

void main() {
  final TestAutomatedTestWidgetsFlutterBinding binding = TestAutomatedTestWidgetsFlutterBinding();

  setUp(() {
    binding._restorationManager = MockRestorationManager();
  });

  testWidgets('does not inject root bucket if inside scope', (WidgetTester tester) async {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = <String, dynamic>{};
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);
    expect(rawData, isEmpty);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnmanagedRestorationScope(
          bucket: root,
          child: const RootRestorationScope(
            restorationId: 'root-child',
            child: BucketSpy(
              child: Text('Hello'),
            ),
          ),
        ),
      ),
    );
    manager.doSerialization();

    expect(binding.restorationManager.rootBucketAccessed, 0);
    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket!.restorationId, 'root-child');
    expect(rawData[childrenMapKey].containsKey('root-child'), isTrue);

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('waits for root bucket', (WidgetTester tester) async {
    final Completer<RestorationBucket> bucketCompleter = Completer<RestorationBucket>();
    binding.restorationManager.rootBucket = bucketCompleter.future;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    // Child rendering is delayed until root bucket is available.
    expect(find.text('Hello'), findsNothing);
    expect(binding.firstFrameIsDeferred, isTrue);

    // Complete the future.
    final Map<String, dynamic> rawData = <String, dynamic>{};
    final RestorationBucket root = RestorationBucket.root(manager: binding.restorationManager, rawData: rawData);
    bucketCompleter.complete(root);
    await tester.pump(const Duration(milliseconds: 100));

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(binding.firstFrameIsDeferred, isFalse);

    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket!.restorationId, 'root-child');
    expect(rawData[childrenMapKey].containsKey('root-child'), isTrue);
  });

  testWidgets('no delay when root is available synchronously', (WidgetTester tester) async {
    final Map<String, dynamic> rawData = <String, dynamic>{};
    final RestorationBucket root = RestorationBucket.root(manager: binding.restorationManager, rawData: rawData);
    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket>(root);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(binding.firstFrameIsDeferred, isFalse);

    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket!.restorationId, 'root-child');
    expect(rawData[childrenMapKey].containsKey('root-child'), isTrue);
  });

  testWidgets('does not insert root when restoration id is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: null,
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 0);
    expect(find.text('Hello'), findsOneWidget);
    expect(binding.firstFrameIsDeferred, isFalse);

    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket, isNull);

    // Change restoration id to non-null.
    final Completer<RestorationBucket> bucketCompleter = Completer<RestorationBucket>();
    binding.restorationManager.rootBucket = bucketCompleter.future;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket, isNull); // root bucket future has not completed yet.

    // Complete the future.
    final RestorationBucket root = RestorationBucket.root(manager: binding.restorationManager, rawData: <String, dynamic>{});
    bucketCompleter.complete(root);
    await tester.pump(const Duration(milliseconds: 100));

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket!.restorationId, 'root-child');

    // Change ID back to null.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: null,
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket, isNull);
  });

  testWidgets('injects root bucket when moved out of scope', (WidgetTester tester) async {
    final Key rootScopeKey = GlobalKey();
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> inScopeRawData = <String, dynamic>{};
    final RestorationBucket inScopeRootBucket = RestorationBucket.root(manager: manager, rawData: inScopeRawData);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnmanagedRestorationScope(
          bucket: inScopeRootBucket,
          child: RootRestorationScope(
            key: rootScopeKey,
            restorationId: 'root-child',
            child: const BucketSpy(
              child: Text('Hello'),
            ),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 0);
    expect(find.text('Hello'), findsOneWidget);
    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket!.restorationId, 'root-child');
    expect(inScopeRawData[childrenMapKey].containsKey('root-child'), isTrue);

    // Move out of scope.
    final Completer<RestorationBucket> bucketCompleter = Completer<RestorationBucket>();
    binding.restorationManager.rootBucket = bucketCompleter.future;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          key: rootScopeKey,
          restorationId: 'root-child',
          child: const BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);

    final Map<String, dynamic> outOfScopeRawData = <String, dynamic>{};
    final RestorationBucket outOfScopeRootBucket = RestorationBucket.root(manager: binding.restorationManager, rawData: outOfScopeRawData);
    bucketCompleter.complete(outOfScopeRootBucket);
    await tester.pump(const Duration(milliseconds: 100));

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket!.restorationId, 'root-child');
    expect(outOfScopeRawData[childrenMapKey].containsKey('root-child'), isTrue);
    expect(inScopeRawData, isEmpty);

    // Move into scope.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnmanagedRestorationScope(
          bucket: inScopeRootBucket,
          child: RootRestorationScope(
            key: rootScopeKey,
            restorationId: 'root-child',
            child: const BucketSpy(
              child: Text('Hello'),
            ),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket!.restorationId, 'root-child');
    expect(outOfScopeRawData, isEmpty);
    expect(inScopeRawData[childrenMapKey].containsKey('root-child'), isTrue);
  });

  testWidgets('injects new root when old one is decommissioned', (WidgetTester tester) async {
    final Map<String, dynamic> firstRawData = <String, dynamic>{};
    final RestorationBucket firstRoot = RestorationBucket.root(manager: binding.restorationManager, rawData: firstRawData);
    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket>(firstRoot);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    state.bucket!.write('foo', 42);
    expect(firstRawData[childrenMapKey]['root-child'][valuesMapKey]['foo'], 42);
    final RestorationBucket firstBucket = state.bucket!;

    // Replace with new root.
    final Map<String, dynamic> secondRawData = <String, dynamic>{
      childrenMapKey: <String, dynamic>{
        'root-child': <String, dynamic>{
          valuesMapKey: <String, dynamic>{
            'foo': 22,
          },
        },
      },
    };
    final RestorationBucket secondRoot = RestorationBucket.root(manager: binding.restorationManager, rawData: secondRawData);
    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket>(secondRoot);
    await tester.pump();
    firstRoot.dispose();

    expect(state.bucket, isNot(same(firstBucket)));
    expect(state.bucket!.read<int>('foo'), 22);
  });

  testWidgets('injects null when rootBucket is null', (WidgetTester tester) async {
    final Completer<RestorationBucket?> completer = Completer<RestorationBucket?>();
    binding.restorationManager.rootBucket = completer.future;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsNothing);

    completer.complete(null);
    await tester.pump(const Duration(milliseconds: 100));

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);

    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket, isNull);

    final RestorationBucket root = RestorationBucket.root(manager: binding.restorationManager, rawData: null);
    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket>(root);
    await tester.pump();

    expect(binding.restorationManager.rootBucketAccessed, 2);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket, isNotNull);
  });

  testWidgets('can switch to null', (WidgetTester tester) async {
    final RestorationBucket root = RestorationBucket.root(manager: binding.restorationManager, rawData: null);
    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket>(root);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RootRestorationScope(
          restorationId: 'root-child',
          child: BucketSpy(
            child: Text('Hello'),
          ),
        ),
      ),
    );

    expect(binding.restorationManager.rootBucketAccessed, 1);
    expect(find.text('Hello'), findsOneWidget);
    final BucketSpyState state = tester.state(find.byType(BucketSpy));
    expect(state.bucket, isNotNull);

    binding.restorationManager.rootBucket = SynchronousFuture<RestorationBucket?>(null);
    await tester.pump();
    root.dispose();

    expect(binding.restorationManager.rootBucketAccessed, 2);
    expect(find.text('Hello'), findsOneWidget);
    expect(state.bucket, isNull);
  });
}

class TestAutomatedTestWidgetsFlutterBinding extends AutomatedTestWidgetsFlutterBinding {
  late MockRestorationManager _restorationManager;

  @override
  MockRestorationManager get restorationManager => _restorationManager;

  @override
  TestRestorationManager createRestorationManager() {
    return TestRestorationManager();
  }

  int _deferred = 0;

  bool get firstFrameIsDeferred => _deferred > 0;

  @override
  void deferFirstFrame() {
    _deferred++;
    super.deferFirstFrame();
  }

  @override
  void allowFirstFrame() {
    _deferred--;
    super.allowFirstFrame();
  }
}
