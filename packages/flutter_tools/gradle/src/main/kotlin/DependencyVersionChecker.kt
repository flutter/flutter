// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import androidx.annotation.VisibleForTesting
import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.logging.Logger
import org.gradle.kotlin.dsl.extra

/**
 * Warns or errors on version ranges of dependencies required to build a Flutter Android app.
 *
 * For code that evaluates if dependencies are compatible with each other see
 * packages/flutter_tools/lib/src/android/gradle_utils.dart.
 */
object DependencyVersionChecker {
    // Logging constants.
    @VisibleForTesting internal const val GRADLE_NAME: String = "Gradle"

    @VisibleForTesting internal const val JAVA_NAME: String = "Java"

    @VisibleForTesting internal const val AGP_NAME: String = "Android Gradle Plugin"

    @VisibleForTesting internal const val KGP_NAME: String = "Kotlin"

    @VisibleForTesting internal const val MIN_SDK_NAME: String = "minimum Android SDK"

    // String constant that defines the name of the Gradle extra property that we set when
    // detecting that the project is using versions outside of Flutter's support range.
    // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api/-project/index.html#-2107180640%2FProperties%2F-1867656071.
    @VisibleForTesting internal const val OUT_OF_SUPPORT_RANGE_PROPERTY = "usesUnsupportedDependencyVersions"

    // The task prefix for assemble builds.
    @VisibleForTesting
    internal const val ASSEMBLE_PREFIX = "assemble"

    // The task postfix to use when checking the minimum SDK version for each flavor.
    internal const val MIN_SDK_CHECK_TASK_POSTFIX = "MinSdkCheck"

    // The following messages represent best effort guesses at where a Flutter developer should
    // look to upgrade a dependency that is below the corresponding threshold. Developers can
    // change some of these locations, so they are not guaranteed to be accurate.
    @VisibleForTesting internal fun getPotentialGradleFix(projectDirectory: String): String =
        "Your project's gradle version is typically " +
            "defined in the gradle wrapper file. By default, this can be found at " +
            "$projectDirectory/gradle/wrapper/gradle-wrapper.properties. \n" +
            "For more information, see https://docs.gradle.org/current/userguide/gradle_wrapper.html.\n"

    // The potential java fix does not make use of the project directory,
    // so it left as a constant.
    @VisibleForTesting internal const val POTENTIAL_JAVA_FIX: String =
        "The Java version used by Flutter can be " +
            "set with `flutter config --jdk-dir=<path>`. \nFor more information about how Flutter " +
            "chooses which version of Java to use, see the --jdk-dir section of the " +
            "output of `flutter config -h`.\n"

    @VisibleForTesting internal fun getPotentialAGPFix(projectDirectory: String): String =
        "Your project's AGP version is typically " +
            "defined in the plugins block of the `settings.gradle` file " +
            "($projectDirectory/settings.gradle), by a plugin with the id of " +
            "com.android.application. \nIf you don't see a plugins block, your project " +
            "was likely created with an older template version. In this case it is most " +
            "likely defined in the top-level build.gradle file " +
            "($projectDirectory/build.gradle) by the following line in the dependencies" +
            " block of the buildscript: \"classpath 'com.android.tools.build:gradle:<version>'\".\n"

    @VisibleForTesting internal fun getPotentialKGPFix(projectDirectory: String): String =
        "Your project's KGP version is typically " +
            "defined in the plugins block of the `settings.gradle` file " +
            "($projectDirectory/settings.gradle), by a plugin with the id of " +
            "org.jetbrains.kotlin.android. \nIf you don't see a plugins block, your project " +
            "was likely created with an older template version, in which case it is most " +
            "likely defined in the top-level build.gradle file " +
            "($projectDirectory/build.gradle) by the ext.kotlin_version property.\n"

    @VisibleForTesting internal fun getPotentialSDKFix(projectDirectory: String): String =
        "Your project's minimum Android SDK version is typically " +
            "defined in the android block of the app-level `build.gradle(.kts)` file " +
            "($projectDirectory/app/build.gradle(.kts))."

    // The following versions define our support policy for Gradle, Java, AGP, and KGP.
    // Before updating any "error" version, ensure that you have updated the corresponding
    // "warn" version for a full release to provide advanced warning. See
    // flutter.dev/go/android-dependency-versions for more.
    // Advice for maintainers for other areas of code that are impacted are documented
    // in packages/flutter_tools/lib/src/android/README.md.
    @VisibleForTesting internal val warnGradleVersion: Version = Version(8, 7, 0)

    @VisibleForTesting internal val errorGradleVersion: Version = Version(8, 3, 0)

