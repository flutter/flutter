def scriptFile = getClass().protectionDomain.codeSource.location.toURI()
def flutterProjectRoot = new File(scriptFile).parentFile.parentFile

gradle.include ":flutter"
gradle.project(":flutter").projectDir = new File(flutterProjectRoot, ".android/Flutter")

def localPropertiesFile = new File(flutterProjectRoot, ".android/local.properties")
def properties = new Properties()

assert localPropertiesFile.exists(), "❗️The Flutter module doesn't have a `$localPropertiesFile` file." +
                                     "\nYou must run `flutter pub get` in `$flutterProjectRoot`."
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
gradle.apply from: "$flutterSdkPath/packages/flutter_tools/gradle/module_plugin_loader.gradle"
