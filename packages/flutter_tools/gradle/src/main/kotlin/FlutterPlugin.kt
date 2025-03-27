package com.flutter.gradle

import com.flutter.gradle.FlutterPluginUtils.readPropertiesIfExist
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.internal.os.OperatingSystem
import java.io.File
import java.nio.file.Paths
import java.util.Properties

class FlutterPlugin : Plugin<Project> {
    companion object {
        const val PROP_LOCAL_ENGINE_REPO: String = "local-engine-repo"

        /**
         * The name prefix for flutter builds. This is used to identify gradle tasks
         * where we expect the flutter tool to provide any error output, and skip the
         * standard Gradle error output in the FlutterEventLogger. If you change this,
         * be sure to change any instances of this string in symbols in the code below
         * to match.
         */
        const val FLUTTER_BUILD_PREFIX: String = "flutterBuild"
    }

    private var project: Project? = null
    private var flutterRoot: File? = null
    private var flutterExecutable: File? = null
    private var localEngine: String? = null
    private var localEngineHost: String? = null
    private var localEngineSrcPath: String? = null
    private var localProperties: Properties? = null
    private var engineVersion: String? = null
    private var engineRealm: String? = null
    private var pluginList: List<Map<String, Any?>?>? = null
    private var pluginDependencies: List<Map<String, Any?>?>? = null

    override fun apply(project: Project) {
        this.project = project

        val rootProject = project.rootProject
        if (FlutterPluginUtils.isFlutterAppProject(project)) {
            addTaskForLockfileGeneration(rootProject)
        }

        val flutterRootSystemVal: String? = System.getenv("FLUTTER_ROOT")
        val flutterRootPath: String =
            resolveProperty("flutter.sdk", flutterRootSystemVal)
                ?: throw GradleException(
                    "Flutter SDK not found. Define location with flutter.sdk in the " +
                        "local.properties file or with a FLUTTER_ROOT environment variable."
                )

        flutterRoot = project.file(flutterRootPath)
        if (!flutterRoot!!.isDirectory) {
            throw GradleException("flutter.sdk must point to the Flutter SDK directory")
        }

        engineVersion =
            if (FlutterPluginUtils.shouldProjectUseLocalEngine(project)) {
                "+" // Match any version since there's only one.
            } else {
                val engineStampPath =
                    Paths.get(flutterRoot!!.absolutePath, "bin", "cache", "engine.stamp")
                val engineStampContent = engineStampPath.toFile().readText().trim()
                "1.0.0-$engineStampContent"
            }

        engineRealm =
            Paths
                .get(flutterRoot!!.absolutePath, "bin", "cache", "engine.realm")
                .toFile()
                .readText()
                .trim()
        engineRealm += "/"

        // Configure the Maven repository.
        val hostedRepository: String =
            System.getenv(FlutterPluginConstants.FLUTTER_STORAGE_BASE_URL)
                ?: FlutterPluginConstants.DEFAULT_MAVEN_HOST
        val repository: String? =
            if (FlutterPluginUtils.shouldProjectUseLocalEngine(project)) {
                project.property(PROP_LOCAL_ENGINE_REPO) as String?
            } else {
                "$hostedRepository/${engineRealm}download.flutter.io"
            }
        rootProject.allprojects {
            repositories.maven {
                url = uri(repository!!)
            }
        }

        project.apply(
            from =
                Paths.get(
                    flutterRoot!!.absolutePath,
                    "packages",
                    "flutter_tools",
                    "gradle",
                    "src",
                    "main",
                    "scripts",
                    "native_plugin_loader.gradle.kts"
                ).toFile()
        )
    }

    private fun resolveProperty(
        propertyName: String,
        defaultValue: String?
    ): String? {
        if (localProperties == null) {
            localProperties =
                readPropertiesIfExist(File(project!!.projectDir.parentFile, "local.properties"))
        }
        return project?.findProperty(propertyName) as? String ?: localProperties!!.getProperty(
            propertyName,
            defaultValue
        )
    }

    private fun addTaskForLockfileGeneration(rootProject: Project) {
        rootProject.tasks.register("generateLockfiles") {
            doLast {
                rootProject.subprojects.forEach { subproject ->
                    val gradlew: String =
                        if (OperatingSystem.current().isWindows) {
                            "${rootProject.projectDir}/gradlew.bat"
                        } else {
                            "${rootProject.projectDir}/gradlew"
                        }
                    rootProject.exec {
                        workingDir(rootProject.projectDir)
                        executable(gradlew)
                        args(":${subproject.name}:dependencies", "--write-locks")
                    }
                }
            }
        }
    }
}
