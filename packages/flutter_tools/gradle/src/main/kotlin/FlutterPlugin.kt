// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.api.ApkVariant
import com.android.build.gradle.tasks.PackageAndroidArtifact
import com.android.build.gradle.tasks.ProcessAndroidResources
import com.flutter.gradle.FlutterPluginUtils.readPropertiesIfExist
import com.flutter.gradle.plugins.PluginHandler
import com.flutter.gradle.tasks.FlutterTask
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.tasks.bundling.Jar
import org.gradle.internal.os.OperatingSystem
import org.gradle.kotlin.dsl.support.serviceOf
import org.gradle.process.ExecOperations
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Paths
import java.util.Properties

class FlutterPlugin : Plugin<Project> {
    private var project: Project? = null
    private var flutterRoot: File? = null
    private var flutterExecutable: File? = null
    private var localEngine: String? = null
    private var localEngineHost: String? = null
    private var localEngineSrcPath: String? = null
    private var localProperties: Properties? = null
    private var engineVersion: String? = null
    private var engineRealm: String? = null
    private var pluginHandler: PluginHandler? = null

    override fun apply(project: Project) {
        this.project = project

        val rootProject = project.rootProject
        if (FlutterPluginUtils.isFlutterAppProject(project)) {
            addTaskForLockfileGeneration(rootProject)
        }

        val flutterRootSystemVal: String? = System.getenv("FLUTTER_ROOT")
        val flutterRootPath: String =
            resolveFlutterSdkProperty(flutterRootSystemVal)
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
        if (engineRealm!!.isNotEmpty()) {
            engineRealm += "/"
        }

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

        project.apply {
            from(
                Paths.get(
                    flutterRoot!!.absolutePath,
                    "packages",
                    "flutter_tools",
                    "gradle",
                    "src",
                    "main",
                    "scripts",
                    "native_plugin_loader.gradle.kts"
                )
            )
        }

        val flutterExtension: FlutterExtension =
            project.extensions.create("flutter", FlutterExtension::class.java)

        // TODO(gmackall): is this actually a different properties file than the previous one?
        val rootProjectLocalProperties = Properties()
        val rootProjectLocalPropertiesFile = rootProject.file("local.properties")
        if (rootProjectLocalPropertiesFile.exists()) {
            rootProjectLocalPropertiesFile.reader(StandardCharsets.UTF_8).use { reader ->
                rootProjectLocalProperties.load(reader)
            }
        }
        flutterExtension.flutterVersionCode =
            rootProjectLocalProperties.getProperty("flutter.versionCode", "1")
        flutterExtension.flutterVersionName =
            rootProjectLocalProperties.getProperty("flutter.versionName", "1.0")

        this.addFlutterTasks(project)

        // By default, assembling APKs generates fat APKs if multiple platforms are passed.
        // Configuring split per ABI allows to generate separate APKs for each abi.
        // This is a noop when building a bundle.
        if (FlutterPluginUtils.shouldProjectSplitPerAbi(project)) {
            FlutterPluginUtils.getAndroidExtension(project).splits.abi {
                isEnable = true
                reset()
                isUniversalApk = false
            }
        } else {
            // When splits-per-abi is NOT enabled, configure abiFilters to control which
            // native libraries are included in the APK.
            //
            // This is crucial: If a project includes third-party dependencies with x86 native libraries,
            // without these abiFilters, Google Play would incorrectly identify the app as supporting x86.
            // When users with x86 devices install the app, it would crash at runtime because Flutter's
            // native libraries aren't available for x86. By filtering out x86 at build time, Google Play
            // correctly excludes x86 devices from the compatible device list.
            //
            // NOTE: This code does NOT affect "add-to-app" scenarios because:
            // 1. For 'flutter build aar': abiFilters have no effect since libflutter.so and libapp.so
            //    are not packaged into AAR artifacts - they are only added as dependencies
            //    in pom files.
            // 2. For project dependencies (implementation(project(":flutter"))): The Flutter
            //    Gradle Plugin is not applied to the main app subproject, so this apply()
            //    method is never called.
            //
            // abiFilters cannot be added to templates because it would break builds when
            // --splits-per-abi is used due to conflicting configuration. This approach
            // adds them programmatically only when splits are not configured.
            //
            // If the user has specified abiFilters in their build.gradle file, those
            // settings will take precedence over these defaults.
            if (!FlutterPluginUtils.shouldProjectDisableAbiFiltering(project)) {
                FlutterPluginUtils.getAndroidExtension(project).buildTypes.forEach { buildType ->
                    buildType.ndk.abiFilters.clear()
                    FlutterPluginConstants.DEFAULT_PLATFORMS.forEach { platform ->
                        val abiValue: String =
                            FlutterPluginConstants.PLATFORM_ARCH_MAP[platform]
                                ?: throw GradleException("Invalid platform: $platform")
                        buildType.ndk.abiFilters.add(abiValue)
                    }
                }
            }
        }
        val propDeferredComponentNames = "deferred-component-names"
        val deferredComponentNamesValue: String? =
            project.findProperty(propDeferredComponentNames) as? String
        if (deferredComponentNamesValue != null) {
            val componentNames: Set<String> =
                deferredComponentNamesValue
                    .split(',')
                    .map { ":$it" }
                    .toSet()
            // TODO(gmackall): Unify the types we use for the android extension. This is yet
            //   another type we need unfortunately.
            val androidExtensionAsApplicationExtension =
                project.extensions.getByType(ApplicationExtension::class.java)
            // TODO(gmackall): Should we clear here? I think this is equivalent to what we used to
            //    do, but unsure. Can't use a closure.
            androidExtensionAsApplicationExtension.dynamicFeatures.clear()
            androidExtensionAsApplicationExtension.dynamicFeatures.addAll(componentNames)
        }

        FlutterPluginUtils.getTargetPlatforms(project).forEach { targetArch ->
            val abiValue: String? = FlutterPluginConstants.PLATFORM_ARCH_MAP[targetArch]
            val androidExtension: BaseExtension = FlutterPluginUtils.getAndroidExtension(project)
            androidExtension.splits.abi.include(abiValue!!)
        }

        val flutterExecutableName = getExecutableNameForPlatform("flutter")
        flutterExecutable =
            Paths.get(flutterRoot!!.absolutePath, "bin", flutterExecutableName).toFile()

        // Validate that the provided Gradle, Java, AGP, and KGP versions are all within our
        // supported range.
        val shouldSkipDependencyChecks: Boolean =
            project.hasProperty("skipDependencyChecks") &&
                (
                    project.properties["skipDependencyChecks"].toString().toBoolean()
                )
        if (!shouldSkipDependencyChecks) {
            try {
                DependencyVersionChecker.checkDependencyVersions(project)
            } catch (e: Exception) {
                if (!project.hasProperty("usesUnsupportedDependencyVersions") ||
                    !(project.properties["usesUnsupportedDependencyVersions"] as Boolean)
                ) {
                    // Possible bug in dependency checking code - warn and do not block build.
                    project.logger.error(
                        "Warning: Flutter was unable to detect project Gradle, Java, " +
                            "AGP, and KGP versions. Skipping dependency version checking. Error was: " +
                            e
                    )
                } else {
                    // If usesUnsupportedDependencyVersions is set, the exception was thrown by us
                    // in the dependency version checker plugin so re-throw it here.
                    throw e
                }
            }
        }

        BaseApplicationNameHandler.setBaseName(project)
        val flutterProguardRules: String =
            Paths
                .get(
                    flutterRoot!!.absolutePath,
                    "packages",
                    "flutter_tools",
                    "gradle",
                    "flutter_proguard_rules.pro"
                ).toString()
        // TODO(gmackall): reconsider getting the android extension every time
        FlutterPluginUtils.getAndroidExtension(project).buildTypes {
            // Add profile build type.
            create("profile") {
                initWith(getByName("debug"))
                // TODO(gmackall): do we need to clear?
                this.matchingFallbacks.clear()
                this.matchingFallbacks.addAll(listOf("debug", "release"))
            }

            // TODO(garyq): Shrinking is only false for multi apk split aot builds, where shrinking is not allowed yet.
            // This limitation has been removed experimentally in gradle plugin version 4.2, so we can remove
            // this check when we upgrade to 4.2+ gradle. Currently, deferred components apps may see
            // increased app size due to this.
            if (FlutterPluginUtils.shouldShrinkResources(project)) {
                getByName("release") {
                    isMinifyEnabled = true
                    // Enables resource shrinking, which is performed by the Android Gradle plugin.
                    // The resource shrinker can't be used for libraries.
                    isShrinkResources = FlutterPluginUtils.isBuiltAsApp(project)
                    proguardFiles(
                        FlutterPluginUtils
                            .getAndroidExtension(project)
                            .getDefaultProguardFile("proguard-android-optimize.txt"),
                        flutterProguardRules
                    )

                    // Optionally adds custom Proguard rules as needed from `android/app/proguard-rules.pro`.
                    // Starting AGP 9.0 Proguard files must exist to be added to the configuration.
                    if (File("${project.projectDir}/proguard-rules.pro").exists()) {
                        proguardFile("proguard-rules.pro")
                    }
                }
            }
        }

        FlutterPluginUtils.forceNdkDownload(project, flutterRootPath)

        if (FlutterPluginUtils.shouldProjectUseLocalEngine(project)) {
            // This is required to pass the local engine to flutter build aot.
            val engineOutPath: String = project.properties["local-engine-out"] as String
            val engineOut: File = project.file(engineOutPath)
            if (!engineOut.isDirectory) {
                throw GradleException("local-engine-out must point to a local engine build")
            }
            localEngine = engineOut.name
            localEngineSrcPath = engineOut.parentFile.parent

            val engineHostOutPath: String = project.properties["local-engine-host-out"] as String
            val engineHostOut: File = project.file(engineHostOutPath)
            if (!engineHostOut.isDirectory) {
                throw GradleException("local-engine-host-out must point to a local engine host build")
            }
            localEngineHost = engineHostOut.name
        }
        FlutterPluginUtils.getAndroidExtension(project).buildTypes.all {
            addFlutterDependencies(this)
        }
    }

