// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import com.flutter.gradle.DependencyVersionChecker.AGP_NAME
import com.flutter.gradle.DependencyVersionChecker.GRADLE_NAME
import com.flutter.gradle.DependencyVersionChecker.JAVA_NAME
import com.flutter.gradle.DependencyVersionChecker.KGP_NAME
import com.flutter.gradle.DependencyVersionChecker.MIN_SDK_NAME
import com.flutter.gradle.DependencyVersionChecker.OUT_OF_SUPPORT_RANGE_PROPERTY
import com.flutter.gradle.DependencyVersionChecker.POTENTIAL_JAVA_FIX
import com.flutter.gradle.DependencyVersionChecker.errorAGPVersion
import com.flutter.gradle.DependencyVersionChecker.errorGradleVersion
import com.flutter.gradle.DependencyVersionChecker.errorKGPVersion
import com.flutter.gradle.DependencyVersionChecker.errorMinSdkVersion
import com.flutter.gradle.DependencyVersionChecker.getErrorMessage
import com.flutter.gradle.DependencyVersionChecker.getFlavorSpecificMessage
import com.flutter.gradle.DependencyVersionChecker.getPotentialAGPFix
import com.flutter.gradle.DependencyVersionChecker.getPotentialGradleFix
import com.flutter.gradle.DependencyVersionChecker.getPotentialKGPFix
import com.flutter.gradle.DependencyVersionChecker.getPotentialSDKFix
import com.flutter.gradle.DependencyVersionChecker.getWarnMessage
import com.flutter.gradle.DependencyVersionChecker.warnAGPVersion
import com.flutter.gradle.DependencyVersionChecker.warnGradleVersion
import com.flutter.gradle.DependencyVersionChecker.warnJavaVersion
import com.flutter.gradle.DependencyVersionChecker.warnKGPVersion
import com.flutter.gradle.DependencyVersionChecker.warnMinSdkVersion
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.slot
import io.mockk.verify
import org.gradle.api.Action
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.logging.Logger
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.api.tasks.TaskContainer
import org.gradle.internal.extensions.core.extra
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

private const val FAKE_PROJECT_ROOT_DIR = "/fake/root/dir"

