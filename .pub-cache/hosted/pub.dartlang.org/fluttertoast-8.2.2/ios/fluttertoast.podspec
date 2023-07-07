#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'fluttertoast'
  s.version          = '0.0.2'
  s.summary          = 'Toast Library for Flutter'
  s.description      = <<-DESC
Toast Library for FLutter
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Karthik Ponnam' => 'ponnamkarthik3@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Toast'
  s.pod_target_xcconfig = {'VALID_ARCHS' => 'x86_64 armv7 arm64', 'DEFINES_MODULE' => 'YES'}
end

