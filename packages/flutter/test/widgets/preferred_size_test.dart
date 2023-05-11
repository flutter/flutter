// ignore_for_file: unused_element

// Regression test for https://github.com/flutter/flutter/issues/126512

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class _ExtendPreferredSizeWidget extends PreferredSizeWidget {
  @override
  Key? get key => null;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Element createElement() {
    throw UnimplementedError('createElement() is not implemented');
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    throw UnimplementedError('toDiagnosticsNode() is not implemented');
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '';
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShort() => '';
}

class _ImplementPreferredSizeWidget implements PreferredSizeWidget {
  @override
  Key? get key => null;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Element createElement() {
    throw UnimplementedError('createElement() is not implemented');
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    throw UnimplementedError('toDiagnosticsNode() is not implemented');
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '';
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShort() => '';
}

class _MixInPreferredSizeWidget with PreferredSizeWidget {
  @override
  Key? get key => null;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Element createElement() {
    throw UnimplementedError('createElement() is not implemented');
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => const <DiagnosticsNode>[];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    throw UnimplementedError('toDiagnosticsNode() is not implemented');
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '';
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines,
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    return '';
  }

  @override
  String toStringShort() => '';
}
