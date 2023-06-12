package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.CMD_GET;
import static com.tekartik.sqflite.Constant.MEMORY_DATABASE_PATH;
import static com.tekartik.sqflite.Constant.METHOD_ANDROID_SET_LOCALE;
import static com.tekartik.sqflite.Constant.METHOD_BATCH;
import static com.tekartik.sqflite.Constant.METHOD_CLOSE_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_DATABASE_EXISTS;
import static com.tekartik.sqflite.Constant.METHOD_DEBUG;
import static com.tekartik.sqflite.Constant.METHOD_DEBUG_MODE;
import static com.tekartik.sqflite.Constant.METHOD_DELETE_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_EXECUTE;
import static com.tekartik.sqflite.Constant.METHOD_GET_DATABASES_PATH;
import static com.tekartik.sqflite.Constant.METHOD_GET_PLATFORM_VERSION;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.METHOD_OPEN_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_OPTIONS;
import static com.tekartik.sqflite.Constant.METHOD_QUERY;
import static com.tekartik.sqflite.Constant.METHOD_QUERY_CURSOR_NEXT;
import static com.tekartik.sqflite.Constant.METHOD_UPDATE;
import static com.tekartik.sqflite.Constant.PARAM_CMD;
import static com.tekartik.sqflite.Constant.PARAM_ID;
import static com.tekartik.sqflite.Constant.PARAM_LOCALE;
import static com.tekartik.sqflite.Constant.PARAM_LOG_LEVEL;
import static com.tekartik.sqflite.Constant.PARAM_PATH;
import static com.tekartik.sqflite.Constant.PARAM_READ_ONLY;
import static com.tekartik.sqflite.Constant.PARAM_RECOVERED;
import static com.tekartik.sqflite.Constant.PARAM_RECOVERED_IN_TRANSACTION;
import static com.tekartik.sqflite.Constant.PARAM_SINGLE_INSTANCE;
import static com.tekartik.sqflite.Constant.TAG;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Process;
import android.util.Log;

import com.tekartik.sqflite.dev.Debug;
import com.tekartik.sqflite.operation.MethodCallOperation;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;

/**
 * SqflitePlugin Android implementation
 */
public class SqflitePlugin implements FlutterPlugin, MethodCallHandler {

    static final Map<String, Integer> _singleInstancesByPath = new HashMap<>();
    @SuppressLint("UseSparseArrays")
    static final Map<Integer, Database> databaseMap = new HashMap<>();
    static private final Object databaseMapLocker = new Object();
    static private final Object openCloseLocker = new Object();
    static int logLevel = LogLevel.none;
    // local cache
    static String databasesPath;
    static private int THREAD_PRIORITY = Process.THREAD_PRIORITY_DEFAULT;
    static private int THREAD_COUNT = 1;
    static private int databaseId = 0; // incremental database id
    // Database worker pool execution
    static private DatabaseWorkerPool databaseWorkerPool;
    private Context context;
    private MethodChannel methodChannel;

    // Needed public constructor
    public SqflitePlugin() {

    }

    // Testing only
    public SqflitePlugin(Context context) {
        this.context = context.getApplicationContext();
    }

