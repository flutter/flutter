#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audioplayers.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audioplayers'
  s.version          = '0.0.1'
  s.summary          = 'A flutter plugin to play multiple simultaneously audio files.'
  s.description      = <<-DESC
  A flutter plugin to play multiple simultaneously audio files.

  This is a fork of rxlabz's audioplayer, with the difference that it supports playing multiple audios at the same time, and exposes volume controls.  
                       DESC
  s.homepage         = 'https://github.com/luanpotter/audioplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Luan Nico' => 'luannico27@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
