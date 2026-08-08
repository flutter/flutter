pluginManagement {
    val (flutterSdkPath, agpVersion) =
        run {
            // A plugin's android dir has no generated local.properties when consumed as a composite
            // build, so it may be absent. Fall back to the FLUTTER_ROOT env var (inherited from the
            // Flutter tool process) for the SDK path.
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            if (localPropertiesFile.exists()) {
                localPropertiesFile.inputStream().use { properties.load(it) }
            }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
                ?: System.getenv("FLUTTER_ROOT")
            // The Flutter tool forwards the host app's resolved AGP version via this JVM system
            // property so every build in the composite agrees on the AGP version. Falls back to a
            // Gradle property / local.properties / a default for standalone builds of this plugin.
            val agpVersion = System.getProperty("flutter.agp.version")
                ?: providers.gradleProperty("agp.version").orNull
                ?: properties.getProperty("agp.version")
                ?: "8.11.1"
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties and FLUTTER_ROOT not set" }
            Pair(flutterSdkPath, agpVersion)
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "com.android.library") {
                useVersion(agpVersion)
            }
        }
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
rootProject.name = "sample_consuming_plugin"
