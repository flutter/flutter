package com.flutter.gradle

import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.builder.model.BuildType
import groovy.lang.Closure
import org.gradle.api.GradleException
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.logging.Logger
import java.io.File
import java.nio.charset.StandardCharsets
import java.util.Properties

/**
 * A collection of static utility functions used by the Flutter Gradle Plugin.
 */
object FlutterPluginUtils {
    // Gradle properties. These must correspond to the values used in
    // flutter/packages/flutter_tools/lib/src/android/gradle.dart, and therefore it is not
    // recommended to use these const values in tests.
    internal const val PROP_SHOULD_SHRINK_RESOURCES = "shrink"
    internal const val PROP_SPLIT_PER_ABI = "split-per-abi"
    internal const val PROP_LOCAL_ENGINE_REPO = "local-engine-repo"
    internal const val PROP_IS_VERBOSE = "verbose"
    internal const val PROP_IS_FAST_START = "fast-start"
    internal const val PROP_TARGET = "target"
    internal const val PROP_LOCAL_ENGINE_BUILD_MODE = "local-engine-build-mode"
    internal const val PROP_TARGET_PLATFORM = "target-platform"

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

    @JvmStatic
    @JvmName("readPropertiesIfExist")
    internal fun readPropertiesIfExist(propertiesFile: File): Properties {
        val result = Properties()
        if (propertiesFile.exists()) {
            propertiesFile
                .reader(StandardCharsets.UTF_8)
                .use { reader ->
                    // Use Kotlin's reader with UTF-8 and 'use' for auto-closing
                    result.load(reader)
                }
        }
        return result
    }

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

    private fun getAndroidExtension(project: Project): BaseExtension {
        // Common supertype of the android extension types.
        // But maybe this should be https://developer.android.com/reference/tools/gradle-api/8.7/com/android/build/api/dsl/TestedExtension.
        return project.extensions.findByType(BaseExtension::class.java)!!
    }

    /**
     * Expected format of getAndroidExtension(project).compileSdkVersion is a string of the form
     * `android-` followed by either the numeric version, e.g. `android-35`, or a preview version,
     * e.g. `android-UpsideDownCake`.
     */
    @JvmStatic
    @JvmName("getCompileSdkFromProject")
    internal fun getCompileSdkFromProject(project: Project): String = getAndroidExtension(project).compileSdkVersion!!.substring(8)

    /**
     * Returns:
     *  The default platforms if the `target-platform` property is not set.
     *  The requested platforms after verifying they are supported by the Flutter plugin, otherwise.
     * Throws a GradleException if any of the requested platforms are not supported.
     */
    @JvmStatic
    @JvmName("getTargetPlatforms")
    internal fun getTargetPlatforms(project: Project): List<String> {
        if (!project.hasProperty(PROP_TARGET_PLATFORM)) {
            return FlutterPluginConstants.DEFAULT_PLATFORMS
        }
        val platformsString = project.property(PROP_TARGET_PLATFORM) as String
        return platformsString.split(",").map { platform ->
            if (!FlutterPluginConstants.PLATFORM_ARCH_MAP.containsKey(platform)) {
                throw GradleException("Invalid platform: $platform")
            }
            platform
        }
    }

    private fun logPluginCompileSdkWarnings(
        maxPluginCompileSdkVersion: Int,
        projectCompileSdkVersion: Int,
        logger: Logger,
        pluginsWithHigherSdkVersion: List<PluginVersionPair>,
        projectDirectory: File
    ) {
        logger.error(
            "Your project is configured to compile against Android SDK $projectCompileSdkVersion, but the following plugin(s) require to be compiled against a higher Android SDK version:"
        )
        for (pluginToCompileSdkVersion in pluginsWithHigherSdkVersion) {
            logger.error(
                "- ${pluginToCompileSdkVersion.name} compiles against Android SDK ${pluginToCompileSdkVersion.version}"
            )
        }
        val buildGradleFile =
            getBuildGradleFileFromProjectDir(
                projectDirectory,
                logger
            )
        logger.error(
            """
            Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
            Add the following to ${buildGradleFile.path}:

                android {
                    compileSdk = $maxPluginCompileSdkVersion
                    ...
                }
            """.trimIndent()
        )
    }

