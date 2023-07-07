// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.messages.codes;

import 'dart:convert' show JsonEncoder, json;

import 'diagnostic_message.dart' show DiagnosticMessage;

import '../scanner/token.dart' show Token;

import 'severity.dart' show Severity;

import '../util/relativize.dart' as util show isWindows, relativizeUri;

part 'codes_generated.dart';

const int noLength = 1;

class Code<T> {
  final String name;

  /// The unique positive integer associated with this code,
  /// or `-1` if none. This index is used when translating
  /// this error to its corresponding Analyzer error.
  final int index;

  final List<String>? analyzerCodes;

  final Severity severity;

  const Code(this.name,
      {this.index: -1, this.analyzerCodes, this.severity: Severity.error});

  String toString() => name;
}

class Message {
  final Code<dynamic> code;

  final String problemMessage;

  final String? correctionMessage;

  final Map<String, dynamic> arguments;

  const Message(this.code,
      {this.correctionMessage,
      required this.problemMessage,
      this.arguments = const {}});

  LocatedMessage withLocation(Uri uri, int charOffset, int length) {
    return new LocatedMessage(uri, charOffset, length, this);
  }

  LocatedMessage withoutLocation() {
    return new LocatedMessage(null, -1, noLength, this);
  }

  String toString() {
    return "Message[$code, $problemMessage, $correctionMessage, $arguments]";
  }
}

class MessageCode extends Code<Null> implements Message {
  final String problemMessage;

  final String? correctionMessage;

  const MessageCode(String name,
      {int index: -1,
      List<String>? analyzerCodes,
      Severity severity: Severity.error,
      required this.problemMessage,
      this.correctionMessage})
      : super(name,
            index: index, analyzerCodes: analyzerCodes, severity: severity);

  Map<String, dynamic> get arguments => const <String, dynamic>{};

  Code<dynamic> get code => this;

  @override
  LocatedMessage withLocation(Uri uri, int charOffset, int length) {
    return new LocatedMessage(uri, charOffset, length, this);
  }

  LocatedMessage withoutLocation() {
    return new LocatedMessage(null, -1, noLength, this);
  }
}

class Template<T> {
  final String problemMessageTemplate;

  final String? correctionMessageTemplate;

  final T withArguments;

  const Template(
      {this.correctionMessageTemplate,
      required this.problemMessageTemplate,
      required this.withArguments});
}

class LocatedMessage implements Comparable<LocatedMessage> {
  final Uri? uri;

  final int charOffset;

  final int length;

  final Message messageObject;

  const LocatedMessage(
      this.uri, this.charOffset, this.length, this.messageObject);

  Code<dynamic> get code => messageObject.code;

  String get problemMessage => messageObject.problemMessage;

  String? get correctionMessage => messageObject.correctionMessage;

  Map<String, dynamic> get arguments => messageObject.arguments;

  @override
  int compareTo(LocatedMessage other) {
    int result = "${uri}".compareTo("${other.uri}");
    if (result != 0) return result;
    result = charOffset.compareTo(other.charOffset);
    if (result != 0) return result;
    return problemMessage.compareTo(problemMessage);
  }

  FormattedMessage withFormatting(PlainAndColorizedString formatted, int line,
      int column, Severity severity, List<FormattedMessage>? relatedInformation,
      {List<Uri>? involvedFiles}) {
    return new FormattedMessage(this, formatted.plain, formatted.colorized,
        line, column, severity, relatedInformation,
        involvedFiles: involvedFiles);
  }

  @override
  int get hashCode =>
      13 * uri.hashCode +
      17 * charOffset.hashCode +
      19 * length.hashCode +
      23 * messageObject.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocatedMessage &&
        uri == other.uri &&
        charOffset == other.charOffset &&
        length == other.length &&
        messageObject == other.messageObject;
  }

  @override
  String toString() =>
      'LocatedMessage(uri=$uri,charOffset=$charOffset,length=$length,'
      'messageObject=$messageObject)';
}

class PlainAndColorizedString {
  final String plain;
  final String colorized;

  @override
  String toString() {
    assert(false, "Called PlainAndColorizedString.toString: $plain");
    return 'PlainAndColorizedString:$plain';
  }

  const PlainAndColorizedString(this.plain, this.colorized);

  const PlainAndColorizedString.plainOnly(this.plain) : this.colorized = plain;
}

class FormattedMessage implements DiagnosticMessage {
  final LocatedMessage locatedMessage;

  final String formattedPlain;

  final String formattedColorized;

  final int line;

  final int column;

  @override
  final Severity severity;

  final List<FormattedMessage>? relatedInformation;

  final List<Uri>? involvedFiles;

  const FormattedMessage(
      this.locatedMessage,
      this.formattedPlain,
      this.formattedColorized,
      this.line,
      this.column,
      this.severity,
      this.relatedInformation,
      {this.involvedFiles});

  Code<dynamic> get code => locatedMessage.code;

  String get codeName => code.name;

  String get problemMessage => locatedMessage.problemMessage;

  String? get correctionMessage => locatedMessage.correctionMessage;

  Map<String, dynamic> get arguments => locatedMessage.arguments;

  Uri? get uri => locatedMessage.uri;

  int get charOffset => locatedMessage.charOffset;

