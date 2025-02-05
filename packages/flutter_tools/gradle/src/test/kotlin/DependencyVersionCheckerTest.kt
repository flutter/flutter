package com.flutter.gradle

import com.android.build.api.AndroidPluginVersion
import com.flutter.gradle.DependencyVersionChecker.AGP_NAME
import com.flutter.gradle.DependencyVersionChecker.OUT_OF_SUPPORT_RANGE_PROPERTY
import com.flutter.gradle.DependencyVersionChecker.errorAGPVersion
import com.flutter.gradle.DependencyVersionChecker.getErrorMessage
import com.flutter.gradle.DependencyVersionChecker.getPotentialAGPFix
import com.flutter.gradle.DependencyVersionChecker.getWarnMessage
import com.flutter.gradle.DependencyVersionChecker.warnAGPVersion
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.gradle.api.Project
import org.gradle.api.logging.Logger
import org.gradle.api.plugins.ExtraPropertiesExtension
import org.gradle.internal.extensions.core.extra
import kotlin.test.Test
import kotlin.test.assertFailsWith

const val FAKE_PROJECT_ROOT_DIR = "/fake/root/dir"

class DependencyVersionCheckerTest {
    @Test
    fun `AGP version in error range results in DependencyValidationException`() {
        val mockProject = mockk<Project>()
        val mockExtraPropertiesExtension = mockk<ExtraPropertiesExtension>()
        every { mockProject.rootDir.path } returns FAKE_PROJECT_ROOT_DIR
        every { mockProject.extra } returns mockExtraPropertiesExtension
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit

        val exampleErrorAgpVersion = AndroidPluginVersion(4, 2, 0)

        val dependencyValidationException =
            assertFailsWith<DependencyValidationException> { DependencyVersionChecker.checkAGPVersion(exampleErrorAgpVersion, mockProject) }
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
        val mockProject = mockk<Project>()
        val mockExtraPropertiesExtension = mockk<ExtraPropertiesExtension>()
        val mockLogger = mockk<Logger>()
        every { mockProject.rootDir.path } returns FAKE_PROJECT_ROOT_DIR
        every { mockProject.extra } returns mockExtraPropertiesExtension
        every { mockExtraPropertiesExtension.set(any(), any()) } returns Unit
        every { mockProject.logger } returns mockLogger
        every { mockLogger.error(any()) } returns Unit

        val exampleWarnAgpVersion = AndroidPluginVersion(7, 1, 0)

        DependencyVersionChecker.checkAGPVersion(exampleWarnAgpVersion, mockProject)
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
}
