pluginManagement {
    repositories {
        val flutterAndroidGradlePluginRepository: String? =
            System.getenv("FLUTTER_ANDROID_GRADLE_PLUGIN_REPOSITORY")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
        if (flutterAndroidGradlePluginRepository != null) {
            maven {
                url = uri(flutterAndroidGradlePluginRepository)
            }
        }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        val flutterAndroidGradlePluginRepository: String? =
            System.getenv("FLUTTER_ANDROID_GRADLE_PLUGIN_REPOSITORY")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
        if (flutterAndroidGradlePluginRepository != null) {
            maven {
                url = uri(flutterAndroidGradlePluginRepository)
            }
        }
        google()
        mavenCentral()
    }
}
