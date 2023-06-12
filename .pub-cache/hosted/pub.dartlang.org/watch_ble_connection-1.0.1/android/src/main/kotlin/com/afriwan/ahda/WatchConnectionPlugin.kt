package com.afriwan.ahda

import android.app.Activity
import androidx.annotation.NonNull
import com.google.android.gms.wearable.*
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.json.JSONObject
import kotlin.reflect.typeOf

/** WatchConnectionPlugin */
public class WatchConnectionPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, MessageClient.OnMessageReceivedListener, DataClient.OnDataChangedListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var activity: Activity? = null
    private val messageListenerIds = mutableListOf<Int>()
    private val dataListenerIds = mutableListOf<Int>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "watchConnection")
    channel.setMethodCallHandler(this);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "watchConnection")
      channel.setMethodCallHandler(WatchConnectionPlugin())
    }
      const val TAG = "WatchConnection"
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "sendMessage" -> {
            sendMessage(call, result)
        }
        "setData" -> {
            setData(call, result)
        }
        "listenMessages" -> {
            registerMessageListener(call)
            result.success(null)
        }
        "listenData" -> {
            registerDataLayerListener(call)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

    private fun registerMessageListener(call: MethodCall) {
        try {
            val id = call.arguments<Int>()
            messageListenerIds.add(id)
        } catch (ex: Exception) {
            Log.e(TAG, ex.localizedMessage, ex)
        }
    }

    private fun registerDataLayerListener(call: MethodCall) {
        try {
            val id = call.arguments<Int>()
            dataListenerIds.add(id)
        } catch (ex: Exception) {
            Log.e(TAG, ex.localizedMessage, ex)
        }
    }

    private fun sendMessage(call: MethodCall, result: Result) {
        if (activity == null) {
            result.success(null)
        } else {
            try {
                val argument = call.arguments<HashMap<String, Any>>()
                val client = Wearable.getMessageClient(activity!!)
                Wearable.getNodeClient(activity!!).connectedNodes.addOnSuccessListener { nodes ->
                    nodes.forEach { node ->
                        val json = JSONObject(argument as Map<Any?, Any?>).toString()
                        client.sendMessage(node.id, "/MessageChannel", json.toByteArray()).addOnSuccessListener {
                            Log.d(TAG,"sent message: $json to ${node.displayName}")
                        }
                    }
                    result.success(null)
                }.addOnFailureListener { ex ->
                    result.error(ex.message, ex.localizedMessage, ex)
                }

            } catch (ex: Exception) {
                Log.d(TAG, "Failed to send message", ex)
            }
        }
    }

    private fun setData(call: MethodCall, result: Result) {
        try {
            val data = call.argument<HashMap<String, Any>>("data") ?: return
            Log.d(TAG, data.toString())
            val name = call.argument<String>("path") ?: return
            val request = PutDataMapRequest.create(name).run {
                loop@ for ((key, value) in data) {
                    when(value) {
                        is String -> {
                            dataMap.putString(key, value)
                        }
                        is Int -> dataMap.putInt(key, value)
                        is Float -> dataMap.putFloat(key, value)
                        is Double -> dataMap.putDouble(key, value)
                        is Long -> dataMap.putLong(key, value)
                        is Boolean -> dataMap.putBoolean(key, value)
                        is List<*> -> {
                            if (value.isNullOrEmpty()) continue@loop
                            value.asArrayListOfType<Int>()?.let {
                                dataMap.putIntegerArrayList(key, it)
                            }
                            value.asArrayListOfType<String>()?.let {
                                dataMap.putStringArrayList(key, it)
                            }
                            value.asArrayOfType<Float>()?.let {
                                dataMap.putFloatArray(key, it.toFloatArray())
                            }
                            value.asArrayOfType<Long>()?.let {
                                dataMap.putLongArray(key, it.toLongArray())
                            }
                        }
                        else -> {
                            Log.d(TAG, "could not translate value of type ${value.javaClass.name}")
                        }
                    }
                }
                asPutDataRequest()
            }
            Wearable.getDataClient(activity!!).putDataItem(request).addOnSuccessListener {
                Log.d(TAG, "Set data on wear")
            }
            result.success(null)
        } catch (ex: Exception) {
            Log.e(TAG, "Failed to send message", ex)
        }
    }

      override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
      }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        startWearableClients(activity!!)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        val a = activity ?: return
        detachWearableClients(a)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        startWearableClients(activity!!)
    }

    override fun onDetachedFromActivity() {
        val a = activity ?: return
        detachWearableClients(a)
        activity = null
    }

    private fun startWearableClients(a: Activity) {
        Wearable.getMessageClient(a).addListener(this)
        Wearable.getDataClient(a).addListener(this)
    }

    private fun detachWearableClients(a: Activity) {
        Wearable.getMessageClient(a).removeListener(this)
        Wearable.getDataClient(a).removeListener(this)
    }

    override fun onMessageReceived(message: MessageEvent) {
        val data = String(message.data)
        messageListenerIds.forEach { id ->
            channel.invokeMethod("messageReceived", hashMapOf(
                    "id" to id,
                    "args" to data
            ))
        }

    }

    override fun onDataChanged(events: DataEventBuffer) {
        events.forEach { event ->
            if (event.type == DataEvent.TYPE_CHANGED) {
                val datamap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val map = hashMapOf<String, Any>()
                for (key in datamap.keySet()) {
                    map[key] = datamap.get(key)
                }
                dataListenerIds.forEach { id ->
                    channel.invokeMethod("dataReceived", hashMapOf(
                        "id" to id,
                        "args" to map
                    ))
                }
                
            }
        }
    }
}

inline fun <reified T> List<*>.asArrayListOfType(): ArrayList<T>? =
        if (all { it is T })
            @Suppress("UNCHECKED_CAST")
            this as ArrayList<T> else
            null

inline fun <reified T> List<*>.asArrayOfType(): Array<T>? =
        if (all { it is T })
            @Suppress("UNCHECKED_CAST")
            this as Array<T> else
            null

