pluginManagement {
    repositories {
        val flutterAndroidGradlePluginRepository: String? =
            System.getenv("FLUTTER_GRADLE_PLUGIN_REPOSITORY_URL")
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
            System.getenv("FLUTTER_GRADLE_PLUGIN_REPOSITORY_URL")
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
