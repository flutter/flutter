import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class MockUrlLauncherPlatform extends UrlLauncherPlatform {
  String? url;
  bool canLaunchMockValue = true;

  @override
  LinkDelegate? get linkDelegate => throw UnimplementedError();

  @override
  Future<bool> canLaunch(String url) async {
    return canLaunchMockValue;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    this.url = url;
    return canLaunchMockValue;
  }
}
