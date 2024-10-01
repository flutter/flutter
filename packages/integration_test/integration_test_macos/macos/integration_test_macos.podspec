#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'integration_test_macos'
  s.version          = '0.0.1'
  s.summary          = 'Adapter for integration tests.'
  s.description      = <<-DESC
Runs tests that use the flutter_test API as integration tests on macOS.
                       DESC
  s.homepage         = 'https://github.com/flutter/flutter/tree/main/packages/integration_test/integration_test_macos'
  s.license          = { :type => 'BSD', :text => <<-LICENSE
Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
LICENSE
   }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/flutter/tree/main/packages/integration_test/integration_test_macos' }
  s.source_files = 'integration_test_macos/Sources/integration_test_macos/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
