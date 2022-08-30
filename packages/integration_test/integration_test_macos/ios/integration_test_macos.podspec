#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'IntegrationTestMacOS'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of the integration_test desktop plugin to avoid build issues on iOS'
  s.description      = <<-DESC
  No-op implementation of integration to avoid build issues on iOS.
  See https://github.com/flutter/flutter/issues/39659
                       DESC
  s.homepage         = 'https://github.com/flutter/flutter/tree/master/packages/integration_test/integration_test_macos'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end
