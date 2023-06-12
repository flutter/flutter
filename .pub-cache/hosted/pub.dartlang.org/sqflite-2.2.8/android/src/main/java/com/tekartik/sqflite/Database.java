package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.EMPTY_STRING_ARRAY;
import static com.tekartik.sqflite.Constant.ERROR_BAD_PARAM;
import static com.tekartik.sqflite.Constant.METHOD_EXECUTE;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.METHOD_QUERY;
import static com.tekartik.sqflite.Constant.METHOD_UPDATE;
import static com.tekartik.sqflite.Constant.PARAM_CANCEL;
import static com.tekartik.sqflite.Constant.PARAM_COLUMNS;
import static com.tekartik.sqflite.Constant.PARAM_CURSOR_ID;
import static com.tekartik.sqflite.Constant.PARAM_CURSOR_PAGE_SIZE;
import static com.tekartik.sqflite.Constant.PARAM_OPERATIONS;
import static com.tekartik.sqflite.Constant.PARAM_ROWS;
import static com.tekartik.sqflite.Constant.PARAM_TRANSACTION_ID;
import static com.tekartik.sqflite.Constant.TAG;
import static com.tekartik.sqflite.Constant.TRANSACTION_ID_FORCE;
import static com.tekartik.sqflite.Utils.cursorRowToList;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.DatabaseErrorHandler;
import android.database.SQLException;
import android.database.sqlite.SQLiteCantOpenDatabaseException;
import android.database.sqlite.SQLiteCursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import com.tekartik.sqflite.operation.BatchOperation;
import com.tekartik.sqflite.operation.MethodCallOperation;
import com.tekartik.sqflite.operation.Operation;
import com.tekartik.sqflite.operation.QueuedOperation;
import com.tekartik.sqflite.operation.SqlErrorInfo;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

class Database {
    // To turn on when supported fully
    // 2022-09-14 experiments show several corruption issue.
    final static boolean WAL_ENABLED_BY_DEFAULT = false;
    private static final String WAL_ENABLED_META_NAME = "com.tekartik.sqflite.wal_enabled";
    static private Boolean walGloballyEnabled;
    final boolean singleInstance;
    @NonNull
    final String path;
    final int id;
    final int logLevel;
    @NonNull
    final Context context;
    /// Delayed operations not in the current transaction.
    final List<QueuedOperation> noTransactionOperationQueue = new ArrayList<>();
    final Map<Integer, SqfliteCursor> cursors = new HashMap<>();
    // Set by plugin
    public DatabaseWorkerPool databaseWorkerPool;
    @Nullable
    SQLiteDatabase sqliteDatabase;
    private int transactionDepth = 0;
    // Transaction
    private int lastTransactionId = 0; // incremental transaction id
    @Nullable
    private Integer currentTransactionId;
    // Cursors
    private int lastCursorId = 0; // incremental cursor id

    Database(Context context, String path, int id, boolean singleInstance, int logLevel) {
        this.context = context;
        this.path = path;
        this.singleInstance = singleInstance;
        this.id = id;
        this.logLevel = logLevel;
    }

    @VisibleForTesting
    @NotNull
    static protected boolean checkWalEnabled(Context context) {
        return checkMetaBoolean(context, WAL_ENABLED_META_NAME, WAL_ENABLED_BY_DEFAULT);
    }

    @SuppressWarnings("deprecation")
    static ApplicationInfo getApplicationInfoWithMeta32(Context context, String packageName, int flags) throws PackageManager.NameNotFoundException {
        return context.getPackageManager().getApplicationInfo(packageName, flags);
    }

