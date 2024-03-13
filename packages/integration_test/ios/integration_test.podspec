#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'integration_test'
  s.version          = '0.0.1'
  s.summary          = 'Adapter for integration tests.'
  s.description      = <<-DESC
Runs tests that use the flutter_test API as integration tests.
                       DESC
  s.homepage         = 'https://github.com/flutter/flutter/tree/master/packages/integration_test'
  s.license          = { :type => 'BSD', :text => <<-LICENSE
Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
LICENSE
   }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/flutter/tree/master/packages/integration_test' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.framework  = 'UIKit'

  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
