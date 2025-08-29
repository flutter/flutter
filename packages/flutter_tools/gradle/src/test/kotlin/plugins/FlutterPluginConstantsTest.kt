package com.flutter.gradle.plugins
import com.flutter.gradle.FlutterPluginConstants
import kotlin.test.Test
import kotlin.test.assertEquals

class FlutterPluginConstantsTest {
    @Test
    fun `test PLATFORM_ARCH_MAP contains correct mappings`() {
        val map = FlutterPluginConstants.PLATFORM_ARCH_MAP
        assertEquals("armeabi-v7a", map["android-arm"])
        assertEquals("arm64-v8a", map["android-arm64"])
        assertEquals("x86_64", map["android-x64"])
    }

    @Test
    fun `test ABI_VERSION contains correct version codes`() {
        val versionMap = FlutterPluginConstants.ABI_VERSION
        assertEquals(1, versionMap["armeabi-v7a"])
        assertEquals(2, versionMap["arm64-v8a"])
        assertEquals(4, versionMap["x86_64"])
    }

    @Test
    fun `test DEFAULT_PLATFORMS list contains all supported platforms`() {
        val platforms = FlutterPluginConstants.DEFAULT_PLATFORMS
        assertEquals(listOf("android-arm", "android-arm64", "android-x64"), platforms)
    }
}
