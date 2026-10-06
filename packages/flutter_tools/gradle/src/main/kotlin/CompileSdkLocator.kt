// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import java.io.File

/**
 * Where an Android project's `compileSdk` is declared, for use in error messages.
 *
 * Line numbers are 1-based.
 */
internal sealed class CompileSdkLocation {
    /** The file the user should edit. */
    abstract val file: File

    /** `compileSdk` is set to a literal in a Gradle build script, e.g. `compileSdk = 35`. */
    data class BuildFile(
        override val file: File,
        val line: Int
    ) : CompileSdkLocation()

    /**
     * `compileSdk` references a version catalog entry, e.g.
     * `compileSdk = libs.versions.compileSdk.get().toInt()`.
     */
    data class VersionCatalog(
        override val file: File,
        val line: Int,
        val key: String,
        val referencedFrom: File,
        val referencedFromLine: Int
    ) : CompileSdkLocation()

    /**
     * The declaration could not be resolved to a literal value, e.g. it comes from
     * `rootProject.ext`, a convention plugin, or `buildSrc`.
     *
     * [line] and [expression] are null when no `compileSdk` declaration was found in [file].
     */
    data class Unresolved(
        override val file: File,
        val line: Int?,
        val expression: String?
    ) : CompileSdkLocation()
}

/**
 * Best-effort, text-based lookup of where an Android project's `compileSdk` is declared.
 *
 * This is used only to produce actionable error messages. It never affects the build result,
 * so when the declaration can't be resolved it falls back to [CompileSdkLocation.Unresolved].
 */
internal object CompileSdkLocator {
    private const val DEFAULT_VERSION_CATALOG_PATH = "gradle/libs.versions.toml"

    // Matches `compileSdk = 35`, `compileSdk 35`, `compileSdkVersion 35`, `compileSdkVersion(35)`,
    // `compileSdkPreview = "Baklava"` and the AGP 9 block form opener `compileSdk {`.
    private val compileSdkDeclaration =
        Regex("""^\s*(compileSdk(?:Version|Preview)?)\b\s*(=|\(|\s)?\s*(.*?)\s*(?://.*)?$""")

    // Matches the value inside the AGP 9 block form, e.g. `version = release(36)` or
    // `version = release(36) { minorApiLevel = 1 }`.
    private val blockFormRelease = Regex("""release\(\s*([^)]+?)\s*\)""")
    private val blockFormVersion = Regex("""^\s*version\s*=\s*(.+?)\s*$""")

    private val integerLiteral = Regex("""^\d+$""")
    private val stringLiteral = Regex("""^(["'])[^"']*\1$""")
    private val versionCatalogReference = Regex("""\blibs\.versions\.([A-Za-z0-9_.]+)""")
    private val tomlTableHeader = Regex("""^\s*\[([^\]]+)]\s*$""")

    /**
     * Returns where `compileSdk` is declared for the project whose build script is [buildFile].
     *
     * [rootDir] is the root project directory, used to locate the default version catalog.
     */
    fun locate(
        buildFile: File,
        rootDir: File
    ): CompileSdkLocation {
        if (!buildFile.isFile) {
            return CompileSdkLocation.Unresolved(buildFile, line = null, expression = null)
        }
        val lines = buildFile.readLines()
        for ((index, rawLine) in lines.withIndex()) {
            if (isComment(rawLine)) {
                continue
            }
            val match = compileSdkDeclaration.matchEntire(rawLine) ?: continue
            val lineNumber = index + 1
            val separator = match.groupValues[2]
            var expression = match.groupValues[3].trim()
            if (separator == "(") {
                expression = expression.removeSuffix(")").trim()
            }
            if (expression.startsWith("{")) {
                expression = findBlockFormValue(lines, index) ?: expression
            }
            return classify(expression, buildFile, lineNumber, rootDir)
        }
        return CompileSdkLocation.Unresolved(buildFile, line = null, expression = null)
    }

    private fun isComment(line: String): Boolean {
        val trimmed = line.trimStart()
        return trimmed.startsWith("//") || trimmed.startsWith("*") || trimmed.startsWith("/*")
    }

    /** Finds the `release(<value>)` or `version = <value>` inside a `compileSdk { ... }` block. */
    private fun findBlockFormValue(
        lines: List<String>,
        openingLineIndex: Int
    ): String? {
        var depth = 0
        for (index in openingLineIndex until lines.size) {
            val line = lines[index]
            blockFormRelease.find(line)?.let { return it.groupValues[1] }
            if (index != openingLineIndex) {
                blockFormVersion.matchEntire(line)?.let { return it.groupValues[1] }
            }
            depth += line.count { it == '{' } - line.count { it == '}' }
            if (depth <= 0 && index != openingLineIndex) {
                return null
            }
        }
        return null
    }

    private fun classify(
        expression: String,
        buildFile: File,
        lineNumber: Int,
        rootDir: File
    ): CompileSdkLocation {
        if (integerLiteral.matches(expression) || stringLiteral.matches(expression)) {
            return CompileSdkLocation.BuildFile(buildFile, lineNumber)
        }
        val catalogMatch = versionCatalogReference.find(expression)
        if (catalogMatch != null) {
            val accessorPath = stripAccessorSuffix(catalogMatch.groupValues[1])
            val catalogFile = File(rootDir, DEFAULT_VERSION_CATALOG_PATH)
            val entry = findVersionCatalogEntry(catalogFile, accessorPath)
            if (entry != null) {
                return CompileSdkLocation.VersionCatalog(
                    file = catalogFile,
                    line = entry.second,
                    key = entry.first,
                    referencedFrom = buildFile,
                    referencedFromLine = lineNumber
                )
            }
        }
        return CompileSdkLocation.Unresolved(buildFile, lineNumber, expression)
    }

    /** Removes trailing accessor calls, e.g. `compileSdk.get` -> `compileSdk`. */
    private fun stripAccessorSuffix(accessorPath: String): String {
        val terminalSegments = setOf("get", "getOrNull", "toInt", "toInteger", "orNull")
        val segments = accessorPath.split('.').filter { it.isNotEmpty() }
        val end = segments.indexOfFirst { it in terminalSegments }.let { if (it == -1) segments.size else it }
        return segments.subList(0, end).joinToString(".")
    }

    /**
     * Finds the `[versions]` entry in [catalogFile] whose generated accessor matches
     * [accessorPath]. Gradle maps `-`, `_` and `.` in catalog aliases to `.` in accessors.
     *
     * Returns the entry's key as written in the file and its 1-based line number.
     */
    private fun findVersionCatalogEntry(
        catalogFile: File,
        accessorPath: String
    ): Pair<String, Int>? {
        if (!catalogFile.isFile || accessorPath.isEmpty()) {
            return null
        }
        val normalizedAccessor = normalizeAlias(accessorPath)
        var inVersionsTable = false
        for ((index, line) in catalogFile.readLines().withIndex()) {
            val header = tomlTableHeader.matchEntire(line)
            if (header != null) {
                inVersionsTable = header.groupValues[1].trim() == "versions"
                continue
            }
            if (!inVersionsTable) {
                continue
            }
            val key =
                line
                    .substringBefore('=', missingDelimiterValue = "")
                    .trim()
                    .removeSurrounding("\"")
            if (key.isNotEmpty() && normalizeAlias(key) == normalizedAccessor) {
                return key to index + 1
            }
        }
        return null
    }

    private fun normalizeAlias(alias: String): String = alias.replace('-', '.').replace('_', '.').lowercase()
}
