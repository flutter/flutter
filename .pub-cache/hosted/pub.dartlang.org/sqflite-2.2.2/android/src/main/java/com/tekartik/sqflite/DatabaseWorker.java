package com.tekartik.sqflite;

import android.os.Handler;
import android.os.HandlerThread;

import androidx.annotation.Nullable;

import java.util.HashSet;

/**
 * Worker that accepts {@link DatabaseTask}.
 *
 * <p>Each worker instance run on one thread.
 */
final class DatabaseWorker {

    private final String name;
    private final int priority;

    private HandlerThread handlerThread;
    private Handler handler;
    private Runnable onIdle;

    // Database that this worker is working on.
    @Nullable
    private Database database;
    // This is a list of database id.
    //
    // All tasks in a transaction should go to the same worker (a.k.a. thread). This list tracks
    // what transactional tasks could be run by this worker.
    private HashSet<Integer> transactionAllowList = new HashSet<>();
    private int numberOfRunningTask = 0;

    DatabaseWorker(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }

    synchronized void start(Runnable onIdle) {
        handlerThread = new HandlerThread(name, priority);
        handlerThread.start();
        handler = new Handler(handlerThread.getLooper());
        this.onIdle = onIdle;
    }

    synchronized void quit() {
        if (handlerThread != null) {
            handlerThread.quit();
            handlerThread = null;
            handler = null;
        }
    }

    synchronized boolean isIdle() {
        return numberOfRunningTask == 0;
    }

    synchronized boolean isBusy() {
        return numberOfRunningTask != 0;
    }

    // Accepts or rejects a task.
    synchronized boolean accept(DatabaseTask task) {
        if (task.isExcludedFrom(transactionAllowList)) {
            return false;
        }
        if (isIdle() || task.isMatchedWith(database)) {
            postTask(task);
            return true;
        }
        return false;
    }

    private void postTask(DatabaseTask task) {
        synchronized (this) {
            database = task.database;
            numberOfRunningTask++;
        }
        handler.post(
                () -> {
                    task.runnable.run();
                    synchronized (this) {
                        numberOfRunningTask--;
                        if (database != null) {
                            if (database.isInTransaction()) {
                                transactionAllowList.add(database.id);
                            } else {
                                transactionAllowList.remove(database.id);
                            }
                        }
                        if (isIdle()) {
                            database = null;
                        }
                    }
                    if (isIdle()) {
                        onIdle.run();
                    }
                });
    }
}
