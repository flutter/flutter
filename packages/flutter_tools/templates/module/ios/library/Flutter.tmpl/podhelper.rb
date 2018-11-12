def parse_KV_file(file, separator='=')
    file_abs_path = File.expand_path(file)
    if !File.exists? file_abs_path
        return [];
    end
    pods_array = []
    skip_line_start_symbols = ["#", "/"]
    File.foreach(file_abs_path) { |line|
        next if skip_line_start_symbols.any? { |symbol| line =~ /^\s*#{symbol}/ }
        plugin = line.split(pattern=separator)
        if plugin.length == 2
            podname = plugin[0].strip()
            path = plugin[1].strip()
            podpath = File.expand_path("#{path}", file_abs_path)
            pods_array.push({:name => podname, :path => podpath});
         else
            puts "Invalid plugin specification: #{line}"
        end
    }
    return pods_array
end

def flutter_root(f)
    generated_xcode_build_settings = parse_KV_file(File.join(f, File.join('.ios', 'Flutter', 'Generated.xcconfig')))
    if generated_xcode_build_settings.empty?
        puts "Generated.xcconfig must exist. Make sure `flutter packages get` is executed in ${f}."
        exit
    end
    generated_xcode_build_settings.map { |p|
        if p[:name] == 'FLUTTER_ROOT'
            return p[:path]
        end
    }
end

# If this wasn't specified, assume it's two levels up from the directory of this script.
flutter_application_path ||= File.join(__dir__, '..', '..')
framework_dir = File.join(flutter_application_path, '.ios', 'Flutter')

engine_dir = File.join(framework_dir, 'engine')
if !File.exist?(engine_dir)
    # Copy the debug engine to have something to link against if the xcode backend script has not run yet.
    debug_framework_dir = File.join(flutter_root(flutter_application_path), 'bin', 'cache', 'artifacts', 'engine', 'ios')
    FileUtils.mkdir_p(engine_dir)
    FileUtils.cp_r(File.join(debug_framework_dir, 'Flutter.framework'), engine_dir)
    FileUtils.cp(File.join(debug_framework_dir, 'Flutter.podspec'), engine_dir)
end

pod 'Flutter', :path => engine_dir
pod 'FlutterPluginRegistrant', :path => File.join(framework_dir, 'FlutterPluginRegistrant')

symlinks_dir = File.join(framework_dir, '.symlinks')
FileUtils.mkdir_p(symlinks_dir)
plugin_pods = parse_KV_file(File.join(flutter_application_path, '.flutter-plugins'))
plugin_pods.map { |r|
    symlink = File.join(symlinks_dir, r[:name])
    FileUtils.rm_f(symlink)
    File.symlink(r[:path], symlink)
    pod r[:name], :path => File.join(symlink, 'ios')
}

# Ensure that ENABLE_BITCODE is set to NO, add a #include to Generated.xcconfig, and
# add a run script to the Build Phases.
# TODO(dnfield): Figure out a way to deliver the Build Phase scripts without manual user intervention.
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            xcconfig_path = config.base_configuration_reference.real_path
            File.open(xcconfig_path, 'a+') do |file|
                file.puts "#include \"#{File.realpath(File.join(framework_dir, 'Generated.xcconfig'))}\""
            end
        end
    end
end
