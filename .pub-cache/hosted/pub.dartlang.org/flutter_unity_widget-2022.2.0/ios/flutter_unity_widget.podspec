#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_unity_widget.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_unity_widget'
  s.version          = '4.0.0'
  s.summary          = 'Flutter unity 3D widget for embedding unity in flutter'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://xraph.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rex Isaac Raphael' => 'rex.raphael@outlook.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'
  s.frameworks = 'UnityFramework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.xcconfig = {
     'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/../UnityLibrary" "${PODS_ROOT}/../.symlinks/flutter/ios-release" "${PODS_CONFIGURATION_BUILD_DIR}"',
     'OTHER_LDFLAGS' => '$(inherited) -framework UnityFramework ${PODS_LIBRARIES}'
  }
end
