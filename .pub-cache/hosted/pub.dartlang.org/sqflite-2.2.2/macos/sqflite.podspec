#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sqflite.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sqflite'
  s.version          = '0.0.2'
  s.summary          = 'SQLite plugin.'
  s.description      = <<-DESC
Accss SQLite database.
                       DESC
  s.homepage         = 'https://github.com/tekartik/sqflite'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tekartik' => 'alex@tekartik.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'FMDB', '>= 2.7.5'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
