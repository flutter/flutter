import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart' hide predicate;
import 'package:test/test.dart' as test show predicate;

/// Returns a [Matcher] that asserts on a [ParserException].
const isParserException = TypeMatcher<ParserException>();

/// Returns a [Matcher] that asserts two parsers are structurally equivalent.
Matcher isParserEqual<T>(Parser<T> parser) => test.predicate(
    (actual) => actual is Parser<T> && actual.isEqualTo(parser),
    'structurally equal');

/// Returns a [Matcher] that asserts the context under test is a [Success].
/// Optionally also asserts [position] and [value].
TypeMatcher<Success<T>> isSuccessContext<T>(
        {dynamic position = anything, dynamic value = anything}) =>
    isA<Success<T>>()
        .having((context) => context.value, 'value', value)
        .having((context) => context.position, 'position', position);

/// Returns a [Matcher] that asserts the parser under test yields a successful
/// parse [result] for the given [input]. If no [position] is provided, assert
/// that the parsing fails at the end of the input.
Matcher isParseSuccess<T>(String input, dynamic result, {dynamic position}) =>
    isA<Parser<T>>()
        .having(
            (parser) => parser.parse(input),
            'parse',
            isSuccessContext<T>(
                value: result, position: position ?? input.length))
        .having((parser) => parser.fastParseOn(input, 0), 'fastParseOn',
            position ?? input.length)
        .having((parser) => parser.accept(input), 'accept', isTrue);

/// Returns a [Matcher] that asserts the context under test is a [Failure].
/// Optionally also asserts [position] and [message].
TypeMatcher<Failure<T>> isFailureContext<T>(
        {dynamic position = anything, dynamic message = anything}) =>
    isA<Failure<T>>()
        .having((context) => context.message, 'message', message)
        .having((context) => context.position, 'position', position);

/// Returns a [Matcher] that asserts the parser under test yields a parse
/// failure for the given [input]. If no [position] is provided, assert that
/// parsing fails at the beginning of the input. An optional [message] can be
/// provided to assert on the error message.
Matcher isParseFailure<T>(String input,
        {dynamic position = 0, dynamic message = anything}) =>
    isA<Parser<T>>()
        .having((parser) => parser.parse(input), 'parse',
            isFailureContext<T>(position: position, message: message))
        .having((parser) => parser.fastParseOn(input, 0), 'fastParseOn', -1)
        .having((parser) => parser.accept(input), 'accept', isFalse);
