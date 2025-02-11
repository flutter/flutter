package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import com.autonomousapps.kit.AbstractGradleProject
import com.autonomousapps.kit.GradleBuilder
import com.autonomousapps.kit.GradleProject
import com.autonomousapps.kit.Source
import com.autonomousapps.kit.gradle.Dependency
import com.autonomousapps.kit.gradle.Plugin
import com.flutter.gradle.DependencyVersionChecker.AGP_NAME
import com.flutter.gradle.DependencyVersionChecker.OUT_OF_SUPPORT_RANGE_PROPERTY
import com.flutter.gradle.DependencyVersionChecker.errorAGPVersion
import com.flutter.gradle.DependencyVersionChecker.getErrorMessage
import com.flutter.gradle.DependencyVersionChecker.getPotentialAGPFix
import com.flutter.gradle.DependencyVersionChecker.getWarnMessage
import com.flutter.gradle.DependencyVersionChecker.warnAGPVersion
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.verify
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.logging.Logger
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.internal.extensions.core.extra
import org.gradle.testkit.runner.GradleRunner
import java.io.File
import kotlin.test.Test
import kotlin.test.assertFailsWith

const val FAKE_PROJECT_ROOT_DIR = "/fake/root/dir"

class DependencyVersionCheckerTest {
    @Test
    fun `AGP version in error range results in DependencyValidationException`() {
        val exampleErrorAgpVersion = AndroidPluginVersion(4, 2, 0)
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(agpVersion = exampleErrorAgpVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> { DependencyVersionChecker.checkDependencyVersions(mockProject) }
        assert(
            dependencyValidationException.message ==
                getErrorMessage(
                    AGP_NAME,
                    exampleErrorAgpVersion.toString(),
                    errorAGPVersion.toString(),
                    getPotentialAGPFix(FAKE_PROJECT_ROOT_DIR)
                )
        )
        verify { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `AGP version in warn range results in warning logs`() {
        val exampleWarnAgpVersion = AndroidPluginVersion(7, 1, 0)
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(agpVersion = exampleWarnAgpVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)
        verify {
            mockLogger.error(
                getWarnMessage(
                    AGP_NAME,
                    exampleWarnAgpVersion.toString(),
                    warnAGPVersion.toString(),
                    getPotentialAGPFix(FAKE_PROJECT_ROOT_DIR)
                )
            )
        }
        verify(exactly = 0) { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
        GradleRunner.create().withPluginClasspath()
    }

    @Test
    fun `blah blah`() {
        val gradleRunner = BlahBlah.gradleProject
        val result = GradleBuilder.build(gradleRunner.rootDir, ":project:assembleDebug")
    }

    @Test
    fun `how about this`() {
        val settingsFileContent =
            """
            pluginManagement {

                includeBuild("/Users/mackall/development/flutter/flutter/packages/flutter_tools/gradle")

                repositories {
                    google()
                    mavenCentral()
                    gradlePluginPortal()
                }
            }

            plugins {
                id("dev.flutter.flutter-plugin-loader") version "1.0.0"
                id("com.android.application") version "8.7.3" apply false
                id("org.jetbrains.kotlin.android") version "2.1.0" apply false
            }
            """.trimIndent()

        val buildFileContent =
            """
            allprojects {
                repositories {
                    google()
                    mavenCentral()
                }
            }

            val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
            rootProject.layout.buildDirectory.value(newBuildDir)

            subprojects {
                val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
                project.layout.buildDirectory.value(newSubprojectBuildDir)
            }
            subprojects {
                project.evaluationDependsOn(":app")
            }

            tasks.register<Delete>("clean") {
                delete(rootProject.layout.buildDirectory)
            }
            """.trimIndent()

        val appBuildFileContent =
            """
                               plugins {
                id("com.android.application")
                id("kotlin-android")
                // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
                id("dev.flutter.flutter-gradle-plugin")
            }

            android {
                namespace = "com.example.abc"
                compileSdk = flutter.compileSdkVersion
                ndkVersion = flutter.ndkVersion

                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }

                kotlinOptions {
                    jvmTarget = JavaVersion.VERSION_11.toString()
                }

                defaultConfig {
                    // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
                    applicationId = "com.example.abc"
                    // You can update the following values to match your application needs.
                    // For more information, see: https://flutter.dev/to/review-gradle-config.
                    minSdk = flutter.minSdkVersion
                    targetSdk = flutter.targetSdkVersion
                    versionCode = flutter.versionCode
                    versionName = flutter.versionName
                }

                buildTypes {
                    release {
                        // TODO: Add your own signing config for the release build.
                        // Signing with the debug keys for now, so `flutter run --release` works.
                        signingConfig = signingConfigs.getByName("debug")
                    }
                }
            }

            flutter {
                source = "../.."
            }                             
            """.trimIndent()

        val localpropertiesContent =
            """
            ## This file must *NOT* be checked into Version Control Systems,
            # as it contains information specific to your local configuration.
            #
            # Location of the SDK. This is only used by Gradle.
            # For customization when using a Version Control System, please read the
            # header note.
            #Wed Feb 05 14:41:22 PST 2025
            sdk.dir=/Users/mackall/Library/Android/sdk

            """.trimIndent()

        val projectDir = File("build/functionalTest")
        projectDir.mkdirs()
        val appDir = projectDir.resolve("app")
        appDir.mkdirs()
        projectDir.resolve("build.gradle.kts").writeText(buildFileContent)
        projectDir.resolve("settings.gradle.kts").writeText(settingsFileContent)
        projectDir.resolve("local.properties").writeText(localpropertiesContent)
        projectDir.resolve("app/build.gradle.kts").writeText(appBuildFileContent)

        val buildResult =
            GradleRunner
                .create()
                .withPluginClasspath()
                .withGradleVersion("7.0")
                .withProjectDir(projectDir)
                .build()
    }
}

object MockProjectFactory {
    fun createMockProjectWithSpecifiedDependencyVersions(
        javaVersion: JavaVersion = SUPPORTED_JAVA_VERSION,
        gradleVersion: String = SUPPORTED_GRADLE_VERSION,
        agpVersion: AndroidPluginVersion = SUPPORTED_AGP_VERSION,
        kgpVersion: String = SUPPORTED_KGP_VERSION
    ): Project {
        // Java
        mockkStatic(JavaVersion::class)
        every { JavaVersion.current() } returns javaVersion

        // Gradle
        val mockProject = mockk<Project>()
        every { mockProject.gradle.gradleVersion } returns gradleVersion

        // AGP
        val mockAndroidComponentsExtension = mockk<AndroidComponentsExtension<*, *, *>>()
        every { mockProject.extensions.findByType(AndroidComponentsExtension::class.java) } returns mockAndroidComponentsExtension
        every { mockAndroidComponentsExtension.pluginVersion } returns agpVersion

        // KGP
        // TODO(gmackall) this should use the actual val
        every { mockProject.hasProperty(eq("kotlin_version")) } returns true
        every { mockProject.properties["kotlin_version"] } returns kgpVersion

        // Logger
        val mockLogger = mockk<Logger>()
        every { mockProject.logger } returns mockLogger

        // Extra properties extension
        val mockExtraPropertiesExtension = mockk<ExtraPropertiesExtension>()
        every { mockProject.extra } returns mockExtraPropertiesExtension

        // Project path
        every { mockProject.rootDir.path } returns FAKE_PROJECT_ROOT_DIR

        return mockProject
    }
}

const val SUPPORTED_GRADLE_VERSION: String = "7.4.2"
val SUPPORTED_JAVA_VERSION: JavaVersion = JavaVersion.VERSION_11
val SUPPORTED_AGP_VERSION: AndroidPluginVersion = AndroidPluginVersion(7, 3, 1)
const val SUPPORTED_KGP_VERSION: String = "1.8.10"

class MyFixture : AbstractGradleProject() {
    // Injected into functionalTest JVM by the plugin
    // Also available via AbstractGradleProject.PLUGIN_UNDER_TEST_VERSION
    private val pluginVersion = System.getProperty("com.autonomousapps.plugin-under-test.version")

    val gradleProject: GradleProject = build()

    private fun build(): GradleProject {
        return newGradleProjectBuilder()
            .withSubproject("project") {
                sources = source
                withBuildScript {
                    plugins(Plugin.javaLibrary, Plugin("my-cool-plugin", pluginVersion))
                    dependencies(Dependency.implementation("com.company:library:1.0"))
                }
            }
            .write()
    }

    private val source =
        mutableListOf(
            Source.java(
                """
      package com.example.project;

      public class Project {
        // do stuff here
      }
      """
            )
                .withPath(/* packagePath = */ "com.example.project", /* className = */ "Project")
                .build()
        )
}

object BlahBlah : AbstractGradleProject() {
    // Injected into functionalTest JVM by the plugin
    // Also available via AbstractGradleProject.PLUGIN_UNDER_TEST_VERSION
    // private val pluginVersion = System.getProperty("com.autonomousapps.plugin-under-test.version")

    val gradleProject: GradleProject = build()

    private fun build(): GradleProject {
        return newGradleProjectBuilder(GradleProject.DslKind.KOTLIN).withRootProject {
            GradleProject.DslKind.KOTLIN
        }
            // .withIncludedBuild("/Users/mackall/development/flutter/flutter/packages/flutter_tools/gradle") { GradleProject.DslKind.KOTLIN }
            .withSubproject("project") {
                println("sources is null? " + source == null)
                sources.addLast(source)
                withBuildScript {
                    plugins(Plugin.of("com.android.application", "8.7.2"), Plugin("my-cool-plugin", "0.1.0"))
                    dependencies(Dependency.implementation("com.android.tools.build:gradle:8.7.3"))
                }
            }
            .build()
            .write()
    }

    private val source =
        Source.java(
            """
      package com.example.project;

      public class Project {
        println("blah");
      }
      """
        )
            .withPath(/* packagePath = */ "com/example/project", /* className = */ "Project")
            .build()
}
