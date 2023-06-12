#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'url_launcher_macos'
  s.version          = '0.0.1'
  s.summary          = 'Flutter macos plugin for launching a URL.'
  s.description      = <<-DESC
  A macOS implementation of the url_launcher plugin.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/main/packages/url_launcher/url_launcher_macos'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/main/packages/url_launcher/url_launcher_macos' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  end

