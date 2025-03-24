package com.flutter.gradle

import com.android.build.gradle.api.BaseVariantOutput
import com.android.build.gradle.tasks.ProcessAndroidResources
import groovy.util.Node
import groovy.util.XmlParser
import org.gradle.api.Project
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCollection
import java.io.File

/**
 * Stateless object to contain the logic used in [FlutterTask]. Any required state should be stored
 * on [FlutterTask] instead, while any logic needed by [FlutterTask] should be added here.
 */
object FlutterTaskHelper {
    const val FLUTTER_ASSETS_INCLUDE_DIRECTORY = "flutter_assets/**"

    internal fun getOutputDirectory(flutterTask: FlutterTask): File? = flutterTask.intermediateDir

    internal fun getAssetsDirectory(flutterTask: FlutterTask): String = "${flutterTask.outputDirectory}/flutter_assets"

    internal fun getAssets(
        project: Project,
        flutterTask: FlutterTask
    ): CopySpec =
        project.copySpec {
            from("${flutterTask.intermediateDir}")
            include(FLUTTER_ASSETS_INCLUDE_DIRECTORY) // the working dir and its files
        }

    internal fun getSnapshots(
        project: Project,
        flutterTask: FlutterTask
    ): CopySpec =
        project.copySpec {
            from("${flutterTask.intermediateDir}")
            if (flutterTask.buildMode == "release" || flutterTask.buildMode == "profile") {
                flutterTask.targetPlatformValues!!.forEach { targetArch ->
                    include("${FlutterPluginConstants.PLATFORM_ARCH_MAP[targetArch]}/app.so")
                }
            }
        }

    private fun readDependencies(
        project: Project,
        dependenciesFile: File,
        inputs: Boolean
    ): FileCollection {
        if (dependenciesFile.exists()) {
            // Dependencies file has Makefile syntax:
            //   <target> <files>: <source> <files> <separated> <by> <non-escaped space>
            val depText = dependenciesFile.readText()
            // So we split list of files by non-escaped(by backslash) space,
            val parts = depText.split(": ")
            val fileString = parts[if (inputs) 1 else 0]
            val matcher = Regex("""(\\ |\S)+""").findAll(fileString)
            // then we replace all escaped spaces with regular spaces
            val depList =
                matcher.map { it.value.replace("\\\\ ", " ") }.toList()
            return project.files(depList)
        }
        return project.files()
    }

    internal fun getSourceFiles(
        project: Project,
        flutterTask: FlutterTask
    ): FileCollection {
        var sources: FileCollection = project.files()
        flutterTask.getDependenciesFiles().forEach { dependenciesFile ->
            sources += readDependencies(project, dependenciesFile, true)
        }
        return sources + project.files("pubspec.yaml")
    }

    internal fun getOutputFiles(
        project: Project,
        flutterTask: FlutterTask
    ): FileCollection {
        var outputs: FileCollection = project.files()
        flutterTask.getDependenciesFiles().forEach { dependenciesFile ->
            outputs += readDependencies(project, dependenciesFile, false)
        }
        return outputs
    }

    internal fun build(flutterTask: FlutterTask) {
        flutterTask.buildBundle()
    }

    internal fun findProcessResources(baseVariantOutput: BaseVariantOutput): ProcessAndroidResources {
        // Semantic change, baseVariant does not have a hasProperty method but that
        // is what the groovy code was checking.
        // val processResources = project.hasProperty(FlutterPluginConstants.PROP_PROCESS_RESOURCES_PROVIDER) ?
        // baseVariantOutput.processResourcesProvider.get() : baseVariantOutput.processResources
        return baseVariantOutput.processResources
    }

