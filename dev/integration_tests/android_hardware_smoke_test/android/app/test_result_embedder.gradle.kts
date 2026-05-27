// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import java.io.File
import java.io.FileOutputStream

tasks.register("embedTestResultImages") {
    group = "verification"
    description = "Dynamically discovers, pulls, and embeds all on-device test result images into the AGP HTML report."

    doLast {
        val buildDir = layout.buildDirectory.get().asFile
        val reportsDir = File(buildDir, "reports/androidTests/connected")
        
        // Dynamically find the active variant directory (e.g. "debug") where HTML files exist
        var targetVariantDir = File(reportsDir, "debug")
        if (!targetVariantDir.exists()) {
            val firstHtmlParent = reportsDir.walk().firstOrNull { it.name.endsWith(".html") && it.parentFile != reportsDir }?.parentFile
            if (firstHtmlParent != null) {
                targetVariantDir = firstHtmlParent
            }
        }

        val imagesDir = File(targetVariantDir, "test_result_images")
        imagesDir.mkdirs()

        val packageId = "com.example.android_hardware_smoke_test"
        val discoveredTests = mutableListOf<Pair<String, String>>()

        // 1. Query the device sandbox to list all files in cache/results/ using ProcessBuilder
        var files = listOf<String>()
        try {
            val process = ProcessBuilder("adb", "shell", "run-as", packageId, "ls", "cache/results")
                .redirectErrorStream(true)
                .start()
            val output = process.inputStream.readBytes()
            process.waitFor()
            files = String(output).trim().split(Regex("\\r?\\n"))
        } catch (e: Exception) {
            println("Failed to query sandbox files from device: ${e.message}")
        }

        // 2. Iterate through all discovered files and pull PNGs
        for (rawFileName in files) {
            val fileName = rawFileName.trim()
            if (fileName.endsWith(".png")) {
                // Extract the clean test case name (e.g. "blueRectangleTest") before any dot-separators
                val testName = fileName.split(".")[0]

                val destinationFile = File(imagesDir, fileName)
                try {
                    // Direct binary safe copy using JDK ProcessBuilder and Kotlin stdlib copyTo
                    val process = ProcessBuilder("adb", "exec-out", "run-as", packageId, "cat", "cache/results/$fileName")
                        .start()
                    
                    FileOutputStream(destinationFile).use { os ->
                        process.inputStream.copyTo(os)
                    }
                    
                    val exitCode = process.waitFor()
                    if (exitCode == 0) {
                        discoveredTests.add(Pair(testName, fileName))
                        println("Successfully pulled test result image: ${destinationFile.absolutePath}")
                    } else {
                        destinationFile.delete()
                        val errorMsg = String(process.errorStream.readBytes()).trim()
                        println("❌ Failed to pull $fileName (exit code $exitCode): $errorMsg")
                    }
                } catch (e: Exception) {
                    if (destinationFile.exists()) {
                        destinationFile.delete()
                    }
                    println("Failed to pull test result image $fileName from device: ${e.message}")
                }
            }
        }

        // 3. Dynamically parse and inject <img> tags for all discovered tests
        if (discoveredTests.isNotEmpty()) {
            targetVariantDir.walk().forEach { file ->
                if (file.name.endsWith(".html")) {
                    var htmlContent = file.readText()
                    var modified = false

                    for (testInfo in discoveredTests) {
                        val testName = testInfo.first
                        val fileName = testInfo.second
                        val targetCell = "<td>$testName</td>"
                        if (htmlContent.contains(targetCell)) {
                            htmlContent = htmlContent.replace(
                                targetCell,
                                "<td>$testName<br/><img src=\"test_result_images/$fileName\" width=\"300\" style=\"border: 2px solid #ccc; margin-top: 10px;\" /><br/><span style=\"font-size: 12px; color: #555; font-style: italic;\">Result Image: $fileName</span></td>"
                            )
                            modified = true
                        }
                    }

                    if (modified) {
                        file.writeText(htmlContent)
                    }
                }
            }
            println("🎉 Successfully embedded ${discoveredTests.size} test result images in HTML report: ${File(targetVariantDir, "index.html").absolutePath}")
        } else {
            println("No test result images found on device to embed.")
        }

        // 4. Final Cleanup: Manually trigger auto-uninstall to leave the device clean.
        //
        // Since we set 'android.injected.androidTest.leaveApksInstalledAfterRun=true' in
        // gradle.properties to prevent the Android Gradle Plugin from immediately uninstalling
        // the app (which would wipe the sandbox cache before we could pull the result images),
        // we must manually run the adb uninstall commands here as the final task action.
        // This ensures the device is left completely clean, matching standard test runner behaviors.
        println("🧹 Performing automated post-test device cleanup...")
        try {
            ProcessBuilder("adb", "uninstall", packageId).start().waitFor()
            ProcessBuilder("adb", "uninstall", "$packageId.test").start().waitFor()
            println("Successfully uninstalled test APKs from device.")
        } catch (e: Exception) {
            println("Failed to execute automated device cleanup: ${e.message}")
        }
    }
}

// Bind the hook to run automatically after tests complete
tasks.configureEach {
    if (name == "connectedDebugAndroidTest") {
        finalizedBy("embedTestResultImages")
    }
}
