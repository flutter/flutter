import android.util.Log

enum class LogLevel(val value: Int) {
    INFO(0), ERROR(1), NONE(2)
}

object Logger {
    var logLevel: LogLevel = LogLevel.ERROR

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
            Log.d("AudioPlayers", message, throwable)
        }
    }
}