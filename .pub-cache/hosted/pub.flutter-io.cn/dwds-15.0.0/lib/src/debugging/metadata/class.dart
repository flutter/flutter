// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.import 'dart:async';

// @dart = 2.9

import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../debugging/classes.dart';
import '../../debugging/inspector.dart';
import '../../debugging/remote_debugger.dart';
import '../../loaders/strategy.dart';
import '../../services/chrome_debug_exception.dart';

/// Meta data for a remote Dart class in Chrome.
class ClassMetaData {
  /// The name of the JS constructor for the object.
  ///
  /// This may be a constructor for a Dart, but it's still a JS name. For
  /// example, 'Number', 'JSArray', 'Object'.
  final String jsName;

  /// The length of the object, if applicable.
  final int length;

  /// The dart type name for the object.
  ///
  /// For example, 'int', 'List<String>', 'Null'
  final String dartName;

  /// The library identifier, which is the URI of the library.
  final String libraryId;

  factory ClassMetaData(
      {Object jsName, Object libraryId, Object dartName, Object length}) {
    return ClassMetaData._(jsName as String, libraryId as String,
        dartName as String, int.tryParse('$length'));
  }

  ClassMetaData._(this.jsName, this.libraryId, this.dartName, this.length);

  /// Returns the ID of the class.
  ///
  /// Takes the form of 'libraryId:name'.
  String get id => '$libraryId:$jsName';

  /// Returns the [ClassMetaData] for the Chrome [remoteObject].
  ///
  /// Returns null if the [remoteObject] is not a Dart class.
  static Future<ClassMetaData> metaDataFor(RemoteDebugger remoteDebugger,
      RemoteObject remoteObject, AppInspector inspector) async {
    try {
      final evalExpression = '''
      function(arg) {
        const sdkUtils = ${globalLoadStrategy.loadModuleSnippet}('dart_sdk').dart;
        const classObject = sdkUtils.getReifiedType(arg);
        const isFunction = sdkUtils.AbstractFunctionType.is(classObject);
        const result = {};
        result['name'] = isFunction ? 'Function' : classObject.name;
        result['libraryId'] = sdkUtils.getLibraryUri(classObject);
        result['dartName'] = sdkUtils.typeName(classObject);
        result['length'] = arg['length'];
        return result;
      }
    ''';
      final result = await inspector.jsCallFunctionOn(
          remoteObject, evalExpression, [remoteObject],
          returnByValue: true);
      final metadata = result.value as Map;
      return ClassMetaData(
        jsName: metadata['name'],
        libraryId: metadata['libraryId'],
        dartName: metadata['dartName'],
        length: metadata['length'],
      );
    } on ChromeDebugException {
      return null;
    }
  }

  /// Return a [ClassRef] appropriate to this metadata.
  ClassRef get classRef => classRefFor(libraryId, dartName);

  /// True if this class refers to system maps, which are treated specially.
  ///
  /// Classes that implement Map or inherit from MapBase are still treated as
  /// plain objects.
  // TODO(alanknight): It may be that IdentityMap should not be treated as a
  // system map.
  bool get isSystemMap => jsName == 'LinkedMap' || jsName == 'IdentityMap';

  /// True if this class refers to system Lists, which are treated specially.
  bool get isSystemList => jsName == 'JSArray';
}
