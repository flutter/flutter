package testing

import com.android.build.api.dsl.ApplicationExtension
import io.mockk.every
import io.mockk.mockk
import org.gradle.api.Project

/** Mocks the Android extension for tests reading compileSdk or ndkVersion via the public DSL. */
fun setUpMockAndroidExtension(
    project: Project,
    compileSdk: Int? = null,
    ndkVersion: String? = "29.0.13846066"
): ApplicationExtension {
    val mockAndroidExtension = mockk<ApplicationExtension>()
    
    if (compileSdk != null) {
        every { mockAndroidExtension.compileSdk } returns compileSdk
        every { mockAndroidExtension.compileSdkPreview } returns null
    }
    if (ndkVersion != null) {
        every { mockAndroidExtension.ndkVersion } returns ndkVersion
    }
    
    every { project.extensions.findByType(ApplicationExtension::class.java) } returns mockAndroidExtension
    every { project.extensions.findByName("android") } returns mockAndroidExtension
    
    every { project.gradle.startParameter.taskNames } returns emptyList()
    every { project.gradle.startParameter.isOffline } returns false
    
    return mockAndroidExtension
}
