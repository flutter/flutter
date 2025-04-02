package com.flutter.gradle.plugins

import com.flutter.gradle.FlutterPluginUtils
import com.flutter.gradle.NativePluginLoaderReflectionBridge
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.plugin.extraProperties
import java.io.FileNotFoundException
import java.nio.charset.StandardCharsets

class PluginHandler(
    val project: Project
) {
    private var pluginList: List<Map<String?, Any?>>? = null
    private var pluginDependencies: List<Map<String?, Any?>>? = null

    /**
     * Gets the list of plugins (as map) that support the Android platform.
     *
     * The map value contains either the plugins `name` (String),
     * its `path` (String), or its `dependencies` (List<String>).
     * See [NativePluginLoader#getPlugins] in packages/flutter_tools/gradle/src/main/scripts/native_plugin_loader.gradle.kts
     */
    internal fun getPluginList(): List<Map<String?, Any?>> {
        if (pluginList == null) {
            pluginList =
                NativePluginLoaderReflectionBridge.getPlugins(
                    project.extraProperties,
                    FlutterPluginUtils.getFlutterSourceDirectory(project)
                )
        }
        return pluginList!!
    }

    // TODO(54566, 48918): Remove in favor of [getPluginList] only, see also
    //  https://github.com/flutter/flutter/blob/1c90ed8b64d9ed8ce2431afad8bc6e6d9acc4556/packages/flutter_tools/lib/src/flutter_plugins.dart#L212

    /** Gets the plugins dependencies from `.flutter-plugins-dependencies`. */
    internal fun getPluginDependencies(): List<Map<String?, Any?>> {
        if (pluginDependencies == null) {
            val meta: Map<String, Any> =
                NativePluginLoaderReflectionBridge.getDependenciesMetadata(
                    project.extraProperties,
                    FlutterPluginUtils.getFlutterSourceDirectory(project)
                )
            // there should be a null check here, skip for now. I think I messed up platform types.
            check(meta["dependencyGraph"] is List<*>)
            @Suppress("UNCHECKED_CAST") // just for now :)
            pluginDependencies = meta["dependencyGraph"] as List<Map<String?, Any?>>
        }
        return pluginDependencies!!
    }

    // TODO(54566, 48918): Can remove once the issues are resolved.
    //  This means all references to `.flutter-plugins` are then removed and
    //  apps only depend exclusively on the `plugins` property in `.flutter-plugins-dependencies`.

    /**
     * Workaround to load non-native plugins for developers who may still use an
     * old `settings.gradle` which includes all the plugins from the
     * `.flutter-plugins` file, even if not made for Android.
     * The settings.gradle then:
     *     1) tries to add the android plugin implementation, which does not
     *        exist at all, but is also not included successfully
     *        (which does not throw an error and therefore isn't a problem), or
     *     2) includes the plugin successfully as a valid android plugin
     *        directory exists, even if the surrounding flutter package does not
     *        support the android platform (see e.g. apple_maps_flutter: 1.0.1).
     *        So as it's included successfully it expects to be added as API.
     *        This is only possible by taking all plugins into account, which
     *        only appear on the `dependencyGraph` and in the `.flutter-plugins` file.
     * So in summary the plugins are currently selected from the `dependencyGraph`
     * and filtered then with the [doesSupportAndroidPlatform] method instead of
     * just using the `plugins.android` list.
     */
    private fun configureLegacyPluginEachProjects(engineVersionValue: String) {
        try {
            // Read the contents of the settings.gradle file.
            // Remove block/line comments
            var settingsText =
                FlutterPluginUtils
                    .getSettingsGradleFileFromProjectDir(
                        project.projectDir,
                        project.logger
                    ).readText(StandardCharsets.UTF_8)
            settingsText =
                settingsText
                    .replace(Regex("""(?s)/\*.*?\*/"""), "")
                    .replace(Regex("""(?m)//.*$"""), "")
            if (!settingsText.contains("'.flutter-plugins'")) {
                return
            }
        } catch (ignored: FileNotFoundException) {
            throw GradleException(
                "settings.gradle/settings.gradle.kts does not exist: " +
                    FlutterPluginUtils
                        .getSettingsGradleFileFromProjectDir(
                            project.projectDir,
                            project.logger
                        ).absolutePath
            )
        }
        // TODO(matanlurey): https://github.com/flutter/flutter/issues/48918.
        project.logger.quiet(
            """
            Warning: This project is still reading the deprecated '.flutter-plugins. file.
            In an upcoming stable release support for this file will be completely removed and your build will fail.
            See https:/flutter.dev/to/flutter-plugins-configuration.
            """.trimIndent()
        )
        val deps: List<Map<String?, Any?>> = getPluginDependencies()
        val pluginsNameSet = HashSet<String>()
        getPluginList().mapTo(pluginsNameSet) { plugin -> plugin["name"] as String }
        deps.filterNot { plugin -> pluginsNameSet.contains(plugin["name"]) }
        deps.forEach { plugin: Map<String?, Any?> ->
            val pluginProject = project.rootProject.findProject(":${plugin["name"]}")
            if (pluginProject == null) {
                // Plugin was not included in `settings.gradle`, but is listed in `.flutter-plugins`.
                project.logger.error(
                    "Plugin project :${plugin["name"]} listed, but not found. Please fix your settings.gradle/settings.gradle.kts."
                )
            } else if (FlutterPluginUtils.pluginSupportsAndroidPlatform(pluginProject)) {
                // Plugin has a functioning `android` folder and is included successfully, although it's not supported.
                // It must be configured nonetheless, to not throw an "Unresolved reference" exception.
                FlutterPluginUtils.configurePluginProject(project, plugin, engineVersionValue)
            } else {
                // Plugin has no or an empty `android` folder. No action required.
            }
        }
    }
}
