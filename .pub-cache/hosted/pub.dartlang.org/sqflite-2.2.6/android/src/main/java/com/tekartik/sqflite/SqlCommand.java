package com.tekartik.sqflite;

import android.database.sqlite.SQLiteProgram;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class SqlCommand {
    final private String sql;
    final private List<Object> rawArguments;

    public SqlCommand(String sql, List<Object> rawArguments) {
        this.sql = sql;
        if (rawArguments == null) {
            rawArguments = new ArrayList<>();
        }
        this.rawArguments = rawArguments;
    }

    // Handle list of int as byte[]
    static private Object toValue(Object value) {
        if (value == null) {
            return null;
        } else {
            // Assume a list is a blob
            if (value instanceof List) {
                @SuppressWarnings("unchecked")
                List<Integer> list = (List<Integer>) value;
                byte[] blob = new byte[list.size()];
                for (int i = 0; i < list.size(); i++) {
                    blob[i] = (byte) (int) list.get(i);
                }
                value = blob;
            }
            return value;
        }
    }

    public String getSql() {
        return sql;
    }

    private Object[] getSqlArguments(List<Object> rawArguments) {
        List<Object> fixedArguments = new ArrayList<>();
        if (rawArguments != null) {
            for (Object rawArgument : rawArguments) {
                fixedArguments.add(toValue(rawArgument));
            }
        }
        return fixedArguments.toArray(new Object[0]);
    }

    public void bindTo(SQLiteProgram statement) {
        if (rawArguments != null) {
            int count = rawArguments.size();
            for (int i = 0; i < count; i++) {
                Object arg = toValue(rawArguments.get(i));
                // sqlite3 variables are 1-indexed
                int sqlIndex = i + 1;

                if (arg == null) {
                    statement.bindNull(sqlIndex);
                } else if (arg instanceof byte[]) {
                    statement.bindBlob(sqlIndex, (byte[]) arg);
                } else if (arg instanceof Double) {
                    statement.bindDouble(sqlIndex, (Double) arg);
                } else if (arg instanceof Integer) {
                    statement.bindLong(sqlIndex, (Integer) arg);
                } else if (arg instanceof Long) {
                    statement.bindLong(sqlIndex, (Long) arg);
                } else if (arg instanceof String) {
                    statement.bindString(sqlIndex, (String) arg);
                } else if (arg instanceof Boolean) {
                    statement.bindLong(sqlIndex, ((Boolean) arg) ? 1 : 0);
                } else {
                    throw new IllegalArgumentException("Could not bind " + arg + " from index "
                            + i + ": Supported types are null, byte[], double, long, boolean and String");
                }
            }
        }
    }

    @Override
    public String toString() {
        return sql + ((rawArguments == null || rawArguments.isEmpty()) ? "" : (" " + rawArguments));
    }

    // As expected by execSQL
    public Object[] getSqlArguments() {
        return getSqlArguments(rawArguments);
    }

    public List<Object> getRawSqlArguments() {
        return rawArguments;
    }

    @Override
    public int hashCode() {
        return sql != null ? sql.hashCode() : 0;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj instanceof SqlCommand) {
            SqlCommand o = (SqlCommand) obj;
            if (sql != null) {
                if (!sql.equals(o.sql)) {
                    return false;
                }
            } else {
                if (o.sql != null) {
                    return false;
                }
            }

            if (rawArguments.size() != o.rawArguments.size()) {
                return false;
            }
            for (int i = 0; i < rawArguments.size(); i++) {
                // special blob handling
                if (rawArguments.get(i) instanceof byte[] && o.rawArguments.get(i) instanceof byte[]) {
                    if (!Arrays.equals((byte[]) rawArguments.get(i), (byte[]) o.rawArguments.get(i))) {
                        return false;
                    }
                } else {
                    if (!rawArguments.get(i).equals(o.rawArguments.get(i))) {
                        return false;
                    }
                }
            }
            return true;
        }
        return false;
    }
}