    private fun logPluginNdkWarnings(
        maxPluginNdkVersion: String,
        projectNdkVersion: String,
        logger: Logger,
        pluginsWithDifferentNdkVersion: List<PluginVersionPair>,
        projectDirectory: File
    ) {
        logger.error(
            "Your project is configured with Android NDK $projectNdkVersion, but the following plugin(s) depend on a different Android NDK version:"
        )
        for (pluginToNdkVersion in pluginsWithDifferentNdkVersion) {
            logger.error("- ${pluginToNdkVersion.name} requires Android NDK ${pluginToNdkVersion.version}")
        }
        val buildGradleFile =
            getBuildGradleFileFromProjectDir(
                projectDirectory,
                logger
            )
        logger.error(
            """
            Fix this issue by using the highest Android NDK version (they are backward compatible).
            Add the following to ${buildGradleFile.path}:

                android {
                    ndkVersion = "$maxPluginNdkVersion"
                    ...
                }
            """.trimIndent()
        )
    }

    /** Prints error message and fix for any plugin compileSdkVersion or ndkVersion that are higher than the project. */
    @JvmStatic
    @JvmName("detectLowCompileSdkVersionOrNdkVersion")
    internal fun detectLowCompileSdkVersionOrNdkVersion(
        project: Project,
        pluginList: List<Map<String?, Any?>>
    ) {
        project.afterEvaluate {
            // getCompileSdkFromProject returns a string if the project uses a preview compileSdkVersion
            // so default to Int.MAX_VALUE in that case.
            val projectCompileSdkVersion: Int =
                getCompileSdkFromProject(project).toIntOrNull() ?: Int.MAX_VALUE

            var maxPluginCompileSdkVersion = projectCompileSdkVersion
            // TODO(gmackall): This should be updated to reflect newer templates.
            // The default for AGP 4.1.0 used in old templates.
            val ndkVersionIfUnspecified = "21.1.6352462"
            val projectNdkVersion =
                getAndroidExtension(project).ndkVersion ?: ndkVersionIfUnspecified
            var maxPluginNdkVersion = projectNdkVersion
            var numProcessedPlugins = pluginList.size
            val pluginsWithHigherSdkVersion = mutableListOf<PluginVersionPair>()
            val pluginsWithDifferentNdkVersion = mutableListOf<PluginVersionPair>()
            pluginList.forEach { pluginObject ->
                val pluginName: String =
                    requireNotNull(
                        pluginObject["name"] as? String
                    ) { "Missing valid \"name\" property for plugin object: $pluginObject" }
                val pluginProject: Project =
                    project.rootProject.findProject(":$pluginName") ?: return@forEach
                pluginProject.afterEvaluate {
                    val pluginCompileSdkVersion: Int =
                        getCompileSdkFromProject(pluginProject).toIntOrNull() ?: Int.MAX_VALUE
                    maxPluginCompileSdkVersion =
                        maxOf(maxPluginCompileSdkVersion, pluginCompileSdkVersion)
                    if (pluginCompileSdkVersion > projectCompileSdkVersion) {
                        pluginsWithHigherSdkVersion.add(
                            PluginVersionPair(
                                pluginName,
                                pluginCompileSdkVersion.toString()
                            )
                        )
                    }
                    val pluginNdkVersion: String =
                        getAndroidExtension(pluginProject).ndkVersion ?: ndkVersionIfUnspecified
                    maxPluginNdkVersion =
                        VersionUtils.mostRecentSemanticVersion(
                            pluginNdkVersion,
                            maxPluginNdkVersion
                        )
                    if (pluginNdkVersion != projectNdkVersion) {
                        pluginsWithDifferentNdkVersion.add(PluginVersionPair(pluginName, pluginNdkVersion))
                    }

                    numProcessedPlugins--
                    if (numProcessedPlugins == 0) {
                        if (maxPluginCompileSdkVersion > projectCompileSdkVersion) {
                            logPluginCompileSdkWarnings(
                                maxPluginCompileSdkVersion = maxPluginCompileSdkVersion,
                                projectCompileSdkVersion = projectCompileSdkVersion,
                                logger = project.logger,
                                pluginsWithHigherSdkVersion = pluginsWithHigherSdkVersion,
                                projectDirectory = project.projectDir
                            )
                        }
                        if (maxPluginNdkVersion != projectNdkVersion) {
                            logPluginNdkWarnings(
                                maxPluginNdkVersion = maxPluginNdkVersion,
                                projectNdkVersion = projectNdkVersion,
                                logger = project.logger,
                                pluginsWithDifferentNdkVersion = pluginsWithDifferentNdkVersion,
                                projectDirectory = project.projectDir
                            )
                        }
                    }
                }
            }
        }
    }

