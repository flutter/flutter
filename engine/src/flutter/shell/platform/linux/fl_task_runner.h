// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_TASK_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_TASK_RUNNER_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlTaskRunner, fl_task_runner, FL, TASK_RUNNER, GObject);

/**
 * fl_task_runner_new:
 * @engine: the #FlEngine owning the task runner.
 *
 * Creates new task runner instance.
 *
 * Returns: an #FlTaskRunner.
 */
FlTaskRunner* fl_task_runner_new(FlEngine* engine);

/**
 * fl_task_runner_post_flutter_task:
 * @task_runner: an #FlTaskRunner.
 * @task: Flutter task being scheduled
 * @target_time_nanos: absolute time in nanoseconds
 *
 * Posts a Flutter task to be executed on main thread. This function is thread
 * safe and may be called from any thread.
 */
void fl_task_runner_post_flutter_task(FlTaskRunner* task_runner,
                                      FlutterTask task,
                                      uint64_t target_time_nanos);

/**
 * fl_task_runner_wait:
 * @task_runner: an #FlTaskRunner.
 *
 * Block until the next task is ready and then perform it. May be interrupted by
 * fl_task_runner_stop_wait(), in which case no task is run but execution will
 * be returned to the caller.
 *
 * Must be called only by the GTK thread.
 */
void fl_task_runner_wait(FlTaskRunner* task_runner);

/**
 * fl_task_runner_stop_wait:
 * @task_runner: an #FlTaskRunner.
 *
 * Cause fl_task_runner_wait() to complete. May be called even if
 * fl_task_runner_wait() is not being used.
 *
 * May be called by any thread.
 */
void fl_task_runner_stop_wait(FlTaskRunner* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_TASK_RUNNER_H_
