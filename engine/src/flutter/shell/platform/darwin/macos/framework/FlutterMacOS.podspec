#
# NOTE: This podspec is NOT to be published. It is only used as a local source!
#

Pod::Spec.new do |s|
  s.name             = 'FlutterMacOS'
  s.version          = '1.0.0'
  s.summary          = 'High-performance, high-fidelity cross-platform apps.'
  s.description      = <<-DESC
Flutter is Google's portable UI toolkit for building beautiful, natively-compiled applications for mobile, web, and desktop from a single codebase.
                       DESC
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.osx.deployment_target = '10.11'
  s.vendored_frameworks = 'FlutterMacOS.framework'
end