    /**
     * Forces the project to download the NDK by configuring properties that makes AGP think the
     * project actually requires the NDK.
     */
    @JvmStatic
    @JvmName("forceNdkDownload")
    internal fun forceNdkDownload(
        gradleProject: Project,
        flutterSdkRootPath: String
    ) {
        // If the project is already configuring a native build, we don't need to do anything.
        val gradleProjectAndroidExtension = getAndroidExtension(gradleProject)
        val forcingNotRequired: Boolean =
            gradleProjectAndroidExtension.externalNativeBuild.cmake.path != null
        if (forcingNotRequired) {
            return
        }

        // Otherwise, point to an empty CMakeLists.txt, and ignore associated warnings.
        gradleProjectAndroidExtension.externalNativeBuild.cmake.path(
            "$flutterSdkRootPath/packages/flutter_tools/gradle/src/main/groovy/CMakeLists.txt"
        )

        // CMake will print warnings when you try to build an empty project.
        // These arguments silence the warnings - our project is intentionally
        // empty.
        gradleProjectAndroidExtension.defaultConfig.externalNativeBuild.cmake
            .arguments("-Wno-dev", "--no-warn-unused-cli")
    }

    @JvmStatic
    @JvmName("isFlutterAppProject")
    internal fun isFlutterAppProject(project: Project): Boolean = project.extensions.findByType(AbstractAppExtension::class.java) != null

    /**
     * Ensures that the dependencies required by the Flutter project are available.
     * This includes:
     *    1. The embedding
     *    2. libflutter.so
     *
     * Should only be called on the main gradle [Project] for this application
     * of the [FlutterPlugin].
     */
    @JvmStatic
    @JvmName("addFlutterDependencies")
    internal fun addFlutterDependencies(
        project: Project,
        buildType: BuildType,
        pluginList: List<Map<String?, Any?>>,
        engineVersion: String
    ) {
        val flutterBuildMode: String = buildModeFor(buildType)
        if (!supportsBuildMode(project, flutterBuildMode)) {
            project.logger.quiet(
                "Project does not support Flutter build mode: $flutterBuildMode, " +
                    "skipping adding flutter dependencies"
            )
            return
        }
        // The embedding is set as an API dependency in a Flutter plugin.
        // Therefore, don't make the app project depend on the embedding if there are Flutter
        // plugin dependencies. In release mode, dev dependencies are stripped, so we do not
        // consider those in the check.
        // This prevents duplicated classes when using custom build types. That is, a custom build
        // type like profile is used, and the plugin and app projects have API dependencies on the
        // embedding.
        val pluginsThatIncludeFlutterEmbeddingAsTransitiveDependency: List<Map<String?, Any?>> =
            if (flutterBuildMode == "release") {
                getPluginListWithoutDevDependencies(
                    pluginList
                )
            } else {
                pluginList
            }

        if (!isFlutterAppProject(project) || pluginsThatIncludeFlutterEmbeddingAsTransitiveDependency.isEmpty()) {
            addApiDependencies(
                project,
                buildType.name,
                "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion"
            )
        }
        val platforms: List<String> = getTargetPlatforms(project)
        platforms.forEach { platform ->
            val arch: String = formatPlatformString(platform)
            // Add the `libflutter.so` dependency.
            addApiDependencies(
                project,
                buildType.name,
                "io.flutter:${arch}_$flutterBuildMode:$engineVersion"
            )
        }
    }

