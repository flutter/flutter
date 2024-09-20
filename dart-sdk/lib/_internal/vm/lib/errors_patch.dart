// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return Object._toString(object);
  }

  @patch
  static String _stringToSafeString(String string) {
    return json.encode(string);
  }

  @patch
  StackTrace? get stackTrace => _stackTrace;

  @pragma("vm:entry-point")
  StackTrace? _stackTrace;

  @patch
  @pragma("vm:external-name", "Error_throwWithStackTrace")
  external static Never _throw(Object error, StackTrace stackTrace);
}

class _AssertionError extends Error implements AssertionError {
  @pragma("vm:entry-point")
  _AssertionError._create(
      this._failedAssertion, this._url, this._line, this._column, this.message);

  // AssertionError_throwNew in errors.cc fishes the assertion source code
  // out of the script. It expects a Dart stack frame from class
  // _AssertionError. Thus we need a Dart stub that calls the native code.
  @pragma("vm:entry-point", "call")
  static _throwNew(int assertionStart, int assertionEnd, Object? message) {
    _doThrowNew(assertionStart, assertionEnd, message);
  }

  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "AssertionError_throwNewSource")
  external static _throwNewSource(String failedAssertion, String? scriptUrl,
      int line, int column, Object? message);

  @pragma("vm:external-name", "AssertionError_throwNew")
  external static _doThrowNew(
      int assertionStart, int assertionEnd, Object? message);

  @pragma("vm:entry-point", "call")
  static _evaluateAssertion(condition) {
    if (identical(condition, true) || identical(condition, false)) {
      return condition;
    }
    if (condition is _Closure) {
      return (condition as dynamic Function())();
    }
    if (condition is Function) {
      condition = (condition as dynamic Function())();
    }
    return condition;
  }

  String get _messageString {
    final msg = message;
    if (msg == null) return "is not true.";
    if (msg is String) return msg;
    return Error.safeToString(msg);
  }

  String toString() {
    if (_url == null) {
      if (message == null) return _failedAssertion.trim();
      return "'${_failedAssertion.trim()}': $_messageString";
    }
    var columnInfo = "";
    if (_column > 0) {
      // Only add column information if it is valid.
      columnInfo = " pos $_column";
    }
    return "'$_url': Failed assertion: line $_line$columnInfo: "
        "'$_failedAssertion': $_messageString";
  }

  final String _failedAssertion;
  final String? _url;
  final int _line;
  final int _column;
  final Object? message;
}

class _TypeError extends Error implements TypeError {
  @pragma("vm:entry-point")
  _TypeError._create(this._url, this._line, this._column, this._message);

  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "TypeError_throwNew")
  external static _throwNew(
      int location, Object srcValue, _Type dstType, String dstName);

  String toString() => _message;

  final String? _url;
  final int? _line;
  final int? _column;
  final String _message;
}

class _InternalError {
  @pragma("vm:entry-point")
  const _InternalError(this._msg);
  String toString() => "InternalError: '${_msg}'";
  final String _msg;
}

@patch
@pragma("vm:entry-point")
class UnsupportedError {
  static _throwNew(String msg) {
    throw new UnsupportedError(msg);
  }
}

@patch
@pragma("vm:entry-point")
class StateError {
  @pragma("vm:entry-point")
  static _throwNew(String msg) {
    throw new StateError(msg);
  }
}

@patch
class NoSuchMethodError {
  final Object? _receiver;
  final Invocation _invocation;

  @patch
  factory NoSuchMethodError.withInvocation(
          Object? receiver, Invocation invocation) =
      NoSuchMethodError._withInvocation;

  NoSuchMethodError._withInvocation(this._receiver, this._invocation);

  static void _throwNewInvocation(Object? receiver, Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(receiver, invocation);
  }

  // The compiler emits a call to _throwNew when it cannot resolve a static
  // method at compile time. The receiver is actually the literal class of the
  // unresolved method.
  @pragma("vm:entry-point", "call")
  static void _throwNew(
      Object receiver,
      String memberName,
      int invocationType,
      int typeArgumentsLength,
      Object? typeArguments,
      List? arguments,
      List? argumentNames) {
    throw new NoSuchMethodError._withType(receiver, memberName, invocationType,
        typeArgumentsLength, typeArguments, arguments, argumentNames);
  }

  // Helper to build a map of named arguments.
  static Map<Symbol, dynamic> _NamedArgumentsMap(
      List arguments, List argumentNames) {
    Map<Symbol, dynamic> namedArguments = new Map<Symbol, dynamic>();
    int numPositionalArguments = arguments.length - argumentNames.length;
    for (int i = 0; i < argumentNames.length; i++) {
      final argValue = arguments[numPositionalArguments + i];
      namedArguments[new Symbol(argumentNames[i])] = argValue;
    }
    return namedArguments;
  }