  int get length => locatedMessage.length;

  @override
  Iterable<String> get ansiFormatted sync* {
    yield formattedColorized;
    if (relatedInformation != null) {
      for (FormattedMessage m in relatedInformation!) {
        yield m.formattedColorized;
      }
    }
  }

  @override
  Iterable<String> get plainTextFormatted sync* {
    yield formattedPlain;
    if (relatedInformation != null) {
      for (FormattedMessage m in relatedInformation!) {
        yield m.formattedPlain;
      }
    }
  }

  Map<String, Object?> toJson() {
    // This should be kept in sync with package:kernel/problems.md
    return <String, Object?>{
      "ansiFormatted": ansiFormatted.toList(),
      "plainTextFormatted": plainTextFormatted.toList(),
      "severity": severity.index,
      "uri": uri?.toString(),
      "involvedFiles": involvedFiles?.map((u) => u.toString()).toList(),
      "codeName": code.name,
    };
  }

  String toJsonString() {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(this);
  }
}

class DiagnosticMessageFromJson implements DiagnosticMessage {
  @override
  final Iterable<String> ansiFormatted;

  @override
  final Iterable<String> plainTextFormatted;

  @override
  final Severity severity;

  final Uri? uri;

  final List<Uri>? involvedFiles;

  final String codeName;

  DiagnosticMessageFromJson(this.ansiFormatted, this.plainTextFormatted,
      this.severity, this.uri, this.involvedFiles, this.codeName);

  factory DiagnosticMessageFromJson.fromJson(String jsonString) {
    Map<String, Object?> decoded = json.decode(jsonString);
    List<String> ansiFormatted =
        new List<String>.from(_asListOfString(decoded["ansiFormatted"]));
    List<String> plainTextFormatted =
        _asListOfString(decoded["plainTextFormatted"]);
    Severity severity = Severity.values[decoded["severity"] as int];
    Uri? uri =
        decoded["uri"] == null ? null : Uri.parse(decoded["uri"] as String);
    List<Uri>? involvedFiles = decoded["involvedFiles"] == null
        ? null
        : _asListOfString(decoded["involvedFiles"])
            .map((e) => Uri.parse(e))
            .toList();
    String codeName = decoded["codeName"] as String;

    return new DiagnosticMessageFromJson(ansiFormatted, plainTextFormatted,
        severity, uri, involvedFiles, codeName);
  }

  Map<String, Object?> toJson() {
    // This should be kept in sync with package:kernel/problems.md
    return <String, Object?>{
      "ansiFormatted": ansiFormatted.toList(),
      "plainTextFormatted": plainTextFormatted.toList(),
      "severity": severity.index,
      "uri": uri?.toString(),
      "involvedFiles": involvedFiles?.map((u) => u.toString()).toList(),
      "codeName": codeName,
    };
  }

  String toJsonString() {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(this);
  }

  static List<String> _asListOfString(Object? value) {
    return (value as List<dynamic>).cast<String>();
  }
}

String? relativizeUri(Uri? uri) {
  // We have this method here for two reasons:
  //
  // 1. It allows us to implement #uri message argument without using it
  // (otherwise, we might get an `UNUSED_IMPORT` warning).
  //
  // 2. We can change `base` argument here if needed.
  return uri == null ? null : util.relativizeUri(Uri.base, uri, util.isWindows);
}

typedef SummaryTemplate = Message Function(int, int, num, num, num);

String itemizeNames(List<String> names) {
  StringBuffer buffer = new StringBuffer();
  for (int i = 0; i < names.length - 1; i++) {
    buffer.write(" - ");
    buffer.writeln(names[i]);
  }
  buffer.write(" - ");
  buffer.write(names.last);
  return "$buffer";
}

/// Convert the synthetic name of an implicit mixin application class
/// into a name suitable for user-faced strings.
///
/// For example, when compiling "class A extends S with M1, M2", the
/// two synthetic classes will be named "_A&S&M1" and "_A&S&M1&M2".
/// This function will return "S with M1" and "S with M1, M2", respectively.
///
/// This method is copied from package:kernel/ast.dart.
// TODO(johnniwinther): Avoid the need for this method.
String demangleMixinApplicationName(String name) {
  List<String> nameParts = name.split('&');
  if (nameParts.length < 2 || name == "&") return name;
  String demangledName = nameParts[1];
  for (int i = 2; i < nameParts.length; i++) {
    demangledName += (i == 2 ? " with " : ", ") + nameParts[i];
  }
  return demangledName;
}

final RegExp templateKey = new RegExp(r'#(\w+)');

/// Replaces occurrences of '#key' in [template], where 'key' is a key in
/// [arguments], with the corresponding values.
String applyArgumentsToTemplate(
    String template, Map<String, dynamic> arguments) {
  // TODO(johnniwinther): Remove `as dynamic` when unsound null safety is
  // no longer supported.
  if (arguments as dynamic == null || arguments.isEmpty) {
    assert(!template.contains(templateKey),
        'Message requires arguments, but none were provided.');
    return template;
  }
  return template.replaceAllMapped(templateKey, (Match match) {
    String? key = match.group(1);
    Object? value = arguments[key];
    assert(value != null, "No value for '$key' found in $arguments");
    return value.toString();
  });
}
