// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.stack_listener;

import '../messages/codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        codeCatchSyntaxExtraParameters,
        codeNativeClauseShouldBeAnnotation,
        templateInternalProblemStackNotEmpty,
        templateInternalProblemUnhandled;

import '../scanner/scanner.dart' show Token;

import 'identifier_context.dart' show IdentifierContext;

import 'parser.dart' show Listener, MemberKind, lengthOfSpan;

import 'quote.dart' show unescapeString;

import 'value_kind.dart';

enum NullValue {
  Arguments,
  As,
  AwaitToken,
  Block,
  BreakTarget,
  CascadeReceiver,
  Combinators,
  Comments,
  ConditionalUris,
  ConditionallySelectedImport,
  ConstructorInitializerSeparator,
  ConstructorInitializers,
  ConstructorReferenceContinuationAfterTypeArguments,
  ContinueTarget,
  Deferred,
  DocumentationComment,
  Expression,
  ExtendsClause,
  FieldInitializer,
  FormalParameters,
  FunctionBody,
  FunctionBodyAsyncToken,
  FunctionBodyStarToken,
  HideClause,
  Identifier,
  IdentifierList,
  Initializers,
  Labels,
  Metadata,
  Modifiers,
  Name,
  OperatorList,
  ParameterDefaultValue,
  Prefix,
  ShowClause,
  StringLiteral,
  SwitchScope,
  Token,
  Type,
  TypeArguments,
  TypeBuilder,
  TypeBuilderList,
  TypeList,
  TypeVariable,
  TypeVariables,
  VarFinalOrConstToken,
  WithClause,
}

abstract class StackListener extends Listener {
  static const bool debugStack = false;
  final Stack stack = debugStack ? new DebugStack() : new StackImpl();

  /// Used to report an internal error encountered in the stack listener.
  Never internalProblem(Message message, int charOffset, Uri uri);

