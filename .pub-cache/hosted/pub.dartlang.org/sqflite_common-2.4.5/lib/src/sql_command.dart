/// Sql command type.
enum SqliteSqlCommandType {
  /// such CREATE TABLE, DROP_INDEX, pragma
  execute,

  /// Insert statement,
  insert,

  /// Update statement.
  update,

  /// Delete statement.
  delete,

  /// Query statement (SELECTà
  query,
}

/// Sql command. internal only.
class SqfliteSqlCommand {
  /// The command type.
  final SqliteSqlCommandType type;

  /// The sql statement.
  final String sql;

  /// The sql arguments.
  final List<Object?>? arguments;

  /// Sql command.
  SqfliteSqlCommand(this.type, this.sql, this.arguments);
}
