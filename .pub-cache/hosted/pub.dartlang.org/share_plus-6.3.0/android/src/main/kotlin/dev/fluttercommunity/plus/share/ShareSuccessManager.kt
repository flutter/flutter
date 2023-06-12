package dev.fluttercommunity.plus.share

import android.content.*
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Handles the callback based status information about a successful or dismissed
 * share. Used to link multiple different callbacks together for easier use.
 */
internal class ShareSuccessManager(private val context: Context) : ActivityResultListener {
    private var callback: MethodChannel.Result? = null
    private var isCalledBack: AtomicBoolean = AtomicBoolean(true)

    /**
     * Set result callback that will wait for the share-sheet to close and get either
     * the componentname of the chosen option or an empty string on dismissal.
     */
    fun setCallback(callback: MethodChannel.Result): Boolean {
        return if (isCalledBack.compareAndSet(true, false)) {
            // Prepare all state for new share
            SharePlusPendingIntent.result = ""
            isCalledBack.set(false)
            this.callback = callback
            true
        } else {
            callback.error(
                "Share callback error",
                "prior share-sheet did not call back, did you await it? Maybe use non-result variant",
                null,
            )
            false
        }
    }

    /**
     * Must be called if `.startActivityForResult` is not available to avoid deadlocking.
     */
    fun unavailable() {
        returnResult(RESULT_UNAVAILABLE)
    }

    /**
     * Send the result to flutter by invoking the previously set callback.
     */
    private fun returnResult(result: String) {
        if (isCalledBack.compareAndSet(false, true) && callback != null) {
            callback!!.success(result)
            callback = null
        }
    }

    /**
     * Handler called after a share sheet was closed. Called regardless of success or
     * dismissal.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return if (requestCode == ACTIVITY_CODE) {
            returnResult(SharePlusPendingIntent.result)
            true
        } else {
            false
        }
    }

    /**
     * Companion object holds constants used throughout the plugin when attempting to return
     * the share result.
     */
    companion object {
        const val ACTIVITY_CODE = 17062003
        const val RESULT_UNAVAILABLE = "dev.fluttercommunity.plus/share/unavailable"
    }
}
