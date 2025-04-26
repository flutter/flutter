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
def flutter_ios_podfile_setup; end

# Same as flutter_ios_podfile_setup for macOS.
def flutter_macos_podfile_setup; end

# Determine whether the target depends on Flutter (including transitive dependency)
def depends_on_flutter(target, engine_pod_name)
  target.dependencies.any? do |dependency|
    if dependency.name == engine_pod_name
      return true
    end

    if depends_on_flutter(dependency.target, engine_pod_name)
      return true
    end
  end
  return false
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
  inherit_deployment_target = target.deployment_target[/\d+/].to_i < 12

  # ARC code targeting iOS 8 does not build on Xcode 14.3.
  force_to_arc_supported_min = target.deployment_target[/\d+/].to_i < 9

  # This podhelper script is at $FLUTTER_ROOT/packages/flutter_tools/bin.
  # Add search paths from $FLUTTER_ROOT/bin/cache/artifacts/engine.
  artifacts_dir = File.join('..', '..', '..', '..', 'bin', 'cache', 'artifacts', 'engine')
  debug_framework_dir = File.expand_path(File.join(artifacts_dir, 'ios', 'Flutter.xcframework'), __FILE__)

  unless Dir.exist?(debug_framework_dir)
    # iOS artifacts have not been downloaded.
    raise "#{debug_framework_dir} must exist. If you're running pod install manually, make sure \"flutter precache --ios\" is executed first"
  end

  release_framework_dir = File.expand_path(File.join(artifacts_dir, 'ios-release', 'Flutter.xcframework'), __FILE__)
  # Bundles are com.apple.product-type.bundle, frameworks are com.apple.product-type.framework.
  target_is_resource_bundle = target.respond_to?(:product_type) && target.product_type == 'com.apple.product-type.bundle'

  target.build_configurations.each do |build_configuration|
    # Build both x86_64 and arm64 simulator archs for all dependencies. If a single plugin does not support arm64 simulators,
    # the app and all frameworks will fall back to x86_64. Unfortunately that case is not detectable in this script.
    # Therefore all pods must have a x86_64 slice available, or linking a x86_64 app will fail.
    build_configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO' if build_configuration.type == :debug

    # Workaround https://github.com/CocoaPods/CocoaPods/issues/11402, do not sign resource bundles.
    if target_is_resource_bundle
      build_configuration.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      build_configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      build_configuration.build_settings['CODE_SIGNING_IDENTITY'] = '-'
      build_configuration.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = '-'
    end

    # ARC code targeting iOS 8 does not build on Xcode 14.3. Force to at least iOS 9.
    build_configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0' if force_to_arc_supported_min

    # Skip other updates if it does not depend on Flutter (including transitive dependency)
    next unless depends_on_flutter(target, 'Flutter')

    # Bitcode is deprecated, Flutter.framework bitcode blob will have been stripped.
    build_configuration.build_settings['ENABLE_BITCODE'] = 'NO'

    # Profile can't be derived from the CocoaPods build configuration. Use release framework (for linking only).
    # TODO(stuartmorgan): Handle local engines here; see https://github.com/flutter/flutter/issues/132228
    configuration_engine_dir = build_configuration.type == :debug ? debug_framework_dir : release_framework_dir
    Dir.new(configuration_engine_dir).each_child do |xcframework_file|
      next if xcframework_file.start_with?('.') # Hidden file, possibly on external disk.
      if xcframework_file.end_with?('-simulator') # ios-arm64_x86_64-simulator
        build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]'] = "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
      elsif xcframework_file.start_with?('ios-') # ios-arm64
        build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]'] = "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
       # else Info.plist or another platform.
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
    build_configuration.build_settings['EXCLUDED_ARCHS[sdk=iphoneos*]'] = '$(inherited) armv7'
  end
end

