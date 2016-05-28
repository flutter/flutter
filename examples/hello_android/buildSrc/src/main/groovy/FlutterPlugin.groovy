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
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction

class FlutterPlugin implements Plugin<Project> {
    private File sdkDir
    private String localEngine

    @Override
    void apply(Project project) {
        Properties properties = new Properties()
        properties.load(project.rootProject.file("local.properties").newDataInputStream())

        String sdkPath = properties.getProperty("flutter.sdk")
        if (sdkPath == null) {
            throw new GradleException("flutter.sdk must be defined in local.properties")
        }
        sdkDir = project.file(sdkPath)
        if (!sdkDir.isDirectory()) {
            throw new GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        File flutterJar
        String flutterJarPath = properties.getProperty("flutter.jar")
        if (flutterJarPath != null) {
            flutterJar = project.file(flutterJarPath)
            if (!flutterJar.isFile()) {
                throw new GradleException("flutter.jar must point to a Flutter engine JAR")
            }
        } else {
            flutterJar = new File(sdkDir, Joiner.on(File.separatorChar).join(
                "bin", "cache", "artifacts", "engine", "android-arm", "flutter.jar"))
            if (!flutterJar.isFile()) {
                project.exec {
                    executable "${sdkDir}/bin/flutter"
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

        FlutterTask flutterTask = project.tasks.create("flutterBuild", FlutterTask) {
            sdkDir this.sdkDir
            sourceDir project.file(project.flutter.source)
            intermediateDir project.file("${project.buildDir}/${AndroidProject.FD_INTERMEDIATES}/flutter")
            localEngine this.localEngine
        }

        project.android.applicationVariants.all { variant ->
            Task copyFlxTask = project.tasks.create(name: "copyFlx${variant.name.capitalize()}", type: Copy) {
                dependsOn flutterTask
                dependsOn variant.mergeAssets
                from flutterTask.flxPath
                into variant.mergeAssets.outputDir
            }
            variant.outputs[0].processResources.dependsOn(copyFlxTask)
        }
    }
}

class FlutterExtension {
    String source
}

class FlutterTask extends DefaultTask {
    File sdkDir

    @InputDirectory
    File sourceDir

    @OutputDirectory
    File intermediateDir

    String localEngine

    String getFlxPath() {
        return "${intermediateDir}/app.flx"
    }

    @TaskAction
    void build() {
        if (!sourceDir.isDirectory()) {
            throw new GradleException("Invalid Flutter source directory: ${sourceDir}")
        }

        intermediateDir.mkdirs()
        project.exec {
            executable "${sdkDir}/bin/flutter"
            workingDir sourceDir
            if (localEngine != null) {
              args "--local-engine", localEngine
            }
            args "build", "flx"
            args "-o", flxPath
            args "--snapshot", "${intermediateDir}/snapshot_blob.bin"
            args "--depfile", "${intermediateDir}/snapshot_blob.bin.d"
            args "--working-dir", "${intermediateDir}/flx"
        }
    }
}
