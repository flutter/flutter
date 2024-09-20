// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../executor.dart';

/// Representation of an argument to a macro constructor.
sealed class Argument implements Serializable {
  ArgumentKind get kind;

  Object? get value;

  Argument();

  /// Reads the next argument from [Deserializer].
  ///
  /// By default this will call `moveNext` on [deserializer] before reading the
  /// argument kind, but this can be skipped by passing `true` for
  /// [alreadyMoved].
  factory Argument.deserialize(Deserializer deserializer,
      {bool alreadyMoved = false}) {
    if (!alreadyMoved) deserializer.moveNext();
    final ArgumentKind kind = ArgumentKind.values[deserializer.expectInt()];
    return switch (kind) {
      ArgumentKind.string =>
        StringArgument((deserializer..moveNext()).expectString()),
      ArgumentKind.bool =>
        BoolArgument((deserializer..moveNext()).expectBool()),
      ArgumentKind.double =>
        DoubleArgument((deserializer..moveNext()).expectDouble()),
      ArgumentKind.int => IntArgument((deserializer..moveNext()).expectInt()),
      ArgumentKind.list ||
      ArgumentKind.set =>
        _IterableArgument._deserialize(kind, deserializer),
      ArgumentKind.map => MapArgument._deserialize(deserializer),
      ArgumentKind.nil => NullArgument(),
      ArgumentKind.typeAnnotation => TypeAnnotationArgument(
          (deserializer..moveNext()).expectRemoteInstance()),
      ArgumentKind.code =>
        CodeArgument((deserializer..moveNext()).expectCode()),
      // These are just for type arguments and aren't supported as actual args.
      ArgumentKind.object ||
      ArgumentKind.dynamic ||
      ArgumentKind.num ||
      ArgumentKind.nullable =>
        throw StateError('Argument kind $kind is not deserializable'),
    };
  }

  /// All subtypes should override this and call super.
  @override
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
  }

  @override
  String toString() => '$runtimeType:$value';
}

final class BoolArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.bool;

  @override
  final bool value;

  BoolArgument(this.value);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.addBool(value);
  }
}

final class DoubleArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.double;

  @override
  final double value;

  DoubleArgument(this.value);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.addDouble(value);
  }
}

final class IntArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.int;

  @override
  final int value;

  IntArgument(this.value);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.addInt(value);
  }
}

final class NullArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.nil;

  @override
  Null get value => null;
}

final class StringArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.string;

  @override
  final String value;

  StringArgument(this.value);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.addString(value);
  }
}

final class CodeArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.code;

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    value.serialize(serializer);
  }

  @override
  final Code value;

  CodeArgument(this.value);
}

final class TypeAnnotationArgument extends Argument {
  @override
  ArgumentKind get kind => ArgumentKind.typeAnnotation;

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    value.serialize(serializer);
  }

  @override
  final TypeAnnotationImpl value;

  TypeAnnotationArgument(this.value);
}

abstract base class _CollectionArgument extends Argument {
  /// Flat list of the actual reified type arguments for this list, in the order
  /// they would appear if written in code.
  ///
  /// For nullable types, they should be preceded by an [ArgumentKind.nullable].
  ///
  /// Note that nested type arguments appear here and are just flattened, so
  /// the type `List<Map<String, List<int>?>>` would have the type arguments:
  ///
  /// [
  ///   ArgumentKind.map,
  ///   ArgumentKind.string,
  ///   ArgumentKind.nullable,
  ///   ArgumentKind.list,
  ///   ArgumentKind.int,
  /// ]
  final List<ArgumentKind> _typeArguments;

  _CollectionArgument(this._typeArguments);

  /// Creates a one or two element list, based on [_typeArguments], but
  /// converted into deep [Cast] objects.
  ///
  /// For an iterable, this will always have a single value, and for a map it
  /// will always have two values.
  List<Cast> _extractTypeArgumentCasts() {
    List<Cast> castStack = [];

    // We build up the list type backwards.
    for (ArgumentKind type in _typeArguments.reversed) {
      castStack.add(switch (type) {
        ArgumentKind.bool => const Cast<bool>(),
        ArgumentKind.double => const Cast<double>(),
        ArgumentKind.int => const Cast<int>(),
        ArgumentKind.map =>
          MapCast.from(castStack.removeLast(), castStack.removeLast()),
        ArgumentKind.nil => const Cast<Null>(),
        ArgumentKind.set => SetCast.from(castStack.removeLast()),
        ArgumentKind.string => const Cast<String>(),
        ArgumentKind.list => ListCast.from(castStack.removeLast()),
        ArgumentKind.typeAnnotation => const Cast<TypeAnnotation>(),
        ArgumentKind.code => const Cast<Code>(),
        ArgumentKind.object => const Cast<Object>(),
        ArgumentKind.dynamic => const Cast<dynamic>(),
        ArgumentKind.num => const Cast<num>(),
        ArgumentKind.nullable => castStack.removeLast().nullable,
      });
    }
    return castStack;
  }

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.startList();
    for (ArgumentKind typeArgument in _typeArguments) {
      serializer.addInt(typeArgument.index);
    }
    serializer.endList();
  }
}

