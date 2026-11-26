// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir
import java.io.File
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.PosixFilePermission
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class CopyFlutterAssetsTaskTest {
    @Test
    fun `stages flutter_assets under the destination directory with user read and write permissions`(
        @TempDir tempDir: Path
    ) {
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        val assetFile = intermediateDir.writeFile("flutter_assets/sub/asset.txt", "asset-bytes")
        assetFile.setWritable(false)
        // Files outside flutter_assets (e.g. app.so snapshots) must not be staged as assets.
        intermediateDir.writeFile("arm64_v8a/app.so", "not-an-asset")
        val destinationDir = tempDir.resolve("staged").toFile()

        runTask(tempDir, intermediateDir, emptyMergedAssetsDir(tempDir), destinationDir)

        val stagedAsset = destinationDir.resolve("flutter_assets/sub/asset.txt")
        assertTrue(stagedAsset.isFile, "expected $stagedAsset to be staged")
        // The contract is that the staged copy is readable and writable even though the source
        // was not writable, because a packaging step downstream has to be able to replace it.
        assertTrue(stagedAsset.canRead(), "staged asset should be user-readable")
        assertTrue(stagedAsset.canWrite(), "staged asset should be user-writable")
        // Files.getPosixFilePermissions throws UnsupportedOperationException on file systems
        // without a POSIX view, which is the usual case on Windows, so assert the owner bits only
        // where they exist.
        if (FileSystems.getDefault().supportedFileAttributeViews().contains("posix")) {
            val perms = Files.getPosixFilePermissions(stagedAsset.toPath())
            assertTrue(perms.contains(PosixFilePermission.OWNER_READ), "staged asset should have POSIX OWNER_READ")
            assertTrue(perms.contains(PosixFilePermission.OWNER_WRITE), "staged asset should have POSIX OWNER_WRITE")
        }
        assertFalse(
            destinationDir.resolve("arm64_v8a/app.so").exists(),
            "only flutter_assets content should be staged"
        )
    }

    @Test
    fun `removes staged assets that the flutter build does not produce`(
        @TempDir tempDir: Path
    ) {
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        intermediateDir.writeFile("flutter_assets/asset.txt", "asset-bytes")
        val destinationDir = tempDir.resolve("staged").toFile()
        val staleFile = destinationDir.writeFile("flutter_assets/stale.txt", "stale")

        runTask(tempDir, intermediateDir, emptyMergedAssetsDir(tempDir), destinationDir)

        assertFalse(staleFile.exists(), "stale staged assets should be removed")
        assertTrue(destinationDir.resolve("flutter_assets/asset.txt").isFile, "expected the asset to be staged")
    }

    @Test
    fun `stages flutter assets whose names AGP would filter by default`(
        @TempDir tempDir: Path
    ) {
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        val assetPaths =
            listOf(
                // Dropped by AGP's default ignoreAssetsPattern (`.*` and `<dir>_*`).
                "flutter_assets/.env",
                "flutter_assets/assets/.hidden",
                "flutter_assets/assets/_private/asset.txt"
            )
        for (path in assetPaths) {
            intermediateDir.writeFile(path, path)
        }
        val destinationDir = tempDir.resolve("staged").toFile()

        runTask(tempDir, intermediateDir, emptyMergedAssetsDir(tempDir), destinationDir)

        for (path in assetPaths) {
            val stagedAsset = destinationDir.resolve(path)
            assertTrue(stagedAsset.isFile, "expected $path to be staged")
            assertEquals(path, stagedAsset.readText())
        }
    }

    @Test
    fun `excludes files matched by Gradle's default excludes`(
        @TempDir tempDir: Path
    ) {
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        intermediateDir.writeFile("flutter_assets/assets/asset.txt", "asset-bytes")
        val excludedPaths =
            listOf(
                "flutter_assets/assets/.gitignore",
                "flutter_assets/assets/.DS_Store",
                "flutter_assets/assets/._resource_fork",
                "flutter_assets/assets/backup.txt~"
            )
        for (path in excludedPaths) {
            intermediateDir.writeFile(path, path)
        }
        val destinationDir = tempDir.resolve("staged").toFile()

        runTask(tempDir, intermediateDir, emptyMergedAssetsDir(tempDir), destinationDir)

        assertTrue(destinationDir.resolve("flutter_assets/assets/asset.txt").isFile, "expected the asset to be staged")
        for (path in excludedPaths) {
            assertFalse(destinationDir.resolve(path).exists(), "expected $path to be excluded")
        }
    }

    @Test
    fun `keeps the merged Android assets and lets flutter assets win on a collision`(
        @TempDir tempDir: Path
    ) {
        val intermediateDir = tempDir.resolve("intermediate").toFile()
        intermediateDir.writeFile("flutter_assets/assets/collision.txt", "flutter_version")
        val mergedAssetsDir = tempDir.resolve("merged").toFile()
        mergedAssetsDir.writeFile("native_asset.txt", "native_asset_content")
        mergedAssetsDir.writeFile("custom/config.json", "{}")
        mergedAssetsDir.writeFile("flutter_assets/assets/collision.txt", "native_override_version")
        val destinationDir = tempDir.resolve("staged").toFile()

        runTask(tempDir, intermediateDir, mergedAssetsDir, destinationDir)

        assertEquals("native_asset_content", destinationDir.resolve("native_asset.txt").readText())
        assertEquals("{}", destinationDir.resolve("custom/config.json").readText())
        assertEquals(
            "flutter_version",
            destinationDir.resolve("flutter_assets/assets/collision.txt").readText()
        )
    }

    private fun runTask(
        tempDir: Path,
        intermediateDir: File,
        mergedAssetsDir: File,
        destinationDir: File
    ) {
        val project = ProjectBuilder.builder().withProjectDir(tempDir.resolve("project").toFile()).build()
        val task =
            project.tasks
                .register("testCopyFlutterAssets", CopyFlutterAssetsTask::class.java)
                .get()
        task.intermediateDir.set(intermediateDir)
        task.mergedAssetsDir.set(mergedAssetsDir)
        task.destinationDir.set(destinationDir)
        task.copy()
    }

    private fun emptyMergedAssetsDir(tempDir: Path): File = tempDir.resolve("merged").toFile().also { it.mkdirs() }

    private fun File.writeFile(
        relativePath: String,
        contents: String
    ): File =
        resolve(relativePath).also {
            it.parentFile.mkdirs()
            it.writeText(contents)
        }
}
