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
import com.flutter.gradle.DependencyVersionChecker.errorJavaVersion
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
import com.flutter.gradle.DependencyVersionChecker.warnKGPVersion
import com.flutter.gradle.DependencyVersionChecker.warnMinSdkVersion
import com.flutter.gradle.testing.setAgpKotlinVersionToNull
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
private const val SUPPORTED_GRADLE_VERSION: String = "9.1.0"
private val SUPPORTED_JAVA_VERSION: JavaVersion = JavaVersion.VERSION_17
private val SUPPORTED_AGP_VERSION: AndroidPluginVersion = AndroidPluginVersion(9, 0, 1)
private const val SUPPORTED_KGP_VERSION: String = "2.3.20"
private val SUPPORTED_SDK_VERSION: MinSdkVersion = MinSdkVersion("release", 30)

private const val TEST_WARN_MIN_SDK_VERSION = 21
private const val TEST_ERROR_MIN_SDK_VERSION = 19

class DependencyVersionCheckerTest {
    @Test
    fun `Template versions are considered supported`() {
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions()

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit
        every { mockLogger.warn(any()) } returns Unit

        DependencyVersionChecker.checkDependencyVersions(mockProject)

        // Verify that no error or warning messages were logged.
        verify(exactly = 0) { mockLogger.error(any()) }
        verify(exactly = 0) { mockLogger.warn(any()) }
        // Verify that the project was not marked as being out of support range.
        verify { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) }
    }

    @Test
    fun `AGP version in error range results in DependencyValidationException`() {
        val exampleErrorAgpVersion = AndroidPluginVersion(8, 11, 0)
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
        val exampleWarnAgpVersion = AndroidPluginVersion(8, 11, 1)
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
        val exampleErrorKgpVersion = "2.0.0"
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
        val exampleWarnKgpVersion = "2.2.20"
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

    // No test for Java version in warn range, as the lowest supported Java version is also the
    // lowest possible.
    @Test
    fun `Java version in error range results in error logs`() {
        val exampleErrorJavaVersion = JavaVersion.VERSION_16
        val mockProject = MockProjectFactory.createMockProjectWithSpecifiedDependencyVersions(javaVersion = exampleErrorJavaVersion)

        val mockExtraPropertiesExtension = mockProject.extra
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, false) } returns Unit
        every { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) } returns Unit
        val mockLogger = mockProject.logger
        every { mockLogger.error(any()) } returns Unit

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> { DependencyVersionChecker.checkDependencyVersions(mockProject) }
        assert(
            dependencyValidationException.message ==
                getErrorMessage(
                    JAVA_NAME,
                    exampleErrorJavaVersion.toString(),
                    errorJavaVersion.toString(),
                    POTENTIAL_JAVA_FIX
                )
        )
        verify(exactly = 1) { mockExtraPropertiesExtension.set(OUT_OF_SUPPORT_RANGE_PROPERTY, true) }
    }

    @Test
    fun `Gradle version in error range results in DependencyValidationException`() {
        val exampleErrorGradleVersion = "8.13.0"
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
        val exampleWarnGradleVersion = "8.14.0"
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
        val exampleWarnSDKVersion = 23
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
            "Error: Your project's minimum Android SDK (flavor='flavor') version ($version) is lower than " +
                "Flutter's minimum supported version of $errorMinSdkVersion. Please upgrade your minimum Android SDK " +
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
        val version = 23

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
                "version ($version) will soon be dropped. Please upgrade your minimum Android SDK " +
                "(flavor='flavor') version to a version of at least $warnMinSdkVersion soon.\n" +
                "Alternatively, use the flag \"--android-skip-build-dependency-validation\" to " +
                "bypass this check.\n" +
                "\n" +
                "Potential fix: Your project's minimum Android SDK version is typically defined in " +
                "the android block of the app-level `build.gradle(.kts)` file " +
                "(projectDir/app/build.gradle(.kts))."
        )
    }

    @Test
    fun `AndroidSupportVersions inflates correctly from JSON`() {
        val jsonText =
            """
            {
              "gradle": {
                "warn": "1.2.3",
                "error": "0.1.2"
              },
              "java": {
                "warn": "11",
                "error": "8"
              },
              "agp": {
                "warn": "4.5.6",
                "error": "3.4.5"
              },
              "kgp": {
                "warn": "1.8.0",
                "error": "1.7.0"
              },
              "minSdkVersion": {
                "warn": ${TEST_WARN_MIN_SDK_VERSION},
                "error": ${TEST_ERROR_MIN_SDK_VERSION}
              },
              "maxKnownVersions": {
                "gradle": "9.3.1",
                "kgp": "2.4.0",
                "agp": "9.2",
                "agpWithKotlin": "9.1.0"
              },
              "oldestConsideredVersions": {
                "gradle": "4.10.1",
                "agp": "3.3.0",
                "kgp": "1.6.20",
                "javaAgp": "4.2",
                "java": "1.8",
                "javaGradle": "2.0"
              },
              "oneMajorVersionHigherJavaVersion": "26",
              "gradleAgpCompat": [
                { "agpMin": "9.1.0", "agpMax": "9.1.99", "gradleMin": "9.3.1", "inclusiveMaxAgp": true }
              ],
              "javaGradleCompat": [
                { "javaMin": "25", "javaMax": "26", "gradleMin": "9.1.0", "gradleMax": "9.2.0" }
              ],
              "javaAgpCompat": [
                { "javaMin": "17", "javaDefault": "17", "agpMin": "8.0", "agpMax": "9.2" }
              ],
              "kgpGradleCompat": [
                { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "gradleMin": "8.5", "gradleMax": "9.5.99", "inclusiveMaxKgp": false, "inclusiveMaxGradle": false }
              ],
              "agpKgpCompat": [
                { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "agpMin": "8.2.2", "agpMax": "9.2.99", "inclusiveMaxKgp": false, "inclusiveMaxAgp": false }
              ],
              "gradleVersionForAgp": [
                { "agpMin": "1.0.0", "agpMax": "1.1.3", "minRequiredGradle": "2.3" }
              ]
            }
            """.trimIndent()
        val versions = AndroidSupportVersions.fromJson(jsonText)

        assertEquals("1.2.3", versions.gradle.warn)
        assertEquals("0.1.2", versions.gradle.error)
        assertEquals("11", versions.java.warn)
        assertEquals("8", versions.java.error)
        assertEquals("4.5.6", versions.agp.warn)
        assertEquals("3.4.5", versions.agp.error)
        assertEquals("1.8.0", versions.kgp.warn)
        assertEquals("1.7.0", versions.kgp.error)
        assertEquals(TEST_WARN_MIN_SDK_VERSION, versions.minSdkVersion.warn)
        assertEquals(TEST_ERROR_MIN_SDK_VERSION, versions.minSdkVersion.error)

        assertEquals("9.3.1", versions.maxKnownVersions.gradle)
        assertEquals("2.4.0", versions.maxKnownVersions.kgp)
        assertEquals("9.2", versions.maxKnownVersions.agp)
        assertEquals("9.1.0", versions.maxKnownVersions.agpWithKotlin)

        assertEquals("4.10.1", versions.oldestConsideredVersions.gradle)
        assertEquals("3.3.0", versions.oldestConsideredVersions.agp)
        assertEquals("1.6.20", versions.oldestConsideredVersions.kgp)
        assertEquals("4.2", versions.oldestConsideredVersions.javaAgp)
        assertEquals("1.8", versions.oldestConsideredVersions.java)
        assertEquals("2.0", versions.oldestConsideredVersions.javaGradle)

        assertEquals("26", versions.oneMajorVersionHigherJavaVersion)

        assertEquals(1, versions.gradleAgpCompat.size)
        assertEquals("9.1.0", versions.gradleAgpCompat[0].agpMin)
        assertEquals("9.1.99", versions.gradleAgpCompat[0].agpMax)
        assertEquals("9.3.1", versions.gradleAgpCompat[0].gradleMin)
        assertEquals(true, versions.gradleAgpCompat[0].inclusiveMaxAgp)

        assertEquals(1, versions.javaGradleCompat.size)
        assertEquals("25", versions.javaGradleCompat[0].javaMin)
        assertEquals("26", versions.javaGradleCompat[0].javaMax)
        assertEquals("9.1.0", versions.javaGradleCompat[0].gradleMin)
        assertEquals("9.2.0", versions.javaGradleCompat[0].gradleMax)

        assertEquals(1, versions.javaAgpCompat.size)
        assertEquals("17", versions.javaAgpCompat[0].javaMin)
        assertEquals("17", versions.javaAgpCompat[0].javaDefault)
        assertEquals("8.0", versions.javaAgpCompat[0].agpMin)
        assertEquals("9.2", versions.javaAgpCompat[0].agpMax)

        assertEquals(1, versions.kgpGradleCompat.size)
        assertEquals("2.4.0", versions.kgpGradleCompat[0].kgpMin)
        assertEquals("2.4.29", versions.kgpGradleCompat[0].kgpMax)
        assertEquals("8.5", versions.kgpGradleCompat[0].gradleMin)
        assertEquals("9.5.99", versions.kgpGradleCompat[0].gradleMax)
        assertEquals(false, versions.kgpGradleCompat[0].inclusiveMaxKgp)
        assertEquals(false, versions.kgpGradleCompat[0].inclusiveMaxGradle)

        assertEquals(1, versions.agpKgpCompat.size)
        assertEquals("2.4.0", versions.agpKgpCompat[0].kgpMin)
        assertEquals("2.4.29", versions.agpKgpCompat[0].kgpMax)
        assertEquals("8.2.2", versions.agpKgpCompat[0].agpMin)
        assertEquals("9.2.99", versions.agpKgpCompat[0].agpMax)
        assertEquals(false, versions.agpKgpCompat[0].inclusiveMaxKgp)
        assertEquals(false, versions.agpKgpCompat[0].inclusiveMaxAgp)

        assertEquals(1, versions.gradleVersionForAgp.size)
        assertEquals("1.0.0", versions.gradleVersionForAgp[0].agpMin)
        assertEquals("1.1.3", versions.gradleVersionForAgp[0].agpMax)
        assertEquals("2.3", versions.gradleVersionForAgp[0].minRequiredGradle)
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
                onVariantsFnSlot.captured.invoke(variant)
            }
            return@answers Unit
        }
        setAgpKotlinVersionToNull(mockProject)

        return mockProject
    }
}
