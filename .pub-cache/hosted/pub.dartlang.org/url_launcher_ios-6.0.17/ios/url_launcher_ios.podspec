#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'url_launcher_ios'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for launching a URL.'
  s.description      = <<-DESC
A Flutter plugin for making the underlying platform (Android or iOS) launch a URL.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/main/packages/url_launcher'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/master/packages/url_launcher/url_launcher_ios' }
  s.documentation_url = 'https://pub.dev/packages/url_launcher'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
