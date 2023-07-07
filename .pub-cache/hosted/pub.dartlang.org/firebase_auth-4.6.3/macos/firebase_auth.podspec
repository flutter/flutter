require 'yaml'

pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
library_version = pubspec['version'].gsub('+', '-')

if defined?($FirebaseSDKVersion)
  Pod::UI.puts "#{pubspec['name']}: Using user specified Firebase SDK version '#{$FirebaseSDKVersion}'"
  firebase_sdk_version = $FirebaseSDKVersion
else
  firebase_core_script = File.join(File.expand_path('..', File.expand_path('..', File.dirname(__FILE__))), 'firebase_core/ios/firebase_sdk_version.rb')
  if File.exist?(firebase_core_script)
    require firebase_core_script
    firebase_sdk_version = firebase_sdk_version!
    Pod::UI.puts "#{pubspec['name']}: Using Firebase SDK version '#{firebase_sdk_version}' defined in 'firebase_core'"
  end
end

begin
  required_macos_version = "10.12"
  current_target_definition = Pod::Config.instance.podfile.send(:current_target_definition)
  user_osx_target = current_target_definition.to_hash["platform"]["osx"]
  if (Gem::Version.new(user_osx_target) < Gem::Version.new(required_macos_version))
    error_message = "The FlutterFire plugin #{pubspec['name']} for macOS requires a macOS deployment target of #{required_macos_version} or later."
    Pod::UI.warn error_message, [
      "Update the `platform :osx, '#{user_osx_target}'` line in your macOS/Podfile to version `#{required_macos_version}` and ensure you commit this file.",
      "Open your `macos/Runner.xcodeproj` Xcode project and under the 'Runner' target General tab set your Deployment Target to #{required_macos_version} or later."
    ]
    raise Pod::Informative, error_message
  end
rescue Pod::Informative
  raise
rescue
  # Do nothing for all other errors and let `pod install` deal with any issues.
end

Pod::Spec.new do |s|
  s.name             = pubspec['name']
  s.version          = library_version
  s.summary          = pubspec['description']
  s.description      = pubspec['description']
  s.homepage         = pubspec['homepage']
  s.license          = { :file => '../LICENSE' }
  s.authors          = 'The Chromium Authors'
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'

  s.platform = :osx, '10.13'

  # Flutter dependencies
  s.dependency 'FlutterMacOS'

  # Firebase dependencies
  s.dependency 'firebase_core'
  s.dependency 'Firebase/CoreOnly', "~> #{firebase_sdk_version}"
  s.dependency 'Firebase/Auth', "~> #{firebase_sdk_version}"

  s.static_framework = true
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => "LIBRARY_VERSION=\\@\\\"#{library_version}\\\" LIBRARY_NAME=\\@\\\"flutter-fire-auth\\\"",
    'DEFINES_MODULE' => 'YES'
  }
end
