#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'connectivity'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of the macos connectivity to avoid build issues on macos'
  s.description      = <<-DESC
  No-op implementation of the connectivity plugin to avoid build issues on macos.
  https://github.com/flutter/flutter/issues/46618
                       DESC
  s.homepage         = 'https://github.com/flutter/plugins/tree/master/packages/connectivity'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

