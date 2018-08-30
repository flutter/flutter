# This file should be used from the target section of the host-app's Podfile like this:
# ```
# target 'host' do
#     flutter_application_path = /"(.*)\/.ios\/Flutter\/Generated.xcconfig"/.match(File.read("./Flutter/FlutterConfig.xcconfig"))[1]
#     eval(File.read(File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')))
# end
# ```

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

# Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
# referring to absolute paths on developers' machines.
system('rm -rf .symlinks')
system('mkdir -p .symlinks/plugins')

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

framework_dir = File.join(File.expand_path(File.dirname(__FILE__)), 'Flutter')
engine_dir = File.join(framework_dir, 'engine')
if !File.exist?(engine_dir)
    # Copy the debug engine to have something to link against if the xcode backend script has not run yet.
    debug_framework_dir = File.join(flutter_root(flutter_application_path), 'bin', 'cache', 'artifacts', 'engine', 'ios')
    FileUtils.mkdir(engine_dir)
    FileUtils.cp_r(File.join(debug_framework_dir, 'Flutter.framework'), engine_dir)
    FileUtils.cp(File.join(debug_framework_dir, 'Flutter.podspec'), engine_dir)
end

symlink = File.join('.symlinks', 'flutter')

File.symlink(framework_dir, symlink)
pod 'Flutter', :path => File.join(symlink, 'engine')


plugin_pods = parse_KV_file(File.join(flutter_application_path, '.flutter-plugins'))

plugin_pods.map { |r|
    symlink = File.join('.symlinks', 'plugins', r[:name])

    File.symlink(r[:path], symlink)
    pod r[:name], :path => File.join(symlink, 'ios')
}

symlink = File.join('.symlinks', 'FlutterApp')
File.symlink(File.absolute_path(flutter_application_path), symlink)

pod 'FlutterPluginRegistrant', :path => File.join(symlink, '.ios', 'Flutter','FlutterPluginRegistrant')
