// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction

/** Prints a message computed lazily, before the task action runs. */
abstract class PrintTask : DefaultTask() {
    @get:Input
    abstract val message: Property<String>

    @TaskAction
    fun run() = println(message.get())
}
