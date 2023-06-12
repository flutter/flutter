// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the SDK script
// "pkg/analyzer/tool/summary/generate.dart $IDL_FILE_PATH",
// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.

// The generator sometimes generates unnecessary 'this' references.
// ignore_for_file: unnecessary_this

library analyzer.src.summary.format;

import 'dart:convert' as convert;
import 'dart:typed_data' as typed_data;

import 'package:analyzer/src/summary/api_signature.dart' as api_sig;
import 'package:analyzer/src/summary/flat_buffers.dart' as fb;
import 'package:analyzer/src/summary/idl.dart' as idl;

class _AvailableDeclarationKindReader
    extends fb.Reader<idl.AvailableDeclarationKind> {
  const _AvailableDeclarationKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.AvailableDeclarationKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.AvailableDeclarationKind.values.length
        ? idl.AvailableDeclarationKind.values[index]
        : idl.AvailableDeclarationKind.CLASS;
  }
}

class _IndexRelationKindReader extends fb.Reader<idl.IndexRelationKind> {
  const _IndexRelationKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.IndexRelationKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.IndexRelationKind.values.length
        ? idl.IndexRelationKind.values[index]
        : idl.IndexRelationKind.IS_ANCESTOR_OF;
  }
}

class _IndexSyntheticElementKindReader
    extends fb.Reader<idl.IndexSyntheticElementKind> {
  const _IndexSyntheticElementKindReader() : super();

  @override
  int get size => 1;

  @override
  idl.IndexSyntheticElementKind read(fb.BufferContext bc, int offset) {
    int index = const fb.Uint8Reader().read(bc, offset);
    return index < idl.IndexSyntheticElementKind.values.length
        ? idl.IndexSyntheticElementKind.values[index]
        : idl.IndexSyntheticElementKind.notSynthetic;
  }
}

