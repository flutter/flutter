import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'url_launcher_mock.dart';

void main() {
  test('registered instance', () {
    SharePlusLinuxPlugin.registerWith();
    expect(SharePlatform.instance, isA<SharePlusLinuxPlugin>());
  });
  test('url encoding is correct for &', () async {
    final mock = MockUrlLauncherPlatform();

    await SharePlusLinuxPlugin(mock).share('foo&bar', subject: 'bar&foo');

    expect(mock.url, 'mailto:?subject=bar%26foo&body=foo%26bar');
  });

  // see https://github.com/dart-lang/sdk/issues/43838#issuecomment-823551891
  test('url encoding is correct for spaces', () async {
    final mock = MockUrlLauncherPlatform();

    await SharePlusLinuxPlugin(mock).share('foo bar', subject: 'bar foo');

    expect(mock.url, 'mailto:?subject=bar%20foo&body=foo%20bar');
  });

  test('throws when url_launcher can\'t launch uri', () async {
    final mock = MockUrlLauncherPlatform();
    mock.canLaunchMockValue = false;

    expect(() async => await SharePlusLinuxPlugin(mock).share('foo bar'),
        throwsException);
  });
}
