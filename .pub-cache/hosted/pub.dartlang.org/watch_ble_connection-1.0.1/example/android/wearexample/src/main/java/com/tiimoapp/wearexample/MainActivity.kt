package com.tiimoapp.wearexample

import android.net.Uri
import android.os.Bundle
import android.support.wearable.activity.WearableActivity
import android.util.Log
import com.google.android.gms.wearable.*
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : WearableActivity(), DataClient.OnDataChangedListener, MessageClient.OnMessageReceivedListener {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Enables Always-on
        setAmbientEnabled()

        messageBtn.setOnClickListener {
            val messageClient = Wearable.getMessageClient(this)
            Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
                nodes.forEach {
                    messageClient.sendMessage(it.id, "/message", "From wear".toByteArray()).addOnSuccessListener {
                        Log.d("Wear", "Sent message to phone")
                    }
                }
            }
        }
        dataBtn.setOnClickListener {
            val request = PutDataMapRequest.create("wear").run {
                dataMap.putString("fromWatch", "Hello from watch")
                asPutDataRequest()
            }
            Wearable.getDataClient(this).putDataItem(request).addOnSuccessListener {
                Log.d("Wear", "Set data on wear")
            }
        }

        val nodeClient = Wearable.getNodeClient(this)
        val nodes = nodeClient.connectedNodes
        nodes.addOnCompleteListener { nodesTask ->
            if (nodesTask.result?.isEmpty() != false){
                return@addOnCompleteListener
            }
            nodesTask.result?.forEach { item ->
                val uri = Uri.Builder()
                        .scheme(PutDataRequest.WEAR_URI_SCHEME)
                        .path("/message")
                        .authority(item.id)
                        .build()

                val dataItem = Wearable.getDataClient(this).getDataItem(uri)
                dataItem.addOnCompleteListener {
                    if (it.isSuccessful && it.result != null){
                        val dataMap = DataMapItem.fromDataItem(it.result!!).dataMap
                        val text = dataMap.getString("text")
                        Log.d("Wear", text)
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()

        Wearable.getMessageClient(this).addListener(this)
        Wearable.getDataClient(this).addListener(this)
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents.forEach { event ->
            if (event.type == DataEvent.TYPE_CHANGED) {
                Log.d("Wear", event.toString())
            }
        }
    }

    override fun onMessageReceived(message: MessageEvent) {
        Log.d("Wear", String(message.data))

    }
}
