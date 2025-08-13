package com.flutter.gradle.tasks

import com.flutter.gradle.AppLinkSettings
import com.flutter.gradle.Deeplink
import com.flutter.gradle.IntentFilterCheck
import groovy.util.Node
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction
import kotlin.io.writeText

/**
 * Create a json file of deeplink settings from an AndroidManifest.
 *
 * This task does not modify the manifest despite using an api
 * designed for modification. The task is responsible for an exact copy of the input
 * manifest being used for the output manifest.
 *
 * An example json:
 * {
 *     applicationId: "com.example.app",
 *         deeplinks: [
 *             {"scheme":"http", "host":"example.com", "path":".*"},
 *             {"scheme":"https","host":"example.com","path":".*"}
 *     ]
 * }
*/
abstract class DeepLinkJsonFromManifestTask : DefaultTask() {
    private val MANIFEST_NAME_KEY = "android:name"
    private val MANIFEST_VALUE_KEY = "android:value"
    private val MANIFEST_VALUE_TRUE = "true"

    // Input property to receive the manifest file
    @get:InputFile
    abstract val manifestFile: RegularFileProperty

    // In the past for this task namespace was the ApplicationId.
    @get:Input
    abstract val namespace: Property<String>

    // Does not need to transform manifest at all but there does not appear to be another dsl
    // supported way to depend on the merged manifest.
    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @get:OutputFile
    abstract val deepLinkJson: RegularFileProperty

    @TaskAction
    fun processManifest() {
        val manifestFile = manifestFile.get().asFile
        updatedManifest.asFile.get().writeText(manifestFile.readText())
        val manifestNode: Node =
            groovy.xml
                .XmlParser(false, false)
                .parse(manifestFile)
        logger.debug("DeepLinkJsonFromManifestTask: Unmodified manifest written.")

        val appLinkSettings = createAppLinkSettings(namespace.get(), manifestNode)
        logger.debug("DeepLinkJsonFromManifestTask: appLinkSettings created.")

        deepLinkJson.asFile.get().writeText(appLinkSettings.toJson().toString())
        logger.debug("DeepLinkJsonFromManifestTask: appLinkSettings written to ${deepLinkJson.get().asFile.absolutePath}.")
    }

    /**
     * Extracts app deeplink information from the Android manifest file then returns
     * an AppLinkSettings object.
     *
     * @param applicationId The application ID or namespace of the variant.
     * @param manifest groovy.xml node representing the Android manifest to be parsed.
     */
    public fun createAppLinkSettings(
        applicationId: String,
        manifest: Node,
    ): AppLinkSettings {
        val appLinkSettings = AppLinkSettings(applicationId)
        val applicationNode: Node? =
            manifest.children().find { node ->
                node is Node && node.name() == "application"
            } as Node?
        if (applicationNode == null) {
            return appLinkSettings
        }
        val activities: List<Node> =
            applicationNode.children().filterIsInstance<Node>().filter { item ->
                item.name() == "activity"
            }

        activities.forEach { activity ->
            val metaDataItems: List<Node> =
                activity.children().filterIsInstance<Node>().filter { metaItem ->
                    metaItem.name() == "meta-data"
                }
            metaDataItems.forEach { metaDataItem ->
                val nameAttribute: Boolean =
                    metaDataItem.attribute(MANIFEST_NAME_KEY) == "flutter_deeplinking_enabled"
                val valueAttribute: Boolean =
                    metaDataItem.attribute(MANIFEST_VALUE_KEY) == MANIFEST_VALUE_TRUE
                if (nameAttribute && valueAttribute) {
                    appLinkSettings.deeplinkingFlagEnabled = true
                }
            }
            val intentFilterItems: List<Node> =
                activity.children().filterIsInstance<Node>().filter { filterItem ->
                    filterItem.name() == "intent-filter"
                }
            intentFilterItems.forEach { appLinkIntent ->
                // Print out the host attributes in data tags.
                val schemes: MutableSet<String?> = mutableSetOf()
                val hosts: MutableSet<String?> = mutableSetOf()
                val paths: MutableSet<String?> = mutableSetOf()
                val intentFilterCheck = IntentFilterCheck()
                if (appLinkIntent.attribute("android:autoVerify") == MANIFEST_VALUE_TRUE) {
                    intentFilterCheck.hasAutoVerify = true
                }

                val actionItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "action"
                    }
                // Any action item causes intentFilterCheck to always be true
                // and we keep looping instead of exiting out early.
                // TODO: Exit out early per intent filter action view.
                actionItems.forEach { action ->
                    if (action.attribute(MANIFEST_NAME_KEY) == "android.intent.action.VIEW") {
                        intentFilterCheck.hasActionView = true
                    }
                }
                val categoryItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "category"
                    }
                categoryItems.forEach { category ->
                    // TODO: Exit out early per intent filter default category.
                    if (category.attribute(MANIFEST_NAME_KEY) == "android.intent.category.DEFAULT") {
                        intentFilterCheck.hasDefaultCategory = true
                    }
                    // TODO: Exit out early per intent filter browsable category.
                    if (category.attribute(MANIFEST_NAME_KEY) == "android.intent.category.BROWSABLE") {
                        intentFilterCheck.hasBrowsableCategory =
                            true
                    }
                }
                val dataItems: List<Node> =
                    appLinkIntent.children().filterIsInstance<Node>().filter { item ->
                        item.name() == "data"
                    }
                dataItems.forEach { data ->
                    data.attributes().forEach { entry ->
                        when (entry.key) {
                            "android:scheme" -> schemes.add(entry.value.toString())
                            "android:host" -> hosts.add(entry.value.toString())
                            // All path patterns add to paths.
                            "android:pathAdvancedPattern" ->
                                paths.add(
                                    entry.value.toString(),
                                )

                            "android:pathPattern" -> paths.add(entry.value.toString())
                            "android:path" -> paths.add(entry.value.toString())
                            "android:pathPrefix" -> paths.add(entry.value.toString() + ".*")
                            "android:pathSuffix" -> paths.add(".*" + entry.value.toString())
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
                    // Sets are not ordered this could produce a bug.
                    schemes.forEach { scheme ->
                        hosts.forEach { host ->
                            paths.forEach { path ->
                                appLinkSettings.deeplinks.add(
                                    Deeplink(
                                        scheme,
                                        host,
                                        path,
                                        intentFilterCheck,
                                    ),
                                )
                            }
                        }
                    }
                }
            }
        }
        return appLinkSettings
    }
}
