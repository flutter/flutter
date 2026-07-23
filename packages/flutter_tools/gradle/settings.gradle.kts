dependencyResolutionManagement {
    // Use PREFER_SETTINGS instead of FAIL_ON_PROJECT_REPOS to avoid failing builds
    // when global initialization scripts (e.g. init.gradle) inject repositories.
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}
