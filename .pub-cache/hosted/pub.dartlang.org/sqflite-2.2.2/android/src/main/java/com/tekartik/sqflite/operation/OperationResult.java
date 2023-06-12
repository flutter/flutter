package com.tekartik.sqflite.operation;

import androidx.annotation.Nullable;

/**
 * Created by alex on 09/01/18.
 */

public interface OperationResult {
    void error(final String errorCode, final String errorMessage, final Object data);

    void success(@Nullable final Object result);
}
