#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wearableCommunicator.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'watch_ble_connection'
  s.version          = '1.0.1'
  s.summary          = 'Communication between Watch and Android/iOS Device'
  s.description      = <<-DESC
Flutter Package for communication between Wear OS or watchOS SmartWatch and Android/iOS Device with Bluetooth Low Energy (BLE).
                       DESC
  s.homepage         = 'https://diponten.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'www.diponten.com' => 'afriwan.phys@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.3'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
