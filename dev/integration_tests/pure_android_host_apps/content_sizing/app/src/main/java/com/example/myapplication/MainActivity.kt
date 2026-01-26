package com.example.myapplication

import android.os.Bundle
import android.content.Context
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.unit.dp
import com.example.myapplication.ui.theme.MyApplicationTheme
import io.flutter.embedding.android.FlutterView

class MainActivity : ComponentActivity() {

    private lateinit var flutterViewEngines: FlutterViewEngines

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        flutterViewEngines = FlutterViewEngines(applicationContext)
        flutterViewEngines.attachToActivity(this)

        setContent {
            MyApplicationTheme {
                Surface() {
                    Column(modifier = Modifier.fillMaxSize().background(Color.Yellow)) {
                        ContentSizedList(engines = flutterViewEngines)
                    }
                }
            }
        }
    }
}

@Composable
fun ContentSizedList(modifier: Modifier = Modifier, context: Context = LocalContext.current, engines: FlutterViewEngines) {
    val numFlutterViews = 3 
    val items = (1..numFlutterViews).toList()

    LazyColumn(modifier = modifier) {
        items(items) { itemNumber ->
            ContentSizedView(context = context, itemText = itemNumber.toString(), engines = engines)
        }
    }
}

@Composable
fun ContentSizedView(context: Context = LocalContext.current, itemText: String, modifier: Modifier = Modifier, engines: FlutterViewEngines) {

    val flutterViewEngine = remember(itemText) {
        engines.createAndRunEngine(itemText, listOf())
    }
    AndroidView(
        factory = { context ->
            FlutterView(context)
        },
        update = { flutterView ->
            flutterViewEngine.attachFlutterView(flutterView)
        },
        modifier = modifier
            .padding(16.dp)
            .wrapContentHeight()
            .fillMaxWidth()
            .background(Color.LightGray),
    )
}
