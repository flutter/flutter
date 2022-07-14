# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

require 'json'

# Minimum CocoaPods Ruby version is 2.0.
# Don't depend on features newer than that.

# Hook for Podfile setup, installation settings.
#
# @example
# flutter_ios_podfile_setup
# target 'Runner' do
# ...
# end
def flutter_ios_podfile_setup
end

# Same as flutter_ios_podfile_setup for macOS.
def flutter_macos_podfile_setup
end

# Add iOS build settings to pod targets.
#
# @example
# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     flutter_additional_ios_build_settings(target)
#   end
# end
# @param [PBXAggregateTarget] target Pod target.
def flutter_additional_ios_build_settings(target)
  return unless target.platform_name == :ios

  # [target.deployment_target] is a [String] formatted as "8.0".
  inherit_deployment_target = target.deployment_target[/\d+/].to_i < 9

  # This podhelper script is at $FLUTTER_ROOT/packages/flutter_tools/bin.
  # Add search paths from $FLUTTER_ROOT/bin/cache/artifacts/engine.
  artifacts_dir = File.join('..', '..', '..', '..', 'bin', 'cache', 'artifacts', 'engine')
  debug_framework_dir = File.expand_path(File.join(artifacts_dir, 'ios', 'Flutter.xcframework'), __FILE__)

  unless Dir.exist?(debug_framework_dir)
    # iOS artifacts have not been downloaded.
    raise "#{debug_framework_dir} must exist. If you're running pod install manually, make sure \"flutter precache --ios\" is executed first"
  end

  release_framework_dir = File.expand_path(File.join(artifacts_dir, 'ios-release', 'Flutter.xcframework'), __FILE__)

  target.build_configurations.each do |build_configuration|
    # Build both x86_64 and arm64 simulator archs for all dependencies. If a single plugin does not support arm64 simulators,
    # the app and all frameworks will fall back to x86_64. Unfortunately that case is not detectable in this script.
    # Therefore all pods must have a x86_64 slice available, or linking a x86_64 app will fail.
    build_configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO' if build_configuration.type == :debug

    # Skip other updates if it's not a Flutter plugin (transitive dependency).
    next unless target.dependencies.any? { |dependency| dependency.name == 'Flutter' }

    # Profile can't be derived from the CocoaPods build configuration. Use release framework (for linking only).
    configuration_engine_dir = build_configuration.type == :debug ? debug_framework_dir : release_framework_dir
    Dir.new(configuration_engine_dir).each_child do |xcframework_file|
      continue if xcframework_file.start_with?(".") # Hidden file, possibly on external disk.
      if xcframework_file.end_with?("-simulator") # ios-arm64_x86_64-simulator
        build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]'] = "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
      elsif xcframework_file.start_with?("ios-") # ios-armv7_arm64
        build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]'] = "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
      else
        # Info.plist or another platform.
      end
    end
    build_configuration.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework Flutter'

    build_configuration.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    # Suppress warning when pod supports a version lower than the minimum supported by Xcode (Xcode 12 - iOS 9).
    # This warning is harmless but confusing--it's not a bad thing for dependencies to support a lower version.
    # When deleted, the deployment version will inherit from the higher version derived from the 'Runner' target.
    # If the pod only supports a higher version, do not delete to correctly produce an error.
    build_configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET' if inherit_deployment_target

    # Override legacy Xcode 11 style VALID_ARCHS[sdk=iphonesimulator*]=x86_64 and prefer Xcode 12 EXCLUDED_ARCHS.
    build_configuration.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = '$(ARCHS_STANDARD)'
    build_configuration.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = '$(inherited) i386'
  end
end