  /// Checks that [value] matches the expected [kind].
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkValue(token, ValueKind.Token, value));
  ///
  /// to document and validate the expected value kind.
  bool checkValue(Token? token, ValueKind kind, Object value) {
    if (!kind.check(value)) {
      String message = 'Unexpected value `${value}` (${value.runtimeType}). '
          'Expected ${kind}.';
      if (token != null) {
        // If offset is available report and internal problem to show the
        // parsed code in the output.
        throw internalProblem(
            new Message(const Code<String>('Internal error'),
                problemMessage: message),
            token.charOffset,
            uri);
      } else {
        throw message;
      }
    }
    return true;
  }

  /// Checks the top of the current stack against [kinds]. If a mismatch is
  /// found, a top of the current stack is print along with the expected [kinds]
  /// marking the frames that don't match, and throws an exception.
  ///
  /// Use this in assert statements like
  ///
  ///     assert(checkState(token, [ValueKind.Integer, ValueKind.StringOrNull]))
  ///
  /// to document the expected stack and get earlier errors on unexpected stack
  /// content.
  bool checkState(Token? token, List<ValueKind> kinds) {
    bool success = true;
    for (int kindIndex = 0; kindIndex < kinds.length; kindIndex++) {
      ValueKind kind = kinds[kindIndex];
      if (kindIndex < stack.length) {
        Object? value = stack[kindIndex];
        if (!kind.check(value)) {
          success = false;
        }
      } else {
        success = false;
      }
    }
    if (!success) {
      StringBuffer sb = new StringBuffer();

      String safeToString(Object? object) {
        try {
          return '$object';
        } catch (e) {
          // Judgments fail on toString.
          return object.runtimeType.toString();
        }
      }

      String padLeft(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return ' ' * (length - text.length) + text;
        }
        return text;
      }

      String padRight(Object object, int length) {
        String text = safeToString(object);
        if (text.length < length) {
          return text + ' ' * (length - text.length);
        }
        return text;
      }

      // Compute kind/stack frame information for all expected values plus 3 more
      // stack elements if available.
      for (int kindIndex = 0; kindIndex < kinds.length + 3; kindIndex++) {
        if (kindIndex >= stack.length && kindIndex >= kinds.length) {
          // No more stack elements nor kinds to display.
          break;
        }
        sb.write(padLeft(kindIndex, 4));
        sb.write(': ');
        ValueKind? kind;
        if (kindIndex < kinds.length) {
          kind = kinds[kindIndex];
          sb.write(padRight(kind, 60));
        } else {
          sb.write(padRight('---', 60));
        }
        if (kindIndex < stack.length) {
          Object? value = stack[kindIndex];
          if (kind == null || kind.check(value)) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write(safeToString(value));
          sb.write(' (${value.runtimeType})');
        } else {
          if (kind == null) {
            sb.write(' ');
          } else {
            sb.write('*');
          }
          sb.write('---');
        }
        sb.writeln();
      }

      String message = '$runtimeType failure\n$sb';
      if (token != null) {
        // If offset is available report and internal problem to show the
        // parsed code in the output.
        throw internalProblem(
            new Message(const Code<String>('Internal error'),
                problemMessage: message),
            token.charOffset,
            uri);
      } else {
        throw message;
      }
    }
    return success;
  }

  @override
  Uri get uri;

  void discard(int n) {
    for (int i = 0; i < n; i++) {
      pop();
    }
  }

  void push(Object? node) {
    if (node == null) {
      internalProblem(
          templateInternalProblemUnhandled.withArguments("null", "push"),
          /* charOffset = */ -1,
          uri);
    }
    stack.push(node);
  }

  void pushIfNull(Token? tokenOrNull, NullValue nullValue) {
    if (tokenOrNull == null) stack.push(nullValue);
  }

  Object? peek() => stack.isNotEmpty ? stack.last : null;

  Object? pop([NullValue? nullValue]) {
    return stack.pop(nullValue);
  }

  Object? popIfNotNull(Object? value) {
    return value == null ? null : pop();
  }

  void debugEvent(String name) {
    // printEvent(name);
  }

  void printEvent(String name) {
    print('\n------------------');
    for (Object? o in stack.values) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(/* startIndex = */ 0, index) + "...";
      }
      print(s);
    }
    print("  >> $name");
  }

  @override
  void logEvent(String name) {
    printEvent(name);
    internalProblem(
        templateInternalProblemUnhandled.withArguments(name, "$runtimeType"),
        /* charOffset = */ -1,
        uri);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    if (!token.isSynthetic) {
      push(token.lexeme);
    } else {
      // This comes from a synthetic token which is inserted by the parser in
      // an attempt to recover.  This almost always means that the parser has
      // gotten very confused and we need to ignore the results.
      push(new ParserRecovery(token.charOffset));
    }
  }

  @override
  void handleNoName(Token token) {
    debugEvent("NoName");
    push(NullValue.Identifier);
  }

  @override
  void endInitializer(Token token) {
    debugEvent("Initializer");
  }

  void checkEmpty(int charOffset) {
    if (stack.isNotEmpty) {
      internalProblem(
          templateInternalProblemStackNotEmpty.withArguments(
              "${runtimeType}", stack.values.join("\n  ")),
          charOffset,
          uri);
    }
  }

  @override
  void endTopLevelDeclaration(Token nextToken) {
    debugEvent("TopLevelDeclaration");
    checkEmpty(nextToken.charOffset);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    checkEmpty(token.charOffset);
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    debugEvent("ClassExtends");
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    debugEvent("MixinOn");
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    debugEvent("ClassHeader");
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    debugEvent("MixinHeader");
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("RecoverMixinHeader");
  }

  @override
  void handleClassOrMixinImplements(
      Token? implementsKeyword, int interfacesCount) {
    debugEvent("ClassImplements");
  }

  @override
  void handleExtensionShowHide(Token? showKeyword, int showElementCount,
      Token? hideKeyword, int hideElementCount) {
    debugEvent("ExtensionShow");
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValue.TypeArguments);
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(NullValue.TypeVariables);
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  @override
  void handleNoType(Token lastConsumed) {
    debugEvent("NoType");
    push(NullValue.TypeBuilder);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    push(NullValue.FormalParameters);
  }

  @override
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    push(NullValue.Arguments);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
    push(NullValue.FunctionBody);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(NullValue.FunctionBody);
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    push(NullValue.Initializers);
  }

  @override
  void handleParenthesizedCondition(Token token) {
    debugEvent("handleParenthesizedCondition");
  }

  @override
  void handleParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression");
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop() as Token;
      push(unescapeString(token.lexeme, token, this));
    } else {
      internalProblem(
          templateInternalProblemUnhandled.withArguments(
              "string interpolation", "endLiteralString"),
          endToken.charOffset,
          uri);
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop(); // Pop the native name which is a String.
    }
  }

  @override
  void handleDirectivesOnly() {
    pop(); // Discard the metadata.
  }

  void handleExtraneousExpression(Token token, Message message) {
    debugEvent("ExtraneousExpression");
    pop(); // Discard the extraneous expression.
  }

  @override
  void endCaseExpression(Token colon) {
    debugEvent("CaseExpression");
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    debugEvent("Error: ${message.problemMessage}");
    if (isIgnoredError(message.code, startToken)) return;
    addProblem(
        message, startToken.charOffset, lengthOfSpan(startToken, endToken));
  }

  bool isIgnoredError(Code<dynamic> code, Token token) {
    if (code == codeNativeClauseShouldBeAnnotation) {
      // TODO(danrubel): Ignore this error until we deprecate `native`
      // support.
      return true;
    } else if (code == codeCatchSyntaxExtraParameters) {
      // Ignored. This error is handled by the BodyBuilder.
      return true;
    } else {
      return false;
    }
  }

  @override
  void handleUnescapeError(
      Message message, Token token, int stringOffset, int length) {
    addProblem(message, token.charOffset + stringOffset, length);
  }

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context});
}

