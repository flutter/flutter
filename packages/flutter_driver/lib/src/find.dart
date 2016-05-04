// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'error.dart';
import 'message.dart';

const List<Type> _supportedKeyValueTypes = const <Type>[String, int];

DriverError _createInvalidKeyValueTypeError(String invalidType) {
  return new DriverError('Unsupported key value type $invalidType. Flutter Driver only supports ${_supportedKeyValueTypes.join(", ")}');
}

/// A command aimed at an object to be located by [finder].
///
/// Implementations must provide a concrete [kind]. If additional data is
/// required beyond the [finder] the implementation may override [serialize]
/// and add more keys to the returned map.
abstract class CommandWithTarget extends Command {
  CommandWithTarget(this.finder) {
    if (finder == null)
      throw new DriverError('${this.runtimeType} target cannot be null');
  }

  /// Locates the object or objects targeted by this command.
  final SerializableFinder finder;

  /// This method is meant to be overridden if data in addition to [finder]
  /// is serialized to JSON.
  ///
  /// Example:
  ///
  ///     Map<String, String> toJson() => super.toJson()..addAll({
  ///       'foo': this.foo,
  ///     });
  @override
  Map<String, String> serialize() => finder.serialize();
}

/// Waits until [finder] can locate the target.
class WaitFor extends CommandWithTarget {
  @override
  final String kind = 'waitFor';

  WaitFor(SerializableFinder finder, {this.timeout})
      : super(finder);

  final Duration timeout;

  static WaitFor deserialize(Map<String, String> json) {
    Duration timeout = json['timeout'] != null
      ? new Duration(milliseconds: int.parse(json['timeout']))
      : null;
    return new WaitFor(SerializableFinder.deserialize(json), timeout: timeout);
  }

  @override
  Map<String, String> serialize() {
    Map<String, String> json = super.serialize();

    if (timeout != null) {
      json['timeout'] = '${timeout.inMilliseconds}';
    }

    return json;
  }
}

class WaitForResult extends Result {
  WaitForResult();

  static WaitForResult fromJson(Map<String, dynamic> json) {
    return new WaitForResult();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// Describes how to the driver should search for elements.
abstract class SerializableFinder {
  String get finderType;

  static SerializableFinder deserialize(Map<String, String> json) {
    String finderType = json['finderType'];
    switch(finderType) {
      case 'ByValueKey': return ByValueKey.deserialize(json);
      case 'ByTooltipMessage': return ByTooltipMessage.deserialize(json);
      case 'ByText': return ByText.deserialize(json);
    }
    throw new DriverError('Unsupported search specification type $finderType');
  }

  Map<String, String> serialize() => <String, String>{
    'finderType': finderType,
  };
}

/// Finds widgets by tooltip text.
class ByTooltipMessage extends SerializableFinder {
  @override
  final String finderType = 'ByTooltipMessage';

  ByTooltipMessage(this.text);

  /// Tooltip message text.
  final String text;

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'text': text,
  });

  static ByTooltipMessage deserialize(Map<String, String> json) {
    return new ByTooltipMessage(json['text']);
  }
}

/// Finds widgets by [text] inside a `Text` widget.
class ByText extends SerializableFinder {
  @override
  final String finderType = 'ByText';

  ByText(this.text);

  final String text;

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'text': text,
  });

  static ByText deserialize(Map<String, String> json) {
    return new ByText(json['text']);
  }
}

/// Finds widgets by `ValueKey`.
class ByValueKey extends SerializableFinder {
  @override
  final String finderType = 'ByValueKey';

  ByValueKey(dynamic keyValue)
    : this.keyValue = keyValue,
      this.keyValueString = '$keyValue',
      this.keyValueType = '${keyValue.runtimeType}' {
    if (!_supportedKeyValueTypes.contains(keyValue.runtimeType))
      throw _createInvalidKeyValueTypeError('$keyValue.runtimeType');
  }

  /// The true value of the key.
  final dynamic keyValue;

  /// Stringified value of the key (we can only send strings to the VM service)
  final String keyValueString;

  /// The type name of the key.
  ///
  /// May be one of "String", "int". The list of supported types may change.
  final String keyValueType;

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'keyValueString': keyValueString,
    'keyValueType': keyValueType,
  });

  static ByValueKey deserialize(Map<String, String> json) {
    String keyValueString = json['keyValueString'];
    String keyValueType = json['keyValueType'];
    switch(keyValueType) {
      case 'int':
        return new ByValueKey(int.parse(keyValueString));
      case 'String':
        return new ByValueKey(keyValueString);
      default:
        throw _createInvalidKeyValueTypeError(keyValueType);
    }
  }
}

/// Command to read the text from a given element.
class GetText extends CommandWithTarget {
  /// [finder] looks for an element that contains a piece of text.
  GetText(SerializableFinder finder) : super(finder);

  @override
  final String kind = 'get_text';

  static GetText deserialize(Map<String, String> json) {
    return new GetText(SerializableFinder.deserialize(json));
  }

  @override
  Map<String, String> serialize() => super.serialize();
}

class GetTextResult extends Result {
  GetTextResult(this.text);

  final String text;

  static GetTextResult fromJson(Map<String, dynamic> json) {
    return new GetTextResult(json['text']);
  }

  @override
  Map<String, dynamic> toJson() => <String, String>{
    'text': text,
  };
}
