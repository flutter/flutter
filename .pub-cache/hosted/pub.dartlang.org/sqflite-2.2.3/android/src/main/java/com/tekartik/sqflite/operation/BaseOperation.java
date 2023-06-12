package com.tekartik.sqflite.operation;

/**
 * Created by alex on 09/01/18.
 */

public abstract class BaseOperation extends BaseReadOperation {

    // We actually have an inner object that does the implementation
    protected abstract OperationResult getOperationResult();

    @Override
    public void success(Object result) {
        getOperationResult().success(result);
    }

    @Override
    public void error(String errorCode, String errorMessage, Object data) {
        getOperationResult().error(errorCode, errorMessage, data);
    }

}
