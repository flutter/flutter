#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audioplayers.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audioplayers_darwin'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation of audioplayers, a Flutter plugin to play multiple audio files simultaneously.'
  s.description      = 'iOS implementation of audioplayers, a Flutter plugin to play multiple audio files simultaneously.'
  s.homepage         = 'https://github.com/bluefireteam/audioplayers'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Blue Fire' => 'contact@blue-fire.xyz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
