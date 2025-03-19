package com.flutter.gradle

import com.android.builder.model.BuildType
import groovy.lang.Closure
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.logging.Logger
import java.io.File

/**
 * A collection of static utility functions used by the Flutter Gradle Plugin.
 */
object FlutterPluginUtils {
    // Gradle properties.
    internal const val PROP_SHOULD_SHRINK_RESOURCES = "shrink"
    internal const val PROP_SPLIT_PER_ABI = "split-per-abi"
    internal const val PROP_LOCAL_ENGINE_REPO = "local-engine-repo"
    internal const val PROP_IS_VERBOSE = "verbose"
    internal const val PROP_IS_FAST_START = "fast-start"
    internal const val PROP_TARGET = "target"
    internal const val PROP_LOCAL_ENGINE_BUILD_MODE = "local-engine-build-mode"

    // ----------------- Methods for string manipulation and comparison. -----------------

    @JvmStatic
    fun toCamelCase(parts: List<String>): String {
        if (parts.isEmpty()) {
            return ""
        }
        return parts[0] +
            parts.drop(1).joinToString("") { capitalize(it) }
    }

    // Kotlin's capitalize function is deprecated, but the suggested replacement uses syntax that
    // our minimum version doesn't support yet. Centralize the use to one place, so that when our
    // minimum version does support the replacement we can replace by changing a single line.
    @JvmStatic
    @Suppress("DEPRECATION")
    internal fun capitalize(string: String): String = string.capitalize()

    // compareTo implementation of version strings in the format of ints and periods
    // Will not crash on RC candidate strings but considers all RC candidates the same version.
    // Returns -1 if firstString < secondString, 0 if firstString == secondString, 1 if firstString > secondString
    @JvmStatic
    @JvmName("compareVersionStrings")
    internal fun compareVersionStrings(
        firstString: String,
        secondString: String
    ): Int {
        val firstVersion = firstString.split(".")
        val secondVersion = secondString.split(".")

        val commonIndices = minOf(firstVersion.size, secondVersion.size)

        for (i in 0 until commonIndices) {
            var firstAtIndex = firstVersion[i]
            var secondAtIndex = secondVersion[i]
            var firstInt = 0
            var secondInt = 0

            // Strip any chars after "-". For example "8.6-rc-2"
            firstAtIndex = firstAtIndex.substringBefore("-")
            try {
                firstInt = firstAtIndex.toInt()
            } catch (nfe: NumberFormatException) {
                println(nfe)
            }

            secondAtIndex = secondAtIndex.substringBefore("-")
            try {
                secondInt = secondAtIndex.toInt()
            } catch (nfe: NumberFormatException) {
                println(nfe)
            }

            val comparisonResult = firstInt.compareTo(secondInt)
            if (comparisonResult != 0) {
                return comparisonResult
            }
        }

        // If we got this far then all the common indices are identical, so whichever version is longer must be more recent
        return firstVersion.size.compareTo(secondVersion.size)
    }

    @JvmStatic
    @JvmName("formatPlatformString")
    fun formatPlatformString(platform: String): String = FlutterPluginConstants.PLATFORM_ARCH_MAP[platform]!!.replace("-", "_")

    // ----------------- Methods that interact primarily with the Gradle project. -----------------

    @JvmStatic
    @JvmName("shouldShrinkResources")
    fun shouldShrinkResources(project: Project): Boolean {
        if (project.hasProperty(PROP_SHOULD_SHRINK_RESOURCES)) {
            val propertyValue = project.property(PROP_SHOULD_SHRINK_RESOURCES)
            return propertyValue.toString().toBoolean()
        }
        return true
    }

    // TODO(54566): Can remove this function and its call sites once resolved.

    /**
     * Returns `true` if the given project is a plugin project having an `android` directory
     * containing a `build.gradle` or `build.gradle.kts` file.
     */
    @JvmStatic
    @JvmName("pluginSupportsAndroidPlatform")
    internal fun pluginSupportsAndroidPlatform(project: Project): Boolean {
        val buildGradle = File(File(project.projectDir.parentFile, "android"), "build.gradle")
        val buildGradleKts =
            File(File(project.projectDir.parentFile, "android"), "build.gradle.kts")
        return buildGradle.exists() || buildGradleKts.exists()
    }

