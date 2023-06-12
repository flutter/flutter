#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'path_provider_macos'
  s.version          = '0.0.1'
  s.summary          = 'A macOS implementation of the path_provider plugin.'
  s.description      = <<-DESC
  A macOS implementation of the Flutter plugin for getting commonly used locations on the filesystem.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/main/packages/path_provider/path_provider_macos'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/main/packages/path_provider/path_provider_macos' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
  s.swift_version = '5.0'
end