class AnalysisDriverExceptionContextBuilder extends Object
    with _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  String? _exception;
  List<AnalysisDriverExceptionFileBuilder>? _files;
  String? _path;
  String? _stackTrace;

  @override
  String get exception => _exception ??= '';

  /// The exception string.
  set exception(String value) {
    this._exception = value;
  }

  @override
  List<AnalysisDriverExceptionFileBuilder> get files =>
      _files ??= <AnalysisDriverExceptionFileBuilder>[];

  /// The state of files when the exception happened.
  set files(List<AnalysisDriverExceptionFileBuilder> value) {
    this._files = value;
  }

  @override
  String get path => _path ??= '';

  /// The path of the file being analyzed when the exception happened.
  set path(String value) {
    this._path = value;
  }

  @override
  String get stackTrace => _stackTrace ??= '';

  /// The exception stack trace string.
  set stackTrace(String value) {
    this._stackTrace = value;
  }

  AnalysisDriverExceptionContextBuilder(
      {String? exception,
      List<AnalysisDriverExceptionFileBuilder>? files,
      String? path,
      String? stackTrace})
      : _exception = exception,
        _files = files,
        _path = path,
        _stackTrace = stackTrace;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _files?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._path ?? '');
    signatureSink.addString(this._exception ?? '');
    signatureSink.addString(this._stackTrace ?? '');
    var files = this._files;
    if (files == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(files.length);
      for (var x in files) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADEC");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_exception;
    fb.Offset? offset_files;
    fb.Offset? offset_path;
    fb.Offset? offset_stackTrace;
    var exception = _exception;
    if (exception != null) {
      offset_exception = fbBuilder.writeString(exception);
    }
    var files = _files;
    if (!(files == null || files.isEmpty)) {
      offset_files =
          fbBuilder.writeList(files.map((b) => b.finish(fbBuilder)).toList());
    }
    var path = _path;
    if (path != null) {
      offset_path = fbBuilder.writeString(path);
    }
    var stackTrace = _stackTrace;
    if (stackTrace != null) {
      offset_stackTrace = fbBuilder.writeString(stackTrace);
    }
    fbBuilder.startTable();
    if (offset_exception != null) {
      fbBuilder.addOffset(1, offset_exception);
    }
    if (offset_files != null) {
      fbBuilder.addOffset(3, offset_files);
    }
    if (offset_path != null) {
      fbBuilder.addOffset(0, offset_path);
    }
    if (offset_stackTrace != null) {
      fbBuilder.addOffset(2, offset_stackTrace);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverExceptionContext readAnalysisDriverExceptionContext(
    List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverExceptionContextReader().read(rootRef, 0);
}

class _AnalysisDriverExceptionContextReader
    extends fb.TableReader<_AnalysisDriverExceptionContextImpl> {
  const _AnalysisDriverExceptionContextReader();

  @override
  _AnalysisDriverExceptionContextImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverExceptionContextImpl(bc, offset);
}

class _AnalysisDriverExceptionContextImpl extends Object
    with _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionContextImpl(this._bc, this._bcOffset);

  String? _exception;
  List<idl.AnalysisDriverExceptionFile>? _files;
  String? _path;
  String? _stackTrace;

  @override
  String get exception {
    return _exception ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
  }

  @override
  List<idl.AnalysisDriverExceptionFile> get files {
    return _files ??= const fb.ListReader<idl.AnalysisDriverExceptionFile>(
            _AnalysisDriverExceptionFileReader())
        .vTableGet(
            _bc, _bcOffset, 3, const <idl.AnalysisDriverExceptionFile>[]);
  }

  @override
  String get path {
    return _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }

  @override
  String get stackTrace {
    return _stackTrace ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
  }
}

abstract class _AnalysisDriverExceptionContextMixin
    implements idl.AnalysisDriverExceptionContext {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_exception = exception;
    if (local_exception != '') {
      result["exception"] = local_exception;
    }
    var local_files = files;
    if (local_files.isNotEmpty) {
      result["files"] = local_files.map((value) => value.toJson()).toList();
    }
    var local_path = path;
    if (local_path != '') {
      result["path"] = local_path;
    }
    var local_stackTrace = stackTrace;
    if (local_stackTrace != '') {
      result["stackTrace"] = local_stackTrace;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "exception": exception,
        "files": files,
        "path": path,
        "stackTrace": stackTrace,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverExceptionFileBuilder extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  String? _content;
  String? _path;

  @override
  String get content => _content ??= '';

  /// The content of the file.
  set content(String value) {
    this._content = value;
  }

  @override
  String get path => _path ??= '';

  /// The path of the file.
  set path(String value) {
    this._path = value;
  }

  AnalysisDriverExceptionFileBuilder({String? content, String? path})
      : _content = content,
        _path = path;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._path ?? '');
    signatureSink.addString(this._content ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_content;
    fb.Offset? offset_path;
    var content = _content;
    if (content != null) {
      offset_content = fbBuilder.writeString(content);
    }
    var path = _path;
    if (path != null) {
      offset_path = fbBuilder.writeString(path);
    }
    fbBuilder.startTable();
    if (offset_content != null) {
      fbBuilder.addOffset(1, offset_content);
    }
    if (offset_path != null) {
      fbBuilder.addOffset(0, offset_path);
    }
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverExceptionFileReader
    extends fb.TableReader<_AnalysisDriverExceptionFileImpl> {
  const _AnalysisDriverExceptionFileReader();

  @override
  _AnalysisDriverExceptionFileImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverExceptionFileImpl(bc, offset);
}

class _AnalysisDriverExceptionFileImpl extends Object
    with _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverExceptionFileImpl(this._bc, this._bcOffset);

  String? _content;
  String? _path;

  @override
  String get content {
    return _content ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 1, '');
  }

  @override
  String get path {
    return _path ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }
}

abstract class _AnalysisDriverExceptionFileMixin
    implements idl.AnalysisDriverExceptionFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_content = content;
    if (local_content != '') {
      result["content"] = local_content;
    }
    var local_path = path;
    if (local_path != '') {
      result["path"] = local_path;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "content": content,
        "path": path,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverResolvedUnitBuilder extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  List<AnalysisDriverUnitErrorBuilder>? _errors;
  AnalysisDriverUnitIndexBuilder? _index;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  /// The full list of analysis errors, both syntactic and semantic.
  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  @override
  AnalysisDriverUnitIndexBuilder? get index => _index;

  /// The index of the unit.
  set index(AnalysisDriverUnitIndexBuilder? value) {
    this._index = value;
  }

  AnalysisDriverResolvedUnitBuilder(
      {List<AnalysisDriverUnitErrorBuilder>? errors,
      AnalysisDriverUnitIndexBuilder? index})
      : _errors = errors,
        _index = index;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
    _index?.flushInformative();
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var errors = this._errors;
    if (errors == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(errors.length);
      for (var x in errors) {
        x.collectApiSignature(signatureSink);
      }
    }
    signatureSink.addBool(this._index != null);
    this._index?.collectApiSignature(signatureSink);
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADRU");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_errors;
    fb.Offset? offset_index;
    var errors = _errors;
    if (!(errors == null || errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(errors.map((b) => b.finish(fbBuilder)).toList());
    }
    var index = _index;
    if (index != null) {
      offset_index = index.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
    }
    if (offset_index != null) {
      fbBuilder.addOffset(1, offset_index);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverResolvedUnit readAnalysisDriverResolvedUnit(
    List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverResolvedUnitReader().read(rootRef, 0);
}

class _AnalysisDriverResolvedUnitReader
    extends fb.TableReader<_AnalysisDriverResolvedUnitImpl> {
  const _AnalysisDriverResolvedUnitReader();

  @override
  _AnalysisDriverResolvedUnitImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AnalysisDriverResolvedUnitImpl(bc, offset);
}

class _AnalysisDriverResolvedUnitImpl extends Object
    with _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverResolvedUnitImpl(this._bc, this._bcOffset);

  List<idl.AnalysisDriverUnitError>? _errors;
  idl.AnalysisDriverUnitIndex? _index;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    return _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
            _AnalysisDriverUnitErrorReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AnalysisDriverUnitError>[]);
  }

  @override
  idl.AnalysisDriverUnitIndex? get index {
    return _index ??= const _AnalysisDriverUnitIndexReader()
        .vTableGetOrNull(_bc, _bcOffset, 1);
  }
}

abstract class _AnalysisDriverResolvedUnitMixin
    implements idl.AnalysisDriverResolvedUnit {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_errors = errors;
    if (local_errors.isNotEmpty) {
      result["errors"] = local_errors.map((value) => value.toJson()).toList();
    }
    var local_index = index;
    if (local_index != null) {
      result["index"] = local_index.toJson();
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "errors": errors,
        "index": index,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverSubtypeBuilder extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  List<int>? _members;
  int? _name;

  @override
  List<int> get members => _members ??= <int>[];

  /// The names of defined instance members.
  /// They are indexes into [AnalysisDriverUnitError.strings] list.
  /// The list is sorted in ascending order.
  set members(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._members = value;
  }

  @override
  int get name => _name ??= 0;

  /// The name of the class.
  /// It is an index into [AnalysisDriverUnitError.strings] list.
  set name(int value) {
    assert(value >= 0);
    this._name = value;
  }

  AnalysisDriverSubtypeBuilder({List<int>? members, int? name})
      : _members = members,
        _name = name;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addInt(this._name ?? 0);
    var members = this._members;
    if (members == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(members.length);
      for (var x in members) {
        signatureSink.addInt(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_members;
    var members = _members;
    if (!(members == null || members.isEmpty)) {
      offset_members = fbBuilder.writeListUint32(members);
    }
    fbBuilder.startTable();
    if (offset_members != null) {
      fbBuilder.addOffset(1, offset_members);
    }
    fbBuilder.addUint32(0, _name, 0);
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverSubtypeReader
    extends fb.TableReader<_AnalysisDriverSubtypeImpl> {
  const _AnalysisDriverSubtypeReader();

  @override
  _AnalysisDriverSubtypeImpl createObject(fb.BufferContext bc, int offset) =>
      _AnalysisDriverSubtypeImpl(bc, offset);
}

class _AnalysisDriverSubtypeImpl extends Object
    with _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverSubtypeImpl(this._bc, this._bcOffset);

  List<int>? _members;
  int? _name;

  @override
  List<int> get members {
    return _members ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 1, const <int>[]);
  }

  @override
  int get name {
    return _name ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
  }
}

abstract class _AnalysisDriverSubtypeMixin
    implements idl.AnalysisDriverSubtype {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_members = members;
    if (local_members.isNotEmpty) {
      result["members"] = local_members;
    }
    var local_name = name;
    if (local_name != 0) {
      result["name"] = local_name;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "members": members,
        "name": name,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnitErrorBuilder extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  List<DiagnosticMessageBuilder>? _contextMessages;
  String? _correction;
  int? _length;
  String? _message;
  int? _offset;
  String? _uniqueName;

  @override
  List<DiagnosticMessageBuilder> get contextMessages =>
      _contextMessages ??= <DiagnosticMessageBuilder>[];

  /// The context messages associated with the error.
  set contextMessages(List<DiagnosticMessageBuilder> value) {
    this._contextMessages = value;
  }

  @override
  String get correction => _correction ??= '';

  /// The optional correction hint for the error.
  set correction(String value) {
    this._correction = value;
  }

  @override
  int get length => _length ??= 0;

  /// The length of the error in the file.
  set length(int value) {
    assert(value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  /// The message of the error.
  set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// The offset from the beginning of the file.
  set offset(int value) {
    assert(value >= 0);
    this._offset = value;
  }

  @override
  String get uniqueName => _uniqueName ??= '';

  /// The unique name of the error code.
  set uniqueName(String value) {
    this._uniqueName = value;
  }

  AnalysisDriverUnitErrorBuilder(
      {List<DiagnosticMessageBuilder>? contextMessages,
      String? correction,
      int? length,
      String? message,
      int? offset,
      String? uniqueName})
      : _contextMessages = contextMessages,
        _correction = correction,
        _length = length,
        _message = message,
        _offset = offset,
        _uniqueName = uniqueName;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _contextMessages?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addInt(this._offset ?? 0);
    signatureSink.addInt(this._length ?? 0);
    signatureSink.addString(this._uniqueName ?? '');
    signatureSink.addString(this._message ?? '');
    signatureSink.addString(this._correction ?? '');
    var contextMessages = this._contextMessages;
    if (contextMessages == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(contextMessages.length);
      for (var x in contextMessages) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_contextMessages;
    fb.Offset? offset_correction;
    fb.Offset? offset_message;
    fb.Offset? offset_uniqueName;
    var contextMessages = _contextMessages;
    if (!(contextMessages == null || contextMessages.isEmpty)) {
      offset_contextMessages = fbBuilder
          .writeList(contextMessages.map((b) => b.finish(fbBuilder)).toList());
    }
    var correction = _correction;
    if (correction != null) {
      offset_correction = fbBuilder.writeString(correction);
    }
    var message = _message;
    if (message != null) {
      offset_message = fbBuilder.writeString(message);
    }
    var uniqueName = _uniqueName;
    if (uniqueName != null) {
      offset_uniqueName = fbBuilder.writeString(uniqueName);
    }
    fbBuilder.startTable();
    if (offset_contextMessages != null) {
      fbBuilder.addOffset(5, offset_contextMessages);
    }
    if (offset_correction != null) {
      fbBuilder.addOffset(4, offset_correction);
    }
    fbBuilder.addUint32(1, _length, 0);
    if (offset_message != null) {
      fbBuilder.addOffset(3, offset_message);
    }
    fbBuilder.addUint32(0, _offset, 0);
    if (offset_uniqueName != null) {
      fbBuilder.addOffset(2, offset_uniqueName);
    }
    return fbBuilder.endTable();
  }
}

class _AnalysisDriverUnitErrorReader
    extends fb.TableReader<_AnalysisDriverUnitErrorImpl> {
  const _AnalysisDriverUnitErrorReader();

  @override
  _AnalysisDriverUnitErrorImpl createObject(fb.BufferContext bc, int offset) =>
      _AnalysisDriverUnitErrorImpl(bc, offset);
}

class _AnalysisDriverUnitErrorImpl extends Object
    with _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnitErrorImpl(this._bc, this._bcOffset);

  List<idl.DiagnosticMessage>? _contextMessages;
  String? _correction;
  int? _length;
  String? _message;
  int? _offset;
  String? _uniqueName;

  @override
  List<idl.DiagnosticMessage> get contextMessages {
    return _contextMessages ??=
        const fb.ListReader<idl.DiagnosticMessage>(_DiagnosticMessageReader())
            .vTableGet(_bc, _bcOffset, 5, const <idl.DiagnosticMessage>[]);
  }

  @override
  String get correction {
    return _correction ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
  }

  @override
  int get length {
    return _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  String get message {
    return _message ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
  }

  @override
  int get offset {
    return _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 0, 0);
  }

  @override
  String get uniqueName {
    return _uniqueName ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
  }
}

abstract class _AnalysisDriverUnitErrorMixin
    implements idl.AnalysisDriverUnitError {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_contextMessages = contextMessages;
    if (local_contextMessages.isNotEmpty) {
      result["contextMessages"] =
          local_contextMessages.map((value) => value.toJson()).toList();
    }
    var local_correction = correction;
    if (local_correction != '') {
      result["correction"] = local_correction;
    }
    var local_length = length;
    if (local_length != 0) {
      result["length"] = local_length;
    }
    var local_message = message;
    if (local_message != '') {
      result["message"] = local_message;
    }
    var local_offset = offset;
    if (local_offset != 0) {
      result["offset"] = local_offset;
    }
    var local_uniqueName = uniqueName;
    if (local_uniqueName != '') {
      result["uniqueName"] = local_uniqueName;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "contextMessages": contextMessages,
        "correction": correction,
        "length": length,
        "message": message,
        "offset": offset,
        "uniqueName": uniqueName,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AnalysisDriverUnitIndexBuilder extends Object
    with _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  List<idl.IndexSyntheticElementKind>? _elementKinds;
  List<int>? _elementNameClassMemberIds;
  List<int>? _elementNameParameterIds;
  List<int>? _elementNameUnitMemberIds;
  List<int>? _elementUnits;
  int? _nullStringId;
  List<String>? _strings;
  List<AnalysisDriverSubtypeBuilder>? _subtypes;
  List<int>? _supertypes;
  List<int>? _unitLibraryUris;
  List<int>? _unitUnitUris;
  List<bool>? _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedElementKinds;
  List<int>? _usedElementLengths;
  List<int>? _usedElementOffsets;
  List<int>? _usedElements;
  List<bool>? _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedNameKinds;
  List<int>? _usedNameOffsets;
  List<int>? _usedNames;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds =>
      _elementKinds ??= <idl.IndexSyntheticElementKind>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the kind of the synthetic element.
  set elementKinds(List<idl.IndexSyntheticElementKind> value) {
    this._elementKinds = value;
  }

  @override
  List<int> get elementNameClassMemberIds =>
      _elementNameClassMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the class member element name, or `null` if the element
  /// is a top-level element.  The list is sorted in ascending order, so that
  /// the client can quickly check whether an element is referenced in this
  /// index.
  set elementNameClassMemberIds(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._elementNameClassMemberIds = value;
  }

  @override
  List<int> get elementNameParameterIds => _elementNameParameterIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.  The list is sorted in ascending order, so that the
  /// client can quickly check whether an element is referenced in this index.
  set elementNameParameterIds(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._elementNameParameterIds = value;
  }

  @override
  List<int> get elementNameUnitMemberIds =>
      _elementNameUnitMemberIds ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the identifier of the top-level element name, or `null` if the element is
  /// the unit.  The list is sorted in ascending order, so that the client can
  /// quickly check whether an element is referenced in this index.
  set elementNameUnitMemberIds(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._elementNameUnitMemberIds = value;
  }

  @override
  List<int> get elementUnits => _elementUnits ??= <int>[];

  /// Each item of this list corresponds to a unique referenced element.  It is
  /// the index into [unitLibraryUris] and [unitUnitUris] for the library
  /// specific unit where the element is declared.
  set elementUnits(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._elementUnits = value;
  }

  @override
  int get nullStringId => _nullStringId ??= 0;

  /// Identifier of the null string in [strings].
  set nullStringId(int value) {
    assert(value >= 0);
    this._nullStringId = value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /// List of unique element strings used in this index.  The list is sorted in
  /// ascending order, so that the client can quickly check the presence of a
  /// string in this index.
  set strings(List<String> value) {
    this._strings = value;
  }

  @override
  List<AnalysisDriverSubtypeBuilder> get subtypes =>
      _subtypes ??= <AnalysisDriverSubtypeBuilder>[];

  /// The list of classes declared in the unit.
  set subtypes(List<AnalysisDriverSubtypeBuilder> value) {
    this._subtypes = value;
  }

  @override
  List<int> get supertypes => _supertypes ??= <int>[];

  /// The identifiers of supertypes of elements at corresponding indexes
  /// in [subtypes].  They are indexes into [strings] list. The list is sorted
  /// in ascending order.  There might be more than one element with the same
  /// value if there is more than one subtype of this supertype.
  set supertypes(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._supertypes = value;
  }

  @override
  List<int> get unitLibraryUris => _unitLibraryUris ??= <int>[];

  /// Each item of this list corresponds to the library URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitLibraryUris(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._unitLibraryUris = value;
  }

  @override
  List<int> get unitUnitUris => _unitUnitUris ??= <int>[];

  /// Each item of this list corresponds to the unit URI of a unique library
  /// specific unit referenced in the index.  It is an index into [strings]
  /// list.
  set unitUnitUris(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._unitUnitUris = value;
  }

  @override
  List<bool> get usedElementIsQualifiedFlags =>
      _usedElementIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding element usage
  /// is qualified with some prefix.
  set usedElementIsQualifiedFlags(List<bool> value) {
    this._usedElementIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds =>
      _usedElementKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the element usage.
  set usedElementKinds(List<idl.IndexRelationKind> value) {
    this._usedElementKinds = value;
  }

  @override
  List<int> get usedElementLengths => _usedElementLengths ??= <int>[];

  /// Each item of this list is the length of the element usage.
  set usedElementLengths(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedElementLengths = value;
  }

  @override
  List<int> get usedElementOffsets => _usedElementOffsets ??= <int>[];

  /// Each item of this list is the offset of the element usage relative to the
  /// beginning of the file.
  set usedElementOffsets(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedElementOffsets = value;
  }

  @override
  List<int> get usedElements => _usedElements ??= <int>[];

  /// Each item of this list is the index into [elementUnits],
  /// [elementNameUnitMemberIds], [elementNameClassMemberIds] and
  /// [elementNameParameterIds].  The list is sorted in ascending order, so
  /// that the client can quickly find element references in this index.
  set usedElements(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedElements = value;
  }

  @override
  List<bool> get usedNameIsQualifiedFlags =>
      _usedNameIsQualifiedFlags ??= <bool>[];

  /// Each item of this list is the `true` if the corresponding name usage
  /// is qualified with some prefix.
  set usedNameIsQualifiedFlags(List<bool> value) {
    this._usedNameIsQualifiedFlags = value;
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds =>
      _usedNameKinds ??= <idl.IndexRelationKind>[];

  /// Each item of this list is the kind of the name usage.
  set usedNameKinds(List<idl.IndexRelationKind> value) {
    this._usedNameKinds = value;
  }

  @override
  List<int> get usedNameOffsets => _usedNameOffsets ??= <int>[];

  /// Each item of this list is the offset of the name usage relative to the
  /// beginning of the file.
  set usedNameOffsets(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedNameOffsets = value;
  }

  @override
  List<int> get usedNames => _usedNames ??= <int>[];

  /// Each item of this list is the index into [strings] for a used name.  The
  /// list is sorted in ascending order, so that the client can quickly find
  /// whether a name is used in this index.
  set usedNames(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._usedNames = value;
  }

  AnalysisDriverUnitIndexBuilder(
      {List<idl.IndexSyntheticElementKind>? elementKinds,
      List<int>? elementNameClassMemberIds,
      List<int>? elementNameParameterIds,
      List<int>? elementNameUnitMemberIds,
      List<int>? elementUnits,
      int? nullStringId,
      List<String>? strings,
      List<AnalysisDriverSubtypeBuilder>? subtypes,
      List<int>? supertypes,
      List<int>? unitLibraryUris,
      List<int>? unitUnitUris,
      List<bool>? usedElementIsQualifiedFlags,
      List<idl.IndexRelationKind>? usedElementKinds,
      List<int>? usedElementLengths,
      List<int>? usedElementOffsets,
      List<int>? usedElements,
      List<bool>? usedNameIsQualifiedFlags,
      List<idl.IndexRelationKind>? usedNameKinds,
      List<int>? usedNameOffsets,
      List<int>? usedNames})
      : _elementKinds = elementKinds,
        _elementNameClassMemberIds = elementNameClassMemberIds,
        _elementNameParameterIds = elementNameParameterIds,
        _elementNameUnitMemberIds = elementNameUnitMemberIds,
        _elementUnits = elementUnits,
        _nullStringId = nullStringId,
        _strings = strings,
        _subtypes = subtypes,
        _supertypes = supertypes,
        _unitLibraryUris = unitLibraryUris,
        _unitUnitUris = unitUnitUris,
        _usedElementIsQualifiedFlags = usedElementIsQualifiedFlags,
        _usedElementKinds = usedElementKinds,
        _usedElementLengths = usedElementLengths,
        _usedElementOffsets = usedElementOffsets,
        _usedElements = usedElements,
        _usedNameIsQualifiedFlags = usedNameIsQualifiedFlags,
        _usedNameKinds = usedNameKinds,
        _usedNameOffsets = usedNameOffsets,
        _usedNames = usedNames;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _subtypes?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var strings = this._strings;
    if (strings == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(strings.length);
      for (var x in strings) {
        signatureSink.addString(x);
      }
    }
    signatureSink.addInt(this._nullStringId ?? 0);
    var unitLibraryUris = this._unitLibraryUris;
    if (unitLibraryUris == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(unitLibraryUris.length);
      for (var x in unitLibraryUris) {
        signatureSink.addInt(x);
      }
    }
    var unitUnitUris = this._unitUnitUris;
    if (unitUnitUris == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(unitUnitUris.length);
      for (var x in unitUnitUris) {
        signatureSink.addInt(x);
      }
    }
    var elementKinds = this._elementKinds;
    if (elementKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementKinds.length);
      for (var x in elementKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var elementUnits = this._elementUnits;
    if (elementUnits == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementUnits.length);
      for (var x in elementUnits) {
        signatureSink.addInt(x);
      }
    }
    var elementNameUnitMemberIds = this._elementNameUnitMemberIds;
    if (elementNameUnitMemberIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameUnitMemberIds.length);
      for (var x in elementNameUnitMemberIds) {
        signatureSink.addInt(x);
      }
    }
    var elementNameClassMemberIds = this._elementNameClassMemberIds;
    if (elementNameClassMemberIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameClassMemberIds.length);
      for (var x in elementNameClassMemberIds) {
        signatureSink.addInt(x);
      }
    }
    var elementNameParameterIds = this._elementNameParameterIds;
    if (elementNameParameterIds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(elementNameParameterIds.length);
      for (var x in elementNameParameterIds) {
        signatureSink.addInt(x);
      }
    }
    var usedElements = this._usedElements;
    if (usedElements == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElements.length);
      for (var x in usedElements) {
        signatureSink.addInt(x);
      }
    }
    var usedElementKinds = this._usedElementKinds;
    if (usedElementKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementKinds.length);
      for (var x in usedElementKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var usedElementOffsets = this._usedElementOffsets;
    if (usedElementOffsets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementOffsets.length);
      for (var x in usedElementOffsets) {
        signatureSink.addInt(x);
      }
    }
    var usedElementLengths = this._usedElementLengths;
    if (usedElementLengths == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementLengths.length);
      for (var x in usedElementLengths) {
        signatureSink.addInt(x);
      }
    }
    var usedElementIsQualifiedFlags = this._usedElementIsQualifiedFlags;
    if (usedElementIsQualifiedFlags == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedElementIsQualifiedFlags.length);
      for (var x in usedElementIsQualifiedFlags) {
        signatureSink.addBool(x);
      }
    }
    var usedNames = this._usedNames;
    if (usedNames == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNames.length);
      for (var x in usedNames) {
        signatureSink.addInt(x);
      }
    }
    var usedNameKinds = this._usedNameKinds;
    if (usedNameKinds == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameKinds.length);
      for (var x in usedNameKinds) {
        signatureSink.addInt(x.index);
      }
    }
    var usedNameOffsets = this._usedNameOffsets;
    if (usedNameOffsets == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameOffsets.length);
      for (var x in usedNameOffsets) {
        signatureSink.addInt(x);
      }
    }
    var usedNameIsQualifiedFlags = this._usedNameIsQualifiedFlags;
    if (usedNameIsQualifiedFlags == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(usedNameIsQualifiedFlags.length);
      for (var x in usedNameIsQualifiedFlags) {
        signatureSink.addBool(x);
      }
    }
    var supertypes = this._supertypes;
    if (supertypes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(supertypes.length);
      for (var x in supertypes) {
        signatureSink.addInt(x);
      }
    }
    var subtypes = this._subtypes;
    if (subtypes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(subtypes.length);
      for (var x in subtypes) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "ADUI");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_elementKinds;
    fb.Offset? offset_elementNameClassMemberIds;
    fb.Offset? offset_elementNameParameterIds;
    fb.Offset? offset_elementNameUnitMemberIds;
    fb.Offset? offset_elementUnits;
    fb.Offset? offset_strings;
    fb.Offset? offset_subtypes;
    fb.Offset? offset_supertypes;
    fb.Offset? offset_unitLibraryUris;
    fb.Offset? offset_unitUnitUris;
    fb.Offset? offset_usedElementIsQualifiedFlags;
    fb.Offset? offset_usedElementKinds;
    fb.Offset? offset_usedElementLengths;
    fb.Offset? offset_usedElementOffsets;
    fb.Offset? offset_usedElements;
    fb.Offset? offset_usedNameIsQualifiedFlags;
    fb.Offset? offset_usedNameKinds;
    fb.Offset? offset_usedNameOffsets;
    fb.Offset? offset_usedNames;
    var elementKinds = _elementKinds;
    if (!(elementKinds == null || elementKinds.isEmpty)) {
      offset_elementKinds =
          fbBuilder.writeListUint8(elementKinds.map((b) => b.index).toList());
    }
    var elementNameClassMemberIds = _elementNameClassMemberIds;
    if (!(elementNameClassMemberIds == null ||
        elementNameClassMemberIds.isEmpty)) {
      offset_elementNameClassMemberIds =
          fbBuilder.writeListUint32(elementNameClassMemberIds);
    }
    var elementNameParameterIds = _elementNameParameterIds;
    if (!(elementNameParameterIds == null || elementNameParameterIds.isEmpty)) {
      offset_elementNameParameterIds =
          fbBuilder.writeListUint32(elementNameParameterIds);
    }
    var elementNameUnitMemberIds = _elementNameUnitMemberIds;
    if (!(elementNameUnitMemberIds == null ||
        elementNameUnitMemberIds.isEmpty)) {
      offset_elementNameUnitMemberIds =
          fbBuilder.writeListUint32(elementNameUnitMemberIds);
    }
    var elementUnits = _elementUnits;
    if (!(elementUnits == null || elementUnits.isEmpty)) {
      offset_elementUnits = fbBuilder.writeListUint32(elementUnits);
    }
    var strings = _strings;
    if (!(strings == null || strings.isEmpty)) {
      offset_strings = fbBuilder
          .writeList(strings.map((b) => fbBuilder.writeString(b)).toList());
    }
    var subtypes = _subtypes;
    if (!(subtypes == null || subtypes.isEmpty)) {
      offset_subtypes = fbBuilder
          .writeList(subtypes.map((b) => b.finish(fbBuilder)).toList());
    }
    var supertypes = _supertypes;
    if (!(supertypes == null || supertypes.isEmpty)) {
      offset_supertypes = fbBuilder.writeListUint32(supertypes);
    }
    var unitLibraryUris = _unitLibraryUris;
    if (!(unitLibraryUris == null || unitLibraryUris.isEmpty)) {
      offset_unitLibraryUris = fbBuilder.writeListUint32(unitLibraryUris);
    }
    var unitUnitUris = _unitUnitUris;
    if (!(unitUnitUris == null || unitUnitUris.isEmpty)) {
      offset_unitUnitUris = fbBuilder.writeListUint32(unitUnitUris);
    }
    var usedElementIsQualifiedFlags = _usedElementIsQualifiedFlags;
    if (!(usedElementIsQualifiedFlags == null ||
        usedElementIsQualifiedFlags.isEmpty)) {
      offset_usedElementIsQualifiedFlags =
          fbBuilder.writeListBool(usedElementIsQualifiedFlags);
    }
    var usedElementKinds = _usedElementKinds;
    if (!(usedElementKinds == null || usedElementKinds.isEmpty)) {
      offset_usedElementKinds = fbBuilder
          .writeListUint8(usedElementKinds.map((b) => b.index).toList());
    }
    var usedElementLengths = _usedElementLengths;
    if (!(usedElementLengths == null || usedElementLengths.isEmpty)) {
      offset_usedElementLengths = fbBuilder.writeListUint32(usedElementLengths);
    }
    var usedElementOffsets = _usedElementOffsets;
    if (!(usedElementOffsets == null || usedElementOffsets.isEmpty)) {
      offset_usedElementOffsets = fbBuilder.writeListUint32(usedElementOffsets);
    }
    var usedElements = _usedElements;
    if (!(usedElements == null || usedElements.isEmpty)) {
      offset_usedElements = fbBuilder.writeListUint32(usedElements);
    }
    var usedNameIsQualifiedFlags = _usedNameIsQualifiedFlags;
    if (!(usedNameIsQualifiedFlags == null ||
        usedNameIsQualifiedFlags.isEmpty)) {
      offset_usedNameIsQualifiedFlags =
          fbBuilder.writeListBool(usedNameIsQualifiedFlags);
    }
    var usedNameKinds = _usedNameKinds;
    if (!(usedNameKinds == null || usedNameKinds.isEmpty)) {
      offset_usedNameKinds =
          fbBuilder.writeListUint8(usedNameKinds.map((b) => b.index).toList());
    }
    var usedNameOffsets = _usedNameOffsets;
    if (!(usedNameOffsets == null || usedNameOffsets.isEmpty)) {
      offset_usedNameOffsets = fbBuilder.writeListUint32(usedNameOffsets);
    }
    var usedNames = _usedNames;
    if (!(usedNames == null || usedNames.isEmpty)) {
      offset_usedNames = fbBuilder.writeListUint32(usedNames);
    }
    fbBuilder.startTable();
    if (offset_elementKinds != null) {
      fbBuilder.addOffset(4, offset_elementKinds);
    }
    if (offset_elementNameClassMemberIds != null) {
      fbBuilder.addOffset(7, offset_elementNameClassMemberIds);
    }
    if (offset_elementNameParameterIds != null) {
      fbBuilder.addOffset(8, offset_elementNameParameterIds);
    }
    if (offset_elementNameUnitMemberIds != null) {
      fbBuilder.addOffset(6, offset_elementNameUnitMemberIds);
    }
    if (offset_elementUnits != null) {
      fbBuilder.addOffset(5, offset_elementUnits);
    }
    fbBuilder.addUint32(1, _nullStringId, 0);
    if (offset_strings != null) {
      fbBuilder.addOffset(0, offset_strings);
    }
    if (offset_subtypes != null) {
      fbBuilder.addOffset(19, offset_subtypes);
    }
    if (offset_supertypes != null) {
      fbBuilder.addOffset(18, offset_supertypes);
    }
    if (offset_unitLibraryUris != null) {
      fbBuilder.addOffset(2, offset_unitLibraryUris);
    }
    if (offset_unitUnitUris != null) {
      fbBuilder.addOffset(3, offset_unitUnitUris);
    }
    if (offset_usedElementIsQualifiedFlags != null) {
      fbBuilder.addOffset(13, offset_usedElementIsQualifiedFlags);
    }
    if (offset_usedElementKinds != null) {
      fbBuilder.addOffset(10, offset_usedElementKinds);
    }
    if (offset_usedElementLengths != null) {
      fbBuilder.addOffset(12, offset_usedElementLengths);
    }
    if (offset_usedElementOffsets != null) {
      fbBuilder.addOffset(11, offset_usedElementOffsets);
    }
    if (offset_usedElements != null) {
      fbBuilder.addOffset(9, offset_usedElements);
    }
    if (offset_usedNameIsQualifiedFlags != null) {
      fbBuilder.addOffset(17, offset_usedNameIsQualifiedFlags);
    }
    if (offset_usedNameKinds != null) {
      fbBuilder.addOffset(15, offset_usedNameKinds);
    }
    if (offset_usedNameOffsets != null) {
      fbBuilder.addOffset(16, offset_usedNameOffsets);
    }
    if (offset_usedNames != null) {
      fbBuilder.addOffset(14, offset_usedNames);
    }
    return fbBuilder.endTable();
  }
}

