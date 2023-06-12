package com.github.florent37.assets_audio_player.stopwhencall

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioManager.ACTION_AUDIO_BECOMING_NOISY
import android.os.Build
import java.util.*
import kotlin.collections.ArrayList

private class MusicIntentReceiver : BroadcastReceiver() {
    var pluggedListener: ((Boolean) -> Unit)? = null
    override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_AUDIO_BECOMING_NOISY) {
                pluggedListener?.invoke(false)
            }
            if (intent.action == Intent.ACTION_HEADSET_PLUG) {
                when (intent.getIntExtra("state", -1)) {
                    0 -> {
                        pluggedListener?.invoke(false)
                        //"Headset is unplugged"
                    }
                    1 -> {
                        pluggedListener?.invoke(true)
                        // "Headset is plugged"
                    }
                    else -> {
                        //"I have no idea what the headset state is"
                    }
                }
            }
    }
}

class HeadsetManager(private val context: Context) {

    var onHeadsetPluggedListener: ((Boolean) -> Unit)? = null
    private val receiver = MusicIntentReceiver().apply {
        this.pluggedListener = { plugged ->
            this@HeadsetManager.onHeadsetPluggedListener?.invoke(plugged)
        }
    }

    val profileListener = object: BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
             if (profile == BluetoothProfile.HEADSET) {
                /* Connected to BT headset profile proxy. */
                this@HeadsetManager.onHeadsetPluggedListener?.invoke(true)
            }
        }
        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HEADSET) {
                /* Disonnected from BT headset profile proxy. */
                this@HeadsetManager.onHeadsetPluggedListener?.invoke(false)
            }
        }
    }

    fun start(){
        val action = if (Build.VERSION.SDK_INT >= 21) {
            AudioManager.ACTION_HEADSET_PLUG
        } else {
            Intent.ACTION_HEADSET_PLUG
        }

        context.registerReceiver(receiver, IntentFilter(action))
        context.registerReceiver(receiver, IntentFilter(ACTION_AUDIO_BECOMING_NOISY))

        //will only work if the     <uses-permission android:name="android.permission.BLUETOOTH" /> is in the manifest
        try {
            if(context.hasPermissionBluetooth()) {
                BluetoothAdapter.getDefaultAdapter()
                        ?.getProfileProxy(context, profileListener, BluetoothProfile.HEADSET)
            }
        } catch (t: Throwable) {
            //t.printStackTrace()
        }
    }

    fun stop(){
        context.unregisterReceiver(receiver)
    }


    fun Context.hasPermissionBluetooth() : Boolean {
        try {
            val packageInfo = this.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            return  packageInfo.requestedPermissions.contains("android.permission.BLUETOOTH")
        } catch (t: Throwable) {

        }

        return false
    }

}