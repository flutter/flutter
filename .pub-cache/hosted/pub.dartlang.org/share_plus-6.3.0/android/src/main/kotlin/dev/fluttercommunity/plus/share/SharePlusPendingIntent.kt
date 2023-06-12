package dev.fluttercommunity.plus.share

import android.content.*
import android.os.Build

/**
 * This helper class allows us to use FLAG_MUTABLE on the PendingIntent used in the Share class,
 * as it allows us to make the underlying Intent explicit, therefore avoiding any risks an implicit
 * mutable Intent may carry.
 *
 * When the PendingIntent is sent, the system will instantiate this class and call `onReceive` on it.
 */
internal class SharePlusPendingIntent: BroadcastReceiver() {
    companion object {
        /**
         * Static member to access the result of the system instantiated instance
         */
        var result: String = ""
    }

    /**
     * Handler called after an action was chosen. Called only on success.
     */
    override fun onReceive(context: Context, intent: Intent) {
        // Extract chosen ComponentName
        val chosenComponent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Only available from API level 33 onwards
            intent.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT, ComponentName::class.java)
        } else {
            // Deprecated in API level 33
            intent.getParcelableExtra<ComponentName>(Intent.EXTRA_CHOSEN_COMPONENT)
        }

        // Unambiguously identify the chosen action
        if (chosenComponent != null) {
            result = chosenComponent.flattenToString()
        }
    }
}
