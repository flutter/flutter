# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def parse_KV_file(file, separator='=')
  file_abs_path = File.expand_path(file)
  if !File.exists? file_abs_path
    return [];
  end
  generated_key_values = {}
  skip_line_start_symbols = ["#", "/"]
  File.foreach(file_abs_path) do |line|
    next if skip_line_start_symbols.any? { |symbol| line =~ /^\s*#{symbol}/ }
    plugin = line.split(pattern=separator)
    if plugin.length == 2
      podname = plugin[0].strip()
      path = plugin[1].strip()
      podpath = File.expand_path("#{path}", file_abs_path)
      generated_key_values[podname] = podpath
    else
      puts "Invalid plugin specification: #{line}"
    end
  end
  generated_key_values
end

target 'Runner' do
  # Flutter Pod

  copied_flutter_dir = File.join(__dir__, 'Flutter')
  copied_framework_path = File.join(copied_flutter_dir, 'Flutter.framework')
  copied_podspec_path = File.join(copied_flutter_dir, 'Flutter.podspec')
  unless File.exist?(copied_framework_path) && File.exist?(copied_podspec_path)
    # Copy Flutter.framework and Flutter.podspec to Flutter/ to have something to link against if the xcode backend script has not run yet.
    # That script will copy the correct debug/profile/release version of the framework based on the currently selected Xcode configuration.
    # CocoaPods will not embed the framework on pod install (before any build phases can generate) if the dylib does not exist.

    generated_xcode_build_settings_path = File.join(copied_flutter_dir, 'Generated.xcconfig')
    unless File.exist?(generated_xcode_build_settings_path)
      raise "Generated.xcconfig must exist. If you're running pod install manually, make sure flutter pub get is executed first"
    end
    generated_xcode_build_settings = parse_KV_file(generated_xcode_build_settings_path)
    cached_framework_dir = generated_xcode_build_settings['FLUTTER_FRAMEWORK_DIR'];

    unless File.exist?(copied_framework_path)
      FileUtils.cp_r(File.join(cached_framework_dir, 'Flutter.framework'), copied_flutter_dir)
    end
    unless File.exist?(copied_podspec_path)
      FileUtils.cp(File.join(cached_framework_dir, 'Flutter.podspec'), copied_flutter_dir)
    end
  end

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'Flutter', :path => 'Flutter'

  # Plugin Pods

  # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
  # referring to absolute paths on developers' machines.
  system('rm -rf .symlinks')
  system('mkdir -p .symlinks/plugins')
  plugin_pods = parse_KV_file('../.flutter-plugins')
  plugin_pods.each do |name, path|
    symlink = File.join('.symlinks', 'plugins', name)
    File.symlink(path, symlink)
    pod name, :path => File.join(symlink, 'ios')
  end
end

# Prevent Cocoapods from embedding a second Flutter framework and causing an error with the new Xcode build system.
install! 'cocoapods', :disable_input_output_paths => true

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
