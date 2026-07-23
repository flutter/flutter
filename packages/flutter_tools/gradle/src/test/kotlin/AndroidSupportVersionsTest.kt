// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import kotlin.test.Test
import kotlin.test.assertEquals

private const val TEST_WARN_MIN_SDK_VERSION = 21
private const val TEST_ERROR_MIN_SDK_VERSION = 19

class AndroidSupportVersionsTest {
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
              "gradleAgpCompat": {
                "comment": "Gradle-AGP compatibility matrix",
                "sourceUrl": "https://developer.android.com/studio/releases/gradle-plugin#updating-gradle",
                "rules": [
                  { "agpMin": "9.1.0", "agpMax": "9.1.99", "gradleMin": "9.3.1", "inclusiveMaxAgp": true }
                ]
              },
              "javaGradleCompat": {
                "comment": "Java-Gradle compatibility matrix",
                "sourceUrl": "https://docs.gradle.org/current/userguide/compatibility.html#java",
                "rules": [
                  { "javaMin": "25", "javaMax": "26", "gradleMin": "9.1.0", "gradleMax": "9.2.0" }
                ]
              },
              "javaAgpCompat": {
                "comment": "Java-AGP compatibility matrix",
                "sourceUrl": "https://developer.android.com/studio/releases/gradle-plugin#compatibility",
                "rules": [
                  { "javaMin": "17", "javaDefault": "17", "agpMin": "8.0", "agpMax": "9.2" }
                ]
              },
              "kgpGradleCompat": {
                "comment": "Kotlin-Gradle compatibility matrix",
                "sourceUrl": "https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin",
                "rules": [
                  { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "gradleMin": "8.5", "gradleMax": "9.5.99", "inclusiveMaxKgp": false, "inclusiveMaxGradle": false }
                ]
              },
              "agpKgpCompat": {
                "comment": "AGP-Kotlin compatibility matrix",
                "sourceUrl": "https://kotlinlang.org/docs/multiplatform-compatibility-guide.html",
                "rules": [
                  { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "agpMin": "8.2.2", "agpMax": "9.2.99", "inclusiveMaxKgp": false, "inclusiveMaxAgp": false }
                ]
              },
              "gradleVersionForAgp": {
                "comment": "Gradle version requirement for AGP",
                "sourceUrl": "https://developer.android.com/studio/releases/gradle-plugin#updating-gradle",
                "rules": [
                  { "agpMin": "1.0.0", "agpMax": "1.1.3", "minRequiredGradle": "2.3" }
                ]
              }
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

        assertEquals("Gradle-AGP compatibility matrix", versions.gradleAgpCompat.comment)
        assertEquals("https://developer.android.com/studio/releases/gradle-plugin#updating-gradle", versions.gradleAgpCompat.sourceUrl)
        assertEquals(1, versions.gradleAgpCompat.rules.size)
        assertEquals("9.1.0", versions.gradleAgpCompat.rules[0].agpMin)
        assertEquals("9.1.99", versions.gradleAgpCompat.rules[0].agpMax)
        assertEquals("9.3.1", versions.gradleAgpCompat.rules[0].gradleMin)
        assertEquals(true, versions.gradleAgpCompat.rules[0].inclusiveMaxAgp)

        assertEquals("Java-Gradle compatibility matrix", versions.javaGradleCompat.comment)
        assertEquals("https://docs.gradle.org/current/userguide/compatibility.html#java", versions.javaGradleCompat.sourceUrl)
        assertEquals(1, versions.javaGradleCompat.rules.size)
        assertEquals("25", versions.javaGradleCompat.rules[0].javaMin)
        assertEquals("26", versions.javaGradleCompat.rules[0].javaMax)
        assertEquals("9.1.0", versions.javaGradleCompat.rules[0].gradleMin)
        assertEquals("9.2.0", versions.javaGradleCompat.rules[0].gradleMax)

        assertEquals("Java-AGP compatibility matrix", versions.javaAgpCompat.comment)
        assertEquals("https://developer.android.com/studio/releases/gradle-plugin#compatibility", versions.javaAgpCompat.sourceUrl)
        assertEquals(1, versions.javaAgpCompat.rules.size)
        assertEquals("17", versions.javaAgpCompat.rules[0].javaMin)
        assertEquals("17", versions.javaAgpCompat.rules[0].javaDefault)
        assertEquals("8.0", versions.javaAgpCompat.rules[0].agpMin)
        assertEquals("9.2", versions.javaAgpCompat.rules[0].agpMax)

        assertEquals("Kotlin-Gradle compatibility matrix", versions.kgpGradleCompat.comment)
        assertEquals("https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin", versions.kgpGradleCompat.sourceUrl)
        assertEquals(1, versions.kgpGradleCompat.rules.size)
        assertEquals("2.4.0", versions.kgpGradleCompat.rules[0].kgpMin)
        assertEquals("2.4.29", versions.kgpGradleCompat.rules[0].kgpMax)
        assertEquals("8.5", versions.kgpGradleCompat.rules[0].gradleMin)
        assertEquals("9.5.99", versions.kgpGradleCompat.rules[0].gradleMax)
        assertEquals(false, versions.kgpGradleCompat.rules[0].inclusiveMaxKgp)
        assertEquals(false, versions.kgpGradleCompat.rules[0].inclusiveMaxGradle)

        assertEquals("AGP-Kotlin compatibility matrix", versions.agpKgpCompat.comment)
        assertEquals("https://kotlinlang.org/docs/multiplatform-compatibility-guide.html", versions.agpKgpCompat.sourceUrl)
        assertEquals(1, versions.agpKgpCompat.rules.size)
        assertEquals("2.4.0", versions.agpKgpCompat.rules[0].kgpMin)
        assertEquals("2.4.29", versions.agpKgpCompat.rules[0].kgpMax)
        assertEquals("8.2.2", versions.agpKgpCompat.rules[0].agpMin)
        assertEquals("9.2.99", versions.agpKgpCompat.rules[0].agpMax)
        assertEquals(false, versions.agpKgpCompat.rules[0].inclusiveMaxKgp)
        assertEquals(false, versions.agpKgpCompat.rules[0].inclusiveMaxAgp)

        assertEquals("Gradle version requirement for AGP", versions.gradleVersionForAgp.comment)
        assertEquals("https://developer.android.com/studio/releases/gradle-plugin#updating-gradle", versions.gradleVersionForAgp.sourceUrl)
        assertEquals(1, versions.gradleVersionForAgp.rules.size)
        assertEquals("1.0.0", versions.gradleVersionForAgp.rules[0].agpMin)
        assertEquals("1.1.3", versions.gradleVersionForAgp.rules[0].agpMax)
        assertEquals("2.3", versions.gradleVersionForAgp.rules[0].minRequiredGradle)
    }
}