idl.AnalysisDriverUnitIndex readAnalysisDriverUnitIndex(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AnalysisDriverUnitIndexReader().read(rootRef, 0);
}

class _AnalysisDriverUnitIndexReader
    extends fb.TableReader<_AnalysisDriverUnitIndexImpl> {
  const _AnalysisDriverUnitIndexReader();

  @override
  _AnalysisDriverUnitIndexImpl createObject(fb.BufferContext bc, int offset) =>
      _AnalysisDriverUnitIndexImpl(bc, offset);
}

class _AnalysisDriverUnitIndexImpl extends Object
    with _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AnalysisDriverUnitIndexImpl(this._bc, this._bcOffset);

  List<idl.IndexSyntheticElementKind>? _elementKinds;
  List<int>? _elementNameClassMemberIds;
  List<int>? _elementNameParameterIds;
  List<int>? _elementNameUnitMemberIds;
  List<int>? _elementUnits;
  int? _nullStringId;
  List<String>? _strings;
  List<idl.AnalysisDriverSubtype>? _subtypes;
  List<int>? _supertypes;
  List<int>? _unitLibraryUris;
  List<int>? _unitUnitUris;
  List<bool>? _usedElementIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedElementKinds;
  List<int>? _usedElementLengths;
  List<int>? _usedElementOffsets;
  List<int>? _usedElements;
  List<bool>? _usedNameIsQualifiedFlags;
  List<idl.IndexRelationKind>? _usedNameKinds;
  List<int>? _usedNameOffsets;
  List<int>? _usedNames;

  @override
  List<idl.IndexSyntheticElementKind> get elementKinds {
    return _elementKinds ??= const fb.ListReader<idl.IndexSyntheticElementKind>(
            _IndexSyntheticElementKindReader())
        .vTableGet(_bc, _bcOffset, 4, const <idl.IndexSyntheticElementKind>[]);
  }

  @override
  List<int> get elementNameClassMemberIds {
    return _elementNameClassMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 7, const <int>[]);
  }

  @override
  List<int> get elementNameParameterIds {
    return _elementNameParameterIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 8, const <int>[]);
  }

  @override
  List<int> get elementNameUnitMemberIds {
    return _elementNameUnitMemberIds ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 6, const <int>[]);
  }

  @override
  List<int> get elementUnits {
    return _elementUnits ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
  }

  @override
  int get nullStringId {
    return _nullStringId ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  List<String> get strings {
    return _strings ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
  }

  @override
  List<idl.AnalysisDriverSubtype> get subtypes {
    return _subtypes ??= const fb.ListReader<idl.AnalysisDriverSubtype>(
            _AnalysisDriverSubtypeReader())
        .vTableGet(_bc, _bcOffset, 19, const <idl.AnalysisDriverSubtype>[]);
  }

  @override
  List<int> get supertypes {
    return _supertypes ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 18, const <int>[]);
  }

  @override
  List<int> get unitLibraryUris {
    return _unitLibraryUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 2, const <int>[]);
  }

  @override
  List<int> get unitUnitUris {
    return _unitUnitUris ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 3, const <int>[]);
  }

  @override
  List<bool> get usedElementIsQualifiedFlags {
    return _usedElementIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 13, const <bool>[]);
  }

  @override
  List<idl.IndexRelationKind> get usedElementKinds {
    return _usedElementKinds ??=
        const fb.ListReader<idl.IndexRelationKind>(_IndexRelationKindReader())
            .vTableGet(_bc, _bcOffset, 10, const <idl.IndexRelationKind>[]);
  }

  @override
  List<int> get usedElementLengths {
    return _usedElementLengths ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 12, const <int>[]);
  }

  @override
  List<int> get usedElementOffsets {
    return _usedElementOffsets ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 11, const <int>[]);
  }

  @override
  List<int> get usedElements {
    return _usedElements ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 9, const <int>[]);
  }

  @override
  List<bool> get usedNameIsQualifiedFlags {
    return _usedNameIsQualifiedFlags ??=
        const fb.BoolListReader().vTableGet(_bc, _bcOffset, 17, const <bool>[]);
  }

  @override
  List<idl.IndexRelationKind> get usedNameKinds {
    return _usedNameKinds ??=
        const fb.ListReader<idl.IndexRelationKind>(_IndexRelationKindReader())
            .vTableGet(_bc, _bcOffset, 15, const <idl.IndexRelationKind>[]);
  }

  @override
  List<int> get usedNameOffsets {
    return _usedNameOffsets ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 16, const <int>[]);
  }

  @override
  List<int> get usedNames {
    return _usedNames ??= const fb.Uint32ListReader()
        .vTableGet(_bc, _bcOffset, 14, const <int>[]);
  }
}