// The following values will need to be modified when the corresponding "warn$DepName" versions
// are updated in DependencyVersionChecker.kt
private const val SUPPORTED_GRADLE_VERSION: String = "7.4.2"
private val SUPPORTED_JAVA_VERSION: JavaVersion = JavaVersion.VERSION_11
private val SUPPORTED_AGP_VERSION: AndroidPluginVersion = AndroidPluginVersion(8, 3, 0)
private const val SUPPORTED_KGP_VERSION: String = "1.8.10"
private val SUPPORTED_SDK_VERSION: MinSdkVersion = MinSdkVersion("release", 30)

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
        val exampleWarnAgpVersion = AndroidPluginVersion(8, 2, 0)
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
    }

    @Test
    fun `KGP version in error range results in DependencyValidationException`() {
        val exampleErrorKgpVersion = "1.6.0"
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(kgpVersion = exampleErrorKgpVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> { DependencyVersionChecker.checkDependencyVersions(mockProject) }

        println(dependencyValidationException.message)
        assert(
            dependencyValidationException.message ==
                getErrorMessage(
                    KGP_NAME,
                    exampleErrorKgpVersion,
                    errorKGPVersion.toString(),
                    getPotentialKGPFix(FAKE_PROJECT_ROOT_DIR)
                )
        )
        verify { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `KGP version in warn range results in warning logs`() {
        val exampleWarnKgpVersion = "1.8.0"
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(kgpVersion = exampleWarnKgpVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)
        verify {
            mockLogger.error(
                getWarnMessage(
                    KGP_NAME,
                    exampleWarnKgpVersion,
                    warnKGPVersion.toString(),
                    getPotentialKGPFix(FAKE_PROJECT_ROOT_DIR)
                )
            )
        }
        verify(exactly = 0) { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    // No test for Java version in error range, as the lowest supported Java version is also the
    // lowest possible.

    @Test
    fun `Java version in warn range results in warning logs`() {
        val exampleWarnJavaVersion = JavaVersion.VERSION_1_8
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(javaVersion = exampleWarnJavaVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)
        verify {
            mockLogger.error(
                getWarnMessage(
                    JAVA_NAME,
                    exampleWarnJavaVersion.toString(),
                    warnJavaVersion.toString(),
                    POTENTIAL_JAVA_FIX
                )
            )
        }
        verify(exactly = 0) { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `Gradle version in error range results in DependencyValidationException`() {
        val exampleErrorGradleVersion = "7.0.0"
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(gradleVersion = exampleErrorGradleVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> { DependencyVersionChecker.checkDependencyVersions(mockProject) }

        assert(
            dependencyValidationException.message ==
                getErrorMessage(
                    GRADLE_NAME,
                    exampleErrorGradleVersion,
                    errorGradleVersion.toString(),
                    getPotentialGradleFix(FAKE_PROJECT_ROOT_DIR)
                )
        )
        verify { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `Gradle version in warn range results in warning logs`() {
        val exampleWarnGradleVersion = "7.4.0"
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(gradleVersion = exampleWarnGradleVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)
        verify {
            mockLogger.error(
                getWarnMessage(
                    GRADLE_NAME,
                    exampleWarnGradleVersion,
                    warnGradleVersion.toString(),
                    getPotentialGradleFix(FAKE_PROJECT_ROOT_DIR)
                )
            )
        }
        verify(exactly = 0) { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `min SDK version in warn range results in warning logs`() {
        val exampleWarnSDKVersion = 19
        val flavorName1 = "flavor1"
        val flavorName2 = "flavor2"
        val mockProject =
            MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(
                minSdkVersions =
                    listOf(
                        MinSdkVersion(flavorName1, exampleWarnSDKVersion),
                        MinSdkVersion(flavorName2, exampleWarnSDKVersion)
                    )
            )

        val mockExtraPropertiesExtension = mockProject.extra
        every {
            mockExtraPropertiesExtension.set(
                OUT_OF_SUPPORT_RANGE_PROPERTY,
                false
            )
        } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)
        verify {
            mockLogger.error(
                getWarnMessage(
                    getFlavorSpecificMessage(flavorName1, MIN_SDK_NAME),
                    exampleWarnSDKVersion.toString(),
                    warnMinSdkVersion.toString(),
                    getPotentialSDKFix(FAKE_PROJECT_ROOT_DIR)
                )
            )
            mockLogger.error(
                getWarnMessage(
                    getFlavorSpecificMessage(flavorName2, MIN_SDK_NAME),
                    exampleWarnSDKVersion.toString(),
                    warnMinSdkVersion.toString(),
                    getPotentialSDKFix(FAKE_PROJECT_ROOT_DIR)
                )
            )
        }
        verify(exactly = 0) {
            mockExtraPropertiesExtension.set(
                OUT_OF_SUPPORT_RANGE_PROPERTY,
                true
            )
        }
    }

    @Test
    fun `min SDK version in error range results in DependencyValidationException`() {
        val exampleErrorSDKVersion = 0
        val flavorName = "flavor1"
        val mockProject =
            MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(
                minSdkVersions =
                    listOf(
                        MinSdkVersion(flavorName, exampleErrorSDKVersion)
                    )
            )

        val mockExtraPropertiesExtension = mockProject.extra
        val mockLogger = mockProject.logger
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit
        every { mockLogger.error(any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> {
                DependencyVersionChecker.checkDependencyVersions(
                    mockProject
                )
            }

        assert(
            dependencyValidationException.message ==
                getErrorMessage(
                    getFlavorSpecificMessage(flavorName, MIN_SDK_NAME),
                    exampleErrorSDKVersion.toString(),
                    errorMinSdkVersion.toString(),
                    getPotentialSDKFix(FAKE_PROJECT_ROOT_DIR)
                )
        )
        verify(exactly = 1) {
            mockExtraPropertiesExtension.set(
                OUT_OF_SUPPORT_RANGE_PROPERTY,
                true
            )
        }
    }

    @Test
    fun `checkMinSdkVersion throws error when in error range for min SDK version`() {
        val mockLogger = mockk<Logger>()
        val mockExtraPropertiesExtension = mockk<ExtraPropertiesExtension>()
        val projectDir = "projectDir"
        val flavor = "flavor"
        val version = 0

        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit
        every { mockLogger.error(any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> {
                DependencyVersionChecker.checkMinSdkVersion(
                    minSdkVersion = MinSdkVersion(flavor, version),
                    projectDirectory = projectDir,
                    logger = mockLogger
                )
            }

        assertEquals(
            dependencyValidationException.message,
            "Error: Your project's minimum Android SDK (flavor='flavor') version (0) is lower than " +
                "Flutter's minimum supported version of 1. Please upgrade your minimum Android SDK " +
                "(flavor='flavor') version. \n" +
                "Alternatively, use the flag \"--android-skip-build-dependency-validation\" to " +
                "bypass this check.\n" +
                "\n" +
                "Potential fix: Your project's minimum Android SDK version is typically defined in " +
                "the android block of the app-level `build.gradle(.kts)` file " +
                "(projectDir/app/build.gradle(.kts))."
        )
    }

    @Test
    fun `checkMinSdkVersion logs warning when in warning range for min SDK version`() {
        val mockLogger = mockk<Logger>()
        val mockExtraPropertiesExtension = mockk<ExtraPropertiesExtension>()
        val projectDir = "projectDir"
        val flavor = "flavor"
        val version = 20

        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit
        every { mockLogger.error(any()) } returns Unit

        DependencyVersionChecker.checkMinSdkVersion(
            minSdkVersion = MinSdkVersion(flavor, version),
            projectDirectory = projectDir,
            logger = mockLogger
        )

        val warningMessageSlot = slot<String>()
        verify {
            mockLogger.error(capture(warningMessageSlot))
        }

        assertEquals(
            warningMessageSlot.captured,
            "Warning: Flutter support for your project's minimum Android SDK (flavor='flavor') " +
                "version (20) will soon be dropped. Please upgrade your minimum Android SDK " +
                "(flavor='flavor') version to a version of at least 21 soon.\n" +
                "Alternatively, use the flag \"--android-skip-build-dependency-validation\" to " +
                "bypass this check.\n" +
                "\n" +
                "Potential fix: Your project's minimum Android SDK version is typically defined in " +
                "the android block of the app-level `build.gradle(.kts)` file " +
                "(projectDir/app/build.gradle(.kts))."
        )
    }
}

// There isn't a way to create a real org.gradle.api.Project object for testing unfortunately, so
// these tests rely heavily on mocking.
//
// TODO(gmackall): We should consider adding functional tests built on top of a testing framework
//  perhaps like
//  https://github.com/autonomousapps/dependency-analysis-gradle-plugin/tree/main/testkit
//  as a way to fill this gap in testing (combined with moving functionality to individual tasks
//  that can be tested independently).
private object MockProjectFactory {
    fun createMockProjectWithSpecifiedDependencyVersions(
        javaVersion: JavaVersion = SUPPORTED_JAVA_VERSION,
        gradleVersion: String = SUPPORTED_GRADLE_VERSION,
        agpVersion: AndroidPluginVersion = SUPPORTED_AGP_VERSION,
        kgpVersion: String = SUPPORTED_KGP_VERSION,
        minSdkVersions: List<MinSdkVersion> = listOf(SUPPORTED_SDK_VERSION)
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

        // SDK
        val actionSlot = slot<Action<Project>>()
        every { mockProject.afterEvaluate(capture(actionSlot)) } answers {
            actionSlot.captured.execute(mockProject)
            return@answers Unit
        }
        val onVariantsFnSlot = slot<(Variant) -> Unit>()
        every { mockAndroidComponentsExtension.selector() } returns
            mockk {
                every { all() } returns mockk()
            }
        every { mockProject.tasks } returns
            mockk<TaskContainer> {
                val registerTaskSlot = slot<Action<Task>>()
                every { register(any(), capture(registerTaskSlot)) } answers registerAnswer@{
                    registerTaskSlot.captured.execute(
                        mockk {
                            val doLastActionSlot = slot<Action<Task>>()
                            every { doLast(capture(doLastActionSlot)) } answers doLastAnswer@{
                                doLastActionSlot.captured.execute(mockk())
                                return@doLastAnswer mockk()
                            }
                        }
                    )
                    return@registerAnswer mockk()
                }

                every { named(any<String>()) } returns
                    mockk {
                        every { configure(any<Action<Task>>()) } returns mockk()
                    }
            }
        every {
            mockAndroidComponentsExtension.onVariants(
                any(),
                capture(onVariantsFnSlot)
            )
        } answers {
            minSdkVersions.forEach {
                val variant = mockk<Variant>()
                every { variant.name } returns it.flavor
                every { variant.minSdk } returns mockk { every { apiLevel } returns it.version }
                every { variant.minSdkVersion } returns mockk { every { apiLevel } returns it.version }
                onVariantsFnSlot.captured.invoke(variant)
            }
            return@answers Unit
        }

        return mockProject
    }
}
