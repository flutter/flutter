package xyz.luan.audioplayers

import org.junit.jupiter.api.Test
import org.assertj.core.api.Assertions.assertThat

internal class LoggerTest {
    @Test
    fun `when set to INFO everything is logged`() {
        val logs = mockLogger()
        Logger.logLevel = LogLevel.INFO
        Logger.info("info")
        Logger.error("error")
        assertThat(logs).containsExactly("info", "error")
    }

    @Test
    fun `when set to ERROR only errors are logged`() {
        val logs = mockLogger()
        Logger.logLevel = LogLevel.ERROR
        Logger.info("info")
        Logger.error("error")
        assertThat(logs).containsExactly("error")
    }

    @Test
    fun `when set to NONE nothing is logged`() {
        val logs = mockLogger()
        Logger.logLevel = LogLevel.NONE
        Logger.info("info")
        Logger.error("error")
        assertThat(logs).isEmpty()
    }

    private fun mockLogger(): MutableList<String> {
        val logs = mutableListOf<String>()
        Logger.androidLogger = { _, m, _ -> logs.add(m) }
        return logs
    }
}
