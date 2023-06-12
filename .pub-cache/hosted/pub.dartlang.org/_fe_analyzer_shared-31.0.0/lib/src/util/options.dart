// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages/codes.dart';
import 'resolve_input_uri.dart';

class CommandLineProblem {
  final Message message;

  CommandLineProblem(this.message);

  CommandLineProblem.deprecated(String message)
      : this(templateUnspecified.withArguments(message));

  String toString() => message.problemMessage;
}

class ParsedOptions {
  final Map<String, dynamic> options = <String, dynamic>{};
  final List<String> arguments = <String>[];
  final Map<String, String> defines = <String, String>{};

  String toString() => "ParsedArguments($options, $arguments)";

  /// Returns arguments stored as line separated text.
  static List<String> readOptionsFile(String optionsFile) {
    return optionsFile
        .split('\n')
        .map((String line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Parses a list of command-line [arguments] into options and arguments.
  ///
  /// An /option/ is something that, normally, starts with `-` or `--` (one or
  /// two dashes). However, as a special case `/?` and `/h` are also recognized
  /// as options for increased compatibility with Windows. An option can have a
  /// value.
  ///
  /// An /argument/ is something that isn't an option, for example, a file name.
  ///
  /// The specification is a map of options to one of the following values:
  /// * the type literal `Uri`, representing an option value of type [Uri],
  /// * the type literal `int`, representing an option value of type [int],
  /// * the bool literal `false`, representing a boolean option that is turned
  ///   off by default,
  /// * the bool literal `true, representing a boolean option that is turned on
  ///   by default,
  /// * or the string literal `","`, representing a comma-separated list of
  ///   values.
  ///
  /// If [arguments] contains `"--"`, anything before is parsed as options, and
  /// arguments; anything following is treated as arguments (even if starting
  /// with, for example, a `-`).
  ///
  /// If an option isn't found in [specification], an error is thrown.
  ///
  /// Boolean options do not require an option value, but an optional value can
  /// be provided using the forms `--option=value` where `value` can be `true`
  /// or `yes` to turn on the option, or `false` or `no` to turn it off.  If no
  /// option value is specified, a boolean option is turned on.
  ///
  /// All other options require an option value, either on the form `--option
  /// value` or `--option=value`.
  static ParsedOptions parse(List<String> arguments, List<Option>? options) {
    options ??= [];
    Map<String, ValueSpecification>? specification = {};
    void addSpec(String flag, ValueSpecification spec) {
      if (specification.containsKey(flag)) {
        throw new CommandLineProblem.deprecated("Duplicate option '${flag}'.");
      }
      specification[flag] = spec;
    }

    for (Option option in options) {
      addSpec(option.flag, option.spec);
      for (String alias in option.aliases) {
        addSpec(alias, new AliasValue(option.flag));
      }
    }
    ParsedOptions result = new ParsedOptions();
    int index = arguments.indexOf("--");
    Iterable<String> nonOptions = const <String>[];
    Iterator<String> iterator = arguments.iterator;
    if (index != -1) {
      nonOptions = arguments.skip(index + 1);
      iterator = arguments.take(index).iterator;
    }
    while (iterator.moveNext()) {
      String argument = iterator.current;
      if (argument.startsWith("-") || argument == "/?" || argument == "/h") {
        String? value;
        if (argument.startsWith("-D")) {
          value = argument.substring("-D".length);
          argument = "-D";
        } else {
          index = argument.indexOf("=");
          if (index != -1) {
            value = argument.substring(index + 1);
            argument = argument.substring(0, index);
          }
        }
        ValueSpecification? valueSpecification = specification[argument];
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option '$argument'.");
        }
        String canonicalArgument = argument;
        if (valueSpecification.alias != null) {
          canonicalArgument = valueSpecification.alias as String;
          valueSpecification = specification[valueSpecification.alias];
        }
        if (valueSpecification == null) {
          throw new CommandLineProblem.deprecated(
              "Unknown option alias '$canonicalArgument'.");
        }
        final bool requiresValue = valueSpecification.requiresValue;
        if (requiresValue && value == null) {
          if (!iterator.moveNext()) {
            throw new CommandLineProblem(
                templateFastaCLIArgumentRequired.withArguments(argument));
          }
          value = iterator.current;
        }
        valueSpecification.processValue(
            result, canonicalArgument, argument, value);
      } else {
        result.arguments.add(argument);
      }
    }
    specification.forEach((String key, ValueSpecification value) {
      if (value.defaultValue != null) {
        result.options[key] ??= value.defaultValue;
      }
    });
    result.arguments.addAll(nonOptions);
    return result;
  }
}

abstract class ValueSpecification<T> {
  const ValueSpecification();

  String? get alias => null;

  T? get defaultValue => null;

  bool get requiresValue => true;

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value);
}

class AliasValue<T> extends ValueSpecification<T> {
  final String alias;