# Same as flutter_ios_podfile_setup for macOS.
def flutter_additional_macos_build_settings(target)
  return unless target.platform_name == :osx

  # Return if it's not a Flutter plugin (transitive dependency).
  return unless target.dependencies.any? { |dependency| dependency.name == 'FlutterMacOS' }

  # [target.deployment_target] is a [String] formatted as "10.8".
  deployment_target_major, deployment_target_minor = target.deployment_target.match(/(\d+).?(\d*)/).captures

  # Suppress warning when pod supports a version lower than the minimum supported by the latest stable version of Xcode (currently 10.9).
  # This warning is harmless but confusing--it's not a bad thing for dependencies to support a lower version.
  inherit_deployment_target = !target.deployment_target.blank? &&
    (deployment_target_major.to_i < 10) ||
    (deployment_target_major.to_i == 10 && deployment_target_minor.to_i < 9)

  # This podhelper script is at $FLUTTER_ROOT/packages/flutter_tools/bin.
  # Add search paths from $FLUTTER_ROOT/bin/cache/artifacts/engine.
  artifacts_dir = File.join('..', '..', '..', '..', 'bin', 'cache', 'artifacts', 'engine')
  debug_framework_dir = File.expand_path(File.join(artifacts_dir, 'darwin-x64'), __FILE__)
  release_framework_dir = File.expand_path(File.join(artifacts_dir, 'darwin-x64-release'), __FILE__)

  unless Dir.exist?(debug_framework_dir)
    # macOS artifacts have not been downloaded.
    raise "#{debug_framework_dir} must exist. If you're running pod install manually, make sure \"flutter precache --macos\" is executed first"
  end

  target.build_configurations.each do |build_configuration|
    # Profile can't be derived from the CocoaPods build configuration. Use release framework (for linking only).
    configuration_engine_dir = build_configuration.type == :debug ? debug_framework_dir : release_framework_dir
    build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS'] = "\"#{configuration_engine_dir}\" $(inherited)"

    # When deleted, the deployment version will inherit from the higher version derived from the 'Runner' target.
    # If the pod only supports a higher version, do not delete to correctly produce an error.
    build_configuration.build_settings.delete 'MACOSX_DEPLOYMENT_TARGET' if inherit_deployment_target

    # Avoid error about Pods-Runner not supporting provisioning profiles.
    # Framework signing is handled at the app layer, not per framework, so disallow individual signing.
    build_configuration.build_settings.delete 'EXPANDED_CODE_SIGN_IDENTITY'
    build_configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    build_configuration.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  end
end

# Install pods needed to embed Flutter iOS engine and plugins.
#
# @example
#   target 'Runner' do
#     flutter_install_all_ios_pods
#   end
# @param [String] ios_application_path Path of the iOS directory of the Flutter app.
#                                      Optional, defaults to the Podfile directory.
def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_engine_pod(ios_application_path)
  flutter_install_plugin_pods(ios_application_path, '.symlinks', 'ios')
end

# Same as flutter_install_all_ios_pods for macOS.
def flutter_install_all_macos_pods(macos_application_path = nil)
  flutter_install_macos_engine_pod(macos_application_path)
  flutter_install_plugin_pods(macos_application_path, File.join('Flutter', 'ephemeral', '.symlinks'), 'macos')
end

# Install iOS Flutter engine pod.
#
# @example
#   target 'Runner' do
#     flutter_install_ios_engine_pod
#   end
# @param [String] ios_application_path Path of the iOS directory of the Flutter app.
#                                      Optional, defaults to the Podfile directory.
def flutter_install_ios_engine_pod(ios_application_path = nil)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  ios_application_path ||= File.dirname(defined_in_file.realpath) if self.respond_to?(:defined_in_file)
  raise 'Could not find iOS application path' unless ios_application_path

  copied_podspec_path = File.expand_path('Flutter.podspec', File.join(ios_application_path, 'Flutter'))

  # Generate a fake podspec to represent the Flutter framework.
  # This is only necessary because plugin podspecs contain `s.dependency 'Flutter'`, and if this Podfile
  # does not add a `pod 'Flutter'` CocoaPods will try to download it from the CocoaPods trunk.
  File.open(copied_podspec_path, 'w') { |podspec|
    podspec.write <<~EOF
      #
      # NOTE: This podspec is NOT to be published. It is only used as a local source!
      #       This is a generated file; do not edit or check into version control.
      #

      Pod::Spec.new do |s|
        s.name             = 'Flutter'
        s.version          = '1.0.0'
        s.summary          = 'High-performance, high-fidelity mobile apps.'
        s.homepage         = 'https://flutter.io'
        s.license          = { :type => 'MIT' }
        s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
        s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
        s.ios.deployment_target = '9.0'
        # Framework linking is handled by Flutter tooling, not CocoaPods.
        # Add a placeholder to satisfy `s.dependency 'Flutter'` plugin podspecs.
        s.vendored_frameworks = 'path/to/nothing'
      end
    EOF
  }

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'Flutter', :path => 'Flutter'
end

