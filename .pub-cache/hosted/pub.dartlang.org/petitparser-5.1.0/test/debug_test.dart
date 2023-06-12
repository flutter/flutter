import 'package:petitparser/debug.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import 'utils/matchers.dart';

final identifier = letter() & word().star();
final labeledIdentifier =
    letter().labeled('first') & word().star().labeled('remaining');

Matcher isProfileFrame({required String parser, int count = 0}) =>
    isA<ProfileFrame>()
        .having((frame) => frame.parser.toString(), 'parser', contains(parser))
        .having((frame) => frame.count, 'count', count)
        .having((frame) => frame.elapsed, 'elapsed',
            greaterThanOrEqualTo(Duration.zero))
        .having((frame) => frame.toString(), 'toString',
            allOf(startsWith(count.toString()), contains(parser)));

Matcher isProgressFrame({required String parser, required int position}) =>
    isA<ProgressFrame>()
        .having((frame) => frame.parser.toString(), 'parser', contains(parser))
        .having((frame) => frame.position, 'position', position)
        .having((frame) => frame.toString(), 'toString',
            allOf(startsWith('*' * (position + 1)), contains(parser)));

Matcher isTraceEvent(
        {required String parser,
        required int level,
        dynamic result = isNull}) =>
    isA<TraceEvent>()
        .having(
            (frame) => frame.parent, 'parent', level == 0 ? isNull : isNotNull)
        .having((frame) => frame.parser.toString(), 'parser', contains(parser))
        .having((frame) => frame.level, 'level', level)
        .having((frame) => frame.result, 'result', result)
        .having(
            (frame) => frame.toString(),
            'toString',
            allOf(
                startsWith('  ' * level),
                result == isNull
                    ? contains(parser)
                    : contains(RegExp('Success|Failure'))));

void main() {
  group('profile', () {
    test('success', () {
      final frames = <ProfileFrame>[];
      final parser = profile(identifier, output: frames.add);
      expect(parser.parse('ab123').isSuccess, isTrue);
      expect(frames, [
        isProfileFrame(parser: 'SequenceParser', count: 1),
        isProfileFrame(parser: 'letter expected', count: 1),
        isProfileFrame(parser: '[0..*]', count: 1),
        isProfileFrame(parser: 'letter or digit expected', count: 5),
      ]);
    });
    test('labeled', () {
      final frames = <ProfileFrame>[];
      final parser = profile(labeledIdentifier,
          output: frames.add, predicate: (parser) => parser is LabeledParser);
      expect(parser.parse('ab123').isSuccess, isTrue);
      expect(frames, [
        isProfileFrame(parser: 'first', count: 1),
        isProfileFrame(parser: 'remaining', count: 1),
      ]);
    });
    test('failure', () {
      final frames = <ProfileFrame>[];
      final parser = profile(identifier, output: frames.add);
      expect(parser.parse('1').isFailure, isTrue);
      expect(frames, [
        isProfileFrame(parser: 'SequenceParser', count: 1),
        isProfileFrame(parser: 'letter expected', count: 1),
        isProfileFrame(parser: '[0..*]'),
        isProfileFrame(parser: 'letter or digit expected'),
      ]);
    });
  });
  group('progress', () {
    test('success', () {
      final frames = <ProgressFrame>[];
      final parser = progress(identifier, output: frames.add);
      expect(parser.parse('ab123').isSuccess, isTrue);
      expect(frames, [
        isProgressFrame(parser: 'SequenceParser', position: 0),
        isProgressFrame(parser: 'letter expected', position: 0),
        isProgressFrame(parser: '[0..*]', position: 1),
        isProgressFrame(parser: 'letter or digit expected', position: 1),
        isProgressFrame(parser: 'letter or digit expected', position: 2),
        isProgressFrame(parser: 'letter or digit expected', position: 3),
        isProgressFrame(parser: 'letter or digit expected', position: 4),
        isProgressFrame(parser: 'letter or digit expected', position: 5),
      ]);
    });
    test('labeled', () {
      final frames = <ProgressFrame>[];
      final parser = progress(labeledIdentifier,
          output: frames.add, predicate: (parser) => parser is LabeledParser);
      expect(parser.parse('ab123').isSuccess, isTrue);
      expect(frames, [
        isProgressFrame(parser: 'first', position: 0),
        isProgressFrame(parser: 'remaining', position: 1),
      ]);
    });
    test('failure', () {
      final frames = <ProgressFrame>[];
      final parser = progress(identifier, output: frames.add);
      expect(parser.parse('1').isFailure, isTrue);
      expect(frames, [
        isProgressFrame(parser: 'SequenceParser', position: 0),
        isProgressFrame(parser: 'letter expected', position: 0),
      ]);
    });
  });
  group('trace', () {
    test('success', () {
      final events = <TraceEvent>[];
      final parser = trace(identifier, output: events.add);
      expect(parser.parse('a').isSuccess, isTrue);
      expect(events, [
        isTraceEvent(parser: 'SequenceParser', level: 0),
        isTraceEvent(parser: 'letter expected', level: 1),
        isTraceEvent(
            parser: 'letter expected',
            level: 1,
            result: isSuccessContext(value: 'a')),
        isTraceEvent(parser: '[0..*]', level: 1),
        isTraceEvent(parser: 'letter or digit expected', level: 2),
        isTraceEvent(
            parser: 'letter or digit expected',
            level: 2,
            result: isFailureContext(message: 'letter or digit expected')),
        isTraceEvent(
            parser: '[0..*]', level: 1, result: isSuccessContext(value: [])),
        isTraceEvent(
            parser: 'SequenceParser', level: 0, result: isSuccessContext()),
      ]);
    });
    test('labeled', () {
      final events = <TraceEvent>[];
      final parser = trace(labeledIdentifier,
          output: events.add, predicate: (parser) => parser is LabeledParser);
      expect(parser.parse('ab123').isSuccess, isTrue);
      expect(events, [
        isTraceEvent(parser: 'first', level: 0),
        isTraceEvent(
            parser: 'first', level: 0, result: isSuccessContext(value: 'a')),
        isTraceEvent(parser: 'remaining', level: 0),
        isTraceEvent(
            parser: 'remaining',
            level: 0,
            result: isSuccessContext(value: 'b123'.split(''))),
      ]);
    });
    test('failure', () {
      final events = <TraceEvent>[];
      final parser = trace(identifier, output: events.add);
      expect(parser.parse('1').isFailure, isTrue);
      expect(events, [
        isTraceEvent(parser: 'SequenceParser', level: 0),
        isTraceEvent(parser: 'letter expected', level: 1),
        isTraceEvent(
            parser: 'letter expected',
            level: 1,
            result: isFailureContext(message: 'letter expected')),
        isTraceEvent(
            parser: 'SequenceParser',
            level: 0,
            result: isFailureContext(message: 'letter expected')),
      ]);
    });
  });
}