    // Java error and warn should align with packages/flutter_tools/lib/src/android/gradle_utils.dart.
    @VisibleForTesting internal val warnJavaVersion: JavaVersion = JavaVersion.VERSION_17

    @VisibleForTesting internal val errorJavaVersion: JavaVersion = JavaVersion.VERSION_17

    @VisibleForTesting internal val warnAGPVersion: AndroidPluginVersion = AndroidPluginVersion(8, 6, 0)

    @VisibleForTesting internal val errorAGPVersion: AndroidPluginVersion = AndroidPluginVersion(8, 1, 1)

    @VisibleForTesting internal val warnKGPVersion: Version = Version(2, 1, 0)

    @VisibleForTesting internal val errorKGPVersion: Version = Version(1, 8, 10)

    // If this value is changed, then make sure to change the documentation on https://docs.flutter.dev/reference/supported-platforms
    // Non inclusive.
    @VisibleForTesting
    internal val warnMinSdkVersion: Int = 24

    @VisibleForTesting
    internal val errorMinSdkVersion: Int = 23

    /**
     * Checks if the project's Android build time dependencies are each within the respective
     * version range that we support. When we can't find a version for a given dependency
     * we treat it as within the range for the purpose of this check.
     */
    @JvmStatic fun checkDependencyVersions(project: Project) {
        project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false)

        checkGradleVersion(VersionFetcher.getGradleVersion(project), project)
        checkJavaVersion(VersionFetcher.getJavaVersion(), project)

        configureMinSdkCheck(project)

        val agpVersion: AndroidPluginVersion? = VersionFetcher.getAGPVersion(project)
        if (agpVersion != null) {
            checkAGPVersion(agpVersion, project)
        } else {
            project.logger.error(
                "Warning: unable to detect project AGP version. Skipping " +
                    "version checking. \nThis may be because you have applied AGP after the Flutter Gradle Plugin."
            )
        }

