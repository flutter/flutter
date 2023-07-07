// uri.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';
import 'istringable.dart';
import 'iuriescapestatics.dart';
import 'iuriruntimeclass.dart';
import 'iuriruntimeclassfactory.dart';
import 'iuriruntimeclasswithabsolutecanonicaluri.dart';
import 'wwwformurldecoder.dart';

/// Defines an object that represents a Uniform Resource Identifier (URI)
/// value and parses it into components. The Uri object is used by many
/// other Windows Runtime APIs that are not necessarily confined to web
/// browser scenarios.
///
/// {@category Class}
/// {@category winrt}
class Uri extends IInspectable
    implements
        IUriRuntimeClass,
        IUriRuntimeClassWithAbsoluteCanonicalUri,
        IStringable {
  Uri.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.Uri';

  // IUriRuntimeClassFactory methods
  static Uri createUri(String uri) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUriRuntimeClassFactory);
    final object = IUriRuntimeClassFactory.fromRawPointer(activationFactoryPtr);

    try {
      return object.createUri(uri);
    } finally {
      object.release();
    }
  }

  static Uri createWithRelativeUri(String baseUri, String relativeUri) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUriRuntimeClassFactory);
    final object = IUriRuntimeClassFactory.fromRawPointer(activationFactoryPtr);

    try {
      return object.createWithRelativeUri(baseUri, relativeUri);
    } finally {
      object.release();
    }
  }

  // IUriEscapeStatics methods
  static String unescapeComponent(String toUnescape) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUriEscapeStatics);
    final object = IUriEscapeStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.unescapeComponent(toUnescape);
    } finally {
      object.release();
    }
  }

  static String escapeComponent(String toEscape) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IUriEscapeStatics);
    final object = IUriEscapeStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.escapeComponent(toEscape);
    } finally {
      object.release();
    }
  }

  // IUriRuntimeClass methods
  late final _iUriRuntimeClass = IUriRuntimeClass.from(this);

  @override
  String get absoluteUri => _iUriRuntimeClass.absoluteUri;

  @override
  String get displayUri => _iUriRuntimeClass.displayUri;

  @override
  String get domain => _iUriRuntimeClass.domain;

  @override
  String get extension => _iUriRuntimeClass.extension;

  @override
  String get fragment => _iUriRuntimeClass.fragment;

  @override
  String get host => _iUriRuntimeClass.host;

  @override
  String get password => _iUriRuntimeClass.password;

  @override
  String get path => _iUriRuntimeClass.path;

  @override
  String get query => _iUriRuntimeClass.query;

  @override
  WwwFormUrlDecoder? get queryParsed => _iUriRuntimeClass.queryParsed;

  @override
  String get rawUri => _iUriRuntimeClass.rawUri;

  @override
  String get schemeName => _iUriRuntimeClass.schemeName;

  @override
  String get userName => _iUriRuntimeClass.userName;

  @override
  int get port => _iUriRuntimeClass.port;

  @override
  bool get suspicious => _iUriRuntimeClass.suspicious;

  @override
  bool equals(Uri? pUri) => _iUriRuntimeClass.equals(pUri);

  @override
  Uri? combineUri(String relativeUri) =>
      _iUriRuntimeClass.combineUri(relativeUri);

  // IUriRuntimeClassWithAbsoluteCanonicalUri methods
  late final _iUriRuntimeClassWithAbsoluteCanonicalUri =
      IUriRuntimeClassWithAbsoluteCanonicalUri.from(this);

  @override
  String get absoluteCanonicalUri =>
      _iUriRuntimeClassWithAbsoluteCanonicalUri.absoluteCanonicalUri;

  @override
  String get displayIri => _iUriRuntimeClassWithAbsoluteCanonicalUri.displayIri;

  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
