// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:pub_semver/pub_semver.dart';

/// A Dart SDK installed in a specified location.
abstract class DartSdk {
  /// The short name of the dart SDK 'async' library.
  static const String DART_ASYNC = "dart:async";

  /// The short name of the dart SDK 'core' library.
  static const String DART_CORE = "dart:core";

  /// The short name of the dart SDK 'html' library.
  static const String DART_HTML = "dart:html";

  /// The prefix shared by all dart library URIs.
  static const String DART_LIBRARY_PREFIX = "dart:";

  /// The version number that is returned when the real version number could not
  /// be determined.
  static const String DEFAULT_VERSION = "0";

  /// Return the content of the `allowed_experiments.json` file, or `null`
  /// if the file cannot be read, e.g. does not exist.
  String? get allowedExperimentsJson;

  /// Return the language version of this SDK, or throws an exception.
  ///
  /// The language version has only major/minor components, the patch number
  /// is always zero, because the patch number does not change the language.
  Version get languageVersion;

  /// Return a list containing all of the libraries defined in this SDK.
  List<SdkLibrary> get sdkLibraries;

  /// Return the revision number of this SDK, or `"0"` if the revision number
  /// cannot be discovered.
  String get sdkVersion;

  /// Return a list containing the library URI's for the libraries defined in
  /// this SDK.
  List<String> get uris;

  /// Return a source representing the given 'file:' [uri] if the file is in
  /// this SDK, or `null` if the file is not in this SDK.
  Source? fromFileUri(Uri uri);

  /// Return the library representing the library with the given 'dart:' [uri],
  /// or `null` if the given URI does not denote a library in this SDK.
  SdkLibrary? getSdkLibrary(String uri);

  /// Return the source representing the library with the given 'dart:' [uri],
  /// or `null` if the given URI does not denote a library in this SDK.
  Source? mapDartUri(String uri);

  /// Return the `dart` URI representing the given [path] if the file is in
  /// this SDK, or `null` if the file is not in this SDK.
  Uri? pathToUri(String path);
}

/// Manages the DartSdk's that have been created. Clients need to create
/// multiple SDKs when the analysis options associated with those SDK's contexts
/// will produce different analysis results.
class DartSdkManager {
  /// The absolute path to the directory containing the default SDK.
  final String defaultSdkDirectory;

  /// A table mapping (an encoding of) analysis options and SDK locations to the
  /// DartSdk from that location that has been configured with those options.
  Map<SdkDescription, DartSdk> sdkMap = HashMap<SdkDescription, DartSdk>();

  /// Initialize a newly created manager.
  DartSdkManager(this.defaultSdkDirectory, [@deprecated bool? canUseSummaries]);

  /// Return any SDK that has been created, or `null` if no SDKs have been
  /// created.
  DartSdk? get anySdk {
    if (sdkMap.isEmpty) {
      return null;
    }
    return sdkMap.values.first;
  }

  /// Return a list of the descriptors of the SDKs that are currently being
  /// managed.
  List<SdkDescription> get sdkDescriptors => sdkMap.keys.toList();

  /// Return the Dart SDK that is appropriate for the given SDK [description].
  /// If such an SDK has not yet been created, then the [ifAbsent] function will
  /// be invoked to create it.
  DartSdk getSdk(SdkDescription description, DartSdk Function() ifAbsent) {
    return sdkMap.putIfAbsent(description, ifAbsent);
  }
}

/// A map from Dart library URI's to the [SdkLibraryImpl] representing that
/// library.
class LibraryMap {
  /// A table mapping Dart library URI's to the library.
  final Map<String, SdkLibraryImpl> _libraryMap = <String, SdkLibraryImpl>{};

  /// Return a list containing all of the sdk libraries in this mapping.
  List<SdkLibraryImpl> get sdkLibraries => List.from(_libraryMap.values);

  /// Return a list containing the library URI's for which a mapping is
  /// available.
  List<String> get uris => _libraryMap.keys.toList();

  /// Return info for debugging https://github.com/dart-lang/sdk/issues/35226.
  Map<String, Object> debugInfo() {
    var map = <String, Object>{};
    for (var entry in _libraryMap.entries) {
      var uri = entry.key;
      var lib = entry.value;
      map[uri] = <String, Object>{
        'path': lib.path,
        'shortName': lib.shortName,
      };
    }
    return map;
  }

  /// Return the library with the given 'dart:' [uri], or `null` if the URI does
  /// not map to a library.
  SdkLibrary? getLibrary(String uri) => _libraryMap[uri];

  /// Set the library with the given 'dart:' [uri] to the given [library].
  void setLibrary(String dartUri, SdkLibraryImpl library) {
    _libraryMap[dartUri] = library;
  }

  /// Return the number of library URI's for which a mapping is available.
  int size() => _libraryMap.length;
}

/// A description of a [DartSdk].
class SdkDescription {
  /// The path of the SDK.
  final String path;

  SdkDescription(this.path);

  @override
  int get hashCode {
    return path.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is SdkDescription) {
      return other.path == path;
    }
    return false;
  }

  @override
  String toString() {
    return path;
  }
}

class SdkLibrariesReader_LibraryBuilder extends RecursiveAstVisitor<void> {
  /// The prefix added to the name of a library to form the URI used in code to
  /// reference the library.
  static const String _LIBRARY_PREFIX = "dart:";

  /// The name of the optional parameter used to indicate whether the library is
  /// an implementation library.
  static const String _IMPLEMENTATION = "implementation";

