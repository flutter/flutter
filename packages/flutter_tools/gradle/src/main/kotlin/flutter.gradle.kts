// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.ApplicationAndroidComponentsExtension
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper

apply<FlutterPluginKts>()

class FlutterPluginKts : Plugin<Project> {
    override fun apply(project: Project) {
        // Validate that the provided Gradle, Java, AGP, and KGP versions are all within our
        // supported range.
        if (project.hasProperty("skipDependencyChecks")) {
            println("HI GRAY, SKIPPING!")
        } else {
            println("HI GRAY, NOT SKIPPING!")
            checkDependencyVersions(project)
        }

        // Use withGroovyBuilder and getProperty() to access Groovy metaprogramming.
        project.withGroovyBuilder {
            getProperty("android").withGroovyBuilder {
                getProperty("defaultConfig").withGroovyBuilder {
                    if (project.hasProperty("multidex-enabled") &&
                        project.property("multidex-enabled").toString().toBoolean()) {
                        setProperty("multiDexEnabled", true)
                        getProperty("manifestPlaceholders").withGroovyBuilder {
                            setProperty("applicationName", "io.flutter.app.FlutterMultiDexApplication")
                        }
                    } else {
                        var baseApplicationName: String = "android.app.Application"
                        if (project.hasProperty("base-application-name")) {
                            baseApplicationName = project.property("base-application-name").toString()
                        }
                        // Setting to android.app.Application is the same as omitting the attribute.
                        getProperty("manifestPlaceholders").withGroovyBuilder {
                            setProperty("applicationName", baseApplicationName)
                        }
                    }
                }
            }
        }
    }

    // The following versions define our support policy for Gradle, Java, AGP, and KGP.
    // All "error" versions are currently set to 0 as this policy is new. They will be increased
    // to match the current values of the "warn" versions in the next release.
    // Before updating any "error" version, ensure that you have updated the corresponding
    // "warn" version for a full release to provide advanced warning. See
    // flutter.dev/go/android-dependency-versions for more.
    val warnGradleVersion : Version = Version(7,0,2)
    val errorGradleVersion : Version = Version(0,0,0)

    val warnJavaVersion : JavaVersion = JavaVersion.VERSION_11
    val errorJavaVersion : JavaVersion = JavaVersion.VERSION_1_1

    val warnAGPVersion : AndroidPluginVersion = AndroidPluginVersion(7,0,0)
    val errorAGPVersion : AndroidPluginVersion = AndroidPluginVersion(0,0,0)

    val warnKGPVersion : Version = Version(1,5,0)
    val errorKGPVersion : Version = Version(0,0,0)

