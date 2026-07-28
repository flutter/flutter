package com.flutter.gradle.tasks

import org.gradle.api.Project
import org.gradle.testfixtures.ProjectBuilder
import java.io.File
import java.util.Base64
import kotlin.test.Test
import kotlin.test.assertTrue

class GenerateEngineFlagsManifestTaskTest {
    @Test
    fun `manifest is generated correctly with decoded json flags`() {
        val project = ProjectBuilder.builder().build()
        val testTask = project.tasks.register(
            "generateEngineFlagsManifestTest",
            GenerateEngineFlagsManifestTask::class.java
        ).get()

        // Base64 encoded JSON
        val jsonStr = """{"io.flutter.embedding.android.enable-impeller":"true","io.flutter.embedding.android.trace-systrace":"true"}"""
        val base64Encoded = Base64.getEncoder().encodeToString(jsonStr.toByteArray(Charsets.UTF_8))
        
        val outputFile = File.createTempFile("AndroidManifest", ".xml")
        outputFile.deleteOnExit()

        testTask.engineShellArgsJson.set(base64Encoded)
        testTask.manifestOutputFile.set(outputFile)

        testTask.generateManifest()

        val manifestContent = outputFile.readText()

        assertTrue(manifestContent.contains("<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">"))
        assertTrue(manifestContent.contains("<application>"))
        assertTrue(manifestContent.contains("""<meta-data android:name="io.flutter.embedding.android.enable-impeller" android:value="true" />"""))
        assertTrue(manifestContent.contains("""<meta-data android:name="io.flutter.embedding.android.trace-systrace" android:value="true" />"""))
        assertTrue(manifestContent.contains("</application>"))
        assertTrue(manifestContent.contains("</manifest>"))
    }
}