        val kgpVersion: Version? = VersionFetcher.getKGPVersion(project)
        if (kgpVersion != null) {
            checkKGPVersion(kgpVersion, project)
        }
        // KGP is not required, so don't log any warning if we can't find the version.
    }

    private fun configureMinSdkCheck(project: Project) {
        val androidComponents =
            project.extensions.findByType(AndroidComponentsExtension::class.java)

        androidComponents?.onVariants(
            androidComponents.selector().all()
        ) {
            val taskName = generateMinSdkCheckTaskName(it)
            val minSdkCheckTask =
                project.tasks.register(taskName) {
                    doLast {
                        val minSdkVersion = getMinSdkVersion(it)
                        try {
                            checkMinSdkVersion(minSdkVersion, project.rootDir.path, project.logger)
                        } catch (e: DependencyValidationException) {
                            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
                            throw e
                        }
                    }
                }

            project.afterEvaluate {
                // Make assemble task depend on minSdkCheckTask for this variant.
                project.tasks
                    .named(generateAssembleTaskName(it))
                    .configure {
                        dependsOn(minSdkCheckTask)
                    }
            }
        }
    }

    private fun generateAssembleTaskName(it: Variant) = "$ASSEMBLE_PREFIX${FlutterPluginUtils.capitalize(it.name)}"

    private fun generateMinSdkCheckTaskName(it: Variant) = "${FlutterPluginUtils.capitalize(it.name)}$MIN_SDK_CHECK_TASK_POSTFIX"

    private fun getMinSdkVersion(it: Variant): MinSdkVersion = MinSdkVersion(it.name, it.minSdk.apiLevel)

    @VisibleForTesting internal fun getErrorMessage(
        dependencyName: String,
        versionString: String,
        errorVersion: String,
        potentialFix: String
    ): String =
        "Error: Your project's $dependencyName version ($versionString) is lower " +
            "than Flutter's minimum supported version of $errorVersion. Please upgrade " +
            "your $dependencyName version. \nAlternatively, use the flag " +
            "\"--android-skip-build-dependency-validation\" to bypass this check.\n\n" +
            "Potential fix: $potentialFix"

    @VisibleForTesting internal fun getWarnMessage(
        dependencyName: String,
        versionString: String,
        warnVersion: String,
        potentialFix: String
    ): String =
        "Warning: Flutter support for your project's $dependencyName version " +
            "($versionString) will soon be dropped. Please upgrade your $dependencyName " +
            "version to a version of at least $warnVersion soon." +
            "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
            " to bypass this check.\n\nPotential fix: $potentialFix"

    @VisibleForTesting
    internal fun getFlavorSpecificMessage(
        flavorName: String?,
        dependencyName: String
    ): String = dependencyName + (if (flavorName != null) " (flavor='$flavorName')" else "")

    @VisibleForTesting internal fun checkGradleVersion(
        version: Version,
        project: Project
    ) {
        if (version < errorGradleVersion) {
            val errorMessage: String =
                getErrorMessage(
                    GRADLE_NAME,
                    version.toString(),
                    errorGradleVersion.toString(),
                    getPotentialGradleFix(project.rootDir.path)
                )
            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
            throw DependencyValidationException(errorMessage)
        } else if (version < warnGradleVersion) {
            val warnMessage: String =
                getWarnMessage(
                    GRADLE_NAME,
                    version.toString(),
                    warnGradleVersion.toString(),
                    getPotentialGradleFix(project.rootDir.path)
                )
            project.logger.error(warnMessage)
        }
    }

    @VisibleForTesting internal fun checkJavaVersion(
        version: JavaVersion,
        project: Project
    ) {
        if (version < errorJavaVersion) {
            val errorMessage: String =
                getErrorMessage(
                    JAVA_NAME,
                    version.toString(),
                    errorJavaVersion.toString(),
                    POTENTIAL_JAVA_FIX
                )
            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
            throw DependencyValidationException(errorMessage)
        } else if (version < warnJavaVersion) {
            val warnMessage: String =
                getWarnMessage(
                    JAVA_NAME,
                    version.toString(),
                    warnJavaVersion.toString(),
                    POTENTIAL_JAVA_FIX
                )
            project.logger.error(warnMessage)
        }
    }

    @VisibleForTesting internal fun checkAGPVersion(
        androidPluginVersion: AndroidPluginVersion,
        project: Project
    ) {
        if (androidPluginVersion < errorAGPVersion) {
            val errorMessage: String =
                getErrorMessage(
                    AGP_NAME,
                    androidPluginVersion.toString(),
                    errorAGPVersion.toString(),
                    getPotentialAGPFix(project.rootDir.path)
                )
            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
            throw DependencyValidationException(errorMessage)
        } else if (androidPluginVersion < warnAGPVersion) {
            val warnMessage: String =
                getWarnMessage(
                    AGP_NAME,
                    androidPluginVersion.toString(),
                    warnAGPVersion.toString(),
                    getPotentialAGPFix(project.rootDir.path)
                )
            project.logger.error(warnMessage)
        }
    }

    @VisibleForTesting internal fun checkKGPVersion(
        version: Version,
        project: Project
    ) {
        if (version < errorKGPVersion) {
            val errorMessage: String =
                getErrorMessage(
                    KGP_NAME,
                    version.toString(),
                    errorKGPVersion.toString(),
                    getPotentialKGPFix(project.rootDir.path)
                )
            project.extra.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true)
            throw DependencyValidationException(errorMessage)
        } else if (version < warnKGPVersion) {
            val warnMessage: String =
                getWarnMessage(
                    KGP_NAME,
                    version.toString(),
                    warnKGPVersion.toString(),
                    getPotentialKGPFix(project.rootDir.path)
                )
            project.logger.error(warnMessage)
        }
    }

    @VisibleForTesting internal fun checkMinSdkVersion(
        minSdkVersion: MinSdkVersion,
        projectDirectory: String,
        logger: Logger
    ) {
        // For Android SDK, only the major version is relevant, no need to do a full version check.
        if (minSdkVersion.version < errorMinSdkVersion) {
            val errorMessage: String =
                getErrorMessage(
                    getFlavorSpecificMessage(minSdkVersion.flavor, MIN_SDK_NAME),
                    minSdkVersion.version.toString(),
                    errorMinSdkVersion.toString(),
                    getPotentialSDKFix(projectDirectory)
                )
            throw DependencyValidationException(errorMessage)
        } else if (minSdkVersion.version < warnMinSdkVersion) {
            val warnMessage: String =
                getWarnMessage(
                    getFlavorSpecificMessage(minSdkVersion.flavor, MIN_SDK_NAME),
                    minSdkVersion.version.toString(),
                    warnMinSdkVersion.toString(),
                    getPotentialSDKFix(projectDirectory)
                )
            logger.error(warnMessage)
        }
    }
}

// Custom error for when the dependency_version_checker.kts script finds a dependency out of
// the defined support range.
@VisibleForTesting internal class DependencyValidationException(
    message: String? = null,
    cause: Throwable? = null
) : Exception(message, cause)

/**
 * Represents the minimum Android SDK version for a specific product flavor.
 *
 * @param flavor The product flavor name, or null for the default configuration.
 * @param version The minimum Android SDK version (API level).
 */
@VisibleForTesting internal class MinSdkVersion(
    val flavor: String,
    val version: Int
)