# Same as flutter_install_ios_engine_pod for macOS.
def flutter_install_macos_engine_pod(mac_application_path = nil)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  mac_application_path ||= File.dirname(defined_in_file.realpath) if self.respond_to?(:defined_in_file)
  raise 'Could not find macOS application path' unless mac_application_path

  copied_podspec_path = File.expand_path('FlutterMacOS.podspec', File.join(mac_application_path, 'Flutter', 'ephemeral'))

  # Generate a fake podspec to represent the FlutterMacOS framework.
  # This is only necessary because plugin podspecs contain `s.dependency 'FlutterMacOS'`, and if this Podfile
  # does not add a `pod 'FlutterMacOS'` CocoaPods will try to download it from the CocoaPods trunk.
  File.open(copied_podspec_path, 'w') { |podspec|
    podspec.write <<~EOF
      #
      # NOTE: This podspec is NOT to be published. It is only used as a local source!
      #       This is a generated file; do not edit or check into version control.
      #

      Pod::Spec.new do |s|
        s.name             = 'FlutterMacOS'
        s.version          = '1.0.0'
        s.summary          = 'High-performance, high-fidelity mobile apps.'
        s.homepage         = 'https://flutter.io'
        s.license          = { :type => 'MIT' }
        s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
        s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
        s.osx.deployment_target = '10.11'
        # Framework linking is handled by Flutter tooling, not CocoaPods.
        # Add a placeholder to satisfy `s.dependency 'FlutterMacOS'` plugin podspecs.
        s.vendored_frameworks = 'path/to/nothing'
      end
    EOF
  }

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'FlutterMacOS', :path => File.join('Flutter', 'ephemeral')
end

# Install Flutter plugin pods.
#
# @param [String] application_path Path of the directory of the Flutter app.
#                                   Optional, defaults to the Podfile directory.
def flutter_install_plugin_pods(application_path = nil, relative_symlink_dir, platform)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  application_path ||= File.dirname(defined_in_file.realpath) if self.respond_to?(:defined_in_file)
  raise 'Could not find application path' unless application_path

  # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
  # referring to absolute paths on developers' machines.

  symlink_dir = File.expand_path(relative_symlink_dir, application_path)
  system('rm', '-rf', symlink_dir) # Avoid the complication of dependencies like FileUtils.

  symlink_plugins_dir = File.expand_path('plugins', symlink_dir)
  system('mkdir', '-p', symlink_plugins_dir)

  plugins_file = File.join(application_path, '..', '.flutter-plugins-dependencies')
  plugin_pods = flutter_parse_plugins_file(plugins_file, platform)
  plugin_pods.each do |plugin_hash|
    plugin_name = plugin_hash['name']
    plugin_path = plugin_hash['path']
    has_native_build = plugin_hash.fetch('native_build', true)
    if (plugin_name && plugin_path && has_native_build)
      symlink = File.join(symlink_plugins_dir, plugin_name)
      File.symlink(plugin_path, symlink)

      # Keep pod path relative so it can be checked into Podfile.lock.
      pod plugin_name, :path => File.join(relative_symlink_dir, 'plugins', plugin_name, platform)
    end
  end
end

# .flutter-plugins-dependencies format documented at
# https://flutter.dev/go/plugins-list-migration
def flutter_parse_plugins_file(file, platform)
  file_path = File.expand_path(file)
  return [] unless File.exists? file_path

  dependencies_file = File.read(file)
  dependencies_hash = JSON.parse(dependencies_file)

  # dependencies_hash.dig('plugins', 'ios') not available until Ruby 2.3
  return [] unless dependencies_hash.has_key?('plugins')
  return [] unless dependencies_hash['plugins'].has_key?('ios')
  dependencies_hash['plugins'][platform] || []
end
