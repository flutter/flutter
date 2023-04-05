import org.gradle.api.Plugin
import org.gradle.api.initialization.Settings

class FlutterSettingsPlugin implements Plugin<Settings> {
    @Override
    void apply(Settings settings) {
        println("Hello from the FlutterSettingsPlugin")
    }
}
