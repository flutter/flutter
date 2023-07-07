// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.googlesignin;

import androidx.annotation.NonNull;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * A class for running tasks in a background thread.
 *
 * <p>TODO(jackson): If this class is useful for other plugins, consider including it in a shared
 * library or in the Flutter engine
 */
public final class BackgroundTaskRunner {

  /**
   * Interface that callers of this API can implement to be notified when a {@link
   * #runInBackground(Callable,Callback) background task} has completed.
   */
  public interface Callback<T> {
    /**
     * Invoked on the UI thread when the specified future has completed (calling {@code get()} on
     * the future is guaranteed not to block). If the future completed with an exception, then
     * {@code get()} will throw an {@code ExecutionException}.
     */
    void run(@NonNull Future<T> future);
  }

  private final ThreadPoolExecutor executor;

  /**
   * Creates a new background processor with the given number of threads.
   *
   * @param threads The fixed number of threads in ther pool.
   */
  public BackgroundTaskRunner(int threads) {
    BlockingQueue<Runnable> workQueue = new LinkedBlockingQueue<>();
    // Only keeps idle threads open for 1 second if we've got more threads than cores.
    executor = new ThreadPoolExecutor(threads, threads, 1, TimeUnit.SECONDS, workQueue);
  }

  /**
   * Executes the specified task in a background thread and notifies the specified callback once the
   * task has completed (either successfully or with an exception).
   *
   * <p>The callback will be notified on the UI thread.
   */
  public <T> void runInBackground(@NonNull Callable<T> task, final @NonNull Callback<T> callback) {
    final ListenableFuture<T> future = runInBackground(task);
    future.addListener(() -> callback.run(future), Executors.uiThreadExecutor());
  }

  /**
   * Executes the specified task in a background thread and returns a future with which the caller
   * can be notified of task completion.
   *
   * <p>Note: the future will be notified on the background thread. To be notified on the UI thread,
   * use {@link #runInBackground(Callable,Callback)}.
   */
  public @NonNull <T> ListenableFuture<T> runInBackground(final @NonNull Callable<T> task) {
    final SettableFuture<T> future = SettableFuture.create();

    executor.execute(
        () -> {
          if (!future.isCancelled()) {
            try {
              future.set(task.call());
            } catch (Throwable t) {
              future.setException(t);
            }
          }
        });

    return future;
  }
}
