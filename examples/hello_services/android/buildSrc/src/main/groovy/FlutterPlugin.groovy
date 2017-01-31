// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.gradle

import java.nio.file.Path
import java.nio.file.Paths

import com.android.builder.model.AndroidProject
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.Plugin
import org.gradle.api.Task
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.bundling.Jar

class FlutterPlugin implements Plugin<Project> {
    private File flutterRoot
    private String localEngine
    private Properties localProperties

    private String resolveProperty(Project project, String name, String defaultValue) {
        if (localProperties == null) {
            localProperties = new Properties()
            def localPropertiesFile = project.rootProject.file("local.properties")
            if (localPropertiesFile.exists()) {
                localProperties.load(localPropertiesFile.newDataInputStream())
            }
        }
        String result;
        if (project.hasProperty(name)) {
            result = project.property(name)
        }
        if (result == null) {
            result = localProperties.getProperty(name)
        }
        if (result == null) {
            result = defaultValue
        }
        return result
    }

    @Override
    void apply(Project project) {
        // Add a 'profile' build type
        project.android.buildTypes {
            profile {
                initWith debug
            }
        }

        String flutterRootPath = resolveProperty(project, "flutter.sdk", System.env.FLUTTER_HOME)
        if (flutterRootPath == null) {
            throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file or with a FLUTTER_HOME environment variable.")
        }
        flutterRoot = project.file(flutterRootPath)
        if (!flutterRoot.isDirectory()) {
            throw new GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        String flutterJarPath = localProperties.getProperty("flutter.jar")
        if (flutterJarPath != null) {
            File flutterJar = project.file(flutterJarPath)
            if (!flutterJar.isFile()) {
                throw new GradleException("flutter.jar must point to a Flutter engine JAR")
            }
            project.dependencies {
                compile project.files(flutterJar)
            }
        } else {
            Path baseEnginePath = Paths.get(flutterRoot.absolutePath, "bin", "cache", "artifacts", "engine")
            File debugFlutterJar = baseEnginePath.resolve("android-arm").resolve("flutter.jar").toFile()
            File profileFlutterJar = baseEnginePath.resolve("android-arm-profile").resolve("flutter.jar").toFile()
            File releaseFlutterJar = baseEnginePath.resolve("android-arm-release").resolve("flutter.jar").toFile()
            if (!debugFlutterJar.isFile()) {
                project.exec {
                    executable "${flutterRoot}/bin/flutter"
                    args "precache"
                }
                if (!debugFlutterJar.isFile()) {
                    throw new GradleException("Unable to find flutter.jar in SDK: ${debugFlutterJar}")
                }
            }

            // Add x86/x86_64 native library. Debug mode only, for now.
            File flutterX86Jar = project.file("${project.buildDir}/${AndroidProject.FD_INTERMEDIATES}/flutter/flutter-x86.jar")
            project.tasks.create("flutterBuildX86Jar", Jar) {
                destinationDir flutterX86Jar.parentFile
                archiveName flutterX86Jar.name
                from("${flutterRoot}/bin/cache/artifacts/engine/android-x86/libsky_shell.so") {
                    into "lib/x86"
                }
                from("${flutterRoot}/bin/cache/artifacts/engine/android-x64/libsky_shell.so") {
                    into "lib/x86_64"
                }
            }

            project.dependencies {
                debugCompile project.files(flutterX86Jar, debugFlutterJar)
                profileCompile project.files(profileFlutterJar)
                releaseCompile project.files(releaseFlutterJar)
            }
        }

        localEngine = localProperties.getProperty("flutter.localEngine")

        project.extensions.create("flutter", FlutterExtension)
        project.afterEvaluate this.&addFlutterTask
    }

    private void addFlutterTask(Project project) {
        if (project.flutter.source == null) {
            throw new GradleException("Must provide Flutter source directory")
        }

        String target = project.flutter.target
        if (target == null) {
            target = 'lib/main.dart'
        }

        project.compileDebugJavaWithJavac.dependsOn project.flutterBuildX86Jar

        project.android.applicationVariants.all { variant ->
            if (!["debug", "profile", "release"].contains(variant.name)) {
                throw new GradleException("Build variant must be one of \"debug\", \"profile\", or \"release\" but was \"${variant.name}\"")
            }

            FlutterTask flutterTask = project.tasks.create("flutterBuild${variant.name.capitalize()}", FlutterTask) {
                flutterRoot this.flutterRoot
                buildMode variant.name
                localEngine this.localEngine
                targetPath target
                sourceDir project.file(project.flutter.source)
                intermediateDir project.file("${project.buildDir}/${AndroidProject.FD_INTERMEDIATES}/flutter/${variant.name}")
            }

            Task copyFlxTask = project.tasks.create(name: "copyFlutterAssets${variant.name.capitalize()}", type: Copy) {
                dependsOn flutterTask
                dependsOn variant.mergeAssets
                into variant.mergeAssets.outputDir
                with flutterTask.assets
            }
            variant.outputs[0].processResources.dependsOn(copyFlxTask)
        }
    }
}

class FlutterExtension {
    String source
    String target
}

class FlutterTask extends DefaultTask {
    File flutterRoot
    String buildMode
    String localEngine
    String targetPath

    File sourceDir

    @OutputDirectory
    File intermediateDir

    CopySpec getAssets() {
        return project.copySpec {
            from "${intermediateDir}/app.flx"
            if (buildMode != 'debug') {
                from "${intermediateDir}/vm_snapshot_data"
                from "${intermediateDir}/vm_snapshot_instr"
                from "${intermediateDir}/isolate_snapshot_data"
                from "${intermediateDir}/isolate_snapshot_instr"
            }
        }
    }

    @InputFiles
    FileCollection getSourceFiles() {
        return project.fileTree(dir: sourceDir, exclude: ['android', 'ios'], include: ['**/*.dart', 'pubspec.yaml', 'flutter.yaml'])
    }

    @TaskAction
    void build() {
        if (!sourceDir.isDirectory()) {
            throw new GradleException("Invalid Flutter source directory: ${sourceDir}")
        }

        intermediateDir.mkdirs()

        if (buildMode != "debug") {
            project.exec {
                executable "${flutterRoot}/bin/flutter"
                workingDir sourceDir
                if (localEngine != null) {
                    args "--local-engine", localEngine
                }
                args "build", "aot"
                args "--target", targetPath
                args "--target-platform", "android-arm"
                args "--output-dir", "${intermediateDir}"
                args "--${buildMode}"
            }
        }

        project.exec {
            executable "${flutterRoot}/bin/flutter"
            workingDir sourceDir
            if (localEngine != null) {
                args "--local-engine", localEngine
            }
            args "build", "flx"
            args "--target", targetPath
            args "--output-file", "${intermediateDir}/app.flx"
            if (buildMode != "debug") {
                args "--precompiled"
            } else {
                args "--snapshot", "${intermediateDir}/snapshot_blob.bin"
                args "--depfile", "${intermediateDir}/snapshot_blob.bin.d"
            }
            args "--working-dir", "${intermediateDir}/flx"
        }
    }
}
