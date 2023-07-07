package com.xraph.plugin.flutter_unity_widget

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter

/** FlutterUnityWidgetPlugin */
class FlutterUnityWidgetPlugin : FlutterPlugin, ActivityAware {
    private var lifecycle: Lifecycle? = null
    private var flutterPluginBinding: FlutterPluginBinding? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPluginBinding) {
        Log.d(LOG_TAG, "onAttachedToEngine")
        flutterPluginBinding = binding
        binding
                .platformViewRegistry
                .registerViewFactory(
                        VIEW_TYPE,
                        FlutterUnityWidgetFactory(
                                binding.binaryMessenger,
                                object : LifecycleProvider {
                                    override fun getLifecycle(): Lifecycle {
                                        return lifecycle!!
                                    }
                                }))
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPluginBinding) {
        Log.d(LOG_TAG, "onDetachedFromEngine")
        flutterPluginBinding = null
    }

    companion object {
        internal const val LOG_TAG = "FUWPlugin"
        private const val VIEW_TYPE = "plugin.xraph.com/unity_view"
    }

    @SuppressLint("LongLogTag")
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(LOG_TAG, "onAttachedToActivity")
        handleActivityChange(binding.activity)
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(LOG_TAG, "onDetachedFromActivityForConfigChanges")
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(LOG_TAG, "onReattachedToActivityForConfigChanges")
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        Log.d(LOG_TAG, "onDetachedFromActivity")
        handleActivityChange(null)
        lifecycle = null
    }

    /**
     *
     */
    private fun handleActivityChange(activity: Activity?) {
        Log.d(LOG_TAG, "handleActivityChange")
        if (activity != null) {
            UnityPlayerUtils.prevActivityRequestedOrientation = activity.requestedOrientation
            UnityPlayerUtils.activity = activity
            return
        }

        UnityPlayerUtils.activity = null
        UnityPlayerUtils.reset()
        UnityPlayerUtils.quitPlayer()
    }

    /**
     * This class provides a {@link LifecycleOwner} for the activity driven by {@link
     * ActivityLifecycleCallbacks}.
     *
     * <p>This is used in the case where a direct Lifecycle/Owner is not available.
     */
    @SuppressLint("NewApi")
    private class ProxyLifecycleProvider(activity: Activity) : Application.ActivityLifecycleCallbacks, LifecycleOwner, LifecycleProvider {
        private val lifecycle = LifecycleRegistry(this)
        private var registrarActivityHashCode: Int = 0

        init {
            UnityPlayerUtils.activity = activity
            this.registrarActivityHashCode = activity.hashCode()
            activity.application.registerActivityLifecycleCallbacks(this)
        }

        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        }

        override fun onActivityStarted(activity: Activity) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_START)
        }

        override fun onActivityResumed(activity: Activity) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
        }

        override fun onActivityPaused(activity: Activity) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE)
        }

        override fun onActivityStopped(activity: Activity) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
        }

        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
            UnityPlayerUtils.activity = activity
        }

        override fun onActivityDestroyed(activity: Activity) {
            UnityPlayerUtils.activity = activity
            if (activity.hashCode() != registrarActivityHashCode) {
                return
            }

            activity.application.unregisterActivityLifecycleCallbacks(this)
            lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
        }

        override fun getLifecycle(): Lifecycle {
            return lifecycle
        }
    }
}