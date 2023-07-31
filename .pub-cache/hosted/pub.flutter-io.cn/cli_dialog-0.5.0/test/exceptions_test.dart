import 'package:test/test.dart';
import 'package:cli_dialog/src/dialog.dart';

Matcher getMatcher(msg) =>
    throwsA(predicate((dynamic e) => e is ArgumentError && e.message == msg));

void main() {
  test('Each question entry must be a list consisting of a question and a key.',
      () {
    final errorMatcher = getMatcher(
        'Each question entry must be a list consisting of a question and a key.');
    expect(
        () => CLI_Dialog(questions: [
              ['valid question', 'some_key'],
              [null, 'question1', null]
            ]),
        errorMatcher);
    expect(
        () => CLI_Dialog(booleanQuestions: [
              ['Some question', null, null]
            ]),
        errorMatcher);
    expect(
        () => CLI_Dialog(listQuestions: [
              [null, 'question2', null]
            ]),
        errorMatcher);
  });

  test('All questions and keys must be Strings.', () {
    final errorMatcher = getMatcher('All questions and keys must be Strings.');
    expect(
        () => CLI_Dialog(questions: [
              ['valid question', 'some_key'],
              [null, 'question1']
            ]),
        errorMatcher);
    expect(
        () => CLI_Dialog(booleanQuestions: [
              ['Some question', null]
            ]),
        errorMatcher);
    expect(
        () => CLI_Dialog(listQuestions: [
              {
                'questions': 'A',
                'options': ['A', 'B']
              },
              null
            ]),
        errorMatcher);
  });

  test('Your question must be a String.', () {
    final errorMatcher = getMatcher('Your question must be a String.');
    expect(
        () => CLI_Dialog(listQuestions: [
              [
                {
                  'question': 1337,
                  'options': ['A', 'B']
                },
                'some_key'
              ],
              [
                {
                  'question': 'valid',
                  'options': ['A', 'B']
                },
                'some_key'
              ]
            ]),
        errorMatcher);
  });

  test('Your list options must be a list of Strings.', () {
    final errorMatcher =
        getMatcher('Your list options must be a list of Strings.');
    expect(
        () => CLI_Dialog(listQuestions: [
              [
                {
                  'question': 'some question',
                  'options': ['A']
                },
                'valid_key'
              ],
              [
                {'question': 'some question', 'options': 1337},
                'some_key'
              ]
            ]),
        errorMatcher);
  });

  test('Your list dialog map must have exactly two entries.', () {
    final errorMatcher =
        getMatcher('Your list dialog map must have exactly two entries.');
    expect(
        () => CLI_Dialog(listQuestions: [
              [
                {
                  'question': 'some question',
                  'options': ['A']
                },
                'valid_key'
              ],
              [
                {
                  'question': 'some question',
                  'options': ['B'],
                  'invalid-entry': 'still invalid'
                },
                'some_key'
              ]
            ]),
        errorMatcher);
  });

  test('You have two or more keys with the same name.', () {
    final errorMatcher =
        getMatcher('You have two or more keys with the same name.');
    expect(
        () => CLI_Dialog(questions: [
              ['Question', 'question1']
            ], listQuestions: [
              [
                {
                  'question': 'Some Question',
                  'options': ['A']
                },
                'question1'
              ]
            ]),
        errorMatcher);
  });
}