/// The base class for [ListArgument] and [SetArgument], most of the logic is
/// the same.
abstract base class _IterableArgument<T extends Iterable<Object?>>
    extends _CollectionArgument {
  /// These are the raw argument values for each entry in this iterable.
  final List<Argument> _arguments;

  _IterableArgument(this._arguments, super._typeArguments);

  factory _IterableArgument._deserialize(
      ArgumentKind kind, Deserializer deserializer) {
    deserializer
      ..moveNext()
      ..expectList();
    final List<ArgumentKind> typeArguments = [
      for (; deserializer.moveNext();)
        ArgumentKind.values[deserializer.expectInt()],
    ];
    deserializer
      ..moveNext()
      ..expectList();
    final List<Argument> values = [
      for (; deserializer.moveNext();)
        Argument.deserialize(deserializer, alreadyMoved: true),
    ];
    return switch (kind) {
      ArgumentKind.list => ListArgument(values, typeArguments),
      ArgumentKind.set => SetArgument(values, typeArguments),
      _ =>
        throw UnsupportedError('Could not deserialize argument of kind $kind'),
    } as _IterableArgument<T>;
  }

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.startList();
    for (Argument argument in _arguments) {
      argument.serialize(serializer);
    }
    serializer.endList();
  }
}

final class ListArgument extends _IterableArgument<List<Object?>> {
  @override
  ArgumentKind get kind => ArgumentKind.list;

  /// Materializes all the `_arguments` as actual values.
  @override
  List<Object?> get value =>
      ListCast.from(_extractTypeArgumentCasts().single).cast([
        for (Argument arg in _arguments) arg.value,
      ]);

  ListArgument(super._arguments, super._typeArguments);
}

final class SetArgument extends _IterableArgument<Set<Object?>> {
  @override
  ArgumentKind get kind => ArgumentKind.set;

  /// Materializes all the `_arguments` as actual values.
  @override
  Set<Object?> get value =>
      SetCast.from(_extractTypeArgumentCasts().single).cast({
        for (Argument arg in _arguments) arg.value,
      });

  SetArgument(super._arguments, super._typeArguments);
}

final class MapArgument extends _CollectionArgument {
  @override
  ArgumentKind get kind => ArgumentKind.map;

  /// These are the raw argument values for the entries in this map.
  final Map<Argument, Argument> _arguments;

  /// Materializes all the `_arguments` as actual values.
  @override
  Map<Object?, Object?> get value {
    // We should have exactly two type arguments, the key and value types.
    final List<Cast> extractedTypes = _extractTypeArgumentCasts();
    assert(extractedTypes.length == 2);
    return MapCast.from(extractedTypes[1], extractedTypes[0]).cast({
      for (MapEntry<Argument, Argument> argument in _arguments.entries)
        argument.key.value: argument.value.value,
    });
  }

  MapArgument(this._arguments, super._typeArguments);

  factory MapArgument._deserialize(Deserializer deserializer) {
    deserializer
      ..moveNext()
      ..expectList();
    final List<ArgumentKind> typeArguments = [
      for (; deserializer.moveNext();)
        ArgumentKind.values[deserializer.expectInt()],
    ];
    deserializer
      ..moveNext()
      ..expectList();
    final Map<Argument, Argument> arguments = {
      for (; deserializer.moveNext();)
        Argument.deserialize(deserializer, alreadyMoved: true):
            Argument.deserialize(deserializer),
    };
    return MapArgument(arguments, typeArguments);
  }

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    serializer.startList();
    for (MapEntry<Argument, Argument> argument in _arguments.entries) {
      argument.key.serialize(serializer);
      argument.value.serialize(serializer);
    }
    serializer.endList();
  }
}

/// The arguments passed to a macro constructor.
///
/// All argument instances must be of type [Code] or a built-in value type that
/// is serializable (num, bool, String, null, etc).
class Arguments implements Serializable {
  final List<Argument> positional;

  final Map<String, Argument> named;

  Arguments(this.positional, this.named);

  factory Arguments.deserialize(Deserializer deserializer) {
    deserializer
      ..moveNext()
      ..expectList();
    final List<Argument> positionalArgs = [
      for (; deserializer.moveNext();)
        Argument.deserialize(deserializer, alreadyMoved: true),
    ];
    deserializer
      ..moveNext()
      ..expectList();
    final Map<String, Argument> namedArgs = {
      for (; deserializer.moveNext();)
        deserializer.expectString(): Argument.deserialize(deserializer),
    };
    return Arguments(positionalArgs, namedArgs);
  }

  @override
  void serialize(Serializer serializer) {
    serializer.startList();
    for (Argument arg in positional) {
      arg.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (MapEntry<String, Argument> arg in named.entries) {
      serializer.addString(arg.key);
      arg.value.serialize(serializer);
    }
    serializer.endList();
  }
}

/// Used for serializing and deserializing arguments.
///
/// Note that the `nullable` variants, as well as `object`, `dynamic`, and `num`
/// are only used for type arguments. Instances should have an argument kind
/// that matches their their actual value.
enum ArgumentKind {
  bool,
  string,
  double,
  int,
  list,
  map,
  set,
  nil,
  object,
  dynamic,
  num,
  nullable,
  typeAnnotation,
  code,
}