  /// The name of the optional parameter used to specify the path used when
  /// compiling for dart2js.
  static const String _DART2JS_PATH = "dart2jsPath";

  /// The name of the optional parameter used to indicate whether the library is
  /// documented.
  static const String _DOCUMENTED = "documented";

  /// The name of the optional parameter used to specify the category of the
  /// library.
  static const String _CATEGORIES = "categories";

  /// The name of the optional parameter used to specify the platforms on which
  /// the library can be used.
  static const String _PLATFORMS = "platforms";

  /// The value of the [PLATFORMS] parameter used to specify that the library
  /// can be used on the VM.
  static const String _VM_PLATFORM = "VM_PLATFORM";

  /// The library map that is populated by visiting the AST structure parsed
  /// from the contents of the libraries file.
  final LibraryMap _librariesMap = LibraryMap();

  /// Return the library map that was populated by visiting the AST structure
  /// parsed from the contents of the libraries file.
  LibraryMap get librariesMap => _librariesMap;

  // To be backwards-compatible the new categories field is translated to
  // an old approximation.
  String convertCategories(String categories) {
    switch (categories) {
      case "":
        return "Internal";
      case "Client":
        return "Client";
      case "Server":
        return "Server";
      case "Client,Server":
        return "Shared";
      case "Client,Server,Embedded":
        return "Shared";
    }
    return "Shared";
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    var key = node.key as SimpleStringLiteral;
    var libraryName = "$_LIBRARY_PREFIX${key.value}";

    Expression value = node.value;
    if (value is InstanceCreationExpression) {
      SdkLibraryImpl library = SdkLibraryImpl(libraryName);
      List<Expression> arguments = value.argumentList.arguments;
      for (Expression argument in arguments) {
        if (argument is SimpleStringLiteral) {
          library.path = argument.value;
        } else if (argument is NamedExpression) {
          String name = argument.name.label.name;
          Expression expression = argument.expression;
          if (name == _CATEGORIES) {
            var value = (expression as StringLiteral).stringValue!;
            library.category = convertCategories(value);
          } else if (name == _IMPLEMENTATION) {
            library._implementation = (expression as BooleanLiteral).value;
          } else if (name == _DOCUMENTED) {
            library.documented = (expression as BooleanLiteral).value;
          } else if (name == _PLATFORMS) {
            if (expression is SimpleIdentifier) {
              String identifier = expression.name;
              if (identifier == _VM_PLATFORM) {
                library.setVmLibrary();
              } else {
                library.setDart2JsLibrary();
              }
            }
          } else if (name == _DART2JS_PATH) {
            if (expression is SimpleStringLiteral) {
              library.path = expression.value;
            }
          }
        }
      }
      _librariesMap.setLibrary(libraryName, library);
    }
  }
}

/// Represents a single library in the SDK
abstract class SdkLibrary {
  /// Return the name of the category containing the library.
  String get category;

  /// Return `true` if this library can be compiled to JavaScript by dart2js.
  bool get isDart2JsLibrary;

  /// Return `true` if the library is documented.
  bool get isDocumented;

  /// Return `true` if the library is an implementation library.
  bool get isImplementation;

  /// Return `true` if library is internal can be used only by other SDK
  /// libraries.
  bool get isInternal;

  /// Return `true` if this library can be used for both client and server.
  bool get isShared;

  /// Return `true` if this library can be run on the VM.
  bool get isVmLibrary;

  /// Return the path to the file defining the library. The path is relative to
  /// the `lib` directory within the SDK.
  String get path;

  /// Return the short name of the library. This is the URI of the library,
  /// including `dart:`.
  String get shortName;
}

/// The information known about a single library within the SDK.
class SdkLibraryImpl implements SdkLibrary {
  /// The bit mask used to access the bit representing the flag indicating
  /// whether a library is intended to work on the dart2js platform.
  static int DART2JS_PLATFORM = 1;

  /// The bit mask used to access the bit representing the flag indicating
  /// whether a library is intended to work on the VM platform.
  static int VM_PLATFORM = 2;

  @override
  final String shortName;

  /// The path to the file defining the library. The path is relative to the
  /// 'lib' directory within the SDK.
  @override
  late String path;

  /// The name of the category containing the library. Unless otherwise
  /// specified in the libraries file all libraries are assumed to be shared
  /// between server and client.
  @override
  String category = "Shared";

  /// A flag indicating whether the library is documented.
  bool _documented = true;

  /// A flag indicating whether the library is an implementation library.
  bool _implementation = false;

  /// An encoding of which platforms this library is intended to work on.
  int _platforms = 0;

  /// Initialize a newly created library to represent the library with the given
  /// [name].
  SdkLibraryImpl(this.shortName);

  /// Set whether the library is documented.
  set documented(bool documented) {
    _documented = documented;
  }

  @override
  bool get isDart2JsLibrary => (_platforms & DART2JS_PLATFORM) != 0;

  @override
  bool get isDocumented => _documented;

  @override
  bool get isImplementation => _implementation;

  @override
  bool get isInternal => category == "Internal";

  @override
  bool get isShared => category == "Shared";

  @override
  bool get isVmLibrary => (_platforms & VM_PLATFORM) != 0;

  /// Record that this library can be compiled to JavaScript by dart2js.
  void setDart2JsLibrary() {
    _platforms |= DART2JS_PLATFORM;
  }

  /// Record that this library can be run on the VM.
  void setVmLibrary() {
    _platforms |= VM_PLATFORM;
  }
}