    /**
     * Checks if the project's Android build time dependencies are each within the respective
     * version range that we support. When we can't find a version for a given dependency
     * we treat it as within the range for the purpose of this check.
     */
    fun checkDependencyVersions(project : Project) {
        var gradleVersion : Version? = null
        var javaVersion : JavaVersion? = null
        var agpVersion : AndroidPluginVersion? = null
        var kgpVersion : Version? = null

        try {
            gradleVersion = getGradleVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project Gradle version. Skipping " +
                    "version checking.")
        }
        if (gradleVersion != null) checkGradleVersion(gradleVersion!!, project)
        try {
            javaVersion = getJavaVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project Java version. Skipping " +
                    "version checking.")
        }
        if (javaVersion != null) checkJavaVersion(javaVersion!!, project)
        try {
            agpVersion = getAGPVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project AGP version. Skipping " +
                    "version checking.")
        }
        if (agpVersion != null) checkAGPVersion(agpVersion!!, project)
        try {
            kgpVersion = getKGPVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project KGP version. Skipping " +
                    "version checking.")
        }
        if (kgpVersion != null) checkKGPVersion(kgpVersion!!, project)
    }

    // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api.invocation/-gradle/index.html#-837060600%2FFunctions%2F-1793262594
    fun getGradleVersion(project : Project) : Version {
        return Version.fromString(project.gradle.getGradleVersion())
    }

    // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api/-java-version/index.html#-1790786897%2FFunctions%2F-1793262594
    fun getJavaVersion(project : Project) : JavaVersion {
        return JavaVersion.current()
    }

    // https://cs.android.com/android-studio/platform/tools/base/+/mirror-goog-studio-main:build-system/gradle-api/src/main/java/com/android/build/api/variant/AndroidComponentsExtension.kt;l=38?q=AndroidComponents&ss=android-studio%2Fplatform%2Ftools%2Fbase:build-system%2Fgradle-api%2Fsrc%2Fmain%2Fjava%2Fcom%2Fandroid%2Fbuild%2Fapi%2F
    fun getAGPVersion(project : Project) : AndroidPluginVersion {
        return project.extensions
            .getByType(ApplicationAndroidComponentsExtension::class.java)!!.pluginVersion
    }

    fun getKGPVersion(project : Project) : Version {
        return Version.fromString(
            project.getPlugins()
                .findPlugin(KotlinAndroidPluginWrapper::class.java)!!
                .pluginVersion
        )
    }

    fun checkGradleVersion(version : Version, project : Project) {
        println("Gradle version is: " + version.toString())
        if (version < errorGradleVersion) {
            project.logger.error("Error: Your project's Gradle version ($version) is lower " +
                    "than our minimum supported version of $errorGradleVersion. Please upgrade " +
                    "your Gradle version. \nAlternatively, use the flag " +
                    "\"--android-skip-build-dependency-validation\" to bypass this check.")
        }
        else if (version < warnGradleVersion) {
            project.logger.quiet("Warning: Flutter support for your project's Gradle version " +
                    "($version) will soon be dropped. Please upgrade your Gradle version soon. " +
                    "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                    " to bypass this check.")
        }
    }

    fun checkJavaVersion(version : JavaVersion, project : Project) {
        println("Java version is: " + version.toString())
        if (version < errorJavaVersion) {
            project.logger.error("Error: Your project's Java version ($version) is lower " +
                    "than our minimum supported version of $errorJavaVersion. Please upgrade " +
                    "your Java version. \nAlternatively, use the flag " +
                    "\"--android-skip-build-dependency-validation\" to bypass this check.")
        }
        else if (version < warnJavaVersion) {
            project.logger.quiet("Warning: Flutter support for your project's Java version " +
                    "($version) will soon be dropped. Please upgrade your Java version soon. " +
                    "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                    " to bypass this check.")
        }
    }

    fun checkAGPVersion(version : AndroidPluginVersion, project : Project) {
        println("AGP version is: " + version.toString())
        if (version < errorAGPVersion) {
            project.logger.error("Error: Your project's Android Gradle Plugin version ($version) " +
                    "is lower than our minimum supported version of $errorAGPVersion. " +
                    "Please upgrade your AGP version. \nAlternatively, use the flag " +
                    "\"--android-skip-build-dependency-validation\" to bypass this check.")
        }
        else if (version < warnAGPVersion) {
            project.logger.quiet("Warning: Flutter support for your project's Android Gradle Plugin" +
                    " version ($version) will soon be dropped. Please upgrade your AGP version soon. " +
                    "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                    " to bypass this check.")
        }
    }

    fun checkKGPVersion(version : Version, project : Project) {
        println("KGP version is: " + version.toString())
        if (version < errorKGPVersion) {
            project.logger.error("Error: Your project's Kotlin version ($version) is lower " +
                    "than our minimum supported version of $errorKGPVersion. Please upgrade " +
                    "your Kotlin version. \nAlternatively, use the flag " +
                    "\"--android-skip-build-dependency-validation\" to bypass this check.")
        }
        else if (version < warnKGPVersion) {
            project.logger.quiet("Warning: Flutter support for your project's Kotlin version " +
                    "($version) will soon be dropped. Please upgrade your Kotlin version soon. " +
                    "\nAlternatively, use the flag \"--android-skip-build-dependency-validation\"" +
                    " to bypass this check.")
        }
    }
}




// Helper class to parse the versions that are provided as plain strings (Gradle, Kotlin) and
// perform easy comparisons.
class Version(val major : Int, val minor : Int, val patch : Int) : Comparable<Version> {
    companion object {
        fun fromString(version : String) : Version {
            val asList : List<String> = version.split(".")
            return Version(
                major = asList.getOrElse(0, {"0"}).toInt(),
                minor = asList.getOrElse(1, {"0"}).toInt(),
                patch = asList.getOrElse(2, {"0"}).toInt()
            )
        }
    }
    override fun compareTo(otherVersion : Version) : Int {
        if (major != otherVersion.major) {
            return major - otherVersion.major
        }
        if (minor != otherVersion.minor) {
            return minor - otherVersion.minor
        }
        if (patch != otherVersion.patch) {
            return patch - otherVersion.patch
        }
        return 0
    }
    override fun toString() : String {
        return major.toString() + "." + minor.toString() + "." + patch.toString()
    }
}
