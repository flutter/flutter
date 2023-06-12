package com.tekartik.sqflite;

import androidx.annotation.Nullable;

import java.util.HashSet;

final class DatabaseTask {

    // Database this task will be run on.
    //
    // It can be null if the task is not running on any database. e.g. closing a NULL database.
    @Nullable
    final Database database;
    final Runnable runnable;

    DatabaseTask(Database database, Runnable runnable) {
        this.database = database;
        this.runnable = runnable;
    }

    boolean isExcludedFrom(HashSet<Integer> allowList) {
        // Do not exclude anyone if the task is not in a transaction.
        if (database == null || !database.isInTransaction()) {
            return false;
        }
        return !allowList.contains(database.id);
    }

    boolean isMatchedWith(@Nullable Database database) {
        if (this.database == null) {
            return database == null;
        } else {
            return this.database.id == database.id;
        }
    }
}