# Same as flutter_ios_podfile_setup for macOS.
def flutter_additional_macos_build_settings(target)
  return unless target.platform_name == :osx

  # [target.deployment_target] is a [String] formatted as "10.8".
  deployment_target_major, deployment_target_minor = target.deployment_target.match(/(\d+).?(\d*)/).captures

  # ARC code targeting macOS 10.10 does not build on Xcode 14.3.
  force_to_arc_supported_min = !target.deployment_target.blank? &&
                                  (deployment_target_major.to_i < 10) ||
                                  (deployment_target_major.to_i == 10 && deployment_target_minor.to_i < 11)

  # Suppress warning when pod supports a version lower than the minimum supported by the latest stable version of Xcode (currently 10.14).
  # This warning is harmless but confusing--it's not a bad thing for dependencies to support a lower version.
  inherit_deployment_target = !target.deployment_target.blank? &&
    (deployment_target_major.to_i < 10) ||
    (deployment_target_major.to_i == 10 && deployment_target_minor.to_i < 14)

  # This podhelper script is at $FLUTTER_ROOT/packages/flutter_tools/bin.
  # Add search paths from $FLUTTER_ROOT/bin/cache/artifacts/engine.
  artifacts_dir = File.join('..', '..', '..', '..', 'bin', 'cache', 'artifacts', 'engine')
  debug_framework_dir = File.expand_path(File.join(artifacts_dir, 'darwin-x64', 'FlutterMacOS.xcframework'), __FILE__)
  release_framework_dir = File.expand_path(File.join(artifacts_dir, 'darwin-x64-release', 'FlutterMacOS.xcframework'), __FILE__)
  application_path = File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  # Find the local engine path, if any.
  local_engine = application_path.nil? ?
    nil : flutter_get_local_engine_dir(File.join(application_path, 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'))

  unless Dir.exist?(debug_framework_dir)
    # macOS artifacts have not been downloaded.
    raise "#{debug_framework_dir} must exist. If you're running pod install manually, make sure \"flutter precache --macos\" is executed first"
  end

  target.build_configurations.each do |build_configuration|
    # ARC code targeting macOS 10.10 does not build on Xcode 14.3. Force to at least macOS 10.11.
    build_configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.11' if force_to_arc_supported_min

    # Skip other updates if it does not depend on Flutter (including transitive dependency)
    next unless depends_on_flutter(target, 'FlutterMacOS')

    if local_engine
      configuration_engine_dir = File.expand_path(File.join(local_engine, 'FlutterMacOS.xcframework'), __FILE__)
    else
      # Profile can't be derived from the CocoaPods build configuration. Use release framework (for linking only).
      configuration_engine_dir = (build_configuration.type == :debug ? debug_framework_dir : release_framework_dir)
    end
    Dir.new(configuration_engine_dir).each_child do |xcframework_file|
      if xcframework_file.start_with?('macos-') # Could be macos-arm64_x86_64, macos-arm64, macos-x86_64
        build_configuration.build_settings['FRAMEWORK_SEARCH_PATHS'] = "\"#{configuration_engine_dir}/#{xcframework_file}\" $(inherited)"
      end
    end

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
  ios_application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  raise 'Could not find iOS application path' unless ios_application_path

  podspec_directory = File.join(ios_application_path, 'Flutter')
  copied_podspec_path = File.expand_path('Flutter.podspec', podspec_directory)

  # Generate a fake podspec to represent the Flutter framework.
  # This is only necessary because plugin podspecs contain `s.dependency 'Flutter'`, and if this Podfile
  # does not add a `pod 'Flutter'` CocoaPods will try to download it from the CocoaPods trunk.
  File.open(copied_podspec_path, 'w') do |podspec|
    podspec.write <<~EOF
      #
      # This podspec is NOT to be published. It is only used as a local source!
      # This is a generated file; do not edit or check into version control.
      #

      Pod::Spec.new do |s|
        s.name             = 'Flutter'
        s.version          = '1.0.0'
        s.summary          = 'A UI toolkit for beautiful and fast apps.'
        s.homepage         = 'https://flutter.dev'
        s.license          = { :type => 'BSD' }
        s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
        s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
        s.ios.deployment_target = '12.0'
        # Framework linking is handled by Flutter tooling, not CocoaPods.
        # Add a placeholder to satisfy `s.dependency 'Flutter'` plugin podspecs.
        s.vendored_frameworks = 'path/to/nothing'
      end
    EOF
  end

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'Flutter', path: flutter_relative_path_from_podfile(podspec_directory)
end

# Same as flutter_install_ios_engine_pod for macOS.
def flutter_install_macos_engine_pod(mac_application_path = nil)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  mac_application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  raise 'Could not find macOS application path' unless mac_application_path

  copied_podspec_path = File.expand_path('FlutterMacOS.podspec', File.join(mac_application_path, 'Flutter', 'ephemeral'))

  # Generate a fake podspec to represent the FlutterMacOS framework.
  # This is only necessary because plugin podspecs contain `s.dependency 'FlutterMacOS'`, and if this Podfile
  # does not add a `pod 'FlutterMacOS'` CocoaPods will try to download it from the CocoaPods trunk.
  File.open(copied_podspec_path, 'w') do |podspec|
    podspec.write <<~EOF
      #
      # This podspec is NOT to be published. It is only used as a local source!
      # This is a generated file; do not edit or check into version control.
      #

      Pod::Spec.new do |s|
        s.name             = 'FlutterMacOS'
        s.version          = '1.0.0'
        s.summary          = 'A UI toolkit for beautiful and fast apps.'
        s.homepage         = 'https://flutter.dev'
        s.license          = { :type => 'BSD' }
        s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
        s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
        s.osx.deployment_target = '10.14'
        # Framework linking is handled by Flutter tooling, not CocoaPods.
        # Add a placeholder to satisfy `s.dependency 'FlutterMacOS'` plugin podspecs.
        s.vendored_frameworks = 'path/to/nothing'
      end
    EOF
  end

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'FlutterMacOS', path: File.join('Flutter', 'ephemeral')
end

# Install Flutter plugin pods.
#
# @param [String] application_path Path of the directory of the Flutter app.
#                                   Optional, defaults to the Podfile directory.
def flutter_install_plugin_pods(application_path = nil, relative_symlink_dir, platform)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  application_path ||= File.dirname(defined_in_file.realpath) if respond_to?(:defined_in_file)
  raise 'Could not find application path' unless application_path

  # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
  # referring to absolute paths on developers' machines.

  symlink_dir = File.expand_path(relative_symlink_dir, application_path)
  system('rm', '-rf', symlink_dir) # Avoid the complication of dependencies like FileUtils.

  symlink_plugins_dir = File.expand_path('plugins', symlink_dir)
  system('mkdir', '-p', symlink_plugins_dir)

  plugins_file = File.join(application_path, '..', '.flutter-plugins-dependencies')
  dependencies_hash = flutter_parse_plugins_file(plugins_file)
  plugin_pods = flutter_get_plugins_list(dependencies_hash, platform)
  swift_package_manager_enabled = flutter_get_swift_package_manager_enabled(dependencies_hash, platform)

  plugin_pods.each do |plugin_hash|
    plugin_name = plugin_hash['name']
    plugin_path = plugin_hash['path']
    has_native_build = plugin_hash.fetch('native_build', true)

    # iOS and macOS code can be shared in "darwin" directory, otherwise
    # respectively in "ios" or "macos" directories.
    shared_darwin_source = plugin_hash.fetch('shared_darwin_source', false)
    platform_directory = shared_darwin_source ? 'darwin' : platform
    next unless plugin_name && plugin_path && has_native_build
    symlink = File.join(symlink_plugins_dir, plugin_name)
    File.symlink(plugin_path, symlink)

    # Keep pod path relative so it can be checked into Podfile.lock.
    relative = flutter_relative_path_from_podfile(symlink)

    # If Swift Package Manager is enabled and the plugin has a Package.swift,
    # skip from installing as a pod.
    swift_package_exists = File.exist?(File.join(relative, platform_directory, plugin_name, "Package.swift"))
    next if swift_package_manager_enabled && swift_package_exists

    # If a plugin is Swift Package Manager compatible but not CocoaPods compatible, skip it.
    # The tool will print an error about it.
    next if swift_package_exists && !File.exist?(File.join(relative, platform_directory, plugin_name + ".podspec"))

    pod plugin_name, path: File.join(relative, platform_directory)
  end
end

def flutter_parse_plugins_file(file)
  file_path = File.expand_path(file)
  return [] unless File.exist? file_path

  dependencies_file = File.read(file)
  JSON.parse(dependencies_file)
end

# .flutter-plugins-dependencies format documented at
# https://flutter.dev/go/plugins-list-migration
def flutter_get_plugins_list(dependencies_hash, platform)
  # dependencies_hash.dig('plugins', 'ios') not available until Ruby 2.3
  return [] unless dependencies_hash.any?
  return [] unless dependencies_hash.has_key?('plugins')
  return [] unless dependencies_hash['plugins'].has_key?(platform)
  dependencies_hash['plugins'][platform] || []
end

def flutter_get_swift_package_manager_enabled(dependencies_hash, platform)
  return false unless dependencies_hash.any?
  return false unless dependencies_hash.has_key?('swift_package_manager_enabled')
  return false unless dependencies_hash['swift_package_manager_enabled'].has_key?(platform)

  dependencies_hash['swift_package_manager_enabled'][platform] == true
end

def flutter_relative_path_from_podfile(path)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  project_directory_pathname = defined_in_file.dirname

  pathname = Pathname.new File.expand_path(path)
  relative = pathname.relative_path_from project_directory_pathname
  relative.to_s
end

def flutter_parse_xcconfig_file(file)
  file_abs_path = File.expand_path(file)
  if !File.exist? file_abs_path
    return [];
  end
  entries = Hash.new
  skip_line_start_symbols = ["#", "/"]
  File.foreach(file_abs_path) { |line|
    next if skip_line_start_symbols.any? { |symbol| line =~ /^\s*#{symbol}/ }
    key_value_pair = line.split(pattern = '=')
    if key_value_pair.length == 2
      entries[key_value_pair[0].strip()] = key_value_pair[1].strip();
    else
      puts "Invalid key/value pair: #{line}"
    end
  }
  return entries
end

def flutter_get_local_engine_dir(xcconfig_file)
  file_abs_path = File.expand_path(xcconfig_file)
  if !File.exist? file_abs_path
    return nil
  end
  config = flutter_parse_xcconfig_file(xcconfig_file)
  local_engine = config['LOCAL_ENGINE']
  base_dir = config['FLUTTER_ENGINE']
  if !local_engine.nil? && !base_dir.nil?
    return File.join(base_dir, 'out', local_engine)
  end
  return nil
end
