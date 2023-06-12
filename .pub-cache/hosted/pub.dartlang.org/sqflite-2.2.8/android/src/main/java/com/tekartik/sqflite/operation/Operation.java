package com.tekartik.sqflite.operation;

import androidx.annotation.Nullable;

import com.tekartik.sqflite.SqlCommand;

/**
 * Created by alex on 09/01/18.
 */

public interface Operation extends OperationResult {

    String getMethod();

    <T> T getArgument(String key);

    boolean hasArgument(String key);

    SqlCommand getSqlCommand();

    boolean getNoResult();

    // In batch, means ignoring the error
    boolean getContinueOnError();

    // Only for execute command, true when entering a transaction, false when exiting
    Boolean getInTransactionChange();

    /**
     * transaction id if any, only for within a transaction
     */
    @Nullable
    Integer getTransactionId();

    /**
     * Transaction v2 support
     */
    boolean hasNullTransactionId();
}