    /**
     * Returns the Gradle settings script for the build. When both Groovy and
     * Kotlin variants exist, then Groovy (settings.gradle) is preferred over
     * Kotlin (settings.gradle.kts). This is the same behavior as Gradle 8.5.
     */
    @JvmStatic
    @JvmName("getSettingsGradleFileFromProjectDir")
    internal fun getSettingsGradleFileFromProjectDir(
        projectDirectory: File,
        logger: Logger
    ): File {
        val settingsGradle = File(projectDirectory.parentFile, "settings.gradle")
        val settingsGradleKts = File(projectDirectory.parentFile, "settings.gradle.kts")
        if (settingsGradle.exists() && settingsGradleKts.exists()) {
            logger.error(
                """
                Both settings.gradle and settings.gradle.kts exist, so
                settings.gradle.kts is ignored. This is likely a mistake.
                """.trimIndent()
            )
        }

        return if (settingsGradle.exists()) settingsGradle else settingsGradleKts
    }

    /**
     * Returns the Gradle build script for the build. When both Groovy and
     * Kotlin variants exist, then Groovy (build.gradle) is preferred over
     * Kotlin (build.gradle.kts). This is the same behavior as Gradle 8.5.
     */
    @JvmStatic
    @JvmName("getBuildGradleFileFromProjectDir")
    internal fun getBuildGradleFileFromProjectDir(
        projectDirectory: File,
        logger: Logger
    ): File {
        val buildGradle = File(File(projectDirectory.parentFile, "app"), "build.gradle")
        val buildGradleKts = File(File(projectDirectory.parentFile, "app"), "build.gradle.kts")
        if (buildGradle.exists() && buildGradleKts.exists()) {
            logger.error(
                """
                Both build.gradle and build.gradle.kts exist, so
                build.gradle.kts is ignored. This is likely a mistake.
                """.trimIndent()
            )
        }

        return if (buildGradle.exists()) buildGradle else buildGradleKts
    }

    @JvmStatic
    @JvmName("shouldProjectSplitPerAbi")
    internal fun shouldProjectSplitPerAbi(project: Project): Boolean =
        project
            .findProperty(
                PROP_SPLIT_PER_ABI
            )?.toString()
            ?.toBoolean() ?: false

    @JvmStatic
    @JvmName("shouldProjectUseLocalEngine")
    internal fun shouldProjectUseLocalEngine(project: Project): Boolean = project.hasProperty(PROP_LOCAL_ENGINE_REPO)

    @JvmStatic
    @JvmName("isProjectVerbose")
    internal fun isProjectVerbose(project: Project): Boolean = project.findProperty(PROP_IS_VERBOSE)?.toString()?.toBoolean() ?: false

    /** Whether to build the debug app in "fast-start" mode. */
    @JvmStatic
    @JvmName("isProjectFastStart")
    internal fun isProjectFastStart(project: Project): Boolean =
        project
            .findProperty(
                PROP_IS_FAST_START
            )?.toString()
            ?.toBoolean() ?: false

//   TODO(gmackall): @JvmStatic internal fun getCompileSdkFromProject(project: Project): String {}

    /**
     * TODO: Remove this AGP hack. https://github.com/flutter/flutter/issues/109560
     *
     * In AGP 4.0, the Android linter task depends on the JAR tasks that generate `libapp.so`.
     * When building APKs, this causes an issue where building release requires the debug JAR,
     * but Gradle won't build debug.
     *
     * To workaround this issue, only configure the JAR task that is required given the task
     * from the command line.
     *
     * The AGP team said that this issue is fixed in Gradle 7.0, which isn't released at the
     * time of adding this code. Once released, this can be removed. However, after updating to
     * AGP/Gradle 7.2.0/7.5, removing this hack still causes build failures. Further
     * investigation necessary to remove this.
     *
     * Tested cases:
     * * `./gradlew assembleRelease`
     * * `./gradlew app:assembleRelease.`
     * * `./gradlew assemble{flavorName}Release`
     * * `./gradlew app:assemble{flavorName}Release`
     * * `./gradlew assemble.`
     * * `./gradlew app:assemble.`
     * * `./gradlew bundle.`
     * * `./gradlew bundleRelease.`
     * * `./gradlew app:bundleRelease.`
     *
     * Related issues:
     * https://issuetracker.google.com/issues/158060799
     * https://issuetracker.google.com/issues/158753935
     */
    @JvmStatic
    @JvmName("shouldConfigureFlutterTask")
    internal fun shouldConfigureFlutterTask(
        project: Project,
        assembleTask: Task
    ): Boolean {
        val cliTasksNames = project.gradle.startParameter.taskNames
        if (cliTasksNames.size != 1 || !cliTasksNames.first().contains("assemble")) {
            return true
        }
        val taskName = cliTasksNames.first().split(":").last()
        if (taskName == "assemble") {
            return true
        }
        if (taskName == assembleTask.name) {
            return true
        }
        if (taskName.endsWith("Release") && assembleTask.name.endsWith("Release")) {
            return true
        }
        if (taskName.endsWith("Debug") && assembleTask.name.endsWith("Debug")) {
            return true
        }
        if (taskName.endsWith("Profile") && assembleTask.name.endsWith("Profile")) {
            return true
        }
        return false
    }

