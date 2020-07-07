// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'restoration.dart';

void main() {
  test('root bucket values', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    expect(bucket.id, const RestorationId('root'));
    expect(bucket.debugOwner, manager);

    // Bucket contains expected values from rawData.
    expect(bucket.get<int>(const RestorationId('value1')), 10);
    expect(bucket.get<String>(const RestorationId('value2')), 'Hello');
    expect(bucket.get<String>(const RestorationId('value3')), isNull); // Does not exist.
    expect(manager.updateScheduled, isFalse);

    // Can overwrite existing value.
    bucket.put<int>(const RestorationId('value1'), 22);
    expect(manager.updateScheduled, isTrue);
    expect(bucket.get<int>(const RestorationId('value1')), 22);
    manager.runFinalizers();
    expect(rawData[valuesMapKey]['value1'], 22);
    expect(manager.updateScheduled, isFalse);

    // Can add a new value.
    bucket.put<bool>(const RestorationId('value3'), true);
    expect(manager.updateScheduled, isTrue);
    expect(bucket.get<bool>(const RestorationId('value3')), true);
    manager.runFinalizers();
    expect(rawData[valuesMapKey]['value3'], true);
    expect(manager.updateScheduled, isFalse);

    // Can remove existing value.
    expect(bucket.remove<int>(const RestorationId('value1')), 22);
    expect(manager.updateScheduled, isTrue);
    expect(bucket.get<int>(const RestorationId('value1')), isNull); // Does not exist anymore.
    manager.runFinalizers();
    expect(rawData[valuesMapKey].containsKey('value1'), isFalse);
    expect(manager.updateScheduled, isFalse);

    // Removing non-existing value is no-op.
    expect(bucket.remove<Object>(const RestorationId('value4')), isNull);
    expect(manager.updateScheduled, isFalse);

    // Can store null.
    bucket.put<bool>(const RestorationId('value4'), null);
    expect(manager.updateScheduled, isTrue);
    expect(bucket.get<int>(const RestorationId('value4')), null);
    manager.runFinalizers();
    expect(rawData[valuesMapKey].containsKey('value4'), isTrue);
    expect(rawData[valuesMapKey]['value4'], null);
    expect(manager.updateScheduled, isFalse);
  });

  test('child bucket values', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rootRawData = _createRawDataSet();
    final Map<String, dynamic> childRawData = castToMap<String, dynamic>(rootRawData[childrenMapKey]['child1']);
    final Object debugOwner = Object();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rootRawData);
    final RestorationBucket child = RestorationBucket.child(
      id: const RestorationId('child1'),
      parent: root,
      debugOwner: debugOwner,
    );

    expect(child.id, const RestorationId('child1'));
    expect(child.debugOwner, debugOwner);

    // Bucket contains expected values from rawData.
    expect(child.get<int>(const RestorationId('foo')), 22);
    expect(child.get<String>(const RestorationId('bar')), isNull); // Does not exist.
    expect(manager.updateScheduled, isFalse);

    // Can overwrite existing value.
    child.put<int>(const RestorationId('foo'), 44);
    expect(manager.updateScheduled, isTrue);
    expect(child.get<int>(const RestorationId('foo')), 44);
    manager.runFinalizers();
    expect(childRawData[valuesMapKey]['foo'], 44);
    expect(manager.updateScheduled, isFalse);

    // Can add a new value.
    child.put<bool>(const RestorationId('value3'), true);
    expect(manager.updateScheduled, isTrue);
    expect(child.get<bool>(const RestorationId('value3')), true);
    manager.runFinalizers();
    expect(childRawData[valuesMapKey]['value3'], true);
    expect(manager.updateScheduled, isFalse);

    // Can remove existing value.
    expect(child.remove<int>(const RestorationId('foo')), 44);
    expect(manager.updateScheduled, isTrue);
    expect(child.get<int>(const RestorationId('foo')), isNull); // Does not exist anymore.
    manager.runFinalizers();
    expect(childRawData.containsKey('foo'), isFalse);
    expect(manager.updateScheduled, isFalse);

    // Removing non-existing value is no-op.
    expect(child.remove<Object>(const RestorationId('value4')), isNull);
    expect(manager.updateScheduled, isFalse);

    // Can store null.
    child.put<bool>(const RestorationId('value4'), null);
    expect(manager.updateScheduled, isTrue);
    expect(child.get<int>(const RestorationId('value4')), null);
    manager.runFinalizers();
    expect(childRawData[valuesMapKey].containsKey('value4'), isTrue);
    expect(childRawData[valuesMapKey]['value4'], null);
    expect(manager.updateScheduled, isFalse);
  });

  test('claim child with exisiting data', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    final Object debugOwner = Object();
    final RestorationBucket child = bucket.claimChild(const RestorationId('child1'), debugOwner: debugOwner);

    expect(manager.updateScheduled, isFalse);
    expect(child.id, const RestorationId('child1'));
    expect(child.debugOwner, debugOwner);

    expect(child.get<int>(const RestorationId('foo')), 22);
    child.put(const RestorationId('bar'), 44);
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(rawData[childrenMapKey]['child1'][valuesMapKey]['bar'], 44);
    expect(manager.updateScheduled, isFalse);
  });

  test('claim child with no exisiting data', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    expect(rawData[childrenMapKey].containsKey('child2'), isFalse);

    final Object debugOwner = Object();
    final RestorationBucket child = bucket.claimChild(const RestorationId('child2'), debugOwner: debugOwner);

    expect(manager.updateScheduled, isTrue);
    expect(child.id, const RestorationId('child2'));
    expect(child.debugOwner, debugOwner);

    child.put(const RestorationId('foo'), 55);
    expect(child.get<int>(const RestorationId('foo')), 55);
    manager.runFinalizers();

    expect(manager.updateScheduled, isFalse);
    expect(rawData[childrenMapKey].containsKey('child2'), isTrue);
    expect(rawData[childrenMapKey]['child2'][valuesMapKey]['foo'], 55);
  });

  test('claim child that is already claimed throws if not given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'FirstClaim');

    expect(manager.updateScheduled, isFalse);
    expect(child1.id, const RestorationId('child1'));
    expect(child1.get<int>(const RestorationId('foo')), 22);

    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    final RestorationBucket child2 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'SecondClaim');
    expect(child2.id, const RestorationId('child1'));
    expect(child2.get<int>(const RestorationId('foo')), isNull); // Value does not exist in this child.

    // child1 is not given up before running finalizers.
    try {
      manager.runFinalizers();
      fail('expected error');
    } on FlutterError catch (e) {
      expect(
        e.message,
        'Multiple owners claimed child RestorationBuckets with the same ID.\n'
        'The following owners claimed child RestorationBuckets with id "RestorationId(child1)" from '
        'the parent RestorationBucket(id: RestorationId(root), owner: MockManager):\n'
        ' * SecondClaim\n'
        ' * FirstClaim (current owner)',
      );
    }
  });

  test('claim child that is already claimed does not throw if given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'FirstClaim');

    expect(manager.updateScheduled, isFalse);
    expect(child1.id, const RestorationId('child1'));
    expect(child1.get<int>(const RestorationId('foo')), 22);

    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    final RestorationBucket child2 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'SecondClaim');
    expect(child2.id, const RestorationId('child1'));
    expect(child2.get<int>(const RestorationId('foo')), isNull); // Value does not exist in this child.
    child2.put<int>(const RestorationId('bar'), 55);

    // give up child1.
    child1.dispose();
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);
    expect(rawData[childrenMapKey]['child1'][valuesMapKey].containsKey('foo'), isFalse);
    expect(rawData[childrenMapKey]['child1'][valuesMapKey]['bar'], 55);
  });

  test('claiming a claimed child twice and only giving it up once throws', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'FirstClaim');
    expect(child1.id, const RestorationId('child1'));
    final RestorationBucket child2 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'SecondClaim');
    expect(child2.id, const RestorationId('child1'));
    child1.dispose();
    final RestorationBucket child3 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'ThirdClaim');
    expect(child3.id, const RestorationId('child1'));
    expect(manager.updateScheduled, isTrue);
    expect(() => manager.runFinalizers(), throwsFlutterError);
  });

  test('unclaiming and then claiming same id gives fresh bucket', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket bucket = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'FirstClaim');
    expect(manager.updateScheduled, isFalse);
    expect(child1.get<int>(const RestorationId('foo')), 22);
    child1.dispose();
    expect(manager.updateScheduled, isTrue);
    final RestorationBucket child2 = bucket.claimChild(const RestorationId('child1'), debugOwner: 'SecondClaim');
    expect(child2.get<int>(const RestorationId('foo')), isNull);
  });

  test('cleans up raw data if last value/child is dropped', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    expect(rawData.containsKey(childrenMapKey), isTrue);
    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner');
    child.dispose();
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(rawData.containsKey(childrenMapKey), isFalse);

    expect(rawData.containsKey(valuesMapKey), isTrue);
    expect(root.remove<int>(const RestorationId('value1')), 10);
    expect(root.remove<String>(const RestorationId('value2')), 'Hello');
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(rawData.containsKey(valuesMapKey), isFalse);
  });

  test('dispose deletes data', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child1OfChild1 = child1.claimChild(const RestorationId('child1OfChild1'), debugOwner: 'owner1.1');
    final RestorationBucket child2OfChild1 = child1.claimChild(const RestorationId('child2OfChild1'), debugOwner: 'owner1.2');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child2'), debugOwner: 'owner2');

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey].containsKey('child1'), isTrue);
    expect(rawData[childrenMapKey].containsKey('child2'), isTrue);

    child1.dispose();
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey].containsKey('child1'), isFalse);

    child2.dispose();
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData.containsKey(childrenMapKey), isFalse);

    // Children of child1 continue to function, but no longer in the tree.
    child1OfChild1.put(const RestorationId('foo'), 10);
    child2OfChild1.put(const RestorationId('bar'), 20);
    expect(child1OfChild1.get<int>(const RestorationId('foo')), 10);
    expect(child2OfChild1.get<int>(const RestorationId('bar')), 20);
    expect(manager.updateScheduled, isFalse);
  });

  test('rename is no-op if same id', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');

    expect(manager.updateScheduled, isFalse);
    expect(child.id, const RestorationId('child1'));
    child.rename(const RestorationId('child1'));
    expect(manager.updateScheduled, isFalse);
    expect(child.id, const RestorationId('child1'));
    expect(rawData[childrenMapKey].containsKey('child1'), isTrue);
  });

  test('rename to unused id', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final Object rawChildData = rawData[childrenMapKey]['child1'];
    expect(rawChildData, isNotNull);

    expect(manager.updateScheduled, isFalse);
    expect(child.id, const RestorationId('child1'));
    child.rename(const RestorationId('new-name'));
    expect(child.id, const RestorationId('new-name'));

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey].containsKey('child1'), isFalse);
    expect(rawData[childrenMapKey]['new-name'], rawChildData);
  });

  test('rename to used id throws if id is not given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child2'), debugOwner: 'owner1');
    manager.runFinalizers();

    expect(child1.id, const RestorationId('child1'));
    expect(child2.id, const RestorationId('child2'));
    child2.rename(const RestorationId('child1'));
    expect(child2.id, const RestorationId('child1'));

    expect(manager.updateScheduled, isTrue);
    expect(() => manager.runFinalizers(), throwsFlutterError);
  });

  test('rename to used id does not throw if id is given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child2'), debugOwner: 'owner1');
    manager.runFinalizers();

    final Object rawChild1Data = rawData[childrenMapKey]['child1'];
    expect(rawChild1Data, isNotNull);
    final Object rawChild2Data = rawData[childrenMapKey]['child2'];
    expect(rawChild2Data, isNotNull);

    expect(child1.id, const RestorationId('child1'));
    expect(child2.id, const RestorationId('child2'));
    child2.rename(const RestorationId('child1'));
    expect(child2.id, const RestorationId('child1'));
    expect(child1.id, const RestorationId('child1'));

    child1.dispose();

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey]['child1'], rawChild2Data);
    expect(rawData[childrenMapKey].containsKey('child2'), isFalse);
  });

  test('renaming a to be added child', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final Object rawChild1Data = rawData[childrenMapKey]['child1'];
    expect(rawChild1Data, isNotNull);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');

    child2.rename(const RestorationId('foo'));

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(child1.id, const RestorationId('child1'));
    expect(child2.id, const RestorationId('foo'));

    expect(rawData[childrenMapKey]['child1'], rawChild1Data);
    expect(rawData[childrenMapKey]['foo'], isEmpty); // new bucket
  });

  test('adopt is no-op if same parent', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');

    root.adoptChild(child1);
    expect(manager.updateScheduled, isFalse);
    expect(rawData[childrenMapKey].containsKey('child1'), isTrue);
  });

  test('adopt fresh child', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = RestorationBucket.empty(id: const RestorationId('fresh-child'), debugOwner: 'owner1');

    root.adoptChild(child);
    expect(manager.updateScheduled, isTrue);

    child.put(const RestorationId('value'), 22);

    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey].containsKey('fresh-child'), isTrue);
    expect(rawData[childrenMapKey]['fresh-child'][valuesMapKey]['value'], 22);

    child.put(const RestorationId('bar'), 'blabla');
    expect(manager.updateScheduled, isTrue);
  });

  test('adopt child that already had a parent', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket childOfChild = child.claimChild(const RestorationId('childOfChild'), debugOwner: 'owner2');
    childOfChild.put<String>(const RestorationId('foo'), 'bar');

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    final Object childOfChildData = rawData[childrenMapKey]['child1'][childrenMapKey]['childOfChild'];
    expect(childOfChildData, isNotEmpty);

    root.adoptChild(childOfChild);
    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey]['child1'].containsKey(childrenMapKey), isFalse); // child1 has no children anymore.
    expect(rawData[childrenMapKey]['childOfChild'], childOfChildData);
  });

  test('adopting child throws if id is already in use and not given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket childOfChild = child.claimChild(const RestorationId('child1'), debugOwner: 'owner2');
    childOfChild.put<String>(const RestorationId('foo'), 'bar');

    root.adoptChild(childOfChild);
    expect(manager.updateScheduled, isTrue);
    expect(() => manager.runFinalizers(), throwsFlutterError);
  });

  test('adopting child does not throw if id is already in use and given up', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket childOfChild = child.claimChild(const RestorationId('child1'), debugOwner: 'owner2');
    childOfChild.put<String>(const RestorationId('foo'), 'bar');

    final Object childOfChildData = rawData[childrenMapKey]['child1'][childrenMapKey]['child1'];
    expect(childOfChildData, isNotEmpty);

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    root.adoptChild(childOfChild);
    expect(manager.updateScheduled, isTrue);
    child.dispose();
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey]['child1'], childOfChildData);
  });

  test('adopting a to-be-added child under an already in use id', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child2'), debugOwner: 'owner1');

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    final RestorationBucket child1OfChild1 = child1.claimChild(const RestorationId('child2'), debugOwner: 'owner2');
    child1OfChild1.put<String>(const RestorationId('hello'), 'world');
    final RestorationBucket child2OfChild1 = child1.claimChild(const RestorationId('child2'), debugOwner: 'owner2');
    child2OfChild1.put<String>(const RestorationId('foo'), 'bar');

    root.adoptChild(child2OfChild1);
    child2.dispose();

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    expect(rawData[childrenMapKey]['child2'][valuesMapKey]['foo'], 'bar');
    expect(rawData[childrenMapKey]['child1'][childrenMapKey]['child2'][valuesMapKey]['hello'], 'world');
  });

  test('decommission drops itself from parent and notifies all listeners', () {
    final MockRestorationManager manager = MockRestorationManager();
    final Map<String, dynamic> rawData = _createRawDataSet();
    final RestorationBucket root = RestorationBucket.root(manager: manager, rawData: rawData);

    final RestorationBucket child1 = root.claimChild(const RestorationId('child1'), debugOwner: 'owner1');
    final RestorationBucket child2 = root.claimChild(const RestorationId('child2'), debugOwner: 'owner1');
    final RestorationBucket childOfChild1 = child1.claimChild(const RestorationId('child1.1'), debugOwner: 'owner1');
    final RestorationBucket childOfChildOfChild1 = childOfChild1.claimChild(const RestorationId('child1.1.1'), debugOwner: 'owner1');

    expect(manager.updateScheduled, isTrue);
    manager.runFinalizers();
    expect(manager.updateScheduled, isFalse);

    bool rootDecommissioned = false;
    root.addListener(() {
      rootDecommissioned = true;
    });
    bool child1Decommissioned = false;
    child1.addListener(() {
      child1Decommissioned = true;
    });
    bool child2Decommissioned = false;
    child2.addListener(() {
      child2Decommissioned = true;
    });
    bool childOfChild1Decommissioned = false;
    childOfChild1.addListener(() {
      childOfChild1Decommissioned = true;
    });
    bool childOfChildOfChild1Decommissioned = false;
    childOfChildOfChild1.addListener(() {
      childOfChildOfChild1Decommissioned = true;
    });

    expect(rawData[childrenMapKey].containsKey('child1'), isTrue);

    child1.decommission();
    expect(rootDecommissioned, isFalse);
    expect(child2Decommissioned, isFalse);
    expect(child1Decommissioned, isTrue);
    expect(childOfChild1Decommissioned, isTrue);
    expect(childOfChildOfChild1Decommissioned, isTrue);

    expect(rawData[childrenMapKey].containsKey('child1'), isFalse);
  });
}

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
        },
      },
    },
  };
}