abstract class Stack {
  /// Pops [count] elements from the stack and puts it into [list].
  /// Returns [null] if a [ParserRecovery] value is found, or [list] otherwise.
  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue);

  /// Pops [count] elements from the stack and puts it into [list].
  /// Returns [null] if a [ParserRecovery] value is found, or [list] otherwise.
  List<T>? popNonNullableList<T>(int count, List<T> list);

  void push(Object value);

  /// Will return [null] instead of [NullValue].
  Object? get last;

  bool get isNotEmpty;

  List<Object?> get values;

  Object? pop(NullValue? nullValue);

  int get length;

  /// Raw, i.e. [NullValue]s will be returned instead of [null].
  Object? operator [](int index);
}

class StackImpl implements Stack {
  List<Object?> array =
      new List<Object?>.filled(/* length = */ 8, /* fill = */ null);
  int arrayLength = 0;

  bool get isNotEmpty => arrayLength > 0;

  int get length => arrayLength;

  Object? get last {
    final Object? value = array[arrayLength - 1];
    return value is NullValue ? null : value;
  }

  Object? operator [](int index) {
    return array[arrayLength - 1 - index];
  }

  void push(Object value) {
    array[arrayLength++] = value;
    if (array.length == arrayLength) {
      _grow();
    }
  }

  Object? pop(NullValue? nullValue) {
    assert(arrayLength > 0);
    final Object? value = array[--arrayLength];
    array[arrayLength] = null;
    if (value is! NullValue) {
      return value;
    } else if (nullValue == null || value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue) {
    assert(arrayLength >= count);
    final List<Object?> array = this.array;
    final int length = arrayLength;
    final int startIndex = length - count;
    bool isParserRecovery = false;
    for (int i = 0; i < count; i++) {
      int arrayIndex = startIndex + i;
      final Object? value = array[arrayIndex];
      array[arrayIndex] = null;
      if (value is NullValue && nullValue == null ||
          identical(value, nullValue)) {
        list[i] = null;
      } else if (value is ParserRecovery) {
        isParserRecovery = true;
      } else {
        assert(value is! NullValue);
        list[i] = value as T;
      }
    }
    arrayLength -= count;

    return isParserRecovery ? null : list;
  }

  List<T>? popNonNullableList<T>(int count, List<T> list) {
    assert(arrayLength >= count);
    final List<Object?> array = this.array;
    final int length = arrayLength;
    final int startIndex = length - count;
    bool isParserRecovery = false;
    for (int i = 0; i < count; i++) {
      int arrayIndex = startIndex + i;
      final Object? value = array[arrayIndex];
      array[arrayIndex] = null;
      if (value is ParserRecovery) {
        isParserRecovery = true;
      } else {
        list[i] = value as T;
      }
    }
    arrayLength -= count;

    return isParserRecovery ? null : list;
  }

  List<Object?> get values {
    final int length = arrayLength;
    final List<Object?> list =
        new List<Object?>.filled(length, /* fill = */ null);
    list.setRange(/* start = */ 0, length, array);
    return list;
  }

  void _grow() {
    final int length = array.length;
    final List<Object?> newArray =
        new List<Object?>.filled(length * 2, /* fill = */ null);
    newArray.setRange(/* start = */ 0, length, array, /* skipCount = */ 0);
    array = newArray;
  }
}

class DebugStack implements Stack {
  Stack realStack = new StackImpl();
  Stack stackTraceStack = new StackImpl();
  List<StackTrace> latestStacktraces = <StackTrace>[];

