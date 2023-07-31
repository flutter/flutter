import 'package:checked_yaml/checked_yaml.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('bob', () {
    expect(
      () => checkedYamlDecode(
        '{"innerMap": {}}',
        (m) {
          throw CheckedFromJsonException(
            m!['innerMap'] as YamlMap,
            null,
            'nothing',
            null,
          );
        },
      ),
      throwsA(
        isA<ParsedYamlException>()
            .having(
              (e) => e.message,
              'message',
              'There was an error parsing the map.',
            )
            .having((e) => e.yamlNode, 'yamlNode', isA<YamlMap>())
            .having(
              (e) => e.innerError,
              'innerError',
              isA<CheckedFromJsonException>(),
            )
            .having((e) => e.formattedMessage, 'formattedMessage', '''
line 1, column 14: There was an error parsing the map.
  ╷
1 │ {"innerMap": {}}
  │              ^^
  ╵'''),
      ),
    );
  });
}
