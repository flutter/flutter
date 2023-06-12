#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'share_plus'
  s.version          = '0.0.1'
  s.summary          = 'No-op spec for share_plus_macos to avoid build issues'
  s.description      = <<-DESC
No-op spec for share_plus_macos to avoid build issues.
https://github.com/flutter/flutter/issues/46618
                          DESC
  s.homepage         = 'https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Community' => 'authors@fluttercommunity.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end