  // Constructor called from Exceptions::ThrowByType(kNoSuchMethod) and from
  // _throwNew above, taking a TypeArguments object rather than an unpacked list
  // of types, as well as a list of all arguments and a list of names, rather
  // than a separate list of positional arguments and a map of named arguments.
  @pragma("vm:entry-point")
  NoSuchMethodError._withType(
      this._receiver,
      String memberName,
      int invocationType,
      int typeArgumentsLength, // Needed with all-dynamic (null) typeArguments.
      Object? typeArguments,
      List? arguments,
      List? argumentNames)
      : this._invocation = new _InvocationMirror._withType(
            new Symbol(memberName),
            invocationType,
            _InvocationMirror._unpackTypeArguments(
                typeArguments, typeArgumentsLength),
            argumentNames != null
                ? arguments!.sublist(0, arguments.length - argumentNames.length)
                : arguments,
            argumentNames != null
                ? _NamedArgumentsMap(arguments!, argumentNames)
                : null);

  @pragma("vm:external-name", "NoSuchMethodError_existingMethodSignature")
  external static String? _existingMethodSignature(
      Object? receiver, String methodName, int invocationType);

  @patch
  String toString() {
    final localInvocation = _invocation;
    if (localInvocation is _InvocationMirror) {
      var internalName = localInvocation.memberName as internal.Symbol;
      String memberName = internal.Symbol.computeUnmangledName(internalName);

      var level = (localInvocation._type >> _InvocationMirror._LEVEL_SHIFT) &
          _InvocationMirror._LEVEL_MASK;
      var kind = localInvocation._type & _InvocationMirror._KIND_MASK;
      if (kind == _InvocationMirror._LOCAL_VAR) {
        return "NoSuchMethodError: Cannot assign to final variable '$memberName'";
      }

      StringBuffer? typeArgumentsBuf = null;
      final typeArguments = localInvocation.typeArguments;
      if ((typeArguments != null) && (typeArguments.length > 0)) {
        final argsBuf = new StringBuffer();
        argsBuf.write("<");
        for (int i = 0; i < typeArguments.length; i++) {
          if (i > 0) {
            argsBuf.write(", ");
          }
          argsBuf.write(Error.safeToString(typeArguments[i]));
        }
        argsBuf.write(">");
        typeArgumentsBuf = argsBuf;
      }
      StringBuffer argumentsBuf = new StringBuffer();
      var positionalArguments = localInvocation.positionalArguments;
      int argumentCount = 0;
      if (positionalArguments != null) {
        for (; argumentCount < positionalArguments.length; argumentCount++) {
          if (argumentCount > 0) {
            argumentsBuf.write(", ");
          }
          argumentsBuf
              .write(Error.safeToString(positionalArguments[argumentCount]));
        }
      }
      var namedArguments = localInvocation.namedArguments;
      if (namedArguments != null) {
        namedArguments.forEach((Symbol key, var value) {
          if (argumentCount > 0) {
            argumentsBuf.write(", ");
          }
          var internalName = key as internal.Symbol;
          argumentsBuf
              .write(internal.Symbol.computeUnmangledName(internalName));
          argumentsBuf.write(": ");
          argumentsBuf.write(Error.safeToString(value));
          argumentCount++;
        });
      }
      String? existingSig = _existingMethodSignature(
          _receiver, memberName, localInvocation._type);
      String argsMsg = existingSig != null ? " with matching arguments" : "";

      String kindBuf = "function";
      if (kind >= 0 && kind < 5) {
        kindBuf = (const [
          "method",
          "getter",
          "setter",
          "getter or setter",
          "variable"
        ])[kind];
      }

      StringBuffer msgBuf = new StringBuffer("NoSuchMethodError: ");
      bool isTypeCall = false;
      switch (level) {
        case _InvocationMirror._DYNAMIC:
          {
            if (_receiver == null) {
              if (existingSig != null) {
                msgBuf.writeln("The null object does not have a $kindBuf "
                    "'$memberName'$argsMsg.");
              } else {
                msgBuf
                    .writeln("The $kindBuf '$memberName' was called on null.");
              }
            } else {
              if (_receiver is _Closure) {
                msgBuf.writeln("Closure call with mismatched arguments: "
                    "function '$memberName'");
              } else if (_receiver is _Type && memberName == "call") {
                isTypeCall = true;
                String name = _receiver.toString();
                msgBuf.writeln("Attempted to use type '$name' as a function. "
                    "Since types do not define a method 'call', this is not "
                    "possible. Did you intend to call the $name constructor and "
                    "forget the 'new' operator?");
              } else {
                msgBuf
                    .writeln("Class '${_receiver.runtimeType}' has no instance "
                        "$kindBuf '$memberName'$argsMsg.");
              }
            }
            break;
          }
        case _InvocationMirror._SUPER:
          {
            msgBuf
                .writeln("Super class of class '${_receiver.runtimeType}' has "
                    "no instance $kindBuf '$memberName'$argsMsg.");
            memberName = "super.$memberName";
            break;
          }
        case _InvocationMirror._STATIC:
          {
            msgBuf.writeln("No static $kindBuf '$memberName'$argsMsg "
                "declared in class '$_receiver'.");
            break;
          }
        case _InvocationMirror._CONSTRUCTOR:
          {
            msgBuf.writeln("No constructor '$memberName'$argsMsg declared "
                "in class '$_receiver'.");
            memberName = "new $memberName";
            break;
          }
        case _InvocationMirror._TOP_LEVEL:
          {
            msgBuf.writeln("No top-level $kindBuf '$memberName'$argsMsg "
                "declared.");
            break;
          }
      }

      if (level == _InvocationMirror._TOP_LEVEL) {
        msgBuf.writeln("Receiver: top-level");
      } else {
        msgBuf.writeln("Receiver: ${Error.safeToString(_receiver)}");
      }

      if (kind == _InvocationMirror._METHOD) {
        String m = isTypeCall ? "$_receiver" : "$memberName";
        msgBuf.write("Tried calling: $m");
        if (typeArgumentsBuf != null) {
          msgBuf.write(typeArgumentsBuf);
        }
        msgBuf.write("($argumentsBuf)");
      } else if (argumentCount == 0) {
        msgBuf.write("Tried calling: $memberName");
      } else if (kind == _InvocationMirror._SETTER) {
        msgBuf.write("Tried calling: $memberName$argumentsBuf");
      } else {
        msgBuf.write("Tried calling: $memberName = $argumentsBuf");
      }

      if (existingSig != null) {
        msgBuf.write("\nFound: $memberName$existingSig");
      }

      return msgBuf.toString();
    }
    return _toStringPlain(_receiver, localInvocation);
  }

