package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.PARAM_LOG_LEVEL;

import io.flutter.plugin.common.MethodCall;

public class LogLevel {

    static final int none = 0;
    static final int sql = 1;
    static final int verbose = 2;

    static Integer getLogLevel(MethodCall methodCall) {
        return methodCall.argument(PARAM_LOG_LEVEL);
    }

    static boolean hasSqlLevel(int level) {
        return level >= sql;
    }

    static boolean hasVerboseLevel(int level) {
        return level >= verbose;
    }
}
