// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.gradle

import com.android.builder.model.AndroidProject
import com.google.common.base.Joiner
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.Plugin
import org.gradle.api.Task
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction

class FlutterPlugin implements Plugin<Project> {
    private File flutterRoot
    private String buildMode
    private String localEngine

    @Override
    void apply(Project project) {
        Properties properties = new Properties()
        properties.load(project.rootProject.file("local.properties").newDataInputStream())

        String flutterRootPath = properties.getProperty("flutter.sdk")
        if (flutterRootPath == null) {
            throw new GradleException("flutter.sdk must be defined in local.properties")
        }
        flutterRoot = project.file(flutterRootPath)
        if (!flutterRoot.isDirectory()) {
            throw new GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        buildMode = properties.getProperty("flutter.buildMode")
        if (buildMode == null) {
            buildMode = "release"
        }
        if (!["debug", "profile", "release"].contains(buildMode)) {
            throw new GradleException("flutter.buildMode must be one of \"debug\", \"profile\", or \"release\" but was \"${buildMode}\"")
        }

        File flutterJar
        String flutterJarPath = properties.getProperty("flutter.jar")
        if (flutterJarPath != null) {
            flutterJar = project.file(flutterJarPath)
            if (!flutterJar.isFile()) {
                throw new GradleException("flutter.jar must point to a Flutter engine JAR")
            }
        } else {
            // TODO(abarth): Support x64 and x86 in addition to arm.
            String artifactType = "unknown";
            if (buildMode == "debug") {
                artifactType = "android-arm"
            } else if (buildMode == "profile") {
                artifactType = "android-arm-profile"
            } else if (buildMode == "release") {
                artifactType = "android-arm-release"
            }
            flutterJar = new File(flutterRoot, Joiner.on(File.separatorChar).join(
                "bin", "cache", "artifacts", "engine", artifactType, "flutter.jar"))
            if (!flutterJar.isFile()) {
                project.exec {
                    executable "${flutterRoot}/bin/flutter"
                    args "precache"
                }
                if (!flutterJar.isFile()) {
                    throw new GradleException("Unable to find flutter.jar in SDK: ${flutterJar}")
                }
            }
        }

        localEngine = properties.getProperty("flutter.localEngine")

        project.extensions.create("flutter", FlutterExtension)
        project.dependencies.add("compile", project.files(flutterJar))
        project.afterEvaluate this.&addFlutterTask
    }

    private void addFlutterTask(Project project) {
        if (project.flutter.source == null) {
            throw new GradleException("Must provide Flutter source directory")
        }

        String target = project.flutter.target;
        if (target == null) {
            target = 'lib/main.dart'
        }

        FlutterTask flutterTask = project.tasks.create("flutterBuild", FlutterTask) {
            flutterRoot this.flutterRoot
            buildMode this.buildMode
            localEngine this.localEngine
            targetPath target
            sourceDir project.file(project.flutter.source)
            intermediateDir project.file("${project.buildDir}/${AndroidProject.FD_INTERMEDIATES}/flutter")
        }

        project.android.applicationVariants.all { variant ->
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

    @InputDirectory
    File sourceDir

    @OutputDirectory
    File intermediateDir

    CopySpec getAssets() {
        return project.copySpec {
            from "${intermediateDir}/app.flx"
            if (buildMode != 'debug') {
                from "${intermediateDir}/snapshot_aot_instr"
                from "${intermediateDir}/snapshot_aot_isolate"
                from "${intermediateDir}/snapshot_aot_rodata"
                from "${intermediateDir}/snapshot_aot_vmisolate"
            }
        }
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