  const AliasValue(this.alias);

  bool get requiresValue =>
      throw new UnsupportedError("AliasValue.requiresValue");

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    throw new UnsupportedError("AliasValue.processValue");
  }
}

class UriValue extends ValueSpecification<Uri?> {
  const UriValue();

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    // TODO(ahe): resolve Uris lazily, so that schemes provided by
    // other flags can be used for parsed command-line arguments too.
    result.options[canonicalArgument] = resolveInputUri(value!);
  }
}

class StringValue extends ValueSpecification<String?> {
  final String? defaultValue;

  const StringValue({this.defaultValue});

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    result.options[canonicalArgument] = value!;
  }
}

class BoolValue extends ValueSpecification<bool?> {
  final bool? defaultValue;

  const BoolValue(this.defaultValue);

  bool get requiresValue => false;

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    bool parsedValue;
    if (value == null || value == "true" || value == "yes") {
      parsedValue = true;
    } else if (value == "false" || value == "no") {
      parsedValue = false;
    } else {
      throw new CommandLineProblem.deprecated(
          "Value for '$argument' is '$value', "
          "but expected one of: 'true', 'false', 'yes', or 'no'.");
    }
    result.options[canonicalArgument] = parsedValue;
  }
}

class IntValue extends ValueSpecification<int?> {
  final int? defaultValue;
  final int? noArgValue;

  const IntValue({this.defaultValue, this.noArgValue});

  bool get requiresValue => noArgValue == null;

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    if (result.options.containsKey(canonicalArgument)) {
      throw new CommandLineProblem.deprecated(
          "Multiple values for '$argument': "
          "'${result.options[canonicalArgument]}' and '$value'.");
    }
    int? parsedValue = noArgValue;
    if (value != null) {
      parsedValue = int.tryParse(value);
    }
    if (parsedValue == null) {
      throw new CommandLineProblem.deprecated(
          "Value for '$argument', '$value', isn't an int.");
    }
    result.options[canonicalArgument] = parsedValue;
  }
}

class DefineValue extends ValueSpecification<Map<String, String>> {
  const DefineValue();

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    int index = value!.indexOf('=');
    String name;
    String expression;
    if (index != -1) {
      name = value.substring(0, index);
      expression = value.substring(index + 1);
    } else {
      name = value;
      expression = value;
    }
    result.defines[name] = expression;
  }
}

class StringListValue extends ValueSpecification<List<String>?> {
  const StringListValue();

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    List<String> values = result.options[canonicalArgument] ??= <String>[];
    values.addAll(value!.split(","));
  }
}

class UriListValue extends ValueSpecification<List<Uri>?> {
  const UriListValue();

  void processValue(ParsedOptions result, String canonicalArgument,
      String argument, String? value) {
    List<Uri> values = result.options[canonicalArgument] ??= <Uri>[];
    values.addAll(value!.split(",").map(resolveInputUri));
  }
}

class Option<T> {
  final String flag;

  final ValueSpecification<T?> spec;

  final bool isDefines;

  final List<String> aliases;

  const Option(this.flag, this.spec,
      {this.isDefines: false, this.aliases: const []});

  T read(ParsedOptions parsedOptions) =>
      (isDefines ? parsedOptions.defines : parsedOptions.options[flag]) as T;
}
