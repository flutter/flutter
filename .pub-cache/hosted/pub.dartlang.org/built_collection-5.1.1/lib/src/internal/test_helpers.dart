// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../list.dart';
import '../list_multimap.dart';
import '../map.dart';
import '../set.dart';
import '../set_multimap.dart';

/// Internal only test helpers.
class BuiltCollectionTestHelpers {
  static BuiltList<int> overridenHashcodeBuiltList(
          Iterable iterable, int hashCode) =>
      OverriddenHashcodeBuiltList<int>(iterable, hashCode);

  static BuiltListMultimap<int, String> overridenHashcodeBuiltListMultimap(
          Object map, int hashCode) =>
      OverriddenHashcodeBuiltListMultimap<int, String>(map, hashCode);

  static BuiltListMultimap<String, String>
      overridenHashcodeBuiltListMultimapWithStringKeys(
              Object map, int hashCode) =>
          OverriddenHashcodeBuiltListMultimap<String, String>(map, hashCode);

  static BuiltMap<int, String> overridenHashcodeBuiltMap(
          Object map, int hashCode) =>
      OverriddenHashcodeBuiltMap<int, String>(map, hashCode);

  static BuiltMap<String, String> overridenHashcodeBuiltMapWithStringKeys(
          Object map, int hashCode) =>
      OverriddenHashcodeBuiltMap<String, String>(map, hashCode);

  static BuiltSet<int> overridenHashcodeBuiltSet(
          Iterable iterable, int hashCode) =>
      OverriddenHashcodeBuiltSet<int>(iterable, hashCode);

  static BuiltSetMultimap<int, String> overridenHashcodeBuiltSetMultimap(
          Object map, int hashCode) =>
      OverriddenHashcodeBuiltSetMultimap<int, String>(map, hashCode);

  static BuiltSetMultimap<String, String>
      overridenHashcodeBuiltSetMultimapWithStringKeys(
              Object map, int hashCode) =>
          OverriddenHashcodeBuiltSetMultimap<String, String>(map, hashCode);
}
