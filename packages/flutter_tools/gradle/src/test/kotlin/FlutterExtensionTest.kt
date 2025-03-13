package com.flutter.gradle

import org.gradle.api.GradleException
import kotlin.test.Test
import kotlin.test.assertFailsWith

class FlutterExtensionTest {
    @Test
    fun `getVersionCode() throws GradleException when flutterVersion is not set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        assertFailsWith<GradleException> { flutterExtension.getVersionCode() }
    }

    @Test
    fun `getVersionCode() throws GradleException when flutterVersion is not an integer`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionCode = "not an integer"
        assertFailsWith<GradleException> { flutterExtension.getVersionCode() }
    }

    @Test
    fun `getVersionCode() returns flutterVersion without error when set and is a number`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionCode = "123"
        assert(flutterExtension.getVersionCode() == 123)
    }

    @Test
    fun `getVersionName() throws GradleException when flutterVersionName is not set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        assertFailsWith<GradleException> { flutterExtension.getVersionName() }
    }

    @Test
    fun `getVersionName() returns flutterVersionName without error when set`() {
        val flutterExtension: FlutterExtension = FlutterExtension()
        flutterExtension.flutterVersionName = "1.2.3"
        assert(flutterExtension.getVersionName() == "1.2.3")
    }
}