    private fun addFlutterDependencies(buildType: com.android.builder.model.BuildType) {
        FlutterPluginUtils.addFlutterDependencies(
            project!!,
            buildType,
            getPluginHandler(project!!),
            engineVersion!!
        )
    }

    private fun getExecutableNameForPlatform(baseExecutableName: String): String =
        if (OperatingSystem.current().isWindows) "$baseExecutableName.bat" else baseExecutableName

    private fun resolveFlutterSdkProperty(defaultValue: String?): String? {
        val propertyName = "flutter.sdk"
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
                        getExecutableNameForPlatform("${rootProject.projectDir}/gradlew")
                    val execOps = rootProject.serviceOf<ExecOperations>()
                    execOps.exec {
                        workingDir(rootProject.projectDir)
                        executable(gradlew)
                        args(":${subproject.name}:dependencies", "--write-locks")
                    }
                }
            }
        }
    }

    private fun addFlutterTasks(projectToAddTasksTo: Project) {
        if (projectToAddTasksTo.state.failure != null) {
            return
        }

        FlutterPluginUtils.addTaskForJavaVersion(projectToAddTasksTo)
        FlutterPluginUtils.addTaskForKGPVersion(projectToAddTasksTo)
        if (FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)) {
            FlutterPluginUtils.addTaskForPrintBuildVariants(projectToAddTasksTo)
            FlutterPluginUtils.addTasksForOutputsAppLinkSettings(projectToAddTasksTo)
        }

        val targetPlatforms: List<String> =
            FlutterPluginUtils.getTargetPlatforms(projectToAddTasksTo)

        val flutterPlugin = this

        if (FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)) {
            // TODO(gmackall): I think this can be BaseExtension, with findByType.
            val android: AbstractAppExtension =
                projectToAddTasksTo.extensions.findByName("android") as AbstractAppExtension
            android.applicationVariants.configureEach {
                val variant = this
                val assembleTask = variant.assembleProvider.get()
                if (!FlutterPluginUtils.shouldConfigureFlutterTask(
                        projectToAddTasksTo,
                        assembleTask
                    )
                ) {
                    return@configureEach
                }
                val copyFlutterAssetsTask: Task =
                    addFlutterDeps(variant, flutterPlugin, targetPlatforms)

                // TODO(gmackall): Migrate to AGPs variant api.
                //    https://github.com/flutter/flutter/issues/166550
                @Suppress("DEPRECATION")
                val variantOutput: com.android.build.gradle.api.BaseVariantOutput = variant.outputs.first()
                val processResources: ProcessAndroidResources =
                    try {
                        variantOutput.processResourcesProvider.get()
                    } catch (e: UnknownTaskException) {
                        // TODO(gmackall): Migrate to AGPs variant api.
                        //    https://github.com/flutter/flutter/issues/166550
                        @Suppress("DEPRECATION")
                        variantOutput.processResources
                    }
                processResources.dependsOn(copyFlutterAssetsTask)

                // Copy the output APKs into a known location, so `flutter run` or `flutter build apk`
                // can discover them. By default, this is `<app-dir>/build/app/outputs/flutter-apk/<filename>.apk`.
                //
                // The filename consists of `app<-abi>?<-flavor-name>?-<build-mode>.apk`.
                // Where:
                //   * `abi` can be `armeabi-v7a|arm64-v8a|x86_64` only if the flag `split-per-abi` is set.
                //   * `flavor-name` is the flavor used to build the app in lower case if the assemble task is called.
                //   * `build-mode` can be `release|debug|profile`.
                variant.outputs.forEach { output ->
                    assembleTask.doLast {
                        // TODO(gmackall): Migrate to AGPs variant api.
                        //    https://github.com/flutter/flutter/issues/166550
                        @Suppress("DEPRECATION")
                        output as com.android.build.gradle.api.ApkVariantOutput
                        val packageApplicationProvider: PackageAndroidArtifact =
                            variant.packageApplicationProvider.get()
                        val outputDirectory: Directory =
                            packageApplicationProvider.outputDirectory.get()
                        val outputDirectoryStr: String = outputDirectory.toString()
                        var filename = "app"

                        // TODO(gmackall): Migrate to AGPs variant api.
                        //    https://github.com/flutter/flutter/issues/166550
                        @Suppress("DEPRECATION")
                        val abi = output.getFilter(com.android.build.VariantOutput.FilterType.ABI)
                        if (abi != null && abi.isNotEmpty()) {
                            filename += "-$abi"
                        }
                        if (variant.flavorName != null && variant.flavorName.isNotEmpty()) {
                            filename += "-${FlutterPluginUtils.lowercase(variant.flavorName)}"
                        }
                        filename += "-${FlutterPluginUtils.buildModeFor(variant.buildType)}"
                        projectToAddTasksTo.copy {
                            from(File("$outputDirectoryStr/${output.outputFileName}"))
                            into(projectToAddTasksTo.layout.buildDirectory.dir("outputs/flutter-apk"))
                            rename { "$filename.apk" }
                        }
                    }
                }
            }
            // Copy the native assets created by build.dart and placed here by flutter assemble.
            // This path is not flavor specific and must only be added once.
            // If support for flavors is added to native assets, then they must only be added
            // once per flavor; see https://github.com/dart-lang/native/issues/1359.
            val nativeAssetsDir =
                "${projectToAddTasksTo.layout.buildDirectory.get()}/../native_assets/android/jniLibs/lib/"
            android.sourceSets
                .getByName("main")
                .jniLibs
                .srcDir(nativeAssetsDir)
            getPluginHandler(projectToAddTasksTo).configurePlugins(engineVersion!!)
            FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(
                projectToAddTasksTo,
                getPluginHandler(projectToAddTasksTo).getPluginList()
            )
            return
        }
        // Flutter host module project (Add-to-app).
        val hostAppProjectName: String? =
            if (projectToAddTasksTo.rootProject.hasProperty("flutter.hostAppProjectName")) {
                projectToAddTasksTo.rootProject.property(
                    "flutter.hostAppProjectName"
                ) as? String
            } else {
                "app"
            }
        val appProject: Project? =
            projectToAddTasksTo.rootProject.findProject(":$hostAppProjectName")
        check(appProject != null) {
            "Project :$hostAppProjectName doesn't exist. To customize the host app project name, set `flutter.hostAppProjectName=<project-name>` in gradle.properties."
        }
        // Wait for the host app project configuration.
        appProject.afterEvaluate {
            val androidLibraryExtension =
                projectToAddTasksTo.extensions.findByType(LibraryExtension::class.java)
            check(androidLibraryExtension != null)
            androidLibraryExtension.libraryVariants.all libraryVariantAll@{
                val libraryVariant = this
                var copyFlutterAssetsTask: Task? = null
                val androidAppExtension =
                    appProject.extensions.findByName("android") as? AbstractAppExtension
                check(androidAppExtension != null)
                androidAppExtension.applicationVariants.all applicationVariantAll@{
                    val appProjectVariant = this
                    val appAssembleTask: Task = appProjectVariant.assembleProvider.get()
                    if (!FlutterPluginUtils.shouldConfigureFlutterTask(project, appAssembleTask)) {
                        return@applicationVariantAll
                    }

                    // Find a compatible application variant in the host app.
                    //
                    // For example, consider a host app that defines the following variants:
                    // | ----------------- | ----------------------------- |
                    // |   Build Variant   |   Flutter Equivalent Variant  |
                    // | ----------------- | ----------------------------- |
                    // |   freeRelease     |   release                     |
                    // |   freeDebug       |   debug                       |
                    // |   freeDevelop     |   debug                       |
                    // |   profile         |   profile                     |
                    // | ----------------- | ----------------------------- |
                    //
                    // This mapping is based on the following rules:
                    // 1. If the host app build variant name is `profile` then the equivalent
                    //    Flutter variant is `profile`.
                    // 2. If the host app build variant is debuggable
                    //    (e.g. `buildType.debuggable = true`), then the equivalent Flutter
                    //    variant is `debug`.
                    // 3. Otherwise, the equivalent Flutter variant is `release`.
                    val variantBuildMode: String =
                        FlutterPluginUtils.buildModeFor(libraryVariant.buildType)
                    if (FlutterPluginUtils.buildModeFor(appProjectVariant.buildType) != variantBuildMode) {
                        return@applicationVariantAll
                    }
                    copyFlutterAssetsTask = copyFlutterAssetsTask ?: addFlutterDeps(
                        libraryVariant,
                        flutterPlugin,
                        targetPlatforms
                    )
                    // TODO(gmackall): Migrate to AGPs variant api.
                    //    https://github.com/flutter/flutter/issues/166550
                    val mergeAssets =
                        projectToAddTasksTo
                            .tasks
                            .findByPath(":$hostAppProjectName:merge${FlutterPluginUtils.capitalize(appProjectVariant.name)}Assets")
                    check(mergeAssets != null)
                    mergeAssets.dependsOn(copyFlutterAssetsTask)
                }
            }
        }
        getPluginHandler(projectToAddTasksTo).configurePlugins(engineVersion!!)
        FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(
            projectToAddTasksTo,
            getPluginHandler(projectToAddTasksTo).getPluginList()
        )
    }

    private fun getPluginHandler(project: Project): PluginHandler {
        if (this.pluginHandler == null) {
            this.pluginHandler = PluginHandler(project)
        }
        return this.pluginHandler!!
    }

    companion object {
        const val PROP_LOCAL_ENGINE_REPO: String = "local-engine-repo"

        /**
         * The name prefix for flutter builds. This is used to identify gradle tasks
         * where we expect the flutter tool to provide any error output, and skip the
         * standard Gradle error output in the FlutterEventLogger. If you change this,
         * be sure to change any instances of this string in symbols in the code below
         * to match.
         */
        private const val FLUTTER_BUILD_PREFIX: String = "flutterBuild"

        /**
         * Finds a task by name, returning null if the task does not exist.
         */
        private fun findTaskOrNull(
            project: Project,
            taskName: String
        ): Task? =
            try {
                project.tasks.named(taskName).get()
            } catch (ignored: UnknownTaskException) {
                null
            }

        // TODO(gmackall): Migrate to AGPs variant api.
        //    https://github.com/flutter/flutter/issues/166550
        private fun addFlutterDeps(
            @Suppress("DEPRECATION") variant: com.android.build.gradle.api.BaseVariant,
            flutterPlugin: FlutterPlugin,
            targetPlatforms: List<String>
        ): Task {
            // Shorthand
            val project: Project = flutterPlugin.project!!

            val fileSystemRootsValue: Array<String>? =
                project
                    .findProperty("filesystem-roots")
                    ?.toString()
                    ?.split("\\|")
                    ?.toTypedArray()
            val fileSystemSchemeValue: String? =
                project.findProperty("filesystem-scheme")?.toString()
            val trackWidgetCreationValue: Boolean =
                project.findProperty("track-widget-creation")?.toString()?.toBoolean() ?: true
            val frontendServerStarterPathValue: String? =
                project.findProperty("frontend-server-starter-path")?.toString()
            val extraFrontEndOptionsValue: String? =
                project.findProperty("extra-front-end-options")?.toString()
            val extraGenSnapshotOptionsValue: String? =
                project.findProperty("extra-gen-snapshot-options")?.toString()
            val splitDebugInfoValue: String? = project.findProperty("split-debug-info")?.toString()
            val dartObfuscationValue: Boolean =
                project.findProperty("dart-obfuscation")?.toString()?.toBoolean() ?: false
            val treeShakeIconsOptionsValue: Boolean =
                project.findProperty("tree-shake-icons")?.toString()?.toBoolean() ?: false
            val dartDefinesValue: String? = project.findProperty("dart-defines")?.toString()
            val performanceMeasurementFileValue: String? =
                project.findProperty("performance-measurement-file")?.toString()
            val codeSizeDirectoryValue: String? =
                project.findProperty("code-size-directory")?.toString()
            val deferredComponentsValue: Boolean =
                project.findProperty("deferred-components")?.toString()?.toBoolean() ?: false
            val validateDeferredComponentsValue: Boolean =
                project.findProperty("validate-deferred-components")?.toString()?.toBoolean() ?: true

            if (FlutterPluginUtils.shouldProjectSplitPerAbi(project)) {
                variant.outputs.forEach { output ->
                    // need to force this as the API does not return the right thing for our use.
                    // TODO(gmackall): Migrate to AGPs variant api.
                    //    https://github.com/flutter/flutter/issues/166550
                    @Suppress("DEPRECATION")
                    output as com.android.build.gradle.api.ApkVariantOutput
                    val versionCodeIfPresent: Int? = if (variant is ApkVariant) variant.versionCode else null

                    // TODO(gmackall): Migrate to AGPs variant api.
                    //    https://github.com/flutter/flutter/issues/166550
                    @Suppress("DEPRECATION")
                    val filterIdentifier: String? =
                        output.getFilter(com.android.build.VariantOutput.FilterType.ABI)
                    val abiVersionCode: Int? = FlutterPluginConstants.ABI_VERSION[filterIdentifier]
                    if (abiVersionCode != null) {
                        output.versionCodeOverride = abiVersionCode * 1000 + (
                            versionCodeIfPresent
                                ?: variant.mergedFlavor.versionCode as Int
                        )
                    }
                }
            }

            // Build an AAR when this property is defined.
            val isBuildingAar: Boolean = project.hasProperty("is-plugin")
            // In add to app scenarios, a Gradle project contains a `:flutter` and `:app` project.
            // `:flutter` is used as a subproject when these tasks exists and the build isn't building an AAR.
            // TODO(gmackall): I think this is just always null? Which is great news! Consider removing.
            val packageAssets: Task? =
                findTaskOrNull(
                    project,
                    "package${FlutterPluginUtils.capitalize(variant.name)}Assets"
                )
            val cleanPackageAssets: Task? =
                findTaskOrNull(
                    project,
                    "cleanPackage${FlutterPluginUtils.capitalize(variant.name)}Assets"
                )

            val isUsedAsSubproject: Boolean =
                packageAssets != null && cleanPackageAssets != null && !isBuildingAar

            val variantBuildMode: String = FlutterPluginUtils.buildModeFor(variant.buildType)
            val flavorValue: String = variant.flavorName
            val taskName: String =
                FlutterPluginUtils.toCamelCase(
                    listOf(
                        "compile",
                        FLUTTER_BUILD_PREFIX,
                        variant.name
                    )
                )
            // The task provider below will shadow a lot of the variable names, so provide this reference
            // to access them within that scope.

            // Be careful when configuring task below, Groovy has bizarre
            // scoping rules: writing `verbose isVerbose()` means calling
            // `isVerbose` on the task itself - which would return `verbose`
            // original value. You either need to hoist the value
            // into a separate variable `verbose verboseValue` or prefix with
            // `this` (`verbose this.isVerbose()`).
            val compileTaskProvider: TaskProvider<FlutterTask> =
                project.tasks.register(taskName, FlutterTask::class.java) {
                    flutterRoot = flutterPlugin.flutterRoot
                    flutterExecutable = flutterPlugin.flutterExecutable
                    buildMode = variantBuildMode
                    minSdkVersion = variant.mergedFlavor.minSdkVersion!!.apiLevel
                    localEngine = flutterPlugin.localEngine
                    localEngineHost = flutterPlugin.localEngineHost
                    localEngineSrcPath = flutterPlugin.localEngineSrcPath
                    targetPath = FlutterPluginUtils.getFlutterTarget(project)
                    verbose = FlutterPluginUtils.isProjectVerbose(project)
                    fileSystemRoots = fileSystemRootsValue
                    fileSystemScheme = fileSystemSchemeValue
                    trackWidgetCreation = trackWidgetCreationValue
                    targetPlatformValues = targetPlatforms
                    sourceDir = FlutterPluginUtils.getFlutterSourceDirectory(project)
                    intermediateDir =
                        project.file(
                            project.layout.buildDirectory.dir("${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/${variant.name}/")
                        )
                    frontendServerStarterPath = frontendServerStarterPathValue
                    extraFrontEndOptions = extraFrontEndOptionsValue
                    extraGenSnapshotOptions = extraGenSnapshotOptionsValue
                    splitDebugInfo = splitDebugInfoValue
                    treeShakeIcons = treeShakeIconsOptionsValue
                    dartObfuscation = dartObfuscationValue
                    dartDefines = dartDefinesValue
                    performanceMeasurementFile = performanceMeasurementFileValue
                    codeSizeDirectory = codeSizeDirectoryValue
                    deferredComponents = deferredComponentsValue
                    validateDeferredComponents = validateDeferredComponentsValue
                    flavor = flavorValue
                }
            val flutterCompileTask: FlutterTask = compileTaskProvider.get()
            val libJar: File =
                project.file(
                    project.layout.buildDirectory.dir("${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/${variant.name}/libs.jar")
                )
            val packJniLibsTaskProvider: TaskProvider<Jar> =
                project.tasks.register(
                    "packJniLibs${FLUTTER_BUILD_PREFIX}${FlutterPluginUtils.capitalize(variant.name)}",
                    Jar::class.java
                ) {
                    destinationDirectory.set(libJar.parentFile)
                    archiveFileName.set(libJar.name)
                    dependsOn(flutterCompileTask)
                    targetPlatforms.forEach { targetPlatform ->
                        val abi: String? = FlutterPluginConstants.PLATFORM_ARCH_MAP[targetPlatform]
                        from("${flutterCompileTask.intermediateDir}/$abi") {
                            include("*.so")
                            // Move `app.so` to `lib/<abi>/libapp.so`
                            rename { filename: String -> "lib/$abi/lib$filename" }
                        }
                        // Copy the native assets created by build.dart and placed in build/native_assets by flutter assemble.
                        // The `$project.layout.buildDirectory` is '.android/Flutter/build/' instead of 'build/'.
                        val buildDir =
                            "${FlutterPluginUtils.getFlutterSourceDirectory(project)}/build"
                        val nativeAssetsDir =
                            "$buildDir/native_assets/android/jniLibs/lib"
                        from("$nativeAssetsDir/$abi") {
                            include("*.so")
                            rename { filename: String -> "lib/$abi/$filename" }
                        }
                    }
                }
            val packJniLibsTask: Task = packJniLibsTaskProvider.get()
            FlutterPluginUtils.addApiDependencies(
                project,
                variant.name,
                project.files({
                    packJniLibsTask
                })
            )
            val copyFlutterAssetsTaskProvider: TaskProvider<Copy> =
                project.tasks.register(
                    "copyFlutterAssets${FlutterPluginUtils.capitalize(variant.name)}",
                    Copy::class.java
                ) {
                    dependsOn(flutterCompileTask)
                    with(flutterCompileTask.assets)
                    filePermissions {
                        user {
                            read = true
                            write = true
                        }
                    }
                    if (isUsedAsSubproject) {
                        // TODO(gmackall): above is always false, can delete
                        dependsOn(packageAssets)
                        dependsOn(cleanPackageAssets)
                        into(packageAssets!!.outputs)
                    }
                    val mergeAssets =
                        try {
                            variant.mergeAssetsProvider.get()
                        } catch (e: IllegalStateException) {
                            // TODO(gmackall): Migrate to AGPs variant api.
                            //    https://github.com/flutter/flutter/issues/166550
                            @Suppress("DEPRECATION")
                            variant.mergeAssets
                        }
                    dependsOn(mergeAssets)
                    dependsOn("clean${FlutterPluginUtils.capitalize(mergeAssets.name)}")
                    mergeAssets.mustRunAfter("clean${FlutterPluginUtils.capitalize(mergeAssets.name)}")
                    into(mergeAssets.outputDir)
                }
            val copyFlutterAssetsTask: Task = copyFlutterAssetsTaskProvider.get()
            if (!isUsedAsSubproject) {
                // TODO(gmackall): Migrate to AGPs variant api.
                //    https://github.com/flutter/flutter/issues/166550
                @Suppress("DEPRECATION")
                val variantOutput: com.android.build.gradle.api.BaseVariantOutput = variant.outputs.first()
                val processResources =
                    try {
                        variantOutput.processResourcesProvider.get()
                    } catch (e: IllegalStateException) {
                        // TODO(gmackall): Migrate to AGPs variant api.
                        //    https://github.com/flutter/flutter/issues/166550
                        @Suppress("DEPRECATION")
                        variantOutput.processResources
                    }
                processResources.dependsOn(copyFlutterAssetsTask)
            }
            // The following tasks use the output of copyFlutterAssetsTask,
            // so it's necessary to declare it as an dependency since Gradle 8.
            // See https://docs.gradle.org/8.1/userguide/validation_problems.html#implicit_dependency.
            val tasksToCheck =
                listOf(
                    "compress${FlutterPluginUtils.capitalize(variant.name)}Assets",
                    "bundle${FlutterPluginUtils.capitalize(variant.name)}Aar",
                    "bundle${FlutterPluginUtils.capitalize(variant.name)}LocalLintAar"
                )
            tasksToCheck.forEach { taskTocheck ->
                try {
                    project.tasks.named(taskTocheck).configure {
                        dependsOn(copyFlutterAssetsTask)
                    }
                } catch (ignored: UnknownTaskException) {
                    // ignored
                }
            }
            return copyFlutterAssetsTask
        }
    }

    /**
     * Returns true if the Gradle task is invoked by Android Studio.
     *
     * This is true when the property `android.injected.invoked.from.ide` is passed to Gradle.
     * This property is set by Android Studio when it invokes a Gradle task.
     */
    private fun isInvokedFromAndroidStudio(): Boolean = project?.hasProperty("android.injected.invoked.from.ide") == true
}
