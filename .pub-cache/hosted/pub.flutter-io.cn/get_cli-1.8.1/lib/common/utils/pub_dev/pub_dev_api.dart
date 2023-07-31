import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../../../core/internationalization.dart';
import '../../../core/locales.g.dart';
import '../logger/log_utils.dart';

class PubDevApi {
  static Future<String?> getLatestVersionFromPackage(String package) async {
    final languageCode = Platform.localeName.split('_')[0];
    final pubSite = languageCode == 'zh'
        ? 'https://pub.flutter-io.cn/api/packages/$package'
        : 'https://pub.dev/api/packages/$package';
    var uri = Uri.parse(pubSite);
    try {
      var value = await get(uri);
      if (value.statusCode == 200) {
        final version = json.decode(value.body)['latest']['version'] as String?;
        return version;
      } else if (value.statusCode == 404) {
        LogService.info(
          LocaleKeys.error_package_not_found.trArgs([package]),
          false,
          false,
        );
      }
      return null;
    } on Exception catch (err) {
      LogService.error(err.toString());
      return null;
    }
  }
}
