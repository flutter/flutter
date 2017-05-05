package io.flutter.plugins;

import io.flutter.app.FlutterActivity;

import io.flutter.plugins.url_launcher.UrlLauncherPlugin;

/**
 * Generated file. Do not edit.
 */

public class PluginRegistry {
    public UrlLauncherPlugin url_launcher;

    public void registerAll(FlutterActivity activity) {
        url_launcher = UrlLauncherPlugin.register(activity);
    }
}
