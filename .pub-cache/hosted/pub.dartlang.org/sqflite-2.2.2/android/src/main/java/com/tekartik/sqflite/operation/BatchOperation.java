package com.tekartik.sqflite.operation;

import static com.tekartik.sqflite.Constant.PARAM_ERROR;
import static com.tekartik.sqflite.Constant.PARAM_ERROR_CODE;
import static com.tekartik.sqflite.Constant.PARAM_ERROR_DATA;
import static com.tekartik.sqflite.Constant.PARAM_ERROR_MESSAGE;
import static com.tekartik.sqflite.Constant.PARAM_METHOD;
import static com.tekartik.sqflite.Constant.PARAM_RESULT;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * Created by alex on 09/01/18.
 */

public class BatchOperation extends BaseOperation {
    final Map<String, Object> map;
    final BatchOperationResult operationResult = new BatchOperationResult();
    final boolean noResult;

    public BatchOperation(Map<String, Object> map, boolean noResult) {
        this.map = map;
        this.noResult = noResult;
    }

    @Override
    public String getMethod() {
        return (String) map.get(PARAM_METHOD);
    }

    @SuppressWarnings("unchecked")
    @Override
    public <T> T getArgument(String key) {
        return (T) map.get(key);
    }

    @Override
    public boolean hasArgument(String key) {
        return map.containsKey(key);
    }

    @Override
    public OperationResult getOperationResult() {
        return operationResult;
    }

    public Map<String, Object> getOperationSuccessResult() {
        Map<String, Object> results = new HashMap<>();
        results.put(PARAM_RESULT, operationResult.result);
        return results;
    }

    public Map<String, Object> getOperationError() {
        Map<String, Object> error = new HashMap<>();
        Map<String, Object> errorDetail = new HashMap<>();
        errorDetail.put(PARAM_ERROR_CODE, operationResult.errorCode);
        errorDetail.put(PARAM_ERROR_MESSAGE, operationResult.errorMessage);
        errorDetail.put(PARAM_ERROR_DATA, operationResult.errorData);
        error.put(PARAM_ERROR, errorDetail);
        return error;
    }

    public void handleError(MethodChannel.Result result) {
        result.error(this.operationResult.errorCode, this.operationResult.errorMessage, this.operationResult.errorData);
    }

    @Override
    public boolean getNoResult() {
        return noResult;
    }

    public void handleSuccess(List<Map<String, Object>> results) {
        if (!getNoResult()) {
            results.add(getOperationSuccessResult());
        }
    }

    public void handleErrorContinue(List<Map<String, Object>> results) {
        if (!getNoResult()) {
            results.add(getOperationError());
        }
    }

    public class BatchOperationResult implements OperationResult {
        // success
        Object result;

        // error
        String errorCode;
        String errorMessage;
        Object errorData;

        @Override
        public void success(Object result) {
            this.result = result;
        }

        @Override
        public void error(String errorCode, String errorMessage, Object data) {
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
            this.errorData = data;
        }
    }


}
