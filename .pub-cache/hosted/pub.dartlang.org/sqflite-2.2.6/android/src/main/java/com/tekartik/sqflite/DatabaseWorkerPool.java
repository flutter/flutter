package com.tekartik.sqflite;

import android.os.Handler;
import android.os.HandlerThread;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Map;
import java.util.Set;

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
    void post(DatabaseTask task);

    default void post(Database database, Runnable runnable) {
        DatabaseDelegate delegate = database == null ? null : new DatabaseDelegate() {
            @Override
            public int getDatabaseId() {
                return database.id;
            }

            @Override
            public boolean isInTransaction() {
                return database.isInTransaction();
            }
        };
        this.post(new DatabaseTask(delegate, runnable));
    }

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
    public void post(DatabaseTask task) {
        handler.post(task.runnable);
    }
}

class DatabaseWorkerPoolImpl implements DatabaseWorkerPool {

    final String name;
    final int numberOfWorkers;
    final int priority;

    private final LinkedList<DatabaseTask> waitingList = new LinkedList<>();
    private final Set<DatabaseWorker> idleWorkers = new HashSet<>();
    private final Set<DatabaseWorker> busyWorkers = new HashSet<>();

    // A map from database id to the only eligible worker.
    //
    // When a database id is found in the map, tasks of the database should only be run by the
    // corresponding worker. Otherwise, any worker is eligible.
    private final Map<Integer, DatabaseWorker> onlyEligibleWorkers = new HashMap<>();

    DatabaseWorkerPoolImpl(String name, int numberOfWorkers, int priority) {
        this.name = name;
        this.numberOfWorkers = numberOfWorkers;
        this.priority = priority;
    }

    @Override
    public synchronized void start() {
        for (int i = 0; i < numberOfWorkers; i++) {
            DatabaseWorker worker = createWorker(name + i, priority);
            worker.start(
                    () -> {
                        onWorkerIdle(worker);
                    });
            idleWorkers.add(worker);
        }
    }

    protected DatabaseWorker createWorker(String name, int priority) {
        return new DatabaseWorker(name, priority);
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
    public synchronized void post(DatabaseTask task) {
        waitingList.add(task);

        Set<DatabaseWorker> workers = new HashSet<>(idleWorkers);
        for (DatabaseWorker worker : workers) {
            tryPostingTaskToWorker(worker);
        }
    }

    private synchronized void tryPostingTaskToWorker(DatabaseWorker worker) {
        DatabaseTask task = findTaskForWorker(worker);
        if (task != null) {
            // Mark the worker busy.
            busyWorkers.add(worker);
            idleWorkers.remove(worker);

            // Since now, the worker is the only eligible one to work on the corresponding database.
            // Allowing others to work on the same database could break the "FIFO manner".
            if (task.getDatabaseId() != null) {
                onlyEligibleWorkers.put(task.getDatabaseId(), worker);
            }
            worker.postTask(task);
        }
    }

    private synchronized DatabaseTask findTaskForWorker(DatabaseWorker worker) {
        ListIterator<DatabaseTask> iter = waitingList.listIterator();
        while (iter.hasNext()) {
            DatabaseTask task = iter.next();
            DatabaseWorker onlyEligibleWorker = null;
            if (task.getDatabaseId() != null) {
                onlyEligibleWorker = onlyEligibleWorkers.get(task.getDatabaseId());
            }
            // Skip current task when the worker is not eligible for it.
            if (onlyEligibleWorker != null && onlyEligibleWorker != worker) {
                continue;
            } else {
                iter.remove();
                return task;
            }
        }
        return null;
    }

    private synchronized void onWorkerIdle(DatabaseWorker worker) {
        // Clone idleWorkers before it get modified.
        Set<DatabaseWorker> others = new HashSet<>(idleWorkers);

        // Mark the worker idle.
        busyWorkers.remove(worker);
        idleWorkers.add(worker);

        // The last task was done and any other worker is eligible to work on the corresponding
        // database since then. However, there is one exception that the last task is in
        // transaction and current worker is still the only eligible one.
        if (!worker.isLastTaskInTransaction() && worker.lastTaskDatabaseId() != null) {
            onlyEligibleWorkers.remove(worker.lastTaskDatabaseId());
        }
        tryPostingTaskToWorker(worker);

        // The eligible relationship was changed above. Try posting tasks again.
        for (DatabaseWorker other : others) {
            tryPostingTaskToWorker(other);
        }
    }
}