  /// Creates a string representation of an invocation.
  ///
  /// Used for situations where there is no extra information available
  /// about the failed invocation than the [Invocation] object and receiver,
  /// which includes errors created using [NoSuchMethodError.withInvocation].
  static String _toStringPlain(Object? receiver, Invocation invocation) {
    var name = _symbolToString(invocation.memberName);
    var receiverType = "${receiver.runtimeType}";
    if (invocation.isAccessor) {
      return "NoSuchMethodError: $receiverType has no $name "
          "${invocation.isGetter ? "getter" : "setter"}";
    }
    var buffer = StringBuffer("NoSuchMethodError")..write(": ");
    buffer.write("$receiverType has no $name method accepting arguments ");
    var separator = "";
    if (invocation.typeArguments.isNotEmpty) {
      buffer.write("<");
      for (var type in invocation.typeArguments) {
        buffer
          ..write(separator)
          ..write("_");
        separator = ", ";
      }
      buffer.write(">");
      separator = "";
    }
    buffer.write("(");
    for (var argument in invocation.positionalArguments) {
      buffer
        ..write(separator)
        ..write("_");
      separator = ", ";
    }
    if (invocation.namedArguments.isNotEmpty) {
      buffer
        ..write(separator)
        ..write("{");
      separator = "";
      for (var name in invocation.namedArguments.keys) {
        buffer
          ..write(separator)
          ..write(_symbolToString(name))
          ..write(": _");
        separator = ",";
      }
      buffer.write("}");
    }
    buffer.write(")");
    return buffer.toString();
  }

  static String _symbolToString(Symbol symbol) {
    if (symbol is internal.Symbol) {
      return internal.Symbol.computeUnmangledName(symbol);
    }
    return "$symbol";
  }
}

@pragma("vm:entry-point")
class _CompileTimeError extends Error {
  final String _errorMsg;
  _CompileTimeError(this._errorMsg);
  String toString() => _errorMsg;
}

/// Used by Fasta to report a runtime error when a final field with an
/// initializer is also initialized in a generative constructor.
///
/// Note: in strong mode, this is a compile-time error and this class becomes
/// obsolete.
class _DuplicatedFieldInitializerError extends Error {
  final String _name;

  _DuplicatedFieldInitializerError(this._name);

  toString() => "Error: field '$_name' is already initialized.";
}

// Implementations needed to implement the `_stackTrace` member added
// in the @patch class of [Error].

@patch
class OutOfMemoryError {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('OutOfMemoryError._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('OutOfMemoryError._stackTrace');
  }
}

@patch
class StackOverflowError {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('StackOverflowError._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('StackOverflowError._stackTrace');
  }
}

@patch
class IntegerDivisionByZeroException {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('IntegerDivisionByZeroException._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('IntegerDivisionByZeroException._stackTrace');
  }
}
