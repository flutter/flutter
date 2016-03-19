// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.gradle

import com.android.builder.model.AndroidProject
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

    @Override
    void apply(Project project) {
        Properties properties = new Properties()
        properties.load(project.rootProject.file("local.properties").newDataInputStream())

        String enginePath = properties.getProperty("flutter.jar")
        if (enginePath == null) {
            throw new GradleException("flutter.jar must be defined in local.properties")
        }
        FileCollection flutterEngine = project.files(enginePath)
        if (!flutterEngine.singleFile.isFile()) {
            throw new GradleException("flutter.jar must point to a Flutter engine JAR")
        }

        String sdkPath = properties.getProperty("flutter.sdk")
        if (sdkPath == null) {
            throw new GradleException("flutter.sdk must be defined in local.properties")
        }
        sdkDir = project.file(sdkPath)
        if (!sdkDir.isDirectory()) {
            throw new GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        project.extensions.create("flutter", FlutterExtension)
        project.dependencies.add("compile", flutterEngine)
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
            args "build", "flx"
            args "-o", flxPath
            args "--snapshot", "${intermediateDir}/snapshot_blob.bin"
            args "--depfile", "${intermediateDir}/snapshot_blob.bin.d"
            args "--working-dir", "${intermediateDir}/flx"
        }
    }
}
