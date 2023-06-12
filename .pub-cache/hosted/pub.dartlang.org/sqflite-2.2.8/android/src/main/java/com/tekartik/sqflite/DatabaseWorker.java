package com.tekartik.sqflite;

import android.os.Handler;
import android.os.HandlerThread;

/**
 * Worker that accepts {@link DatabaseTask}.
 *
 * <p>Each worker instance run on one thread.
 */
class DatabaseWorker {

    private final String name;
    private final int priority;

    private HandlerThread handlerThread;
    private Handler handler;
    protected Runnable onIdle;

    private DatabaseTask lastTask;

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

    boolean isLastTaskInTransaction() {
        return lastTask != null && lastTask.isInTransaction();
    }

    Integer lastTaskDatabaseId() {
        return lastTask != null ? lastTask.getDatabaseId() : null;
    }

    void postTask(final DatabaseTask task) {
        handler.post(() -> this.work(task));
    }

    void work(DatabaseTask task) {
        task.runnable.run();
        lastTask = task;
        onIdle.run();
    }
}
