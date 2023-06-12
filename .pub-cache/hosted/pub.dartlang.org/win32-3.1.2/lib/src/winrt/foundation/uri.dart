// uri.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import 'iuriruntimeclass.dart';
import 'iuriruntimeclasswithabsolutecanonicaluri.dart';
import 'istringable.dart';
import 'iuriruntimeclassfactory.dart';
import 'iuriescapestatics.dart';
import 'wwwformurldecoder.dart';
import '../../com/iinspectable.dart';

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
    final activationFactory =
        CreateActivationFactory(_className, IID_IUriRuntimeClassFactory);

    try {
      return IUriRuntimeClassFactory.fromRawPointer(activationFactory)
          .createUri(uri);
    } finally {
      free(activationFactory);
    }
  }

  static Uri createWithRelativeUri(String baseUri, String relativeUri) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IUriRuntimeClassFactory);

    try {
      return IUriRuntimeClassFactory.fromRawPointer(activationFactory)
          .createWithRelativeUri(baseUri, relativeUri);
    } finally {
      free(activationFactory);
    }
  }

  // IUriEscapeStatics methods
  static String unescapeComponent(String toUnescape) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IUriEscapeStatics);

    try {
      return IUriEscapeStatics.fromRawPointer(activationFactory)
          .unescapeComponent(toUnescape);
    } finally {
      free(activationFactory);
    }
  }

  static String escapeComponent(String toEscape) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IUriEscapeStatics);

    try {
      return IUriEscapeStatics.fromRawPointer(activationFactory)
          .escapeComponent(toEscape);
    } finally {
      free(activationFactory);
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
  WwwFormUrlDecoder get queryParsed => _iUriRuntimeClass.queryParsed;

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
  bool equals(Uri pUri) => _iUriRuntimeClass.equals(pUri);

  @override
  Uri combineUri(String relativeUri) =>
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