  @override
  Object? operator [](int index) {
    Object? result = realStack[index];
    latestStacktraces.clear();
    latestStacktraces.add(stackTraceStack[index] as StackTrace);
    return result;
  }

  @override
  bool get isNotEmpty => realStack.isNotEmpty;

  @override
  Object? get last {
    Object? result = this[0];
    if (result is NullValue) return null;
    return result;
  }

  @override
  int get length => realStack.length;

  @override
  Object? pop(NullValue? nullValue) {
    Object? result = realStack.pop(nullValue);
    latestStacktraces.clear();
    latestStacktraces
        .add(stackTraceStack.pop(/* nullValue = */ null) as StackTrace);
    return result;
  }

  @override
  List<T?>? popList<T>(int count, List<T?> list, NullValue? nullValue) {
    List<T?>? result = realStack.popList(count, list, nullValue);
    latestStacktraces.length = count;
    stackTraceStack.popList(count, latestStacktraces, /* nullValue = */ null);
    return result;
  }

  @override
  List<T>? popNonNullableList<T>(int count, List<T> list) {
    List<T>? result = realStack.popNonNullableList(count, list);
    latestStacktraces.length = count;
    stackTraceStack.popList(count, latestStacktraces, /* nullValue = */ null);
    return result;
  }

  @override
  void push(Object value) {
    realStack.push(value);
    stackTraceStack.push(StackTrace.current);
  }

  @override
  List<Object?> get values => realStack.values;
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns null instead of empty lists, and the lists returned are of fixed
/// length.
class FixedNullableList<T> {
  const FixedNullableList();

  List<T?>? pop(Stack stack, int count, [NullValue? nullValue]) {
    if (count == 0) return null;
    return stack.popList(
        count, new List<T?>.filled(count, /* fill = */ null), nullValue);
  }

  List<T>? popNonNullable(Stack stack, int count, T dummyValue) {
    if (count == 0) return null;
    return stack.popNonNullableList(
        count, new List<T>.filled(count, dummyValue));
  }

  List<T?>? popPadded(Stack stack, int count, int padding,
      [NullValue? nullValue]) {
    if (count + padding == 0) return null;
    return stack.popList(count,
        new List<T?>.filled(count + padding, /* fill = */ null), nullValue);
  }

  List<T>? popPaddedNonNullable(
      Stack stack, int count, int padding, T dummyValue) {
    if (count + padding == 0) return null;
    return stack.popNonNullableList(
        count, new List<T>.filled(count + padding, dummyValue));
  }
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns growable lists (also when empty).
class GrowableList<T> {
  const GrowableList();

  List<T?>? pop(Stack stack, int count, [NullValue? nullValue]) {
    return stack.popList(
        count,
        new List<T?>.filled(count, /* fill = */ null, growable: true),
        nullValue);
  }

  List<T>? popNonNullable(Stack stack, int count, T dummyValue) {
    if (count == 0) return null;
    return stack.popNonNullableList(
        count, new List<T>.filled(count, dummyValue, growable: true));
  }
}

class ParserRecovery {
  final int charOffset;
  ParserRecovery(this.charOffset);

  String toString() => "ParserRecovery(@$charOffset)";
}