abstract class _AnalysisDriverUnitIndexMixin
    implements idl.AnalysisDriverUnitIndex {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_elementKinds = elementKinds;
    if (local_elementKinds.isNotEmpty) {
      result["elementKinds"] = local_elementKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_elementNameClassMemberIds = elementNameClassMemberIds;
    if (local_elementNameClassMemberIds.isNotEmpty) {
      result["elementNameClassMemberIds"] = local_elementNameClassMemberIds;
    }
    var local_elementNameParameterIds = elementNameParameterIds;
    if (local_elementNameParameterIds.isNotEmpty) {
      result["elementNameParameterIds"] = local_elementNameParameterIds;
    }
    var local_elementNameUnitMemberIds = elementNameUnitMemberIds;
    if (local_elementNameUnitMemberIds.isNotEmpty) {
      result["elementNameUnitMemberIds"] = local_elementNameUnitMemberIds;
    }
    var local_elementUnits = elementUnits;
    if (local_elementUnits.isNotEmpty) {
      result["elementUnits"] = local_elementUnits;
    }
    var local_nullStringId = nullStringId;
    if (local_nullStringId != 0) {
      result["nullStringId"] = local_nullStringId;
    }
    var local_strings = strings;
    if (local_strings.isNotEmpty) {
      result["strings"] = local_strings;
    }
    var local_subtypes = subtypes;
    if (local_subtypes.isNotEmpty) {
      result["subtypes"] =
          local_subtypes.map((value) => value.toJson()).toList();
    }
    var local_supertypes = supertypes;
    if (local_supertypes.isNotEmpty) {
      result["supertypes"] = local_supertypes;
    }
    var local_unitLibraryUris = unitLibraryUris;
    if (local_unitLibraryUris.isNotEmpty) {
      result["unitLibraryUris"] = local_unitLibraryUris;
    }
    var local_unitUnitUris = unitUnitUris;
    if (local_unitUnitUris.isNotEmpty) {
      result["unitUnitUris"] = local_unitUnitUris;
    }
    var local_usedElementIsQualifiedFlags = usedElementIsQualifiedFlags;
    if (local_usedElementIsQualifiedFlags.isNotEmpty) {
      result["usedElementIsQualifiedFlags"] = local_usedElementIsQualifiedFlags;
    }
    var local_usedElementKinds = usedElementKinds;
    if (local_usedElementKinds.isNotEmpty) {
      result["usedElementKinds"] = local_usedElementKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_usedElementLengths = usedElementLengths;
    if (local_usedElementLengths.isNotEmpty) {
      result["usedElementLengths"] = local_usedElementLengths;
    }
    var local_usedElementOffsets = usedElementOffsets;
    if (local_usedElementOffsets.isNotEmpty) {
      result["usedElementOffsets"] = local_usedElementOffsets;
    }
    var local_usedElements = usedElements;
    if (local_usedElements.isNotEmpty) {
      result["usedElements"] = local_usedElements;
    }
    var local_usedNameIsQualifiedFlags = usedNameIsQualifiedFlags;
    if (local_usedNameIsQualifiedFlags.isNotEmpty) {
      result["usedNameIsQualifiedFlags"] = local_usedNameIsQualifiedFlags;
    }
    var local_usedNameKinds = usedNameKinds;
    if (local_usedNameKinds.isNotEmpty) {
      result["usedNameKinds"] = local_usedNameKinds
          .map((value) => value.toString().split('.')[1])
          .toList();
    }
    var local_usedNameOffsets = usedNameOffsets;
    if (local_usedNameOffsets.isNotEmpty) {
      result["usedNameOffsets"] = local_usedNameOffsets;
    }
    var local_usedNames = usedNames;
    if (local_usedNames.isNotEmpty) {
      result["usedNames"] = local_usedNames;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "elementKinds": elementKinds,
        "elementNameClassMemberIds": elementNameClassMemberIds,
        "elementNameParameterIds": elementNameParameterIds,
        "elementNameUnitMemberIds": elementNameUnitMemberIds,
        "elementUnits": elementUnits,
        "nullStringId": nullStringId,
        "strings": strings,
        "subtypes": subtypes,
        "supertypes": supertypes,
        "unitLibraryUris": unitLibraryUris,
        "unitUnitUris": unitUnitUris,
        "usedElementIsQualifiedFlags": usedElementIsQualifiedFlags,
        "usedElementKinds": usedElementKinds,
        "usedElementLengths": usedElementLengths,
        "usedElementOffsets": usedElementOffsets,
        "usedElements": usedElements,
        "usedNameIsQualifiedFlags": usedNameIsQualifiedFlags,
        "usedNameKinds": usedNameKinds,
        "usedNameOffsets": usedNameOffsets,
        "usedNames": usedNames,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableDeclarationBuilder extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  List<AvailableDeclarationBuilder>? _children;
  int? _codeLength;
  int? _codeOffset;
  String? _defaultArgumentListString;
  List<int>? _defaultArgumentListTextRanges;
  String? _docComplete;
  String? _docSummary;
  int? _fieldMask;
  bool? _isAbstract;
  bool? _isConst;
  bool? _isDeprecated;
  bool? _isFinal;
  bool? _isStatic;
  idl.AvailableDeclarationKind? _kind;
  int? _locationOffset;
  int? _locationStartColumn;
  int? _locationStartLine;
  String? _name;
  List<String>? _parameterNames;
  String? _parameters;
  List<String>? _parameterTypes;
  List<String>? _relevanceTags;
  int? _requiredParameterCount;
  String? _returnType;
  String? _typeParameters;

  @override
  List<AvailableDeclarationBuilder> get children =>
      _children ??= <AvailableDeclarationBuilder>[];

  set children(List<AvailableDeclarationBuilder> value) {
    this._children = value;
  }

  @override
  int get codeLength => _codeLength ??= 0;

  set codeLength(int value) {
    assert(value >= 0);
    this._codeLength = value;
  }

  @override
  int get codeOffset => _codeOffset ??= 0;

  set codeOffset(int value) {
    assert(value >= 0);
    this._codeOffset = value;
  }

  @override
  String get defaultArgumentListString => _defaultArgumentListString ??= '';

  set defaultArgumentListString(String value) {
    this._defaultArgumentListString = value;
  }

  @override
  List<int> get defaultArgumentListTextRanges =>
      _defaultArgumentListTextRanges ??= <int>[];

  set defaultArgumentListTextRanges(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._defaultArgumentListTextRanges = value;
  }

  @override
  String get docComplete => _docComplete ??= '';

  set docComplete(String value) {
    this._docComplete = value;
  }

  @override
  String get docSummary => _docSummary ??= '';

  set docSummary(String value) {
    this._docSummary = value;
  }

  @override
  int get fieldMask => _fieldMask ??= 0;

  set fieldMask(int value) {
    assert(value >= 0);
    this._fieldMask = value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  set isAbstract(bool value) {
    this._isAbstract = value;
  }

  @override
  bool get isConst => _isConst ??= false;

  set isConst(bool value) {
    this._isConst = value;
  }

  @override
  bool get isDeprecated => _isDeprecated ??= false;

  set isDeprecated(bool value) {
    this._isDeprecated = value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  set isFinal(bool value) {
    this._isFinal = value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  set isStatic(bool value) {
    this._isStatic = value;
  }

  @override
  idl.AvailableDeclarationKind get kind =>
      _kind ??= idl.AvailableDeclarationKind.CLASS;

  /// The kind of the declaration.
  set kind(idl.AvailableDeclarationKind value) {
    this._kind = value;
  }

  @override
  int get locationOffset => _locationOffset ??= 0;

  set locationOffset(int value) {
    assert(value >= 0);
    this._locationOffset = value;
  }

  @override
  int get locationStartColumn => _locationStartColumn ??= 0;

  set locationStartColumn(int value) {
    assert(value >= 0);
    this._locationStartColumn = value;
  }

  @override
  int get locationStartLine => _locationStartLine ??= 0;

  set locationStartLine(int value) {
    assert(value >= 0);
    this._locationStartLine = value;
  }

  @override
  String get name => _name ??= '';

  /// The first part of the declaration name, usually the only one, for example
  /// the name of a class like `MyClass`, or a function like `myFunction`.
  set name(String value) {
    this._name = value;
  }

  @override
  List<String> get parameterNames => _parameterNames ??= <String>[];

  set parameterNames(List<String> value) {
    this._parameterNames = value;
  }

  @override
  String get parameters => _parameters ??= '';

  set parameters(String value) {
    this._parameters = value;
  }

  @override
  List<String> get parameterTypes => _parameterTypes ??= <String>[];

  set parameterTypes(List<String> value) {
    this._parameterTypes = value;
  }

  @override
  List<String> get relevanceTags => _relevanceTags ??= <String>[];

  /// The partial list of relevance tags.  Not every declaration has one (for
  /// example, function do not currently), and not every declaration has to
  /// store one (for classes it can be computed when we know the library that
  /// includes this file).
  set relevanceTags(List<String> value) {
    this._relevanceTags = value;
  }

  @override
  int get requiredParameterCount => _requiredParameterCount ??= 0;

  set requiredParameterCount(int value) {
    assert(value >= 0);
    this._requiredParameterCount = value;
  }

  @override
  String get returnType => _returnType ??= '';

  set returnType(String value) {
    this._returnType = value;
  }

  @override
  String get typeParameters => _typeParameters ??= '';

  set typeParameters(String value) {
    this._typeParameters = value;
  }

  AvailableDeclarationBuilder(
      {List<AvailableDeclarationBuilder>? children,
      int? codeLength,
      int? codeOffset,
      String? defaultArgumentListString,
      List<int>? defaultArgumentListTextRanges,
      String? docComplete,
      String? docSummary,
      int? fieldMask,
      bool? isAbstract,
      bool? isConst,
      bool? isDeprecated,
      bool? isFinal,
      bool? isStatic,
      idl.AvailableDeclarationKind? kind,
      int? locationOffset,
      int? locationStartColumn,
      int? locationStartLine,
      String? name,
      List<String>? parameterNames,
      String? parameters,
      List<String>? parameterTypes,
      List<String>? relevanceTags,
      int? requiredParameterCount,
      String? returnType,
      String? typeParameters})
      : _children = children,
        _codeLength = codeLength,
        _codeOffset = codeOffset,
        _defaultArgumentListString = defaultArgumentListString,
        _defaultArgumentListTextRanges = defaultArgumentListTextRanges,
        _docComplete = docComplete,
        _docSummary = docSummary,
        _fieldMask = fieldMask,
        _isAbstract = isAbstract,
        _isConst = isConst,
        _isDeprecated = isDeprecated,
        _isFinal = isFinal,
        _isStatic = isStatic,
        _kind = kind,
        _locationOffset = locationOffset,
        _locationStartColumn = locationStartColumn,
        _locationStartLine = locationStartLine,
        _name = name,
        _parameterNames = parameterNames,
        _parameters = parameters,
        _parameterTypes = parameterTypes,
        _relevanceTags = relevanceTags,
        _requiredParameterCount = requiredParameterCount,
        _returnType = returnType,
        _typeParameters = typeParameters;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _children?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var children = this._children;
    if (children == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(children.length);
      for (var x in children) {
        x.collectApiSignature(signatureSink);
      }
    }
    signatureSink.addInt(this._codeLength ?? 0);
    signatureSink.addInt(this._codeOffset ?? 0);
    signatureSink.addString(this._defaultArgumentListString ?? '');
    var defaultArgumentListTextRanges = this._defaultArgumentListTextRanges;
    if (defaultArgumentListTextRanges == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(defaultArgumentListTextRanges.length);
      for (var x in defaultArgumentListTextRanges) {
        signatureSink.addInt(x);
      }
    }
    signatureSink.addString(this._docComplete ?? '');
    signatureSink.addString(this._docSummary ?? '');
    signatureSink.addInt(this._fieldMask ?? 0);
    signatureSink.addBool(this._isAbstract == true);
    signatureSink.addBool(this._isConst == true);
    signatureSink.addBool(this._isDeprecated == true);
    signatureSink.addBool(this._isFinal == true);
    signatureSink.addBool(this._isStatic == true);
    signatureSink.addInt(this._kind?.index ?? 0);
    signatureSink.addInt(this._locationOffset ?? 0);
    signatureSink.addInt(this._locationStartColumn ?? 0);
    signatureSink.addInt(this._locationStartLine ?? 0);
    signatureSink.addString(this._name ?? '');
    var parameterNames = this._parameterNames;
    if (parameterNames == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(parameterNames.length);
      for (var x in parameterNames) {
        signatureSink.addString(x);
      }
    }
    signatureSink.addString(this._parameters ?? '');
    var parameterTypes = this._parameterTypes;
    if (parameterTypes == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(parameterTypes.length);
      for (var x in parameterTypes) {
        signatureSink.addString(x);
      }
    }
    var relevanceTags = this._relevanceTags;
    if (relevanceTags == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(relevanceTags.length);
      for (var x in relevanceTags) {
        signatureSink.addString(x);
      }
    }
    signatureSink.addInt(this._requiredParameterCount ?? 0);
    signatureSink.addString(this._returnType ?? '');
    signatureSink.addString(this._typeParameters ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_children;
    fb.Offset? offset_defaultArgumentListString;
    fb.Offset? offset_defaultArgumentListTextRanges;
    fb.Offset? offset_docComplete;
    fb.Offset? offset_docSummary;
    fb.Offset? offset_name;
    fb.Offset? offset_parameterNames;
    fb.Offset? offset_parameters;
    fb.Offset? offset_parameterTypes;
    fb.Offset? offset_relevanceTags;
    fb.Offset? offset_returnType;
    fb.Offset? offset_typeParameters;
    var children = _children;
    if (!(children == null || children.isEmpty)) {
      offset_children = fbBuilder
          .writeList(children.map((b) => b.finish(fbBuilder)).toList());
    }
    var defaultArgumentListString = _defaultArgumentListString;
    if (defaultArgumentListString != null) {
      offset_defaultArgumentListString =
          fbBuilder.writeString(defaultArgumentListString);
    }
    var defaultArgumentListTextRanges = _defaultArgumentListTextRanges;
    if (!(defaultArgumentListTextRanges == null ||
        defaultArgumentListTextRanges.isEmpty)) {
      offset_defaultArgumentListTextRanges =
          fbBuilder.writeListUint32(defaultArgumentListTextRanges);
    }
    var docComplete = _docComplete;
    if (docComplete != null) {
      offset_docComplete = fbBuilder.writeString(docComplete);
    }
    var docSummary = _docSummary;
    if (docSummary != null) {
      offset_docSummary = fbBuilder.writeString(docSummary);
    }
    var name = _name;
    if (name != null) {
      offset_name = fbBuilder.writeString(name);
    }
    var parameterNames = _parameterNames;
    if (!(parameterNames == null || parameterNames.isEmpty)) {
      offset_parameterNames = fbBuilder.writeList(
          parameterNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    var parameters = _parameters;
    if (parameters != null) {
      offset_parameters = fbBuilder.writeString(parameters);
    }
    var parameterTypes = _parameterTypes;
    if (!(parameterTypes == null || parameterTypes.isEmpty)) {
      offset_parameterTypes = fbBuilder.writeList(
          parameterTypes.map((b) => fbBuilder.writeString(b)).toList());
    }
    var relevanceTags = _relevanceTags;
    if (!(relevanceTags == null || relevanceTags.isEmpty)) {
      offset_relevanceTags = fbBuilder.writeList(
          relevanceTags.map((b) => fbBuilder.writeString(b)).toList());
    }
    var returnType = _returnType;
    if (returnType != null) {
      offset_returnType = fbBuilder.writeString(returnType);
    }
    var typeParameters = _typeParameters;
    if (typeParameters != null) {
      offset_typeParameters = fbBuilder.writeString(typeParameters);
    }
    fbBuilder.startTable();
    if (offset_children != null) {
      fbBuilder.addOffset(0, offset_children);
    }
    fbBuilder.addUint32(1, _codeLength, 0);
    fbBuilder.addUint32(2, _codeOffset, 0);
    if (offset_defaultArgumentListString != null) {
      fbBuilder.addOffset(3, offset_defaultArgumentListString);
    }
    if (offset_defaultArgumentListTextRanges != null) {
      fbBuilder.addOffset(4, offset_defaultArgumentListTextRanges);
    }
    if (offset_docComplete != null) {
      fbBuilder.addOffset(5, offset_docComplete);
    }
    if (offset_docSummary != null) {
      fbBuilder.addOffset(6, offset_docSummary);
    }
    fbBuilder.addUint32(7, _fieldMask, 0);
    fbBuilder.addBool(8, _isAbstract == true);
    fbBuilder.addBool(9, _isConst == true);
    fbBuilder.addBool(10, _isDeprecated == true);
    fbBuilder.addBool(11, _isFinal == true);
    fbBuilder.addBool(12, _isStatic == true);
    fbBuilder.addUint8(
        13, _kind?.index, idl.AvailableDeclarationKind.CLASS.index);
    fbBuilder.addUint32(14, _locationOffset, 0);
    fbBuilder.addUint32(15, _locationStartColumn, 0);
    fbBuilder.addUint32(16, _locationStartLine, 0);
    if (offset_name != null) {
      fbBuilder.addOffset(17, offset_name);
    }
    if (offset_parameterNames != null) {
      fbBuilder.addOffset(18, offset_parameterNames);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(19, offset_parameters);
    }
    if (offset_parameterTypes != null) {
      fbBuilder.addOffset(20, offset_parameterTypes);
    }
    if (offset_relevanceTags != null) {
      fbBuilder.addOffset(21, offset_relevanceTags);
    }
    fbBuilder.addUint32(22, _requiredParameterCount, 0);
    if (offset_returnType != null) {
      fbBuilder.addOffset(23, offset_returnType);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(24, offset_typeParameters);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableDeclarationReader
    extends fb.TableReader<_AvailableDeclarationImpl> {
  const _AvailableDeclarationReader();

  @override
  _AvailableDeclarationImpl createObject(fb.BufferContext bc, int offset) =>
      _AvailableDeclarationImpl(bc, offset);
}

class _AvailableDeclarationImpl extends Object
    with _AvailableDeclarationMixin
    implements idl.AvailableDeclaration {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableDeclarationImpl(this._bc, this._bcOffset);

  List<idl.AvailableDeclaration>? _children;
  int? _codeLength;
  int? _codeOffset;
  String? _defaultArgumentListString;
  List<int>? _defaultArgumentListTextRanges;
  String? _docComplete;
  String? _docSummary;
  int? _fieldMask;
  bool? _isAbstract;
  bool? _isConst;
  bool? _isDeprecated;
  bool? _isFinal;
  bool? _isStatic;
  idl.AvailableDeclarationKind? _kind;
  int? _locationOffset;
  int? _locationStartColumn;
  int? _locationStartLine;
  String? _name;
  List<String>? _parameterNames;
  String? _parameters;
  List<String>? _parameterTypes;
  List<String>? _relevanceTags;
  int? _requiredParameterCount;
  String? _returnType;
  String? _typeParameters;

  @override
  List<idl.AvailableDeclaration> get children {
    return _children ??= const fb.ListReader<idl.AvailableDeclaration>(
            _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
  }

  @override
  int get codeLength {
    return _codeLength ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  int get codeOffset {
    return _codeOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 2, 0);
  }

  @override
  String get defaultArgumentListString {
    return _defaultArgumentListString ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 3, '');
  }

  @override
  List<int> get defaultArgumentListTextRanges {
    return _defaultArgumentListTextRanges ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 4, const <int>[]);
  }

  @override
  String get docComplete {
    return _docComplete ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 5, '');
  }

  @override
  String get docSummary {
    return _docSummary ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 6, '');
  }

  @override
  int get fieldMask {
    return _fieldMask ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 7, 0);
  }

  @override
  bool get isAbstract {
    return _isAbstract ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 8, false);
  }

  @override
  bool get isConst {
    return _isConst ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 9, false);
  }

  @override
  bool get isDeprecated {
    return _isDeprecated ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 10, false);
  }

  @override
  bool get isFinal {
    return _isFinal ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 11, false);
  }

  @override
  bool get isStatic {
    return _isStatic ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 12, false);
  }

  @override
  idl.AvailableDeclarationKind get kind {
    return _kind ??= const _AvailableDeclarationKindReader()
        .vTableGet(_bc, _bcOffset, 13, idl.AvailableDeclarationKind.CLASS);
  }

  @override
  int get locationOffset {
    return _locationOffset ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 14, 0);
  }

  @override
  int get locationStartColumn {
    return _locationStartColumn ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 15, 0);
  }

  @override
  int get locationStartLine {
    return _locationStartLine ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 16, 0);
  }

  @override
  String get name {
    return _name ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 17, '');
  }

  @override
  List<String> get parameterNames {
    return _parameterNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 18, const <String>[]);
  }

  @override
  String get parameters {
    return _parameters ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 19, '');
  }

  @override
  List<String> get parameterTypes {
    return _parameterTypes ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 20, const <String>[]);
  }

  @override
  List<String> get relevanceTags {
    return _relevanceTags ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 21, const <String>[]);
  }

  @override
  int get requiredParameterCount {
    return _requiredParameterCount ??=
        const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 22, 0);
  }

  @override
  String get returnType {
    return _returnType ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 23, '');
  }

  @override
  String get typeParameters {
    return _typeParameters ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 24, '');
  }
}

