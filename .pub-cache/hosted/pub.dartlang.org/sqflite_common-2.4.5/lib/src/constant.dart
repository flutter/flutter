//
// Native methods to use
//

/// Native sql INSERT.
const String methodInsert = 'insert';

/// Native batch.
const String methodBatch = 'batch';

/// Native debug method.
const String methodDebug = 'debug';

/// Native options method.
const String methodOptions = 'options';

/// Native close database method.
const String methodCloseDatabase = 'closeDatabase';

/// Native open database method.
const String methodOpenDatabase = 'openDatabase';

/// Native sql execute.
const String methodExecute = 'execute';

/// Native sql UPDATE or DELETE method.
const String methodUpdate = 'update';

/// Native sql SELECT method.
const String methodQuery = 'query';

/// Native sql SELECT method.
const String methodQueryCursorNext = 'queryCursorNext';

/// deprecated.
const String methodGetPlatformVersion = 'getPlatformVersion';

/// Native getDatabasePath method.
const String methodGetDatabasesPath = 'getDatabasesPath';

/// Native database exists method.
const String methodDatabaseExists = 'databaseExists';

/// Native database delete method.
const String methodDeleteDatabase = 'deleteDatabase';

/// Native batch operations parameter.
const String paramOperations = 'operations';

/// Native batch 'no result' flag.
///
/// if true the result of each batch operation is not filled
const String paramNoResult = 'noResult';

/// Native batch 'continue on error' flag.
///
/// if true all the operation in the batch are executed even if on failed.
const String paramContinueOnError = 'continueOnError';

/// Batch operation method (insert/execute/query/update
const String paramMethod = 'method';

/// Batch operation result.
const String paramResult = 'result';

/// Error.
const String paramError = 'error';

/// Error code.
const String paramErrorCode = 'code';

/// Error message.
const String paramErrorMessage = 'message';

/// Error message.
const String paramErrorResultCode = 'resultCode';

/// Error data.
const String paramErrorData = 'data';

/// Open database 'recovered' flag.
///
/// True if a single instance was recovered from the native world.
const String paramRecovered = 'recovered';

/// Open database 'recovered in transaction' flag.
///
/// True if a single instance was recovered from the native world
/// while in a transaction.
const String paramRecoveredInTransaction = 'recoveredInTransaction';

/// The database path (string).
const String paramPath = 'path';

/// The database version (int).
const String paramVersion = 'version';

/// The database id (int)
const String paramId = 'id';

/// True if the database is in a transaction
const String paramInTransaction = 'inTransaction';

/// For beginTransaction, set it to null
/// Returned by beingTransaction for new implementation
///
/// Transaction param, to set in all calls during a transaction.
///
/// To set to null when beginning a transaction, it tells the implementation
/// that transactionId is supported by the client (compared to a raw BEGIN calls)
const String paramTransactionId = 'transactionId';

/// Special transaction id to force even if a transaction is running.
const int paramTransactionIdValueForce = -1;

/// True when opening the database (bool)
const String paramReadOnly = 'readOnly';

/// True if opened as a single instance (bool)
const String paramSingleInstance = 'singleInstance';

/// SQL query (insert/execute/update/select).
///
/// String.
const String paramSql = 'sql';

/// SQL query parameters.
///
/// List.
const String paramSqlArguments = 'arguments';

/// SQL query cursorId parameter.
///
/// Integer.
const String paramCursorId = 'cursorId';

/// SQL query cursor page size parameter.
///
/// If null to cursor is used
///
/// Integer.
const String paramCursorPageSize = 'cursorPageSize';

/// SQL query cursor next cancel parameter.
///
/// true or false
///
/// boolean.
const String paramCursorCancel = 'cancel';

/// SQLite error code
const String sqliteErrorCode = 'sqlite_error';

/// Special database name opened in memory
const String inMemoryDatabasePath = ':memory:';

/// Default duration before printing a lock warning if a database call hangs.
///
/// Non final for changing it during testing.
///
/// If a database called is delayed by this duration, a print will happen.
const Duration lockWarningDurationDefault = Duration(seconds: 10);

//
// Log levels
//
/// No logs
final sqfliteLogLevelNone = 0;

/// Log native sql commands
final sqfliteLogLevelSql = 1;

/// Log native verbose
final sqfliteLogLevelVerbose = 2;

// deprecated since 1.1.6
// @deprecated
/// deprecated
const String methodSetDebugModeOn = 'debugMode';

/// Default buffer size for queryCursor
const int queryCursorBufferSizeDefault = 100;
