// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import java.io.File
import java.io.ByteArrayOutputStream
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

        // 1. Query the device sandbox to list all files in cache/results/
        val stdout = ByteArrayOutputStream()
        try {
            exec {
                commandLine("adb", "shell", "run-as", packageId, "ls", "cache/results")
                standardOutput = stdout
                isIgnoreExitValue = true 
            }

            // Parse the output lines into a clean list of filenames
            val files = stdout.toString().trim().split(Regex("\\r?\\n"))

            // 2. Iterate through all discovered files and pull PNGs
            for (rawFileName in files) {
                val fileName = rawFileName.trim()
                if (fileName.endsWith(".png")) {
                    // Extract the clean test case name (e.g. "blueRectangleTest") before any dot-separators
                    val testName = fileName.split(".")[0]
                    discoveredTests.add(Pair(testName, fileName))

                    val destinationFile = File(imagesDir, fileName)
                    FileOutputStream(destinationFile).use { os ->
                        exec {
                            commandLine("adb", "exec-out", "run-as", packageId, "cat", "cache/results/$fileName")
                            standardOutput = os
                            isIgnoreExitValue = true
                        }
                    }
                    println("Successfully pulled test result image: ${destinationFile.absolutePath}")
                }
            }
        } catch (e: Exception) {
            println("Failed to query or pull test result images from device: ${e.message}")
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
            exec {
                commandLine("adb", "uninstall", packageId)
                isIgnoreExitValue = true
            }
            exec {
                commandLine("adb", "uninstall", "$packageId.test")
                isIgnoreExitValue = true
            }
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
