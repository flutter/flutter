package com.xraph.plugin.flutter_unity_widget

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import com.unity3d.player.UnityPlayerActivity
import java.util.Objects

class OverrideUnityActivity : UnityPlayerActivity() {
    private lateinit var mMainActivityClass: Class<*>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
        this.window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        val intent = intent
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            handleIntent(intent)
        }
    }

    private fun unloadPlayer() {
        mUnityPlayer?.unload()
        showMainActivity()
    }

    private fun quitPlayer() {
        mUnityPlayer?.quit()
    }

    private fun showMainActivity() {
        val intent = Intent(this, mMainActivityClass)
        intent.putExtra("showMain", true)
        intent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
        startActivity(intent)
    }

    override fun onUnityPlayerUnloaded() {
        showMainActivity()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mUnityPlayer?.lowMemory()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            handleIntent(intent)
        }
        setIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Set activity not fullscreen
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            val st = Objects.requireNonNull(intent.extras)?.get("flutterActivity") as Class<*>
            mMainActivityClass = st
            // Set activity not fullscreen
            if (Objects.requireNonNull(intent.extras)?.getBoolean("fullscreen") == true) {
                val fullscreen = intent.extras?.getBoolean("fullscreen")
                if (!fullscreen!!) {
                    this.window.addFlags(WindowManager.LayoutParams.FLAG_FORCE_NOT_FULLSCREEN)
                    this.window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
                } else {
                    this.window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
                }
            }
            // Unloads unity
            if (Objects.requireNonNull(intent.extras)?.containsKey("unload") == true) {
                mUnityPlayer?.unload()
            }
        }
    }

    override fun onBackPressed() {
        Log.i(LOG_TAG, "onBackPressed called")
        this.showMainActivity()
        super.onBackPressed()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
    }

    override fun onPause() {
        super.onPause()
        this.mUnityPlayer?.pause()
    }

    override fun onResume() {
        super.onResume()
        this.mUnityPlayer?.resume()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    companion object {
        var instance: OverrideUnityActivity? = null
        internal val LOG_TAG = "OverrideUnityActivity"
    }
}