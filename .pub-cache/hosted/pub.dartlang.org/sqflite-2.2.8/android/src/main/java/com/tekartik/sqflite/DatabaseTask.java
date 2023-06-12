package com.tekartik.sqflite;

import androidx.annotation.Nullable;

interface DatabaseDelegate {
    int getDatabaseId();
    boolean isInTransaction();
}

final class DatabaseTask {

    // Database this task will be run on.
    //
    // It can be null if the task is not running on any database. e.g. closing a NULL database.
    @Nullable
    private final DatabaseDelegate database;
    final Runnable runnable;

    DatabaseTask(DatabaseDelegate database, Runnable runnable) {
        this.database = database;
        this.runnable = runnable;
    }

    public boolean isInTransaction() {
        return database != null && database.isInTransaction();
    }

    public Integer getDatabaseId() {
        return database != null ? database.getDatabaseId() : null;
    }
}