    /**
     * Gets the list of plugins (as map) that support the Android platform and are dependencies of the
     * Android project excluding dev dependencies.
     *
     * The map value contains either the plugins `name` (String),
     * its `path` (String), or its `dependencies` (List<String>).
     * See [NativePluginLoader#getPlugins] in packages/flutter_tools/gradle/src/main/groovy/native_plugin_loader.groovy
     */
    private fun getPluginListWithoutDevDependencies(pluginList: List<Map<String?, Any?>>): List<Map<String?, Any?>> =
        pluginList.filter { pluginObject -> pluginObject["dev_dependency"] == false }

    /**
     * Add the dependencies on other plugin projects to the plugin project.
     * A plugin A can depend on plugin B. As a result, this dependency must be surfaced by
     * making the Gradle plugin project A depend on the Gradle plugin project B.
     */
    @JvmStatic
    @JvmName("configurePluginDependencies")
    internal fun configurePluginDependencies(
        project: Project,
        pluginObject: Map<String?, Any?>
    ) {
        val pluginName: String =
            requireNotNull(pluginObject["name"] as? String) {
                "Missing valid \"name\" property for plugin object: $pluginObject"
            }
        val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return

        getAndroidExtension(project).buildTypes.forEach { buildType ->
            val flutterBuildMode: String = buildModeFor(buildType)
            if (flutterBuildMode == "release" && (pluginObject["dev_dependency"] as? Boolean == true)) {
                // This plugin is a dev dependency will not be included in the
                // release build, so no need to add its dependencies.
                return@forEach
            }
            val dependencies = requireNotNull(pluginObject["dependencies"] as? List<*>)
            dependencies.forEach innerForEach@{ pluginDependencyName ->
                check(pluginDependencyName is String)
                if (pluginDependencyName.isEmpty()) {
                    return@innerForEach
                }

                val dependencyProject =
                    project.rootProject.findProject(":$pluginDependencyName") ?: return@innerForEach
                pluginProject.afterEvaluate {
                    pluginProject.dependencies.add("implementation", dependencyProject)
                }
            }
        }
    }

    /**
     * Performs configuration related to the plugin's Gradle [Project], including
     * 1. Adding the plugin itself as a dependency to the main project.
     * 2. Adding the main project's build types to the plugin's build types.
     * 3. Adding a dependency on the Flutter embedding to the plugin.
     *
     * Should only be called on plugins that support the Android platform.
     */
    @JvmStatic
    @JvmName("configurePluginProject")
    internal fun configurePluginProject(
        project: Project,
        pluginObject: Map<String?, Any?>,
        engineVersion: String
    ) {
        // TODO(gmackall): should guard this with a pluginObject.contains().
        val pluginName =
            requireNotNull(pluginObject["name"] as? String) { "Plugin name must be a string for plugin object: $pluginObject" }
        val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return

        // Apply the "flutter" Gradle extension to plugins so that they can use it's vended
        // compile/target/min sdk values.
        pluginProject.extensions.create("flutter", FlutterExtension::class.java)

        // Add plugin dependency to the app project. We only want to add dependency
        // for dev dependencies in non-release builds.
        project.afterEvaluate {
            getAndroidExtension(project).buildTypes.forEach { buildType ->
                if (!(pluginObject["dev_dependency"] as Boolean) || buildType.name != "release") {
                    project.dependencies.add("${buildType.name}Api", pluginProject)
                }
            }
        }

        // Wait until the Android plugin loaded.
        pluginProject.afterEvaluate {
            // Checks if there is a mismatch between the plugin compileSdkVersion and the project compileSdkVersion.
            val projectCompileSdkVersion: String = getCompileSdkFromProject(project)
            val pluginCompileSdkVersion: String = getCompileSdkFromProject(pluginProject)
            // TODO(gmackall): This is doing a string comparison, which is odd and also can be wrong
            //                 when comparing preview versions (against non preview, and also in the
            //                 case of alphabet reset which happened with "Baklava".
            if (pluginCompileSdkVersion > projectCompileSdkVersion) {
                project.logger.quiet("Warning: The plugin $pluginName requires Android SDK version $pluginCompileSdkVersion or higher.")
                project.logger.quiet(
                    "For more information about build configuration, see ${FlutterPluginConstants.WEBSITE_DEPLOYMENT_ANDROID_BUILD_CONFIG}."
                )
            }

            getAndroidExtension(project).buildTypes.forEach { buildType ->
                addEmbeddingDependencyToPlugin(project, pluginProject, buildType, engineVersion)
            }
        }
    }

