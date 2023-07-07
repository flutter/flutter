#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'webview_flutter_wkwebview'
  s.version          = '0.0.1'
  s.summary          = 'A WebView Plugin for Flutter.'
  s.description      = <<-DESC
A Flutter plugin that provides a WebView widget.
Downloaded by pub (not CocoaPods).
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/main/packages/webview_flutter/webview_flutter_wkwebview' }
  s.documentation_url = 'https://pub.dev/packages/webview_flutter'
  s.source_files = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.module_map = 'Classes/FlutterWebView.modulemap'
  s.dependency 'Flutter'

  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
