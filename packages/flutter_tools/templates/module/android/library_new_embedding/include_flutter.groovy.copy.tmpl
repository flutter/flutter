def gradle = null
def flutterProjectRoot = null

// The second block handles the original syntax for including Flutter modules, which used a Groovy
// method that isn't a part of the Kotlin Gradle DSL (setBinding). The first block handles the
// preferred way of including Flutter modules, which is to use the apply from: Gradle syntax.
if (!getBinding().getVariables().containsKey("gradle")) {
    gradle = this
    flutterProjectRoot = gradle.buildscript.getSourceFile().getParentFile().getParentFile().absolutePath
} else {
    gradle = getBinding().getVariables().get("gradle")
    def scriptFile = getClass().protectionDomain.codeSource.location.toURI()
    flutterProjectRoot = new File(scriptFile).parentFile.parentFile.absolutePath
}

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

gradle.pluginManagement{
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}
