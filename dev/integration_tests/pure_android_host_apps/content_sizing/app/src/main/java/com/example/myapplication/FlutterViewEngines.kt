package com.example.myapplication

import android.app.Activity
import android.content.Context
import android.view.ViewGroup
import androidx.activity.ComponentActivity
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.android.ExclusiveAppComponent
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup

class FlutterViewEngines(private val context: Context) {
  private var activity: ComponentActivity? = null
  // There is one "engine group" for the whole app, so that the shared library is loaded
  // once and they share the same heap space and garbage collector.
  private val engineGroup = FlutterEngineGroup(context)
  // Each engine in the group has its own runtime state and widget tree.
  private var engines = mutableMapOf<String, FlutterViewEngine>()

  fun attachToActivity(activity: ComponentActivity) {
    this.activity = activity
  }

  /**
   * Creates a new FlutterEngine instance and cache it with provided key or get the existing engine
   * if it's already created.
   *
   * @return the new or existing FlutterEngine.
   */
  fun createAndRunEngine(key: String, dartEntrypointArgs: List<String>): FlutterViewEngine {
    if (engines.containsKey(key)) {
      return engines[key]!!
    }

    val options =
      FlutterEngineGroup.Options(context).apply {
        automaticallyRegisterPlugins = false
        this.dartEntrypointArgs = dartEntrypointArgs
      }

    val engine = engineGroup.createAndRunEngine(options)
    FlutterEngineCache.getInstance().put(key, engine)
    val flutterViewEngine = FlutterViewEngine(engine)
    flutterViewEngine.attachToActivity(activity!!)
    engines[key] = flutterViewEngine
    return flutterViewEngine
  }
}

class FlutterViewEngine constructor(val engine: FlutterEngine) :
  DefaultLifecycleObserver, ExclusiveAppComponent<Activity> {
  private var activity: ComponentActivity? = null
  private var flutterView: FlutterView? = null

  fun attachToActivity(activity: ComponentActivity) {
    this.activity = activity
  }

  fun detachActivity() {
    if (flutterView != null) {
      unhookActivityAndView()
    }
    activity = null
  }

  fun attachFlutterView(flutterView: FlutterView) {
    this.flutterView = flutterView
    hookActivityAndView()
  }

  fun detachFlutterView(flutterViewContainer: ViewGroup) {
    flutterViewContainer.removeView(flutterView)
    unhookActivityAndView()
    flutterView = null
  }

  fun destroy() {
    detachActivity()
    engine.destroy()
  }

  override fun onResume(owner: LifecycleOwner) {
    if (activity != null) {
      engine.lifecycleChannel.appIsResumed()
    }
  }

  override fun onPause(owner: LifecycleOwner) {
    if (activity != null) {
      engine.lifecycleChannel.appIsInactive()
    }
  }

  override fun onStop(owner: LifecycleOwner) {
    if (activity != null) {
      engine.lifecycleChannel.appIsPaused()
    }
  }

  override fun onDestroy(owner: LifecycleOwner) {
    destroy()
  }

  override fun detachFromFlutterEngine() {
    // Do nothing here
  }

  override fun getAppComponent(): Activity {
    return activity!!
  }

  private fun hookActivityAndView() {
    // Assert state.
    activity!!.let { activity ->
      flutterView!!.let { flutterView ->
        engine.activityControlSurface.attachToActivity(this, activity.lifecycle)
        flutterView.attachToFlutterEngine(engine)
        activity.lifecycle.addObserver(this)
      }
    }
  }

  private fun unhookActivityAndView() {
    // Stop reacting to activity events.
    activity!!.lifecycle.removeObserver(this)

    // Plugins are no longer attached to an activity.
    engine.activityControlSurface.detachFromActivity()

    // Set Flutter's application state to detached.
    engine.lifecycleChannel.appIsDetached()

    // Detach rendering pipeline.
    flutterView!!.detachFromFlutterEngine()
  }
}
