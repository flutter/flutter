// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Functions for converting between the different object references we use.
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Convert [argument] to a form usable in WIP evaluation calls.
///
/// The [argument] should be either a RemoteObject or a simple object that can
/// be passed through the protocol directly.
///
/// Note that this doesn't agree with the Chrome Protocol type CallArgument -
/// it's just a Map corresponding to a RemoteObject. But this seems to work
/// consistently where the callArgument format doesn't, at least if we're
/// using the `arguments` pseudo-variable in JS instead of passing directly
/// as real arguments.
Map<String, Object?> callArgumentFor(Object argument) {
  if (argument is RemoteObject) {
    return _isPrimitive(argument)
        ? _callArgumentForPrimitive(argument.value)
        : _callArgumentForRemote(argument);
  } else {
    return _callArgumentForPrimitive(argument);
  }
}

/// True if [remote] represents a primitive
bool _isPrimitive(RemoteObject remote) {
  final id = remote.objectId;
  return id == null || isStringId(id) || id.startsWith('objects/');
}

/// A List of Chrome RemoteObjects from Dart object Ids [dartIds].
///
/// See [remoteObjectFor] for the accepted ID format.
List<RemoteObject> remoteObjectsFor(Iterable<String> dartIds) {
  return dartIds.map(remoteObjectFor).toList();
}

/// A Chrome RemoteObject from a Dart object Id [dartId].
///
/// We expect [dartId] to be one of the following forms.
///   * Chrome objectId - e.g. '{"injectedScriptId":1,"id":1}'
///   * Our fabricated string Id - e.g. '#StringInstanceRef#actualString'
///   * Dart fabricated IDs - e.g.  objects/int-8765
///
/// Note that this does NOT accept a Dart library URI, which can be used as an
/// InstanceRef identifier in the protocol. Libraries aren't first class, and
/// must be handled separately.
RemoteObject remoteObjectFor(String dartId) {
  final data = <String, Object?>{};
  data['objectId'] = dartId;
  if (isStringId(dartId)) {
    data['type'] = 'string';
    data['value'] = _stringFromDartId(dartId);
  } else if (isDoubleId(dartId)) {
    data['type'] = 'number';
    data['value'] = _doubleFromDartId(dartId);
  } else if (isIntId(dartId)) {
    data['type'] = 'number';
    data['value'] = _intFromDartId(dartId);
  } else if (isBoolId(dartId)) {
    data['type'] = 'boolean';
    data['value'] = _boolFromDartId(dartId);
  } else if (dartId == _nullId) {
    data['type'] = 'undefined';
    data['value'] = null;
  } else {
    data['type'] = 'object';
  }
  return RemoteObject(data);
}

/// A Dart object Id appropriate for [argument].
///
/// This will work for simple values, RemoteObject, and Maps representations of
/// RemoteObjects.
String dartIdFor(Object? argument) {
  if (argument == null) {
    return _nullId;
  }
  if (argument is double) {
    return '$_prefixForDoubleIds$argument';
  }
  if (argument is int) {
    return '$_prefixForIntIds$argument';
  }
  if (argument is bool) {
    return '$_prefixForBoolIds$argument';
  }
  if (argument is String) {
    return '$_prefixForStringIds$argument';
  }
  if (argument is RemoteObject) {
    if (argument.objectId == null) {
      throw ArgumentError.value(argument, 'objectId', 'No objectId found');
    }
    return argument.objectId!;
  }
  if (argument is Map<String, dynamic>) {
    final id = argument['objectId'] as String?;
    if (id == null) {
      throw ArgumentError.value(argument, 'objectId', 'No objectId found');
    }
    return id;
  }
  throw ArgumentError.value(argument, 'objectId', 'No objectId found');
}

/// Converts a Dart object Id for a String to the underlying string.
///
/// If the ID is not for a String, throws ArgumentError. If you don't know what
/// the ID represents, use a more general API like [remoteObjectFor] and if it
/// is a primitive, you can get the value from the resulting [RemoteObject].
String stringFromDartId(String dartId) {
  if (!isStringId(dartId)) {
    throw ArgumentError.value(
        dartId, 'dart object ID', 'Expected a valid ID for a String');
  }
  return _stringFromDartId(dartId);
}

/// Is [dartId] an Id for a String.
bool isStringId(String dartId) => dartId.startsWith(_prefixForStringIds);

/// Is [dartId] an Id for a boolean.
bool isBoolId(String dartId) => dartId.startsWith(_prefixForBoolIds);

/// Is [dartId] an Id for a int.
bool isIntId(String dartId) => dartId.startsWith(_prefixForIntIds);

/// Is [dartId] an Id for a double.
bool isDoubleId(String dartId) => dartId.startsWith(_prefixForDoubleIds);

/// Is [dartId] an Id for a Dart library.
bool isLibraryId(String dartId) => _uriPrefixes.any(dartId.startsWith);

/// A Map representing a RemoteObject for a primitive object.
Map<String, Object?> _callArgumentForPrimitive(Object? primitive) {
  return {'type': _jsTypeOf(primitive), 'value': primitive};
}

/// A Map representing a RemoteObject from an actual RemoteObject.
Map<String, Object?> _callArgumentForRemote(RemoteObject remote) {
  return {'type': 'object', 'objectId': remote.objectId};
}

/// The JS type name to use in a RemoteObject reference to [object].
String _jsTypeOf(Object? object) {
  if (object == null) return 'undefined';
  if (object is String) return 'string';
  if (object is num) return 'num';
  if (object is bool) return 'bool';
  return 'object';
}

/// Prefixes we use to identify if a Dart ID is a library URI.
const _uriPrefixes = ['dart:', 'package:', 'org-dartlang-app:'];

/// Convert [dartIdForString] to its corresponding String.
String _stringFromDartId(String dartIdForString) =>
    dartIdForString.substring(_prefixForStringIds.length);

/// Convert [dartIdForInt] to its corresponding int.
int? _intFromDartId(String dartIdForInt) =>
    int.tryParse(dartIdForInt.substring(_prefixForIntIds.length));

/// Convert [dartIdForDouble] to its corresponding double.
double? _doubleFromDartId(String dartIdForDouble) =>
    double.tryParse(dartIdForDouble.substring(_prefixForDoubleIds.length));

/// Convert [dartIdForBool] to its corresponding boolean.
bool _boolFromDartId(String dartIdForBool) =>
    dartIdForBool.substring(_prefixForBoolIds.length) == 'true';

/// Chrome doesn't give us an objectId for a String. So we use the string
/// as its own ID, with a prefix.
///
/// This should not be confused with any
/// other object Ids, as those will be Chrome objectIds, which are
/// opaque, but are JSON serialized objects of the form
/// "{\"injectedScriptId\":1,\"id\":1}".
const _prefixForStringIds = '#StringInstanceRef#';

/// The prefix the Dart VM uses for ints, followed by a string representation of
/// the number.
const _prefixForIntIds = 'objects/int-';

/// The prefix we use for doubles, followed by a string representation of
/// the number.
const _prefixForDoubleIds = 'objects/double-';

/// The prefix the Dart VM uses for booleans, followed by 'true' or 'false'.
const _prefixForBoolIds = 'objects/bool-';

/// The object id the Dart VM uses for null.
const _nullId = 'objects/null';