    private fun addEmbeddingDependencyToPlugin(
        project: Project,
        pluginProject: Project,
        buildType: BuildType,
        engineVersion: String
    ) {
        val flutterBuildMode: String = buildModeFor(buildType)
        // TODO(gmackall): this should be safe to remove, as the minimum required AGP is well above
        //                 3.5. We should try to remove it.
        // In AGP 3.5, the embedding must be added as an API implementation,
        // so java8 features are desugared against the runtime classpath.
        // For more, see https://github.com/flutter/flutter/issues/40126
        if (!supportsBuildMode(pluginProject, flutterBuildMode)) {
            return
        }
        if (!pluginProject.hasProperty("android")) {
            return
        }

        // Copy build types from the app to the plugin.
        // This allows to build apps with plugins and custom build types or flavors.
        getAndroidExtension(pluginProject).buildTypes.addAll(getAndroidExtension(project).buildTypes)

        // The embedding is API dependency of the plugin, so the AGP is able to desugar
        // default method implementations when the interface is implemented by a plugin.
        //
        // See https://issuetracker.google.com/139821726, and
        // https://github.com/flutter/flutter/issues/72185 for more details.
        addApiDependencies(pluginProject, buildType.name, "io.flutter:flutter_embedding_$flutterBuildMode:$engineVersion")
    }

    // ------------------ Task adders (a subset of the above category)

    // Add a task that can be called on flutter projects that prints the Java version used in Gradle.
    //
    // Format of the output of this task can be used in debugging what version of Java Gradle is using.
    // Not recommended for use in time sensitive commands like `flutter run` or `flutter build` as
    // Gradle is slower than we want. Particularly in light of https://github.com/flutter/flutter/issues/119196.
    @JvmStatic
    @JvmName("addTaskForJavaVersion")
    internal fun addTaskForJavaVersion(project: Project) {
        project.tasks.register("javaVersion") {
            description = "Print the current java version used by gradle. see: " +
                "https://docs.gradle.org/current/javadoc/org/gradle/api/JavaVersion.html"
            doLast {
                println(JavaVersion.current())
            }
        }
    }

    // Add a task that can be called on Flutter projects that prints the available build variants
    // in Gradle.
    //
    // This task prints variants in this format:
    //
    // BuildVariant: debug
    // BuildVariant: release
    // BuildVariant: profile
    //
    // Format of the output of this task is used by `AndroidProject.getBuildVariants`.
    @JvmStatic
    @JvmName("addTaskForPrintBuildVariants")
    internal fun addTaskForPrintBuildVariants(project: Project) {
        // Groovy was dynamically getting a different subtype here than our Kotlin getAndroidExtension method.
        // TODO(gmackall): We should take another pass at the different types we are using in our conversion of
        //                 the groovy `flutter.android` lines.
        val androidExtension = project.extensions.getByType(AbstractAppExtension::class.java)
        project.tasks.register("printBuildVariants") {
            description = "Prints out all build variants for this Android project"
            doLast {
                androidExtension.applicationVariants.forEach { variant ->
                    println("BuildVariant: ${variant.name}")
                }
            }
        }
    }
}

private data class PluginVersionPair(
    val name: String,
    val version: String
)
