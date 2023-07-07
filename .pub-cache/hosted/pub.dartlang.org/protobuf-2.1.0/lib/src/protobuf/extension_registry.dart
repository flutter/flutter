// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// A collection of [Extension] objects, organized by the message type they
/// extend.
class ExtensionRegistry {
  final Map<String, Map<int, Extension>> _extensions =
      <String, Map<int, Extension>>{};

  // ignore: constant_identifier_names
  static const ExtensionRegistry EMPTY = _EmptyExtensionRegistry();

  /// Stores an [extension] in the registry.
  void add(Extension extension) {
    var map =
        _extensions.putIfAbsent(extension.extendee, () => <int, Extension>{});
    map[extension.tagNumber] = extension;
  }

  /// Stores all [extensions] in the registry.
  void addAll(Iterable<Extension> extensions) {
    extensions.forEach(add);
  }

  /// Retrieves an extension from the registry that adds tag number [tagNumber]
  /// to the [messageName] message type.
  Extension? getExtension(String messageName, int tagNumber) {
    var map = _extensions[messageName];
    if (map != null) {
      return map[tagNumber];
    }
    return null;
  }

  /// Creates a shallow copy of [message], with all extensions in `this` parsed
  /// from the unknown fields of [message] and of every nested submessage.
  ///
  /// Extensions already present in [message] will be preserved.
  ///
  /// If [message] is frozen, the result will be as well.
  ///
  /// Returns the original message if no new extensions are parsed.
  ///
  /// Throws an [InvalidProtocolBufferException] if the parsed extensions are
  /// malformed.
  ///
  /// Using this method to retrieve extensions is more expensive overall than
  /// using an [ExtensionRegistry] with all the needed extensions when doing
  /// [GeneratedMessage.mergeFromBuffer].
  ///
  /// Example:
  ///
  /// `sample.proto`
  /// ```proto
  /// syntax = "proto2";
  ///
  /// message Foo {
  ///   extensions 1 to max;
  /// }
  ///
  /// extend Foo {
  ///   optional string val1 = 1;
  ///   optional string val2 = 2;
  /// }
  /// ```
  /// `main.dart`
  /// ```
  /// import 'package:protobuf/protobuf.dart';
  /// import 'package:test/test.dart';
  /// import 'src/generated/sample.pb.dart';
  ///
  /// void main() {
  ///   ExtensionRegistry r1 = ExtensionRegistry()..add(Sample.val1);
  ///   ExtensionRegistry r2 = ExtensionRegistry()..add(Sample.val2);
  ///   Foo original = Foo()..setExtension(Sample.val1, 'a')..setExtension(Sample.val2, 'b');
  ///   Foo withUnknownFields = Foo.fromBuffer(original.writeToBuffer());
  ///   Foo reparsed1 = r1.reparseMessage(withUnknownFields);
  ///   Foo reparsed2 = r2.reparseMessage(reparsed1);
  ///   expect(withUnknownFields.hasExtension(Sample.val1), isFalse);
  ///   expect(withUnknownFields.hasExtension(Sample.val2), isFalse);
  ///   expect(reparsed1.hasExtension(Sample.val1), isTrue);
  ///   expect(reparsed1.hasExtension(Sample.val2), isFalse);
  ///   expect(reparsed2.hasExtension(Sample.val1), isTrue);
  ///   expect(reparsed2.hasExtension(Sample.val2), isTrue);
  /// }
  /// ```
  T reparseMessage<T extends GeneratedMessage>(T message) =>
      _reparseMessage(message, this);
}

T _reparseMessage<T extends GeneratedMessage>(
    T message, ExtensionRegistry extensionRegistry) {
  T? result;
  T ensureResult() {
    if (result == null) {
      result ??= message.info_.createEmptyInstance!() as T;
      result!._fieldSet._shallowCopyValues(message._fieldSet);
    }
    return result!;
  }

  UnknownFieldSet? resultUnknownFields;
  UnknownFieldSet ensureUnknownFields() =>
      resultUnknownFields ??= ensureResult()._fieldSet._unknownFields!;

  var messageUnknownFields = message._fieldSet._unknownFields;
  if (messageUnknownFields != null) {
    var codedBufferWriter = CodedBufferWriter();
    extensionRegistry._extensions[message.info_.qualifiedMessageName]
        ?.forEach((tagNumber, extension) {
      final unknownField = messageUnknownFields._fields[tagNumber];
      if (unknownField != null) {
        unknownField.writeTo(tagNumber, codedBufferWriter);
        ensureUnknownFields()._fields.remove(tagNumber);
      }
    });

    if (codedBufferWriter.toBuffer().isNotEmpty) {
      ensureResult()
          .mergeFromBuffer(codedBufferWriter.toBuffer(), extensionRegistry);
    }
  }

  for (var field in message._fieldSet._meta.byIndex) {
    PbList? resultEntries;
    PbList ensureEntries() =>
        resultEntries ??= ensureResult()._fieldSet._values[field.index!];

    PbMap? resultMap;
    PbMap ensureMap() =>
        resultMap ??= ensureResult()._fieldSet._values[field.index!];

    if (field.isRepeated) {
      final messageEntries = message._fieldSet._values[field.index!];
      if (messageEntries == null) continue;
      if (field.isGroupOrMessage) {
        for (var i = 0; i < messageEntries.length; i++) {
          final GeneratedMessage entry = messageEntries[i];
          final reparsedEntry = _reparseMessage(entry, extensionRegistry);
          if (!identical(entry, reparsedEntry)) {
            ensureEntries()[i] = reparsedEntry;
          }
        }
      }
    } else if (field is MapFieldInfo) {
      final messageMap = message._fieldSet._values[field.index!];
      if (messageMap == null) continue;
      if (_isGroupOrMessage(field.valueFieldType)) {
        for (var key in messageMap.keys) {
          final GeneratedMessage value = messageMap[key];
          final reparsedValue = _reparseMessage(value, extensionRegistry);
          if (!identical(value, reparsedValue)) {
            ensureMap()[key] = reparsedValue;
          }
        }
      }
    } else if (field.isGroupOrMessage) {
      final messageSubField = message._fieldSet._values[field.index!];
      if (messageSubField == null) continue;
      final reparsedSubField =
          _reparseMessage<GeneratedMessage>(messageSubField, extensionRegistry);
      if (!identical(messageSubField, reparsedSubField)) {
        ensureResult()._fieldSet._values[field.index!] = reparsedSubField;
      }
    }
  }

  if (result != null && message.isFrozen) {
    result!.freeze();
  }

  return result ?? message;
}

class _EmptyExtensionRegistry implements ExtensionRegistry {
  const _EmptyExtensionRegistry();

  @override
  Map<String, Map<int, Extension>> get _extensions =>
      const <String, Map<int, Extension>>{};

  @override
  void add(Extension extension) {
    throw UnsupportedError('Immutable ExtensionRegistry');
  }

  @override
  void addAll(Iterable<Extension> extensions) {
    throw UnsupportedError('Immutable ExtensionRegistry');
  }

  @override
  Extension? getExtension(String messageName, int tagNumber) => null;

  @override
  T reparseMessage<T extends GeneratedMessage>(T message) =>
      _reparseMessage(message, this);
}