    /**
     * Adds required tasks for the AppLinkSettings feature.
     *
     * Should only be called if the build target is an app, as opposed to an aar/module.
     *
     * Add a task that can be called on Flutter projects that outputs app link related project
     * settings into a json file.
     * See https://developer.android.com/training/app-links/ for more information about app link.
     * The json will be saved in path stored in outputPath parameter.
     *
     * An example json:
     *  {
     *      applicationId: "com.example.app",
     *          deeplinks: [
     *              {"scheme":"http", "host":"example.com", "path":".*"},
     *              {"scheme":"https","host":"example.com","path":".*"}
     *          ]
     *  }
     * The output file is parsed and used by devtool.
     */
    internal fun addTasksForOutputsAppLinkSettings(project: Project) {
        // Integration test for AppLinkSettings task defined in
        // flutter/flutter/packages/flutter_tools/test/integration.shard/android_gradle_outputs_app_link_settings_test.dart
        val android = FlutterPluginUtils.getAndroidExtensionOrNull(project)
        if (android == null) {
            project.logger.info("addTasksForOutputsAppLinkSettings called on project without android extension")
            return
        }
        android.applicationVariants.configureEach {
            val variant = this
            project.tasks.register("output${FlutterPluginUtils.capitalize(variant.name)}AppLinkSettings") {
                val task = this
                task.description =
                    "stores app links settings for the given build variant of this Android project into a json file."
                variant.outputs.configureEach {
                    val baseVariantOutput = this
                    // Deeplinks are defined in AndroidManifest.xml and is only available after
                    // processResourcesProvider.
                    dependsOn(findProcessResources(baseVariantOutput))
                }
                doLast {
                    // We are configuring the same object before a doLast and in a doLast.
                    // without a clear reason why. That is not good.
                    variant.outputs.configureEach {
                        val baseVariantOutput = this

                        val appLinkSettings = AppLinkSettings(variant.applicationId)
                        // TODO use import groovy.xml.XmlParser instead.
                        // It is not namespace aware because it makes querying nodes cumbersome.
                        val manifest: Node =
                            XmlParser(false, false).parse(findProcessResources(baseVariantOutput).manifestFile)
                        // The new import would use getProperty like
                        // manifest.getProperty("application").let { applicationNode -> ...
                        val applicationNode: Node? =
                            manifest.children().find { node ->
                                node is Node && node.name() == "application"
                            } as Node?

                        applicationNode?.let { appNode ->
                            val activities: List<Any?> =
                                appNode.children().filter { item ->
                                    item is Node && item.name() == "activity"
                                }

                            activities.forEach { activity ->
                                if (activity is Node) {
                                    val metaDataItems: List<Any?> =
                                        activity.children().filter { metaItem ->
                                            metaItem is Node && metaItem.name() == "meta-data"
                                        }
                                    metaDataItems.forEach { metaDataItem ->
                                        if (metaDataItem is Node) {
                                            val nameAttribute: Boolean =
                                                metaDataItem.attribute("android:name") == "flutter_deeplinking_enabled"
                                            val valueAttribute: Boolean =
                                                metaDataItem.attribute("android:value") == "true"
                                            if (nameAttribute && valueAttribute) {
                                                appLinkSettings.deeplinkingFlagEnabled = true
                                            }
                                        }
                                    }
                                    val intentFilterItems: List<Any?> =
                                        activity.children().filter { filterItem ->
                                            filterItem is Node && filterItem.name() == "intent-filter"
                                        }
                                    intentFilterItems.forEach { appLinkIntent ->
                                        if (appLinkIntent is Node) {
                                            // Print out the host attributes in data tags.
                                            val schemes: MutableSet<String?> = mutableSetOf()
                                            val hosts: MutableSet<String?> = mutableSetOf()
                                            val paths: MutableSet<String?> = mutableSetOf()
                                            val intentFilterCheck = IntentFilterCheck()
                                            if (appLinkIntent.attribute("android:autoVerify") == "true") {
                                                intentFilterCheck.hasAutoVerify = true
                                            }

                                            val actionItems: List<Any?> =
                                                appLinkIntent.children().filter { item ->
                                                    item is Node && item.name() == "action"
                                                }
                                            // Weird that any action item causes intentFilterCheck to always be true
                                            // and we keep looping.
                                            actionItems.forEach { action ->
                                                if (action is Node) {
                                                    if (action.attribute("android:name") == "android.intent.action.VIEW") {
                                                        intentFilterCheck.hasActionView = true
                                                    }
                                                }
                                            }
                                            val categoryItems: List<Any?> =
                                                appLinkIntent.children().filter { item ->
                                                    item is Node && item.name() == "category"
                                                }
                                            categoryItems.forEach { category ->
                                                if (category is Node) {
                                                    if (category.attribute("android:name") == "android.intent.category.DEFAULT") {
                                                        intentFilterCheck.hasDefaultCategory = true
                                                    }
                                                    if (category.attribute("android:name") == "android.intent.category.BROWSABLE") {
                                                        intentFilterCheck.hasBrowsableCategory =
                                                            true
                                                    }
                                                }
                                            }
                                            val dataItems: List<Any?> =
                                                appLinkIntent.children().filter { item ->
                                                    item is Node && item.name() == "data"
                                                }
                                            dataItems.forEach { data ->
                                                if (data is Node) {
                                                    data.attributes().forEach { entry ->
                                                        when ((entry.key)) {
                                                            "android:scheme" -> schemes.add(entry.value.toString())
                                                            "android:host" -> hosts.add(entry.value.toString())
                                                            // All path patterns add to paths.
                                                            "android:pathAdvancedPattern" ->
                                                                paths.add(
                                                                    entry.value.toString()
                                                                )

                                                            "android:pathPattern" -> paths.add(entry.value.toString())
                                                            "android:path" -> paths.add(entry.value.toString())
                                                            "android:pathPrefix" -> paths.add(entry.value.toString() + ".*")
                                                            "android:pathSuffix" -> paths.add(".*" + entry.value.toString())
                                                        }
                                                    }
                                                }
                                            }
                                            if (hosts.isNotEmpty() || paths.isNotEmpty()) {
                                                if (schemes.isEmpty()) {
                                                    schemes.add(null)
                                                }
                                                if (hosts.isEmpty()) {
                                                    hosts.add(null)
                                                }
                                                if (paths.isEmpty()) {
                                                    paths.add(".*")
                                                }
                                                // Sets are not ordered this is dangerous.
                                                schemes.forEach { scheme ->
                                                    hosts.forEach { host ->
                                                        paths.forEach { path ->
                                                            appLinkSettings.deeplinks.add(
                                                                Deeplink(
                                                                    scheme,
                                                                    host,
                                                                    path,
                                                                    intentFilterCheck
                                                                )
                                                            )
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    File(project.property("outputPath").toString()).writeText(
                                        appLinkSettings.toJson().toString()
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
