import 'dart:io';

/// Number of parsers that can be combined.
final int min = 2;
final int max = 9;

/// Ordinal numbers for the sequence.
const ordinals = [
  'first',
  'second',
  'third',
  'fourth',
  'fifth',
  'sixth',
  'seventh',
  'eighth',
  'ninth',
];

/// Implementation file.
File implementationFile(int i) =>
    File('lib/src/parser/combinator/generated/sequence_$i.dart');

/// Test file.
final File testFile = File('test/generated/sequence_test.dart');

/// Pretty prints and cleans up a dart file.
Future<void> format(File file) async =>
    Process.run('dart', ['format', '--fix', file.absolute.path]);

/// Generate the variable names.
List<String> generateValues(String prefix, int i) =>
    List.generate(i, (i) => '$prefix${i + 1}');

void generateWarning(StringSink out) {
  out.writeln('// AUTO-GENERATED CODE: DO NOT EDIT');
  out.writeln();
}

Future<void> generateImplementation(int index) async {
  final file = implementationFile(index);
  final out = file.openWrite();
  final parserNames = generateValues('parser', index);
  final resultTypes = generateValues('R', index);
  final resultNames = generateValues('result', index);
  final valueTypes = generateValues('T', index);
  final valueNames = ordinals.sublist(0, index);

  generateWarning(out);
  out.writeln('import \'package:meta/meta.dart\';');
  out.writeln();
  out.writeln('import \'../../../context/context.dart\';');
  out.writeln('import \'../../../context/result.dart\';');
  out.writeln('import \'../../../core/parser.dart\';');
  out.writeln('import \'../../../shared/annotations.dart\';');
  out.writeln('import \'../../action/map.dart\';');
  out.writeln('import \'../../utils/sequential.dart\';');
  out.writeln();

  // Constructor function
  out.writeln('/// Creates a parser that consumes a sequence of $index parsers '
      'and returns a ');
  out.writeln('/// typed sequence [Sequence$index].');
  out.writeln('Parser<Sequence$index<${resultTypes.join(', ')}>> '
      'seq$index<${resultTypes.join(', ')}>(');
  for (var i = 0; i < index; i++) {
    out.writeln('Parser<${resultTypes[i]}> ${parserNames[i]},');
  }
  out.writeln(') => SequenceParser$index<${resultTypes.join(', ')}>(');
  for (var i = 0; i < index; i++) {
    out.writeln('${parserNames[i]},');
  }
  out.writeln(');');
  out.writeln();

  // Parser implementation.
  out.writeln('/// A parser that consumes a sequence of $index typed parsers '
      'and returns a typed ');
  out.writeln('/// sequence [Sequence$index].');
  out.writeln('class SequenceParser$index<${resultTypes.join(', ')}> '
      'extends Parser<Sequence$index<${resultTypes.join(', ')}>> '
      'implements SequentialParser {');
  out.writeln('SequenceParser$index('
      '${parserNames.map((each) => 'this.$each').join(', ')});');
  out.writeln();
  for (var i = 0; i < index; i++) {
    out.writeln('Parser<${resultTypes[i]}> ${parserNames[i]};');
  }
  out.writeln();
  out.writeln('@override');
  out.writeln('Result<Sequence$index<${resultTypes.join(', ')}>> '
      'parseOn(Context context) {');
  for (var i = 0; i < index; i++) {
    out.writeln('final ${resultNames[i]} = ${parserNames[i]}'
        '.parseOn(${i == 0 ? 'context' : resultNames[i - 1]});');
    out.writeln('if (${resultNames[i]}.isFailure) '
        'return ${resultNames[i]}.failure(${resultNames[i]}.message);');
  }
  out.writeln('return ${resultNames[index - 1]}.success('
      'Sequence$index<${resultTypes.join(', ')}>'
      '(${resultNames.map((each) => '$each.value').join(', ')}));');
  out.writeln('}');
  out.writeln();
  out.writeln('@override');
  out.writeln('int fastParseOn(String buffer, int position) {');
  for (var i = 0; i < index; i++) {
    out.writeln('position = ${parserNames[i]}.fastParseOn(buffer, position);');
    out.writeln('if (position < 0) return -1;');
  }
  out.writeln('return position;');
  out.writeln('}');
  out.writeln();
  out.writeln('@override');
  out.writeln('List<Parser> get children => [${parserNames.join(', ')}];');
  out.writeln();
  out.writeln('@override');
  out.writeln('void replace(Parser source, Parser target) {');
  out.writeln('super.replace(source, target);');
  for (var i = 0; i < index; i++) {
    out.writeln('if (${parserNames[i]} == source) '
        '${parserNames[i]} = target as Parser<${resultTypes[i]}>;');
  }
  out.writeln('}');
  out.writeln();
  out.writeln('@override');
  out.writeln('SequenceParser$index<${resultTypes.join(', ')}> copy() => '
      'SequenceParser$index<${resultTypes.join(', ')}>'
      '(${parserNames.join(', ')});');
  out.writeln('}');
  out.writeln();

  /// Data class implementation.
  out.writeln('/// Immutable typed sequence with $index values.');
  out.writeln('@immutable');
  out.writeln('class Sequence$index<${valueTypes.join(', ')}> {');
  out.writeln('/// Constructs a sequence with $index typed values.');
  out.writeln('Sequence$index('
      '${valueNames.map((each) => 'this.$each').join(', ')});');
  out.writeln();
  for (var i = 0; i < index; i++) {
    out.writeln('/// Returns the ${valueNames[i]} element of this sequence.');
    out.writeln('final ${valueTypes[i]} ${valueNames[i]};');
    out.writeln();
  }
  out.writeln('/// Returns the last (or ${valueNames.last}) element of this '
      'sequence.');
  out.writeln('@inlineVm @inlineJs');
  out.writeln('${valueTypes.last} get last => ${valueNames.last};');
  out.writeln();
  out.writeln('/// Converts this sequence to a new type [R] with the provided '
      '[callback].');
  out.writeln('@inlineVm @inlineJs');
  out.writeln('R map<R>(R Function(${valueTypes.join(', ')}) callback) => '
      'callback(${valueNames.join(', ')});');
  out.writeln();
  out.writeln('@override');
  out.writeln('int get hashCode => Object.hash(${valueNames.join(', ')});');
  out.writeln();
  out.writeln('@override');
  out.writeln('bool operator ==(Object other) => '
      'other is Sequence$index<${valueTypes.join(', ')}> && '
      '${valueNames.map((each) => '$each == other.$each').join(' && ')};');
  out.writeln();
  out.writeln('@override');
  out.writeln('String toString() => \'\${super.toString()}'
      '(${valueNames.map((each) => '\$$each').join(', ')})\';');
  out.writeln('}');
  out.writeln();

  // Mapping extension.
  out.writeln(
      'extension ParserSequenceExtension$index<${valueTypes.join(', ')}>'
      ' on Parser<Sequence$index<${valueTypes.join(', ')}>> {');
  out.writeln('/// Maps a typed sequence to [R] using the provided '
      '[callback].');
  out.writeln(
      'Parser<R> map$index<R>(R Function(${valueTypes.join(', ')}) callback) => '
      'map((sequence) => sequence.map(callback));');
  out.writeln('}');
  out.writeln();

  await out.close();
  await format(file);
}

