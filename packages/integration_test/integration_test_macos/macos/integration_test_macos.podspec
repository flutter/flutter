#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'IntegrationTestMacOS'
  s.version          = '0.0.1'
  s.summary          = 'Adapter for integration tests.'
  s.description      = <<-DESC
Runs tests that use the flutter_test API as integration tests on macOS.
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/integration_test/integration_test_macos'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/plugins/tree/master/packages/integration_test' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end