    private fun getFlutterExtensionOrNull(project: Project): FlutterExtension? = project.extensions.findByType(FlutterExtension::class.java)

    /**
     * Gets the directory that contains the Flutter source code.
     * This is the directory containing the `android/` directory.
     */
    @JvmStatic
    @JvmName("getFlutterSourceDirectory")
    internal fun getFlutterSourceDirectory(project: Project): File {
        val flutterExtension = getFlutterExtensionOrNull(project)
        // TODO(gmackall): clean up this NPE that is still around from the Groovy conversion.
        if (flutterExtension!!.source == null) {
            throw GradleException("Flutter source directory not set.")
        }
        return project.file(flutterExtension.source!!)
    }

    /**
     * Gets the target file. This is typically `lib/main.dart`.
     *
     * Returns
     *  1. the value of the `target` property, if it exists
     *  2. the target value set in the FlutterExtension, if it exists
     *  3. `lib/main.dart` otherwise
     */
    @JvmStatic
    @JvmName("getFlutterTarget")
    internal fun getFlutterTarget(project: Project): String {
        if (project.hasProperty(PROP_TARGET)) {
            return project.property(PROP_TARGET).toString()
        }
        val target: String = getFlutterExtensionOrNull(project)!!.target ?: "lib/main.dart"
        return target
    }

    @JvmStatic
    @JvmName("isBuiltAsApp")
    internal fun isBuiltAsApp(project: Project): Boolean {
        // Projects are built as applications when the they use the `com.android.application`
        // plugin.
        return project.plugins.hasPlugin("com.android.application")
    }

    // Optional parameters don't work when Groovy makes calls into Kotlin, so provide an additional
    // signature for the 3 argument version.
    @JvmStatic
    @JvmName("addApiDependencies")
    internal fun addApiDependencies(
        project: Project,
        variantName: String,
        dependency: Any
    ) {
        addApiDependencies(project, variantName, dependency, null)
    }

    @JvmStatic
    @JvmName("addApiDependencies")
    internal fun addApiDependencies(
        project: Project,
        variantName: String,
        dependency: Any,
        config: Closure<Any>?
    ) {
        var configuration: String
        try {
            project.configurations.named("api")
            configuration = "${variantName}Api"
        } catch (ignored: UnknownTaskException) {
            // TODO(gmackall): The docs say the above should actually be an UnknownDomainObjectException.
            configuration = "${variantName}Compile"
        }

        if (config == null) {
            project.dependencies.add(
                configuration,
                dependency
            )
        } else {
            project.dependencies.add(configuration, dependency, config)
        }
    }

    /**
     * Returns a Flutter build mode suitable for the specified Android buildType.
     *
     * @return "debug", "profile", or "release" (fall-back).
     */
    @JvmStatic
    @JvmName("buildModeFor")
    internal fun buildModeFor(buildType: BuildType): String {
        if (buildType.name == "profile") {
            return "profile"
        } else if (buildType.isDebuggable) {
            return "debug"
        }
        return "release"
    }

    /**
     * Returns true if the build mode is supported by the current call to Gradle.
     * This only relevant when using a local engine. Because the engine
     * is built for a specific mode, the call to Gradle must match that mode.
     */
    @JvmStatic
    @JvmName("supportsBuildMode")
    internal fun supportsBuildMode(
        project: Project,
        flutterBuildMode: String
    ): Boolean {
        if (!shouldProjectUseLocalEngine(project)) {
            return true
        }
        check(project.hasProperty(PROP_LOCAL_ENGINE_BUILD_MODE)) { "Project must have property '$PROP_LOCAL_ENGINE_BUILD_MODE'" }
        // Don't configure dependencies for a build mode that the local engine
        // doesn't support.
        return project.property(PROP_LOCAL_ENGINE_BUILD_MODE) == flutterBuildMode
    }
}
