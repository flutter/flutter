// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:matcher/matcher.dart';

/// Matcher for == and hashCode methods of a class.
///
/// To use, invoke areEqualityGroups with a list of equality groups where each
/// group contains objects that are supposed to be equal to each other, and
/// objects of different groups are expected to be unequal. For example:
///
///     expect({
///      'hello': ["hello", "h" + "ello"],
///      'world': ["world", "wor" + "ld"],
///      'three': [2, 1 + 1]
///     }, areEqualityGroups);
///
/// This tests that:
///
///    * comparing each object against itself returns true
///    * comparing each object against an instance of an incompatible class
///      returns false
///    * comparing each pair of objects within the same equality group returns
///      true
///    * comparing each pair of objects from different equality groups returns
///      false
///    * the hash codes of any two equal objects are equal
///    * equals implementation is idempotent
///
/// The format of the Map passed to expect is such that the map keys are used in
/// error messages to identify the group described by the map value.
///
/// When a test fails, the error message labels the objects involved in
/// the failed comparison as follows:
///
///     "`[group x, item j]`" refers to the ith item in the xth equality group,
///      where both equality groups and the items within equality groups are
///      numbered starting from 1.  When either a constructor argument or an
///      equal object is provided, that becomes group 1.
const Matcher areEqualityGroups = _EqualityGroupMatcher();

const _repetitions = 3;

class _EqualityGroupMatcher extends Matcher {
  const _EqualityGroupMatcher();

  static const failureReason = 'failureReason';

  @override
  Description describe(Description description) =>
      description.add('to be equality groups');

  @override
  bool matches(item, Map matchState) {
    try {
      _verifyEqualityGroups(item, matchState);
      return true;
    } on MatchError catch (e) {
      matchState[failureReason] = e.toString();
      return false;
    }
  }

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription.add(' ${matchState[failureReason]}');

  void _verifyEqualityGroups(
      Map<String?, List?>? equalityGroups, Map matchState) {
    if (equalityGroups == null) {
      throw MatchError('Equality Group must not be null');
    }
    final equalityGroupsCopy = <String, List>{};
    equalityGroups.forEach((String? groupName, List? group) {
      if (groupName == null) {
        throw MatchError('Group name must not be null');
      }
      if (group == null) {
        throw MatchError('Group must not be null');
      }
      equalityGroupsCopy[groupName] = List.from(group);
    });

    // Run the test multiple times to ensure deterministic equals
    for (var i = 0; i < _repetitions; i++) {
      _checkBasicIdentity(equalityGroupsCopy, matchState);
      _checkGroupBasedEquality(equalityGroupsCopy);
    }
  }

  void _checkBasicIdentity(Map<String, List> equalityGroups, Map matchState) {
    var flattened = equalityGroups.values.expand((group) => group);
    for (final item in flattened) {
      if (item == _NotAnInstance.equalToNothing) {
        throw MatchError(
            '$item must not be equal to an arbitrary object of another class');
      }

      if (item != item) {
        throw MatchError('$item must be equal to itself');
      }

      if (item.hashCode != item.hashCode) {
        throw MatchError('the implementation of hashCode of $item must '
            'be idempotent');
      }
    }
  }

  void _checkGroupBasedEquality(Map<String, List> equalityGroups) {
    equalityGroups.forEach((String groupName, List group) {
      var groupLength = group.length;
      for (var itemNumber = 0; itemNumber < groupLength; itemNumber++) {
        _checkEqualToOtherGroup(
            equalityGroups, groupLength, itemNumber, groupName);
        _checkUnequalToOtherGroups(equalityGroups, groupName, itemNumber);
      }
    });
  }

  void _checkUnequalToOtherGroups(
      Map<String, List> equalityGroups, String groupName, int itemNumber) {
    equalityGroups.forEach((String unrelatedGroupName, List unrelatedGroup) {
      if (groupName != unrelatedGroupName) {
        for (var unrelatedItemNumber = 0;
            unrelatedItemNumber < unrelatedGroup.length;
            unrelatedItemNumber++) {
          _expectUnrelated(equalityGroups, groupName, itemNumber,
              unrelatedGroupName, unrelatedItemNumber);
        }
      }
    });
  }

  void _checkEqualToOtherGroup(Map<String, List> equalityGroups,
      int groupLength, int itemNumber, String groupName) {
    for (var relatedItemNumber = 0;
        relatedItemNumber < groupLength;
        relatedItemNumber++) {
      if (itemNumber != relatedItemNumber) {
        _expectRelated(
            equalityGroups, groupName, itemNumber, relatedItemNumber);
      }
    }
  }

  void _expectRelated(Map<String, List> equalityGroups, String groupName,
      int itemNumber, int relatedItemNumber) {
    var itemInfo = _createItem(equalityGroups, groupName, itemNumber);
    var relatedInfo = _createItem(equalityGroups, groupName, relatedItemNumber);

    if (itemInfo.value != relatedInfo.value) {
      throw MatchError('$itemInfo must be equal to $relatedInfo');
    }

    if (itemInfo.value.hashCode != relatedInfo.value.hashCode) {
      throw MatchError(
          'the hashCode (${itemInfo.value.hashCode}) of $itemInfo must '
          'be equal to the hashCode (${relatedInfo.value.hashCode}) of '
          '$relatedInfo}');
    }
  }

  void _expectUnrelated(Map<String, List> equalityGroups, String groupName,
      int itemNumber, String unrelatedGroupName, int unrelatedItemNumber) {
    var itemInfo = _createItem(equalityGroups, groupName, itemNumber);
    var unrelatedInfo =
        _createItem(equalityGroups, unrelatedGroupName, unrelatedItemNumber);

    if (itemInfo.value == unrelatedInfo.value) {
      throw MatchError('$itemInfo must not be equal to $unrelatedInfo)');
    }
  }

  _Item _createItem(
          Map<String, List> equalityGroups, String groupName, int itemNumber) =>
      _Item(equalityGroups[groupName]![itemNumber], groupName, itemNumber);
}

class _NotAnInstance {
  const _NotAnInstance._();
  static const equalToNothing = _NotAnInstance._();
}

class _Item {
  _Item(this.value, this.groupName, this.itemNumber);

  final Object? value;
  final String groupName;
  final int itemNumber;

  @override
  String toString() => "$value [group '$groupName', item ${itemNumber + 1}]";
}

class MatchError extends Error {
  /// The [message] describes the match error.
  MatchError([this.message = '']);

  final String message;

  @override
  String toString() => message;
}
