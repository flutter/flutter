package xyz.luan.audioplayers

import android.util.Log

enum class LogLevel(val value: Int) {
    INFO(2), ERROR(1), NONE(0)
}

object Logger {
    var logLevel: LogLevel = LogLevel.ERROR

    // this can be changed for testing purposes
    var androidLogger: (String, String, Throwable?) -> Unit = { tag, message, t ->
        Log.d(tag, message, t)
    }

    fun info(message: String) {
        log(LogLevel.INFO, message)
    }

    fun error(message: String) {
        log(LogLevel.ERROR, message)
    }

    fun error(message: String, throwable: Throwable) {
        log(LogLevel.ERROR, message, throwable)
    }

    private fun log(level: LogLevel, message: String, throwable: Throwable? = null) {
        if (level.value <= logLevel.value) {
            androidLogger("AudioPlayers", message, throwable)
        }
    }
}