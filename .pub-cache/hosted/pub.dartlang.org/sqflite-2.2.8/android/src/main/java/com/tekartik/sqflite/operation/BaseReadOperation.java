package com.tekartik.sqflite.operation;


import static com.tekartik.sqflite.Constant.PARAM_CONTINUE_OR_ERROR;
import static com.tekartik.sqflite.Constant.PARAM_IN_TRANSACTION_CHANGE;
import static com.tekartik.sqflite.Constant.PARAM_NO_RESULT;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;
import static com.tekartik.sqflite.Constant.PARAM_TRANSACTION_ID;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tekartik.sqflite.SqlCommand;

import java.util.List;

/**
 * Created by alex on 09/01/18.
 */

public abstract class BaseReadOperation implements Operation {
    private String getSql() {
        return getArgument(PARAM_SQL);
    }

    private List<Object> getSqlArguments() {
        return getArgument(PARAM_SQL_ARGUMENTS);
    }

    @Nullable
    public Integer getTransactionId() {
        return getArgument(PARAM_TRANSACTION_ID);
    }

    public boolean hasNullTransactionId() {
        return hasArgument(PARAM_TRANSACTION_ID) && getTransactionId() == null;
    }

    public SqlCommand getSqlCommand() {
        return new SqlCommand(getSql(), getSqlArguments());
    }

    public Boolean getInTransactionChange() {
        return getBoolean(PARAM_IN_TRANSACTION_CHANGE);
    }

    @Override
    public boolean getNoResult() {
        return Boolean.TRUE.equals(getArgument(PARAM_NO_RESULT));
    }

    @Override
    public boolean getContinueOnError() {
        return Boolean.TRUE.equals(getArgument(PARAM_CONTINUE_OR_ERROR));
    }

    private Boolean getBoolean(String key) {
        Object value = getArgument(key);
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return null;
    }

    // We actually have an inner object that does the implementation
    protected abstract OperationResult getOperationResult();

    @NonNull
    @Override
    public String toString() {
        return "" + getMethod() + " " + getSql() + " " + getSqlArguments();
    }
}
