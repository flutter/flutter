package com.tekartik.sqflite;

import android.os.Handler;
import android.os.HandlerThread;

import java.util.LinkedList;
import java.util.ListIterator;

/**
 * Pool that assigns {@link DatabaseTask} to {@link DatabaseWorker}.
 */
public interface DatabaseWorkerPool {
    void start();
    void quit();

    // Posts a new task.
    //
    // Some rules for assigning a task to a worker.
    // - All tasks in a transaction go to the same worker. Otherwise errors will happen.
    // - All tasks belonging to the same database run in FIFO manner. No overlapping between any
    //   two tasks.
    // - Tasks belonging to different databases could be run simultaneously but not necessarily
    //   in FIFO manner.
    void post(Database database, Runnable runnable);

    static DatabaseWorkerPool create(String name, int numberOfWorkers, int priority) {
        if (numberOfWorkers == 1) {
            return new SingleDatabaseWorkerPoolImpl(name, priority);
        }
        return new DatabaseWorkerPoolImpl(name, numberOfWorkers, priority);
    }
}

class SingleDatabaseWorkerPoolImpl implements DatabaseWorkerPool {

    final String name;
    final int priority;

    private HandlerThread handlerThread;
    private Handler handler;

    SingleDatabaseWorkerPoolImpl(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }

    @Override
    public void start() {
        handlerThread = new HandlerThread(name, priority);
        handlerThread.start();
        handler = new Handler(handlerThread.getLooper());
    }

    @Override
    public void quit() {
        if (handlerThread != null) {
            handlerThread.quit();
            handlerThread = null;
            handler = null;
        }
    }

    @Override
    public void post(Database database, Runnable runnable) {
        handler.post(runnable);
    }
}

class DatabaseWorkerPoolImpl implements DatabaseWorkerPool {

    final String name;
    final int numberOfWorkers;
    final int priority;

    private final LinkedList<DatabaseTask> waitingList = new LinkedList<>();
    private final LinkedList<DatabaseWorker> idleWorkers = new LinkedList<>();
    private final LinkedList<DatabaseWorker> busyWorkers = new LinkedList<>();

    DatabaseWorkerPoolImpl(String name, int numberOfWorkers, int priority) {
        this.name = name;
        this.numberOfWorkers = numberOfWorkers;
        this.priority = priority;
    }

    @Override
    public synchronized void start() {
        for (int i = 0; i < numberOfWorkers; i++) {
            DatabaseWorker worker = new DatabaseWorker(name + i, priority);
            worker.start(
                    () -> {
                        onWorkerIdle(worker);
                    });
            idleWorkers.add(worker);
        }
    }

    @Override
    public synchronized void quit() {
        for (DatabaseWorker worker : idleWorkers) {
            worker.quit();
        }
        for (DatabaseWorker worker : busyWorkers) {
            worker.quit();
        }
    }

    @Override
    public synchronized void post(Database database, Runnable runnable) {
        DatabaseTask task = new DatabaseTask(database, runnable);

        // Try finding a worker that is already working for the database of the task.
        //
        // Only run this branch when no tasks are waiting. Otherwise waiting tasks could get
        // starved if following tasks keep cutting in the queue.
        if (waitingList.isEmpty()) {
            for (DatabaseWorker worker : busyWorkers) {
                if (worker.accept(task)) {
                    return;
                }
            }
        }

        // Wait in the list.
        waitingList.add(task);

        // Try finding a idle worker.
        for (DatabaseWorker worker : idleWorkers) {
            findTasksForIdleWorker(worker);
            if (worker.isBusy()) {
                busyWorkers.add(worker);
                idleWorkers.remove(worker);
                return;
            }
        }
    }

    private synchronized void onWorkerIdle(DatabaseWorker worker) {
        findTasksForIdleWorker(worker);
        if (worker.isIdle()) {
            busyWorkers.remove(worker);
            idleWorkers.add(worker);
        }
    }

    private synchronized void findTasksForIdleWorker(DatabaseWorker worker) {
        ListIterator<DatabaseTask> iter = waitingList.listIterator();

        // Find the first task that can be accepted by the worker.
        while (iter.hasNext()) {
            if (worker.accept(iter.next())) {
                iter.remove();
                break;
            }
        }

        // If a following task is accepted by the worker, keep moving it to the worker.
        while (iter.hasNext()) {
            if (worker.accept(iter.next())) {
                iter.remove();
            } else {
                break;
            }
        }
    }
}
