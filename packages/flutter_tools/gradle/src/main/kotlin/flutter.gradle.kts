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
        println("GRAAAAAAAAAAAAAAAY")
        project.logger.error("blaaaaaah")
        DependencyVersionChecker.checkDependencyVersions(project)

        println(project.gradle.getGradleVersion())

        println(JavaVersion.current())

        val androidComponents = project.extensions.getByType(ApplicationAndroidComponentsExtension::class.java)
        println(androidComponents.pluginVersion)
        println(project.getPlugins().findPlugin(KotlinAndroidPluginWrapper::class.java)!!.pluginVersion)
        println(JavaVersion.VERSION_1_8)
        println(JavaVersion.VERSION_11 > JavaVersion.VERSION_1_8)
        //println(project.properties)

        //println(findProperty("android")!!.findProperty("defaultConfig"))
        //println(project.extensions.extraProperties.properties)


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
}

class DependencyVersionChecker {

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
        if (gradleVersion != null) checkGradleVersion(gradleVersion)
        try {
            javaVersion = getJavaVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project Java version. Skipping " +
                    "version checking.")
        }
        if (javaVersion != null) checkJavaVersion(javaVersion)
        try {
            agpVersion = getAGPVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project AGP version. Skipping " +
                    "version checking.")
        }
        if (agpVersion != null) checkAGPVersion(agpVersion)
        try {
            kgpVersion = getKGPVersion(project)
        } catch (ignored : Exception){
            project.logger.quiet("Warning: unable to detect project KGP version. Skipping " +
                    "version checking.")
        }
        if (kgpVersion != null) checkKGPVersion(kgpVersion)
    }

    // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api.invocation/-gradle/index.html#-837060600%2FFunctions%2F-1793262594
    private fun getGradleVersion(project : Project) : Version {
        return Version.fromString(project.gradle.getGradleVersion())
    }

    // https://docs.gradle.org/current/kotlin-dsl/gradle/org.gradle.api/-java-version/index.html#-1790786897%2FFunctions%2F-1793262594
    private fun getJavaVersion(project : Project) : JavaVersion {
        return JavaVersion.current()
    }

    // https://cs.android.com/android-studio/platform/tools/base/+/mirror-goog-studio-main:build-system/gradle-api/src/main/java/com/android/build/api/variant/AndroidComponentsExtension.kt;l=38?q=AndroidComponents&ss=android-studio%2Fplatform%2Ftools%2Fbase:build-system%2Fgradle-api%2Fsrc%2Fmain%2Fjava%2Fcom%2Fandroid%2Fbuild%2Fapi%2F
    private fun getAGPVersion(project : Project) : AndroidPluginVersion {
        return project.extensions
            .getByType(ApplicationAndroidComponentsExtension::class.java)!!.pluginVersion
    }

    private fun getKGPVersion(project : Project) : Version {
        return Version.fromString(
            project.getPlugins()
                .findPlugin(KotlinAndroidPluginWrapper::class.java)!!
                .pluginVersion
        )
    }

    private fun checkGradleVersion(version : Version) {
        if (version < errorGradleVersion) {
            project.logger.error("")
        }
        else if (version < warnGradleVersion) {
            project.logger.quiet("")
        }
    }

    private fun checkJavaVersion(version : JavaVersion) {
        if (version < errorJavaVersion) {
            project.logger.error("")
        }
        else if (version < warnJavaVersion) {
            project.logger.quiet("")
        }
    }

    private fun checkAGPVersion(version : AndroidPluginVersion) {
        if (version < errorAGPVersion) {
            project.logger.error("")
        }
        else if (version < warnAGPVersion) {
            project.logger.quiet("")
        }
    }

    private fun checkKGPVersion(version : Version) {
        if (version < errorKGPVersion) {
            project.logger.error("")
        }
        else if (version < warnKGPVersion) {
            project.logger.quiet("")
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