abstract class _AvailableDeclarationMixin implements idl.AvailableDeclaration {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_children = children;
    if (local_children.isNotEmpty) {
      result["children"] =
          local_children.map((value) => value.toJson()).toList();
    }
    var local_codeLength = codeLength;
    if (local_codeLength != 0) {
      result["codeLength"] = local_codeLength;
    }
    var local_codeOffset = codeOffset;
    if (local_codeOffset != 0) {
      result["codeOffset"] = local_codeOffset;
    }
    var local_defaultArgumentListString = defaultArgumentListString;
    if (local_defaultArgumentListString != '') {
      result["defaultArgumentListString"] = local_defaultArgumentListString;
    }
    var local_defaultArgumentListTextRanges = defaultArgumentListTextRanges;
    if (local_defaultArgumentListTextRanges.isNotEmpty) {
      result["defaultArgumentListTextRanges"] =
          local_defaultArgumentListTextRanges;
    }
    var local_docComplete = docComplete;
    if (local_docComplete != '') {
      result["docComplete"] = local_docComplete;
    }
    var local_docSummary = docSummary;
    if (local_docSummary != '') {
      result["docSummary"] = local_docSummary;
    }
    var local_fieldMask = fieldMask;
    if (local_fieldMask != 0) {
      result["fieldMask"] = local_fieldMask;
    }
    var local_isAbstract = isAbstract;
    if (local_isAbstract != false) {
      result["isAbstract"] = local_isAbstract;
    }
    var local_isConst = isConst;
    if (local_isConst != false) {
      result["isConst"] = local_isConst;
    }
    var local_isDeprecated = isDeprecated;
    if (local_isDeprecated != false) {
      result["isDeprecated"] = local_isDeprecated;
    }
    var local_isFinal = isFinal;
    if (local_isFinal != false) {
      result["isFinal"] = local_isFinal;
    }
    var local_isStatic = isStatic;
    if (local_isStatic != false) {
      result["isStatic"] = local_isStatic;
    }
    var local_kind = kind;
    if (local_kind != idl.AvailableDeclarationKind.CLASS) {
      result["kind"] = local_kind.toString().split('.')[1];
    }
    var local_locationOffset = locationOffset;
    if (local_locationOffset != 0) {
      result["locationOffset"] = local_locationOffset;
    }
    var local_locationStartColumn = locationStartColumn;
    if (local_locationStartColumn != 0) {
      result["locationStartColumn"] = local_locationStartColumn;
    }
    var local_locationStartLine = locationStartLine;
    if (local_locationStartLine != 0) {
      result["locationStartLine"] = local_locationStartLine;
    }
    var local_name = name;
    if (local_name != '') {
      result["name"] = local_name;
    }
    var local_parameterNames = parameterNames;
    if (local_parameterNames.isNotEmpty) {
      result["parameterNames"] = local_parameterNames;
    }
    var local_parameters = parameters;
    if (local_parameters != '') {
      result["parameters"] = local_parameters;
    }
    var local_parameterTypes = parameterTypes;
    if (local_parameterTypes.isNotEmpty) {
      result["parameterTypes"] = local_parameterTypes;
    }
    var local_relevanceTags = relevanceTags;
    if (local_relevanceTags.isNotEmpty) {
      result["relevanceTags"] = local_relevanceTags;
    }
    var local_requiredParameterCount = requiredParameterCount;
    if (local_requiredParameterCount != 0) {
      result["requiredParameterCount"] = local_requiredParameterCount;
    }
    var local_returnType = returnType;
    if (local_returnType != '') {
      result["returnType"] = local_returnType;
    }
    var local_typeParameters = typeParameters;
    if (local_typeParameters != '') {
      result["typeParameters"] = local_typeParameters;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "children": children,
        "codeLength": codeLength,
        "codeOffset": codeOffset,
        "defaultArgumentListString": defaultArgumentListString,
        "defaultArgumentListTextRanges": defaultArgumentListTextRanges,
        "docComplete": docComplete,
        "docSummary": docSummary,
        "fieldMask": fieldMask,
        "isAbstract": isAbstract,
        "isConst": isConst,
        "isDeprecated": isDeprecated,
        "isFinal": isFinal,
        "isStatic": isStatic,
        "kind": kind,
        "locationOffset": locationOffset,
        "locationStartColumn": locationStartColumn,
        "locationStartLine": locationStartLine,
        "name": name,
        "parameterNames": parameterNames,
        "parameters": parameters,
        "parameterTypes": parameterTypes,
        "relevanceTags": relevanceTags,
        "requiredParameterCount": requiredParameterCount,
        "returnType": returnType,
        "typeParameters": typeParameters,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileBuilder extends Object
    with _AvailableFileMixin
    implements idl.AvailableFile {
  List<AvailableDeclarationBuilder>? _declarations;
  DirectiveInfoBuilder? _directiveInfo;
  List<AvailableFileExportBuilder>? _exports;
  bool? _isLibrary;
  bool? _isLibraryDeprecated;
  List<int>? _lineStarts;
  List<String>? _parts;

  @override
  List<AvailableDeclarationBuilder> get declarations =>
      _declarations ??= <AvailableDeclarationBuilder>[];

  /// Declarations of the file.
  set declarations(List<AvailableDeclarationBuilder> value) {
    this._declarations = value;
  }

  @override
  DirectiveInfoBuilder? get directiveInfo => _directiveInfo;

  /// The Dartdoc directives in the file.
  set directiveInfo(DirectiveInfoBuilder? value) {
    this._directiveInfo = value;
  }

  @override
  List<AvailableFileExportBuilder> get exports =>
      _exports ??= <AvailableFileExportBuilder>[];

  /// Exports directives of the file.
  set exports(List<AvailableFileExportBuilder> value) {
    this._exports = value;
  }

  @override
  bool get isLibrary => _isLibrary ??= false;

  /// Is `true` if this file is a library.
  set isLibrary(bool value) {
    this._isLibrary = value;
  }

  @override
  bool get isLibraryDeprecated => _isLibraryDeprecated ??= false;

  /// Is `true` if this file is a library, and it is deprecated.
  set isLibraryDeprecated(bool value) {
    this._isLibraryDeprecated = value;
  }

  @override
  List<int> get lineStarts => _lineStarts ??= <int>[];

  /// Offsets of the first character of each line in the source code.
  set lineStarts(List<int> value) {
    assert(value.every((e) => e >= 0));
    this._lineStarts = value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /// URIs of `part` directives.
  set parts(List<String> value) {
    this._parts = value;
  }

  AvailableFileBuilder(
      {List<AvailableDeclarationBuilder>? declarations,
      DirectiveInfoBuilder? directiveInfo,
      List<AvailableFileExportBuilder>? exports,
      bool? isLibrary,
      bool? isLibraryDeprecated,
      List<int>? lineStarts,
      List<String>? parts})
      : _declarations = declarations,
        _directiveInfo = directiveInfo,
        _exports = exports,
        _isLibrary = isLibrary,
        _isLibraryDeprecated = isLibraryDeprecated,
        _lineStarts = lineStarts,
        _parts = parts;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _declarations?.forEach((b) => b.flushInformative());
    _directiveInfo?.flushInformative();
    _exports?.forEach((b) => b.flushInformative());
    _lineStarts = null;
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var declarations = this._declarations;
    if (declarations == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(declarations.length);
      for (var x in declarations) {
        x.collectApiSignature(signatureSink);
      }
    }
    signatureSink.addBool(this._directiveInfo != null);
    this._directiveInfo?.collectApiSignature(signatureSink);
    var exports = this._exports;
    if (exports == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(exports.length);
      for (var x in exports) {
        x.collectApiSignature(signatureSink);
      }
    }
    signatureSink.addBool(this._isLibrary == true);
    signatureSink.addBool(this._isLibraryDeprecated == true);
    var parts = this._parts;
    if (parts == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(parts.length);
      for (var x in parts) {
        signatureSink.addString(x);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "UICF");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_declarations;
    fb.Offset? offset_directiveInfo;
    fb.Offset? offset_exports;
    fb.Offset? offset_lineStarts;
    fb.Offset? offset_parts;
    var declarations = _declarations;
    if (!(declarations == null || declarations.isEmpty)) {
      offset_declarations = fbBuilder
          .writeList(declarations.map((b) => b.finish(fbBuilder)).toList());
    }
    var directiveInfo = _directiveInfo;
    if (directiveInfo != null) {
      offset_directiveInfo = directiveInfo.finish(fbBuilder);
    }
    var exports = _exports;
    if (!(exports == null || exports.isEmpty)) {
      offset_exports =
          fbBuilder.writeList(exports.map((b) => b.finish(fbBuilder)).toList());
    }
    var lineStarts = _lineStarts;
    if (!(lineStarts == null || lineStarts.isEmpty)) {
      offset_lineStarts = fbBuilder.writeListUint32(lineStarts);
    }
    var parts = _parts;
    if (!(parts == null || parts.isEmpty)) {
      offset_parts = fbBuilder
          .writeList(parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_declarations != null) {
      fbBuilder.addOffset(0, offset_declarations);
    }
    if (offset_directiveInfo != null) {
      fbBuilder.addOffset(1, offset_directiveInfo);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(2, offset_exports);
    }
    fbBuilder.addBool(3, _isLibrary == true);
    fbBuilder.addBool(4, _isLibraryDeprecated == true);
    if (offset_lineStarts != null) {
      fbBuilder.addOffset(5, offset_lineStarts);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(6, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

idl.AvailableFile readAvailableFile(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _AvailableFileReader().read(rootRef, 0);
}

class _AvailableFileReader extends fb.TableReader<_AvailableFileImpl> {
  const _AvailableFileReader();

  @override
  _AvailableFileImpl createObject(fb.BufferContext bc, int offset) =>
      _AvailableFileImpl(bc, offset);
}

class _AvailableFileImpl extends Object
    with _AvailableFileMixin
    implements idl.AvailableFile {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileImpl(this._bc, this._bcOffset);

  List<idl.AvailableDeclaration>? _declarations;
  idl.DirectiveInfo? _directiveInfo;
  List<idl.AvailableFileExport>? _exports;
  bool? _isLibrary;
  bool? _isLibraryDeprecated;
  List<int>? _lineStarts;
  List<String>? _parts;

  @override
  List<idl.AvailableDeclaration> get declarations {
    return _declarations ??= const fb.ListReader<idl.AvailableDeclaration>(
            _AvailableDeclarationReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AvailableDeclaration>[]);
  }

  @override
  idl.DirectiveInfo? get directiveInfo {
    return _directiveInfo ??=
        const _DirectiveInfoReader().vTableGetOrNull(_bc, _bcOffset, 1);
  }

  @override
  List<idl.AvailableFileExport> get exports {
    return _exports ??= const fb.ListReader<idl.AvailableFileExport>(
            _AvailableFileExportReader())
        .vTableGet(_bc, _bcOffset, 2, const <idl.AvailableFileExport>[]);
  }

  @override
  bool get isLibrary {
    return _isLibrary ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 3, false);
  }

  @override
  bool get isLibraryDeprecated {
    return _isLibraryDeprecated ??=
        const fb.BoolReader().vTableGet(_bc, _bcOffset, 4, false);
  }

  @override
  List<int> get lineStarts {
    return _lineStarts ??=
        const fb.Uint32ListReader().vTableGet(_bc, _bcOffset, 5, const <int>[]);
  }

  @override
  List<String> get parts {
    return _parts ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 6, const <String>[]);
  }
}

abstract class _AvailableFileMixin implements idl.AvailableFile {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_declarations = declarations;
    if (local_declarations.isNotEmpty) {
      result["declarations"] =
          local_declarations.map((value) => value.toJson()).toList();
    }
    var local_directiveInfo = directiveInfo;
    if (local_directiveInfo != null) {
      result["directiveInfo"] = local_directiveInfo.toJson();
    }
    var local_exports = exports;
    if (local_exports.isNotEmpty) {
      result["exports"] = local_exports.map((value) => value.toJson()).toList();
    }
    var local_isLibrary = isLibrary;
    if (local_isLibrary != false) {
      result["isLibrary"] = local_isLibrary;
    }
    var local_isLibraryDeprecated = isLibraryDeprecated;
    if (local_isLibraryDeprecated != false) {
      result["isLibraryDeprecated"] = local_isLibraryDeprecated;
    }
    var local_lineStarts = lineStarts;
    if (local_lineStarts.isNotEmpty) {
      result["lineStarts"] = local_lineStarts;
    }
    var local_parts = parts;
    if (local_parts.isNotEmpty) {
      result["parts"] = local_parts;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "declarations": declarations,
        "directiveInfo": directiveInfo,
        "exports": exports,
        "isLibrary": isLibrary,
        "isLibraryDeprecated": isLibraryDeprecated,
        "lineStarts": lineStarts,
        "parts": parts,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileExportBuilder extends Object
    with _AvailableFileExportMixin
    implements idl.AvailableFileExport {
  List<AvailableFileExportCombinatorBuilder>? _combinators;
  String? _uri;

  @override
  List<AvailableFileExportCombinatorBuilder> get combinators =>
      _combinators ??= <AvailableFileExportCombinatorBuilder>[];

  /// Combinators contained in this export directive.
  set combinators(List<AvailableFileExportCombinatorBuilder> value) {
    this._combinators = value;
  }

  @override
  String get uri => _uri ??= '';

  /// URI of the exported library.
  set uri(String value) {
    this._uri = value;
  }

  AvailableFileExportBuilder(
      {List<AvailableFileExportCombinatorBuilder>? combinators, String? uri})
      : _combinators = combinators,
        _uri = uri;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _combinators?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._uri ?? '');
    var combinators = this._combinators;
    if (combinators == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(combinators.length);
      for (var x in combinators) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_combinators;
    fb.Offset? offset_uri;
    var combinators = _combinators;
    if (!(combinators == null || combinators.isEmpty)) {
      offset_combinators = fbBuilder
          .writeList(combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    var uri = _uri;
    if (uri != null) {
      offset_uri = fbBuilder.writeString(uri);
    }
    fbBuilder.startTable();
    if (offset_combinators != null) {
      fbBuilder.addOffset(1, offset_combinators);
    }
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableFileExportReader
    extends fb.TableReader<_AvailableFileExportImpl> {
  const _AvailableFileExportReader();

  @override
  _AvailableFileExportImpl createObject(fb.BufferContext bc, int offset) =>
      _AvailableFileExportImpl(bc, offset);
}

class _AvailableFileExportImpl extends Object
    with _AvailableFileExportMixin
    implements idl.AvailableFileExport {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileExportImpl(this._bc, this._bcOffset);

  List<idl.AvailableFileExportCombinator>? _combinators;
  String? _uri;

  @override
  List<idl.AvailableFileExportCombinator> get combinators {
    return _combinators ??=
        const fb.ListReader<idl.AvailableFileExportCombinator>(
                _AvailableFileExportCombinatorReader())
            .vTableGet(
                _bc, _bcOffset, 1, const <idl.AvailableFileExportCombinator>[]);
  }

  @override
  String get uri {
    return _uri ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }
}

abstract class _AvailableFileExportMixin implements idl.AvailableFileExport {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_combinators = combinators;
    if (local_combinators.isNotEmpty) {
      result["combinators"] =
          local_combinators.map((value) => value.toJson()).toList();
    }
    var local_uri = uri;
    if (local_uri != '') {
      result["uri"] = local_uri;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "combinators": combinators,
        "uri": uri,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class AvailableFileExportCombinatorBuilder extends Object
    with _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  List<String>? _hides;
  List<String>? _shows;

  @override
  List<String> get hides => _hides ??= <String>[];

  /// List of names which are hidden.  Empty if this is a `show` combinator.
  set hides(List<String> value) {
    this._hides = value;
  }

  @override
  List<String> get shows => _shows ??= <String>[];

  /// List of names which are shown.  Empty if this is a `hide` combinator.
  set shows(List<String> value) {
    this._shows = value;
  }

  AvailableFileExportCombinatorBuilder(
      {List<String>? hides, List<String>? shows})
      : _hides = hides,
        _shows = shows;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var shows = this._shows;
    if (shows == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(shows.length);
      for (var x in shows) {
        signatureSink.addString(x);
      }
    }
    var hides = this._hides;
    if (hides == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(hides.length);
      for (var x in hides) {
        signatureSink.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_hides;
    fb.Offset? offset_shows;
    var hides = _hides;
    if (!(hides == null || hides.isEmpty)) {
      offset_hides = fbBuilder
          .writeList(hides.map((b) => fbBuilder.writeString(b)).toList());
    }
    var shows = _shows;
    if (!(shows == null || shows.isEmpty)) {
      offset_shows = fbBuilder
          .writeList(shows.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_hides != null) {
      fbBuilder.addOffset(1, offset_hides);
    }
    if (offset_shows != null) {
      fbBuilder.addOffset(0, offset_shows);
    }
    return fbBuilder.endTable();
  }
}

class _AvailableFileExportCombinatorReader
    extends fb.TableReader<_AvailableFileExportCombinatorImpl> {
  const _AvailableFileExportCombinatorReader();

  @override
  _AvailableFileExportCombinatorImpl createObject(
          fb.BufferContext bc, int offset) =>
      _AvailableFileExportCombinatorImpl(bc, offset);
}

class _AvailableFileExportCombinatorImpl extends Object
    with _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _AvailableFileExportCombinatorImpl(this._bc, this._bcOffset);

  List<String>? _hides;
  List<String>? _shows;

  @override
  List<String> get hides {
    return _hides ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
  }

  @override
  List<String> get shows {
    return _shows ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
  }
}

abstract class _AvailableFileExportCombinatorMixin
    implements idl.AvailableFileExportCombinator {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_hides = hides;
    if (local_hides.isNotEmpty) {
      result["hides"] = local_hides;
    }
    var local_shows = shows;
    if (local_shows.isNotEmpty) {
      result["shows"] = local_shows;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "hides": hides,
        "shows": shows,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class CiderUnitErrorsBuilder extends Object
    with _CiderUnitErrorsMixin
    implements idl.CiderUnitErrors {
  List<AnalysisDriverUnitErrorBuilder>? _errors;

  @override
  List<AnalysisDriverUnitErrorBuilder> get errors =>
      _errors ??= <AnalysisDriverUnitErrorBuilder>[];

  set errors(List<AnalysisDriverUnitErrorBuilder> value) {
    this._errors = value;
  }

  CiderUnitErrorsBuilder({List<AnalysisDriverUnitErrorBuilder>? errors})
      : _errors = errors;

  /// Flush [informative] data recursively.
  void flushInformative() {
    _errors?.forEach((b) => b.flushInformative());
  }

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var errors = this._errors;
    if (errors == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(errors.length);
      for (var x in errors) {
        x.collectApiSignature(signatureSink);
      }
    }
  }

  typed_data.Uint8List toBuffer() {
    fb.Builder fbBuilder = fb.Builder();
    return fbBuilder.finish(finish(fbBuilder), "CUEr");
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_errors;
    var errors = _errors;
    if (!(errors == null || errors.isEmpty)) {
      offset_errors =
          fbBuilder.writeList(errors.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_errors != null) {
      fbBuilder.addOffset(0, offset_errors);
    }
    return fbBuilder.endTable();
  }
}

idl.CiderUnitErrors readCiderUnitErrors(List<int> buffer) {
  fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);
  return const _CiderUnitErrorsReader().read(rootRef, 0);
}

class _CiderUnitErrorsReader extends fb.TableReader<_CiderUnitErrorsImpl> {
  const _CiderUnitErrorsReader();

  @override
  _CiderUnitErrorsImpl createObject(fb.BufferContext bc, int offset) =>
      _CiderUnitErrorsImpl(bc, offset);
}

class _CiderUnitErrorsImpl extends Object
    with _CiderUnitErrorsMixin
    implements idl.CiderUnitErrors {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _CiderUnitErrorsImpl(this._bc, this._bcOffset);

  List<idl.AnalysisDriverUnitError>? _errors;

  @override
  List<idl.AnalysisDriverUnitError> get errors {
    return _errors ??= const fb.ListReader<idl.AnalysisDriverUnitError>(
            _AnalysisDriverUnitErrorReader())
        .vTableGet(_bc, _bcOffset, 0, const <idl.AnalysisDriverUnitError>[]);
  }
}

abstract class _CiderUnitErrorsMixin implements idl.CiderUnitErrors {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_errors = errors;
    if (local_errors.isNotEmpty) {
      result["errors"] = local_errors.map((value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "errors": errors,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class DiagnosticMessageBuilder extends Object
    with _DiagnosticMessageMixin
    implements idl.DiagnosticMessage {
  String? _filePath;
  int? _length;
  String? _message;
  int? _offset;
  String? _url;

  @override
  String get filePath => _filePath ??= '';

  /// The absolute and normalized path of the file associated with this message.
  set filePath(String value) {
    this._filePath = value;
  }

  @override
  int get length => _length ??= 0;

  /// The length of the source range associated with this message.
  set length(int value) {
    assert(value >= 0);
    this._length = value;
  }

  @override
  String get message => _message ??= '';

  /// The text of the message.
  set message(String value) {
    this._message = value;
  }

  @override
  int get offset => _offset ??= 0;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  set offset(int value) {
    assert(value >= 0);
    this._offset = value;
  }

  @override
  String get url => _url ??= '';

  /// The URL of the message, if any.
  set url(String value) {
    this._url = value;
  }

  DiagnosticMessageBuilder(
      {String? filePath,
      int? length,
      String? message,
      int? offset,
      String? url})
      : _filePath = filePath,
        _length = length,
        _message = message,
        _offset = offset,
        _url = url;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    signatureSink.addString(this._filePath ?? '');
    signatureSink.addInt(this._length ?? 0);
    signatureSink.addString(this._message ?? '');
    signatureSink.addInt(this._offset ?? 0);
    signatureSink.addString(this._url ?? '');
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_filePath;
    fb.Offset? offset_message;
    fb.Offset? offset_url;
    var filePath = _filePath;
    if (filePath != null) {
      offset_filePath = fbBuilder.writeString(filePath);
    }
    var message = _message;
    if (message != null) {
      offset_message = fbBuilder.writeString(message);
    }
    var url = _url;
    if (url != null) {
      offset_url = fbBuilder.writeString(url);
    }
    fbBuilder.startTable();
    if (offset_filePath != null) {
      fbBuilder.addOffset(0, offset_filePath);
    }
    fbBuilder.addUint32(1, _length, 0);
    if (offset_message != null) {
      fbBuilder.addOffset(2, offset_message);
    }
    fbBuilder.addUint32(3, _offset, 0);
    if (offset_url != null) {
      fbBuilder.addOffset(4, offset_url);
    }
    return fbBuilder.endTable();
  }
}

class _DiagnosticMessageReader extends fb.TableReader<_DiagnosticMessageImpl> {
  const _DiagnosticMessageReader();

  @override
  _DiagnosticMessageImpl createObject(fb.BufferContext bc, int offset) =>
      _DiagnosticMessageImpl(bc, offset);
}

class _DiagnosticMessageImpl extends Object
    with _DiagnosticMessageMixin
    implements idl.DiagnosticMessage {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _DiagnosticMessageImpl(this._bc, this._bcOffset);

  String? _filePath;
  int? _length;
  String? _message;
  int? _offset;
  String? _url;

  @override
  String get filePath {
    return _filePath ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 0, '');
  }

  @override
  int get length {
    return _length ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 1, 0);
  }

  @override
  String get message {
    return _message ??=
        const fb.StringReader().vTableGet(_bc, _bcOffset, 2, '');
  }

  @override
  int get offset {
    return _offset ??= const fb.Uint32Reader().vTableGet(_bc, _bcOffset, 3, 0);
  }

  @override
  String get url {
    return _url ??= const fb.StringReader().vTableGet(_bc, _bcOffset, 4, '');
  }
}

abstract class _DiagnosticMessageMixin implements idl.DiagnosticMessage {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_filePath = filePath;
    if (local_filePath != '') {
      result["filePath"] = local_filePath;
    }
    var local_length = length;
    if (local_length != 0) {
      result["length"] = local_length;
    }
    var local_message = message;
    if (local_message != '') {
      result["message"] = local_message;
    }
    var local_offset = offset;
    if (local_offset != 0) {
      result["offset"] = local_offset;
    }
    var local_url = url;
    if (local_url != '') {
      result["url"] = local_url;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "filePath": filePath,
        "length": length,
        "message": message,
        "offset": offset,
        "url": url,
      };

  @override
  String toString() => convert.json.encode(toJson());
}

class DirectiveInfoBuilder extends Object
    with _DirectiveInfoMixin
    implements idl.DirectiveInfo {
  List<String>? _templateNames;
  List<String>? _templateValues;

  @override
  List<String> get templateNames => _templateNames ??= <String>[];

  /// The names of the defined templates.
  set templateNames(List<String> value) {
    this._templateNames = value;
  }

  @override
  List<String> get templateValues => _templateValues ??= <String>[];

  /// The values of the defined templates.
  set templateValues(List<String> value) {
    this._templateValues = value;
  }

  DirectiveInfoBuilder(
      {List<String>? templateNames, List<String>? templateValues})
      : _templateNames = templateNames,
        _templateValues = templateValues;

  /// Flush [informative] data recursively.
  void flushInformative() {}

  /// Accumulate non-[informative] data into [signature].
  void collectApiSignature(api_sig.ApiSignature signatureSink) {
    var templateNames = this._templateNames;
    if (templateNames == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(templateNames.length);
      for (var x in templateNames) {
        signatureSink.addString(x);
      }
    }
    var templateValues = this._templateValues;
    if (templateValues == null) {
      signatureSink.addInt(0);
    } else {
      signatureSink.addInt(templateValues.length);
      for (var x in templateValues) {
        signatureSink.addString(x);
      }
    }
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    fb.Offset? offset_templateNames;
    fb.Offset? offset_templateValues;
    var templateNames = _templateNames;
    if (!(templateNames == null || templateNames.isEmpty)) {
      offset_templateNames = fbBuilder.writeList(
          templateNames.map((b) => fbBuilder.writeString(b)).toList());
    }
    var templateValues = _templateValues;
    if (!(templateValues == null || templateValues.isEmpty)) {
      offset_templateValues = fbBuilder.writeList(
          templateValues.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_templateNames != null) {
      fbBuilder.addOffset(0, offset_templateNames);
    }
    if (offset_templateValues != null) {
      fbBuilder.addOffset(1, offset_templateValues);
    }
    return fbBuilder.endTable();
  }
}

class _DirectiveInfoReader extends fb.TableReader<_DirectiveInfoImpl> {
  const _DirectiveInfoReader();

  @override
  _DirectiveInfoImpl createObject(fb.BufferContext bc, int offset) =>
      _DirectiveInfoImpl(bc, offset);
}

class _DirectiveInfoImpl extends Object
    with _DirectiveInfoMixin
    implements idl.DirectiveInfo {
  final fb.BufferContext _bc;
  final int _bcOffset;

  _DirectiveInfoImpl(this._bc, this._bcOffset);

  List<String>? _templateNames;
  List<String>? _templateValues;

  @override
  List<String> get templateNames {
    return _templateNames ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 0, const <String>[]);
  }

  @override
  List<String> get templateValues {
    return _templateValues ??= const fb.ListReader<String>(fb.StringReader())
        .vTableGet(_bc, _bcOffset, 1, const <String>[]);
  }
}

abstract class _DirectiveInfoMixin implements idl.DirectiveInfo {
  @override
  Map<String, Object> toJson() {
    Map<String, Object> result = <String, Object>{};
    var local_templateNames = templateNames;
    if (local_templateNames.isNotEmpty) {
      result["templateNames"] = local_templateNames;
    }
    var local_templateValues = templateValues;
    if (local_templateValues.isNotEmpty) {
      result["templateValues"] = local_templateValues;
    }
    return result;
  }

  @override
  Map<String, Object?> toMap() => {
        "templateNames": templateNames,
        "templateValues": templateValues,
      };

  @override
  String toString() => convert.json.encode(toJson());
}
