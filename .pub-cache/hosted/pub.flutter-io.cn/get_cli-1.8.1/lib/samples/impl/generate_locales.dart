import '../interface/sample_interface.dart';

class GenerateLocalesSample extends Sample {
  final String _translationsKeys;
  final String _keys;
  final String _locales;
  GenerateLocalesSample(this._keys, this._locales, this._translationsKeys,
      {String path = 'lib/generated/locales.g.dart'})
      : super(path, overwrite: true);

  @override
  String get content => '''
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

// ignore_for_file: lines_longer_than_80_chars
// ignore: avoid_classes_with_only_static_members
class AppTranslation {

\tstatic Map<String, Map<String, String>> translations = {
$_translationsKeys
\t};

}

class LocaleKeys {
LocaleKeys._();
$_keys
}

class Locales {
\t$_locales
}
''';
}
