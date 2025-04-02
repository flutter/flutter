package com.flutter.gradle.plugins

import org.gradle.api.Project

class PluginConfigurer(
    val project: Project
) {
    private var pluginList: List<Map<String?, Any?>>? = null
    private var pluginDependencies: List<Map<String?, Any?>>? = null
}
