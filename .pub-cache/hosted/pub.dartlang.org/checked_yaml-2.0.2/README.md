[![Pub Package](https://img.shields.io/pub/v/checked_yaml.svg)](https://pub.dev/packages/checked_yaml)

`package:checked_yaml` provides a `checkedYamlDecode` function that wraps the
the creation of classes annotated for [`package:json_serializable`] it helps
provide more helpful exceptions when the provided YAML is not compatible with
the target type.

[`package:json_serializable`] can generate classes that can parse the
[`YamlMap`] type provided by [`package:yaml`] when `anyMap: true` is specified
for the class annotation.

```dart
@JsonSerializable(
  anyMap: true,
  checked: true,
  disallowUnrecognizedKeys: true,
)
class Configuration {
  @JsonKey(required: true)
  final String name;
  final int count;

  Configuration({required this.name, required this.count}) {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Cannot be empty.');
    }
  }

  factory Configuration.fromJson(Map json) => _$ConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigurationToJson(this);

  @override
  String toString() => 'Configuration: ${toJson()}';
}
```

When `checked: true` is set, exceptions thrown when decoding an instance from a
`Map` are wrapped in a `CheckedFromJsonException`. The
`checkedYamlDecode` function catches these exceptions and throws a
`ParsedYamlException` which maps the exception to the location in the input
YAML with the error.

```dart
void main(List<String> arguments) {
  final sourcePathOrYaml = arguments.single;
  String yamlContent;
  Uri? sourceUri;

  if (FileSystemEntity.isFileSync(sourcePathOrYaml)) {
    yamlContent = File(sourcePathOrYaml).readAsStringSync();
    sourceUri = Uri.parse(sourcePathOrYaml);
  } else {
    yamlContent = sourcePathOrYaml;
  }

  final config = checkedYamlDecode(
    yamlContent,
    (m) => Configuration.fromJson(m!),
    sourceUrl: sourceUri,
  );
  print(config);
}
```

When parsing an invalid YAML file, an actionable error message is produced.

```console
$ dart example/example.dart '{"name": "", "count": 1}'
Unhandled exception:
ParsedYamlException: line 1, column 10: Unsupported value for "name". Cannot be empty.
  ╷
1 │ {"name": "", "count": 1}
  │          ^^
  ╵
```

[`package:json_serializable`]: https://pub.dev/packages/json_serializable
[`package:yaml`]: https://pub.dev/packages/yaml
[`YamlMap`]: https://pub.dev/documentation/yaml/latest/yaml/YamlMap-class.html