    @VisibleForTesting
    @NotNull
    static protected boolean checkMetaBoolean(Context context, String metaKey, boolean defaultValue) {
        try {
            final String packageName = context.getPackageName();
            ApplicationInfo applicationInfo;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                applicationInfo = context.getPackageManager().getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA));
            } else {
                applicationInfo = getApplicationInfoWithMeta32(context, packageName, PackageManager.GET_META_DATA);
            }
            final boolean walEnabled = applicationInfo.metaData.getBoolean(metaKey, defaultValue);
            if (walEnabled) {
                return true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }


    static void deleteDatabase(String path) {
        SQLiteDatabase.deleteDatabase(new File(path));
    }

    /**
     * Never fails
     */
    public static boolean existsDatabase(String path) {
        boolean exists = false;
        try {
            exists = new File(path).exists();
        } catch (Exception ignore) {
        }
        return exists;
    }

    public void open() {
        int flags = SQLiteDatabase.CREATE_IF_NECESSARY;

        // Check meta data only once
        if (walGloballyEnabled == null) {
            walGloballyEnabled = checkWalEnabled(context);
            if (walGloballyEnabled) {
                if (LogLevel.hasVerboseLevel(logLevel)) {
                    Log.d(TAG, getThreadLogPrefix() + "[sqflite] WAL enabled");
                }
            }
        }
        if (walGloballyEnabled) {
            // Turned on since 2.1.0-dev.1
            flags |= SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING;
        }

        sqliteDatabase = SQLiteDatabase.openDatabase(path, null, flags);
    }

    // Change default error handler to avoid erasing the existing file.
    public void openReadOnly() {
        sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                SQLiteDatabase.OPEN_READONLY, new DatabaseErrorHandler() {
                    @Override
                    public void onCorruption(SQLiteDatabase dbObj) {
                        // ignored
                        // default implementation delete the file
                        //
                        // This happens asynchronously so cannot be tracked. However a simple
                        // access should fail
                    }
                });
    }

    public void close() {
        if (!cursors.isEmpty()) {
            if (LogLevel.hasSqlLevel(logLevel)) {
                Log.d(TAG, getThreadLogPrefix() + cursors.size() + " cursor(s) are left opened");
            }
        }
        sqliteDatabase.close();
    }

    public SQLiteDatabase getWritableDatabase() {
        return sqliteDatabase;
    }

    public SQLiteDatabase getReadableDatabase() {
        return sqliteDatabase;
    }

    public boolean enableWriteAheadLogging() {
        try {
            return sqliteDatabase.enableWriteAheadLogging();
        } catch (Exception e) {
            Log.e(TAG, getThreadLogPrefix() + "enable WAL error: " + e);
            return false;
        }
    }

    String getThreadLogTag() {
        Thread thread = Thread.currentThread();

        return "" + id + "," + thread.getName() + "(" + thread.getId() + ")";
    }

    String getThreadLogPrefix() {
        return "[" + getThreadLogTag() + "] ";
    }

    private Map<String, Object> cursorToResults(Cursor cursor, @Nullable Integer cursorPageSize) {
        Map<String, Object> results = null;
        List<List<Object>> rows = null;
        int columnCount = 0;
        while (cursor.moveToNext()) {

            if (results == null) {
                rows = new ArrayList<>();
                results = new HashMap<>();
                columnCount = cursor.getColumnCount();
                results.put(PARAM_COLUMNS, Arrays.asList(cursor.getColumnNames()));
                results.put(PARAM_ROWS, rows);
            }
            rows.add(cursorRowToList(cursor, columnCount));

            // Paging support
            if (cursorPageSize != null) {
                if (rows.size() >= cursorPageSize) {
                    break;
                }
            }
        }
        // Handle empty
        if (results == null) {
            results = new HashMap<>();
        }

        return results;
    }

    private void runQueuedOperations() {
        while (!noTransactionOperationQueue.isEmpty()) {
            if (currentTransactionId != null) {
                break;
            }
            QueuedOperation queuedOperation = noTransactionOperationQueue.get(0);
            queuedOperation.run();
            noTransactionOperationQueue.remove(0);
        }
    }

    private void wrapSqlOperationHandler(final @NonNull Operation operation, Runnable r) {
        Integer transactionId = operation.getTransactionId();
        if (currentTransactionId == null) {
            // ignore transactionId, could be null or -1 or something else if closed...
            r.run();
        } else if (transactionId != null && (transactionId.equals(currentTransactionId) || transactionId == TRANSACTION_ID_FORCE)) {
            r.run();
            // run queued action asynchronously
            if (currentTransactionId == null && !noTransactionOperationQueue.isEmpty()) {
                databaseWorkerPool.post(this, this::runQueuedOperations);
            }

        } else {
            // Queue for later
            QueuedOperation queuedOperation = new QueuedOperation(operation, r);
            noTransactionOperationQueue.add(queuedOperation);
        }
    }

    public void query(final @NonNull Operation operation) {
        wrapSqlOperationHandler(operation, () -> doQuery(operation));
    }

    private boolean doQuery(final @NonNull Operation operation) {
        // Non null means dealing with saved cursor.
        Integer cursorPageSize = operation.getArgument(PARAM_CURSOR_PAGE_SIZE);
        boolean cursorHasMoreData = false;

        final SqlCommand command = operation.getSqlCommand();


        // Might be created if reading by page and result don't fit
        SqfliteCursor sqfliteCursor = null;
        if (LogLevel.hasSqlLevel(logLevel)) {
            Log.d(TAG, getThreadLogPrefix() + command);
        }
        Cursor cursor = null;

        try {
            cursor = getReadableDatabase().rawQueryWithFactory(
                    (sqLiteDatabase, sqLiteCursorDriver, editTable, sqLiteQuery) -> {
                        command.bindTo(sqLiteQuery);
                        return new SQLiteCursor(sqLiteCursorDriver, editTable, sqLiteQuery);
                    }, command.getSql(), EMPTY_STRING_ARRAY, null);

            Map<String, Object> results = cursorToResults(cursor, cursorPageSize);
            if (cursorPageSize != null) {
                // We'll have potentially more data to fetch
                cursorHasMoreData = !(cursor.isLast() || cursor.isAfterLast());

            }

            if (cursorHasMoreData) {
                int cursorId = ++lastCursorId;
                results.put(PARAM_CURSOR_ID, cursorId);
                sqfliteCursor = new SqfliteCursor(cursorId, cursorPageSize, cursor);
                cursors.put(cursorId, sqfliteCursor);
            }
            operation.success(results);

            return true;

        } catch (Exception exception) {
            handleException(exception, operation);
            // Cleanup
            if (sqfliteCursor != null) {
                closeCursor(sqfliteCursor);
            }
            return false;
        } finally {
            // Close the cursor for non-paged query
            if (sqfliteCursor == null) {
                if (cursor != null) {
                    cursor.close();
                }
            }
        }
    }

    public void queryCursorNext(final @NonNull Operation operation) {
        wrapSqlOperationHandler(operation, () -> doQueryCursorNext(operation));
    }

    private boolean doQueryCursorNext(final @NonNull Operation operation) {
        // Non null means dealing with saved cursor.
        int cursorId = operation.getArgument(PARAM_CURSOR_ID);
        boolean cancel = Boolean.TRUE.equals(operation.getArgument(PARAM_CANCEL));
        if (LogLevel.hasVerboseLevel(logLevel)) {
            Log.d(TAG, getThreadLogPrefix() + "cursor " + cursorId + (cancel ? " cancel" : " next"));
        }
        if (cancel) {
            closeCursor(cursorId);
            operation.success(null);
            return true;
        }
        SqfliteCursor sqfliteCursor = cursors.get(cursorId);
        boolean cursorHasMoreData = false;
        try {
            if (sqfliteCursor == null) {
                throw new IllegalStateException("Cursor " + cursorId + " not found");
            }
            Cursor cursor = sqfliteCursor.cursor;

            Map<String, Object> results = cursorToResults(cursor, sqfliteCursor.pageSize);

            // We'll have potentially more data to fetch
            cursorHasMoreData = !(cursor.isLast() || cursor.isAfterLast());

            if (cursorHasMoreData) {
                // Keep the cursor Id in the response to specify that we have more data
                results.put(PARAM_CURSOR_ID, cursorId);
            }
            operation.success(results);

            return true;

        } catch (Exception exception) {
            handleException(exception, operation);
            // Cleanup
            if (sqfliteCursor != null) {
                closeCursor(sqfliteCursor);
                sqfliteCursor = null;
            }
            return false;
        } finally {
            // Close the cursor if we don't have any more data
            if (!cursorHasMoreData) {
                if (sqfliteCursor != null) {
                    closeCursor(sqfliteCursor);
                }
            }
        }
    }

    private void closeCursor(@NonNull SqfliteCursor sqfliteCursor) {
        try {
            int cursorId = sqfliteCursor.cursorId;
            if (LogLevel.hasVerboseLevel(logLevel)) {
                Log.d(TAG, getThreadLogPrefix() + "closing cursor " + cursorId);
            }
            cursors.remove(cursorId);
            sqfliteCursor.cursor.close();
        } catch (Exception ignore) {
        }
    }

    // No exception thrown here
    private void closeCursor(int cursorId) {
        SqfliteCursor sqfliteCursor = cursors.get(cursorId);
        if (sqfliteCursor != null) {
            closeCursor(sqfliteCursor);
        }
    }

    void handleException(Exception exception, Operation operation) {
        if (exception instanceof SQLiteCantOpenDatabaseException) {
            operation.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
            return;
        } else if (exception instanceof SQLException) {
            operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
            return;
        }
        operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
    }

    // Called during batch, warning duplicated code!
    private boolean executeOrError(Operation operation) {
        SqlCommand command = operation.getSqlCommand();
        if (LogLevel.hasSqlLevel(logLevel)) {
            Log.d(TAG, getThreadLogPrefix() + command);
        }
        Boolean operationInTransaction = operation.getInTransactionChange();
        try {
            getWritableDatabase().execSQL(command.getSql(), command.getSqlArguments());
            enterOrLeaveInTransaction(operationInTransaction);
            return true;
        } catch (Exception exception) {
            handleException(exception, operation);
            return false;
        }
    }

    /**
     * Handle inTransactionChange
     *
     * @param operation
     * @return
     */
    public void execute(final @NonNull Operation operation) {
        wrapSqlOperationHandler(operation, () -> {
            Boolean inTransactionChange = operation.getInTransactionChange();
            // Transaction v2 support
            boolean enteringTransaction = Boolean.TRUE.equals(inTransactionChange) && operation.hasNullTransactionId();
            if (enteringTransaction) {
                currentTransactionId = ++lastTransactionId;
            }
            if (!executeOrError(operation)) {
                // Revert if needed
                if (enteringTransaction) {
                    currentTransactionId = null;
                }

            } else if (enteringTransaction) {
                /// Return the transaction id
                Map<String, Object> result = new HashMap<>();
                result.put(PARAM_TRANSACTION_ID, currentTransactionId);
                operation.success(result);
            } else {
                if (Boolean.FALSE.equals(inTransactionChange)) {
                    // We are leaving our current transaction
                    currentTransactionId = null;
                }
                operation.success(null);
            }
        });
    }

    // Return true on success
    private boolean doExecute(final Operation operation) {
        if (!executeOrError(operation)) {
            return false;
        }
        operation.success(null);
        return true;
    }

    public void insert(final Operation operation) {
        wrapSqlOperationHandler(operation, () -> doInsert(operation));
    }

    // Return true on success
    private boolean doInsert(final Operation operation) {
        if (!executeOrError(operation)) {
            return false;
        }
        // don't get last id if not expected
        if (operation.getNoResult()) {
            operation.success(null);
            return true;
        }

        Cursor cursor = null;
        // Read both the changes and last insert row id in on sql call
        String sql = "SELECT changes(), last_insert_rowid()";

        // Handle ON CONFLICT but ignore error, issue #164
        // Read the number of changes before getting the inserted id
        try {
            SQLiteDatabase db = getWritableDatabase();

            cursor = db.rawQuery(sql, null);
            if (cursor != null && cursor.getCount() > 0 && cursor.moveToFirst()) {
                final int changed = cursor.getInt(0);

                // If the change count is 0, assume the insert failed
                // and return null
                if (changed == 0) {
                    if (LogLevel.hasSqlLevel(logLevel)) {
                        Log.d(TAG, getThreadLogPrefix() + "no changes (id was " + cursor.getLong(1) + ")");
                    }
                    operation.success(null);
                    return true;
                } else {
                    final long id = cursor.getLong(1);
                    if (LogLevel.hasSqlLevel(logLevel)) {
                        Log.d(TAG, getThreadLogPrefix() + "inserted " + id);
                    }
                    operation.success(id);
                    return true;
                }
            } else {
                Log.e(TAG, getThreadLogPrefix() + "fail to read changes for Insert");
            }
            operation.success(null);
            return true;
        } catch (Exception exception) {
            handleException(exception, operation);
            return false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }


    public void update(final @NonNull Operation operation) {
        wrapSqlOperationHandler(operation, () -> doUpdate(operation));
    }

    // Return true on success
    private boolean doUpdate(final Operation operation) {
        if (!executeOrError(operation)) {
            return false;
        }
        // don't get last id if not expected
        if (operation.getNoResult()) {
            operation.success(null);
            return true;
        }
        Cursor cursor = null;
        try {
            SQLiteDatabase db = getWritableDatabase();

            cursor = db.rawQuery("SELECT changes()", null);
            if (cursor != null && cursor.getCount() > 0 && cursor.moveToFirst()) {
                final int changed = cursor.getInt(0);
                if (LogLevel.hasSqlLevel(logLevel)) {
                    Log.d(TAG, getThreadLogPrefix() + "changed " + changed);
                }
                operation.success(changed);
                return true;
            } else {
                Log.e(TAG, getThreadLogPrefix() + "fail to read changes for Update/Delete");
            }
            operation.success(null);
            return true;
        } catch (Exception e) {
            handleException(e, operation);
            return false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }

    void batch(final MethodCall call, final MethodChannel.Result result) {
        MethodCallOperation mainOperation = new MethodCallOperation(call, result);

        boolean noResult = mainOperation.getNoResult();
        boolean continueOnError = mainOperation.getContinueOnError();

        List<Map<String, Object>> operations = mainOperation.getArgument(PARAM_OPERATIONS);
        List<Map<String, Object>> results = new ArrayList<>();

        //devLog(TAG, "operations " + operations);
        for (Map<String, Object> map : operations) {
            //devLog(TAG, "map " + map);
            BatchOperation operation = new BatchOperation(map, noResult);
            String method = operation.getMethod();
            switch (method) {
                case METHOD_EXECUTE:
                    if (doExecute(operation)) {
                        //devLog(TAG, "results: " + operation.getBatchResults());
                        operation.handleSuccess(results);
                    } else if (continueOnError) {
                        operation.handleErrorContinue(results);
                    } else {
                        // we stop at the first error
                        operation.handleError(result);
                        return;
                    }
                    break;
                case METHOD_INSERT:
                    if (doInsert(operation)) {
                        //devLog(TAG, "results: " + operation.getBatchResults());
                        operation.handleSuccess(results);
                    } else if (continueOnError) {
                        operation.handleErrorContinue(results);
                    } else {
                        // we stop at the first error
                        operation.handleError(result);
                        return;
                    }
                    break;
                case METHOD_QUERY:
                    if (doQuery(operation)) {
                        //devLog(TAG, "results: " + operation.getBatchResults());
                        operation.handleSuccess(results);
                    } else if (continueOnError) {
                        operation.handleErrorContinue(results);
                    } else {
                        // we stop at the first error
                        operation.handleError(result);
                        return;
                    }
                    break;
                case METHOD_UPDATE:
                    if (doUpdate(operation)) {
                        //devLog(TAG, "results: " + operation.getBatchResults());
                        operation.handleSuccess(results);
                    } else if (continueOnError) {
                        operation.handleErrorContinue(results);
                    } else {
                        // we stop at the first error
                        operation.handleError(result);
                        return;
                    }
                    break;
                default:
                    result.error(ERROR_BAD_PARAM, "Batch method '" + method + "' not supported", null);
                    return;
            }
        }
        // Set the results of all operations
        // devLog(TAG, "results " + results);
        if (noResult) {
            result.success(null);
        } else {
            result.success(results);
        }
    }

    synchronized boolean isInTransaction() {
        return transactionDepth > 0;
    }

    synchronized void enterOrLeaveInTransaction(Boolean value) {
        if (Boolean.TRUE.equals(value)) {
            transactionDepth++;
        } else if (Boolean.FALSE.equals(value)) {
            transactionDepth--;
        }
    }
}
