#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'connectivity_macos'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for checking connectivity'
  s.description      = <<-DESC
  Desktop implementation of the connectivity plugin
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/connectivity/connectivity_macos'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/master/packages/connectivity/connectivity_macos' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'Reachability'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
  s.swift_version = '5.0'
end
