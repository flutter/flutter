// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.nio.file.Path
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CopyFlutterAssetsTaskTest {
    @Test
    fun `stages flutter_assets under the destination directory with user read and write permissions`(
        @TempDir tempDir: Path
    ) {
        val project = ProjectBuilder.builder().withProjectDir(tempDir.resolve("project").toFile()).build()
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        val assetFile = intermediateDir.resolve("flutter_assets/sub/asset.txt")
        assetFile.parentFile.mkdirs()
        assetFile.writeText("asset-bytes")
        assetFile.setWritable(false)
        // Files outside flutter_assets (e.g. app.so snapshots) must not be staged as assets.
        val nonAssetFile = intermediateDir.resolve("arm64_v8a/app.so")
        nonAssetFile.parentFile.mkdirs()
        nonAssetFile.writeText("not-an-asset")
        val destinationDir = tempDir.resolve("staged").toFile()

        val task =
            project.tasks
                .register("testCopyFlutterAssets", CopyFlutterAssetsTask::class.java) {
                    it.intermediateDir.set(intermediateDir)
                    it.destinationDir.set(destinationDir)
                }.get()

        task.copy()

        val stagedAsset = destinationDir.resolve("flutter_assets/sub/asset.txt")
        assertTrue(stagedAsset.isFile, "expected $stagedAsset to be staged")
        assertTrue(stagedAsset.canRead(), "staged asset should be user-readable")
        assertTrue(stagedAsset.canWrite(), "staged asset should be user-writable")
        assertFalse(
            destinationDir.resolve("arm64_v8a/app.so").exists(),
            "only flutter_assets content should be staged"
        )
    }

    @Test
    fun `clears the destination directory when there is no flutter build for the variant`(
        @TempDir tempDir: Path
    ) {
        val project = ProjectBuilder.builder().withProjectDir(tempDir.resolve("project").toFile()).build()
        val destinationDir = tempDir.resolve("staged").toFile()
        val staleFile = destinationDir.resolve("flutter_assets/stale.txt")
        staleFile.parentFile.mkdirs()
        staleFile.writeText("stale")

        val task =
            project.tasks
                .register("testCopyFlutterAssets", CopyFlutterAssetsTask::class.java) {
                    it.destinationDir.set(destinationDir)
                }.get()

        task.copy()

        assertFalse(staleFile.exists(), "stale staged assets should be removed")
    }
}
