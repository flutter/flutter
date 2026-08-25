// settings.gradle.kts for the flutter_tools gradle included build

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter hosted artifacts used by some plugins
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

dependencyResolutionManagement {
    // Use settings repositories for this included build
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}