    //
    // Plugin registration.
    //
    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        SqflitePlugin sqflitePlugin = new SqflitePlugin();
        sqflitePlugin.onAttachedToEngine(registrar.context(), registrar.messenger());
    }

    static private Map<String, Object> fixMap(Map<Object, Object> map) {
        Map<String, Object> newMap = new HashMap<>();
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object value = entry.getValue();
            if (value instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<Object, Object> mapValue = (Map<Object, Object>) value;
                value = fixMap(mapValue);
            } else {
                value = toString(value);
            }
            newMap.put(toString(entry.getKey()), value);
        }
        return newMap;
    }

    // Convert a value to a string
    // especially byte[]
    static private String toString(Object value) {
        if (value == null) {
            return null;
        } else if (value instanceof byte[]) {
            List<Integer> list = new ArrayList<>();
            for (byte _byte : (byte[]) value) {
                list.add((int) _byte);
            }
            return list.toString();
        } else if (value instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<Object, Object> mapValue = (Map<Object, Object>) value;
            return fixMap(mapValue).toString();
        } else {
            return value.toString();
        }
    }

    static boolean isInMemoryPath(String path) {
        return (path == null || path.equals(MEMORY_DATABASE_PATH));
    }

    // {
    // 'id': xxx
    // 'recovered': true // if recovered only for single instance
    // }
    static Map makeOpenResult(int databaseId, boolean recovered, boolean recoveredInTransaction) {
        Map<String, Object> result = new HashMap<>();
        result.put(PARAM_ID, databaseId);
        if (recovered) {
            result.put(PARAM_RECOVERED, true);
        }
        if (recoveredInTransaction) {
            result.put(PARAM_RECOVERED_IN_TRANSACTION, true);
        }
        return result;
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.context = applicationContext;
        methodChannel = new MethodChannel(messenger, Constant.PLUGIN_KEY,
                StandardMethodCodec.INSTANCE,
                messenger.makeBackgroundTaskQueue());
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
    }

    private Context getContext() {
        return context;
    }

    private Database getDatabase(int databaseId) {
        return databaseMap.get(databaseId);
    }

    private Database getDatabaseOrError(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabase(databaseId);

        if (database != null) {
            return database;
        } else {
            result.error(Constant.SQLITE_ERROR, Constant.ERROR_DATABASE_CLOSED + " " + databaseId, null);
            return null;
        }
    }

    //
    // query
    //
    private void onQueryCall(final MethodCall call, final Result result) {
        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            database.query(operation);
        });
    }

    //
    // cursor query next
    //
    private void onQueryCursorNextCall(final MethodCall call, final Result result) {
        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            database.queryCursorNext(operation);
        });
    }

    //
    // Sqflite.batch
    //
    private void onBatchCall(final MethodCall call, final Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> database.batch(call, result));
    }

    //
    // Insert
    //
    private void onInsertCall(final MethodCall call, final Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            database.insert(operation);
        });
    }

    //
    // Sqflite.execute
    //
    private void onExecuteCall(final MethodCall call, final Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            database.execute(operation);
        });
    }

    private void onSetLocaleCall(final MethodCall call, final Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            String localeString = call.argument(PARAM_LOCALE);
            try {
                database.sqliteDatabase.setLocale(Utils.localeForLanguateTag(localeString));
                result.success(null);
            } catch (Exception exception) {
                result.error(Constant.SQLITE_ERROR, "Error calling setLocale: " + exception.getMessage(), null);
            }

        });
    }

    //
    // Sqflite.update
    //
    private void onUpdateCall(final MethodCall call, final Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        databaseWorkerPool.post(database, () -> {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            database.update(operation);
        });
    }

    private void onDebugCall(final MethodCall call, final Result result) {
        String cmd = call.argument(PARAM_CMD);
        Map<String, Object> map = new HashMap<>();

        // Get database info

        if (CMD_GET.equals(cmd)) {
            if (logLevel > LogLevel.none) {
                map.put(PARAM_LOG_LEVEL, logLevel);
            }
            if (!databaseMap.isEmpty()) {
                Map<String, Object> databasesInfo = new HashMap<>();
                for (Map.Entry<Integer, Database> entry : databaseMap.entrySet()) {
                    Database database = entry.getValue();
                    Map<String, Object> info = new HashMap<>();
                    info.put(PARAM_PATH, database.path);
                    info.put(PARAM_SINGLE_INSTANCE, database.singleInstance);
                    if (database.logLevel > LogLevel.none) {
                        info.put(PARAM_LOG_LEVEL, database.logLevel);
                    }
                    databasesInfo.put(entry.getKey().toString(), info);

                }
                map.put("databases", databasesInfo);
            }
        }
        result.success(map);
    }


    // Deprecated since 1.1.6
    private void onDebugModeCall(final MethodCall call, final Result result) {
        // Old / argument was just a boolean
        Object on = call.arguments();
        Debug.LOGV = Boolean.TRUE.equals(on);
        Debug.EXTRA_LOGV = Debug._EXTRA_LOGV && Debug.LOGV;

        // set default logs to match existing
        if (Debug.LOGV) {
            if (Debug.EXTRA_LOGV) {
                logLevel = LogLevel.verbose;
            } else if (Debug.LOGV) {
                logLevel = LogLevel.sql;
            }

        } else {
            logLevel = LogLevel.none;
        }
        result.success(null);
    }

    //
    // Sqflite.open
    //
    private void onOpenDatabaseCall(final MethodCall call, final Result result) {
        final String path = call.argument(PARAM_PATH);
        final Boolean readOnly = call.argument(PARAM_READ_ONLY);
        final boolean inMemory = isInMemoryPath(path);

        final boolean singleInstance = !Boolean.FALSE.equals(call.argument(PARAM_SINGLE_INSTANCE)) && !inMemory;

        // For single instance we create or reuse a thread right away
        // DO NOT TRY TO LOAD existing instance, the database has been closed


        if (singleInstance) {
            // Look for in memory instance
            synchronized (databaseMapLocker) {
                if (LogLevel.hasVerboseLevel(logLevel)) {
                    Log.d(Constant.TAG, "Look for " + path + " in " + _singleInstancesByPath.keySet());
                }
                Integer databaseId = _singleInstancesByPath.get(path);
                if (databaseId != null) {
                    Database database = databaseMap.get(databaseId);
                    if (database != null) {
                        if (!database.sqliteDatabase.isOpen()) {
                            if (LogLevel.hasVerboseLevel(logLevel)) {
                                Log.d(Constant.TAG, database.getThreadLogPrefix() + "single instance database of " + path + " not opened");
                            }
                        } else {
                            if (LogLevel.hasVerboseLevel(logLevel)) {
                                Log.d(Constant.TAG, database.getThreadLogPrefix() + "re-opened single instance " + (database.isInTransaction() ? "(in transaction) " : "") + databaseId + " " + path);
                            }
                            result.success(makeOpenResult(databaseId, true, database.isInTransaction()));
                            return;
                        }
                    }
                }
            }
        }

        // Generate new id
        int newDatabaseId;
        synchronized (databaseMapLocker) {
            newDatabaseId = ++databaseId;
        }
        final int databaseId = newDatabaseId;

        final Database database = new Database(context, path, databaseId, singleInstance, logLevel);

        synchronized (databaseMapLocker) {
            // Create worker pool if necessary
            if (databaseWorkerPool == null) {
                databaseWorkerPool = DatabaseWorkerPool.create(
                        "Sqflite", THREAD_COUNT, SqflitePlugin.THREAD_PRIORITY);
                databaseWorkerPool.start();
                if (LogLevel.hasSqlLevel(database.logLevel)) {
                    Log.d(TAG, database.getThreadLogPrefix() + "starting worker pool with priority " + SqflitePlugin.THREAD_PRIORITY);
                }
            }
            database.databaseWorkerPool = databaseWorkerPool;
            if (LogLevel.hasSqlLevel(database.logLevel)) {
                Log.d(TAG, database.getThreadLogPrefix() + "opened " + databaseId + " " + path);
            }


            // Open in background thread
            databaseWorkerPool.post(
                    database,
                    () -> {

                        synchronized (openCloseLocker) {

                            if (!inMemory) {
                                File file = new File(path);
                                File directory = new File(file.getParent());
                                if (!directory.exists()) {
                                    if (!directory.mkdirs()) {
                                        if (!directory.exists()) {
                                            result.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
                                            return;
                                        }
                                    }
                                }
                            }

                            // force opening
                            try {
                                if (Boolean.TRUE.equals(readOnly)) {
                                    database.openReadOnly();
                                } else {
                                    database.open();
                                }
                            } catch (Exception e) {
                                MethodCallOperation operation = new MethodCallOperation(call, result);
                                database.handleException(e, operation);
                                return;
                            }

                            synchronized (databaseMapLocker) {
                                if (singleInstance) {
                                    _singleInstancesByPath.put(path, databaseId);
                                }
                                databaseMap.put(databaseId, database);
                            }
                            if (LogLevel.hasSqlLevel(database.logLevel)) {
                                Log.d(TAG, database.getThreadLogPrefix() + "opened " + databaseId + " " + path);
                            }
                        }

                        result.success(makeOpenResult(databaseId, false, false));
                    });
        }

    }

    //
    // Sqflite.close
    //
    private void onCloseDatabaseCall(MethodCall call, final Result result) {
        final int databaseId = call.argument(PARAM_ID);
        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }

        if (LogLevel.hasSqlLevel(database.logLevel)) {
            Log.d(TAG, database.getThreadLogPrefix() + "closing " + databaseId + " " + database.path);
        }

        final String path = database.path;

        // Remove from map right away
        synchronized (databaseMapLocker) {
            databaseMap.remove(databaseId);

            if (database.singleInstance) {
                _singleInstancesByPath.remove(path);
            }
        }

        databaseWorkerPool.post(database, new Runnable() {
            @Override
            public void run() {
                synchronized (openCloseLocker) {
                    closeDatabase(database);
                }

                result.success(null);
            }
        });

    }

    //
    // Sqflite.open
    //
    private void onDeleteDatabaseCall(final MethodCall call, final Result result) {
        final String path = call.argument(PARAM_PATH);
        Database foundOpenedDatabase = null;
        // Look for in memory instance
        synchronized (databaseMapLocker) {
            if (LogLevel.hasVerboseLevel(logLevel)) {
                Log.d(Constant.TAG, "Look for " + path + " in " + _singleInstancesByPath.keySet());
            }
            Integer databaseId = _singleInstancesByPath.get(path);
            if (databaseId != null) {
                Database database = databaseMap.get(databaseId);
                if (database != null) {
                    if (database.sqliteDatabase.isOpen()) {
                        if (LogLevel.hasVerboseLevel(logLevel)) {
                            Log.d(Constant.TAG, database.getThreadLogPrefix() + "found single instance " + (database.isInTransaction() ? "(in transaction) " : "") + databaseId + " " + path);
                        }
                        foundOpenedDatabase = database;

                        // Remove from map right away
                        databaseMap.remove(databaseId);
                        _singleInstancesByPath.remove(path);
                    }
                }
            }
        }
        final Database openedDatabase = foundOpenedDatabase;

        final Runnable deleteRunnable = new Runnable() {
            @Override
            public void run() {
                synchronized (openCloseLocker) {

                    if (openedDatabase != null) {
                        closeDatabase(openedDatabase);
                    }
                    try {
                        if (LogLevel.hasVerboseLevel(logLevel)) {
                            Log.d(Constant.TAG, "delete database " + path);
                        }
                        Database.deleteDatabase(path);
                    } catch (Exception e) {
                        Log.e(TAG, "error " + e + " while closing database " + databaseId);
                    }
                }
                result.success(null);
            }
        };

        // worker pool might not exist yet
        if (databaseWorkerPool != null) {
            databaseWorkerPool.post(openedDatabase, deleteRunnable);
        } else {
            // Otherwise run in the UI thread
            deleteRunnable.run();
        }

    }

    private void onDatabaseExistsCall(final MethodCall call, final Result result) {
        final String path = call.argument(PARAM_PATH);
        boolean exists = Database.existsDatabase(path);
        result.success(exists);
    }

    private void closeDatabase(Database database) {
        try {
            if (LogLevel.hasSqlLevel(database.logLevel)) {
                Log.d(TAG, database.getThreadLogPrefix() + "closing database ");
            }
            database.close();
        } catch (Exception e) {
            Log.e(TAG, "error " + e + " while closing database " + databaseId);
        }
        synchronized (databaseMapLocker) {

            if (databaseMap.isEmpty() && databaseWorkerPool != null) {
                if (LogLevel.hasSqlLevel(database.logLevel)) {
                    Log.d(TAG, database.getThreadLogPrefix() + "stopping thread");
                }
                databaseWorkerPool.quit();
                databaseWorkerPool = null;
            }
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            // quick testing
            case METHOD_GET_PLATFORM_VERSION:
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case METHOD_CLOSE_DATABASE: {
                onCloseDatabaseCall(call, result);
                break;
            }
            case METHOD_QUERY: {
                onQueryCall(call, result);
                break;
            }
            case METHOD_INSERT: {
                onInsertCall(call, result);
                break;
            }
            case METHOD_UPDATE: {
                onUpdateCall(call, result);
                break;
            }
            case METHOD_EXECUTE: {
                onExecuteCall(call, result);
                break;
            }
            case METHOD_OPEN_DATABASE: {
                onOpenDatabaseCall(call, result);
                break;
            }
            case METHOD_BATCH: {
                onBatchCall(call, result);
                break;
            }
            case METHOD_OPTIONS: {
                onOptionsCall(call, result);
                break;
            }
            case METHOD_GET_DATABASES_PATH: {
                onGetDatabasesPathCall(call, result);
                break;
            }
            case METHOD_DELETE_DATABASE: {
                onDeleteDatabaseCall(call, result);
                break;
            }
            case METHOD_DEBUG: {
                onDebugCall(call, result);
                break;
            }
            case METHOD_QUERY_CURSOR_NEXT: {
                onQueryCursorNextCall(call, result);
                break;
            }
            case METHOD_DATABASE_EXISTS: {
                onDatabaseExistsCall(call, result);
                break;
            }
            // Obsolete
            case METHOD_DEBUG_MODE: {
                onDebugModeCall(call, result);
                break;
            }
            case METHOD_ANDROID_SET_LOCALE: {
                onSetLocaleCall(call, result);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    void onOptionsCall(final MethodCall call, final Result result) {
        Object threadPriority = call.argument(Constant.PARAM_THREAD_PRIORITY);
        if (threadPriority != null) {
            THREAD_PRIORITY = (Integer) threadPriority;
        }
        Object threadCount = call.argument(Constant.PARAM_THREAD_COUNT);
        if (threadCount != null && !threadCount.equals(THREAD_COUNT)) {
            THREAD_COUNT = (Integer) threadCount;
            // Reset databaseWorkerPool when THREAD_COUNT change.
            if (databaseWorkerPool != null) {
                databaseWorkerPool.quit();
                databaseWorkerPool = null;
            }
        }
        Integer logLevel = LogLevel.getLogLevel(call);
        if (logLevel != null) {
            SqflitePlugin.logLevel = logLevel;
        }
        result.success(null);
    }

    //private static class Database

    void onGetDatabasesPathCall(final MethodCall call, final Result result) {
        if (databasesPath == null) {
            String dummyDatabaseName = "tekartik_sqflite.db";
            File file = context.getDatabasePath(dummyDatabaseName);
            databasesPath = file.getParent();
        }
        result.success(databasesPath);
    }
}