Future<void> generateTest() async {
  final file = testFile;
  final out = file.openWrite();
  generateWarning(out);
  out.writeln('import \'package:petitparser/petitparser.dart\';');
  out.writeln('import \'package:test/test.dart\';');
  out.writeln();
  out.writeln('import \'../utils/assertions.dart\';');
  out.writeln('import \'../utils/matchers.dart\';');
  out.writeln();
  out.writeln('void main() {');
  for (var i = min; i <= max; i++) {
    final chars =
        List.generate(i, (i) => String.fromCharCode('a'.codeUnitAt(0) + i));
    final string = chars.join();

    out.writeln('group(\'seq$i\', () {');
    out.writeln('final parser = seq$i('
        '${chars.map((each) => 'char(\'$each\')').join(', ')});');
    out.writeln('final sequence = Sequence$i('
        '${chars.map((each) => '\'$each\'').join(', ')});');
    out.writeln('expectParserInvariants(parser);');
    out.writeln('test(\'success\', () {');
    out.writeln('expect(parser, isParseSuccess(\'$string\', sequence));');
    out.writeln('expect(parser, '
        'isParseSuccess(\'$string*\', sequence, position: $i));');
    out.writeln('});');
    for (var j = 0; j < i; j++) {
      out.writeln('test(\'failure at $j\', () {');
      out.writeln('expect(parser, isParseFailure(\''
          '${string.substring(0, j)}\', '
          'message: \'"${chars[j]}" expected\', '
          'position: $j));');
      out.writeln('expect(parser, isParseFailure(\''
          '${string.substring(0, j)}*\', '
          'message: \'"${chars[j]}" expected\', '
          'position: $j));');
      out.writeln('});');
    }
    out.writeln('});');

    out.writeln('group(\'map$i\', () {');
    out.writeln('final parser = seq$i('
        '${chars.map((each) => 'char(\'$each\')').join(', ')})'
        '.map$i((${chars.join(', ')}) => '
        '\'${chars.map((each) => '\$$each').join()}\');');
    out.writeln('expectParserInvariants(parser);');
    out.writeln('test(\'success\', () {');
    out.writeln('expect(parser, isParseSuccess(\'$string\', \'$string\'));');
    out.writeln(
        'expect(parser, isParseSuccess(\'$string*\', \'$string\', position: $i));');
    out.writeln('});');
    for (var j = 0; j < i; j++) {
      out.writeln('test(\'failure at $j\', () {');
      out.writeln('expect(parser, isParseFailure(\''
          '${string.substring(0, j)}\', '
          'message: \'"${chars[j]}" expected\', '
          'position: $j));');
      out.writeln('expect(parser, isParseFailure(\''
          '${string.substring(0, j)}*\', '
          'message: \'"${chars[j]}" expected\', '
          'position: $j));');
      out.writeln('});');
    }
    out.writeln('});');

    out.writeln('group(\'Sequence$i\', () {');
    out.writeln('final sequence = Sequence$i('
        '${chars.map((each) => '\'$each\'').join(', ')});');
    out.writeln('final other = Sequence$i('
        '${chars.reversed.map((each) => '\'$each\'').join(', ')});');
    out.writeln('test(\'accessors\', () {');
    for (var j = 0; j < i; j++) {
      out.writeln('expect(sequence.${ordinals[j]}, \'${chars[j]}\');');
    }
    out.writeln('expect(sequence.last, \'${chars[i - 1]}\');');
    out.writeln('});');
    out.writeln('test(\'map\', () {');
    out.writeln('expect(sequence.map((${chars.join(', ')}) {');
    for (var j = 0; j < i; j++) {
      out.writeln('expect(${chars[j]}, \'${chars[j]}\');');
    }
    out.writeln('return 42;');
    out.writeln('}), 42);');
    out.writeln('});');
    out.writeln('test(\'equals\', () {');
    out.writeln('expect(sequence, sequence);');
    out.writeln('expect(sequence, isNot(other));');
    out.writeln('expect(other, isNot(sequence));');
    out.writeln('expect(other, other);');
    out.writeln('});');
    out.writeln('test(\'hashCode\', () {');
    out.writeln('expect(sequence.hashCode, sequence.hashCode);');
    out.writeln('expect(sequence.hashCode, isNot(other.hashCode));');
    out.writeln('expect(other.hashCode, isNot(sequence.hashCode));');
    out.writeln('expect(other.hashCode, other.hashCode);');
    out.writeln('});');
    out.writeln('test(\'toString\', () {');
    out.writeln('expect(sequence.toString(), '
        'endsWith(\'(${chars.join(', ')})\'));');
    out.writeln('expect(other.toString(), '
        'endsWith(\'(${chars.reversed.join(', ')})\'));');
    out.writeln('});');
    out.writeln('});');
  }
  out.writeln('}');
  await out.close();
  await format(file);
}

Future<void> main() => Future.wait([
      for (var i = min; i <= max; i++) generateImplementation(i),
      generateTest(),
    ]);
