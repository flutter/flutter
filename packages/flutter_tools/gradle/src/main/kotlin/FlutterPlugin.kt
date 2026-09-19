// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.Variant
import com.android.build.gradle.AbstractAppExtension
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.api.ApkVariant
import com.android.build.gradle.tasks.PackageAndroidArtifact
import com.flutter.gradle.FlutterPluginConstants.PLATFORM_ABI_LIST
import com.flutter.gradle.FlutterPluginUtils.readPropertiesIfExist
import com.flutter.gradle.plugins.PluginHandler
import com.flutter.gradle.tasks.CopyFlutterAssetsTask
import com.flutter.gradle.tasks.CopyFlutterJniLibsTask
import com.flutter.gradle.tasks.FlutterTask
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.UnknownTaskException
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.TaskProvider
import org.gradle.internal.os.OperatingSystem
import org.gradle.kotlin.dsl.support.serviceOf
import org.gradle.process.ExecOperations
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Paths
import java.util.Properties
import com.android.build.api.dsl.BuildType as DslBuildType

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

        val propDeferredComponentNames = "deferred-component-names"
        val deferredComponentNamesValue: String? =
            project.findProperty(propDeferredComponentNames) as? String
        if (deferredComponentNamesValue != null) {
            val componentNames: Set<String> =
                deferredComponentNamesValue
                    .split(',')
                    .map { ":$it" }
                    .toSet()
            val androidExtensionAsApplicationExtension =
                FlutterPluginUtils.getAndroidApplicationExtension(project)
            // TODO(gmackall): Should we clear here? I think this is equivalent to what we used to
            //    do, but unsure. Can't use a closure.
            androidExtensionAsApplicationExtension.dynamicFeatures.clear()
            androidExtensionAsApplicationExtension.dynamicFeatures.addAll(componentNames)
        }

        FlutterPluginUtils.getTargetPlatforms(project).forEach { targetArch ->
            val abiValue: String? = FlutterPluginConstants.PLATFORM_ARCH_MAP[targetArch]
            FlutterPluginUtils
                .getAndroidExtension(project)
                .splits.abi
                .include(abiValue!!)
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
        val flutterProguardRules =
            Paths
                .get(
                    flutterRoot!!.absolutePath,
                    "packages",
                    "flutter_tools",
                    "gradle",
                    "flutter_proguard_rules.pro"
                ).toFile()
        // TODO(gmackall): reconsider getting the android extension every time
        val debugBuildType: DslBuildType = FlutterPluginUtils.getAndroidExtension(project).buildTypes.getByName("debug")
        FlutterPluginUtils.getAndroidExtension(project).buildTypes.create(
            "profile",
            {
                initWith(debugBuildType)
                // TODO(gmackall): do we need to clear?
                this.matchingFallbacks.clear()
                this.matchingFallbacks.addAll(listOf("debug", "release"))
            }
        )
        if (FlutterPluginUtils.shouldShrinkResources(project)) {
            val releaseBuildType: DslBuildType = FlutterPluginUtils.getAndroidExtension(project).buildTypes.getByName("release")
            releaseBuildType.isMinifyEnabled = true
            releaseBuildType.isShrinkResources = FlutterPluginUtils.isBuiltAsApp(project)
            releaseBuildType.proguardFiles.add(
                FlutterPluginUtils.getAndroidExtension(project).getDefaultProguardFile("proguard-android-optimize.txt")
            )
            releaseBuildType.proguardFiles.add(flutterProguardRules)
            val proguardRulesPro = File("${project.projectDir}/proguard-rules.pro")
            if (proguardRulesPro.exists()) {
                releaseBuildType.proguardFiles.add(proguardRulesPro)
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

    private fun addFlutterDependencies(buildType: DslBuildType) {
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
            FlutterPluginUtils.addTaskForPrintNdkVersion(projectToAddTasksTo)
            FlutterPluginUtils.addTasksForOutputsAppLinkSettings(projectToAddTasksTo)

            // Task required to pass command line flags for apps to the Flutter Android embedding.
            FlutterPluginUtils.addTaskForGeneratingEngineShellArgumentManifest(projectToAddTasksTo)
        }
        // Only applies to app projects. For module (aar) projects the host app's manifest is
        // the source of truth for HCPP; see addTasksForEnableHcppManifest for why injecting
        // into the library manifest would break host builds that explicitly opt out.
        FlutterPluginUtils.addTasksForEnableHcppManifest(projectToAddTasksTo)

        val targetPlatforms: List<String> =
            FlutterPluginUtils.getTargetPlatforms(projectToAddTasksTo)

        // The Android Gradle Plugin is always applied to Flutter Android projects, so its components
        // extension is expected to be present. Use getByType (not findByType) so a misconfiguration
        // fails loudly rather than silently skipping libapp.so registration.
        val androidComponents = projectToAddTasksTo.extensions.getByType(AndroidComponentsExtension::class.java)
        // `this` is shadowed inside the task configuration blocks reached from here, so capture the
        // plugin instance that owns the resolved Flutter SDK and local engine paths.
        val flutterGradlePlugin = this
        val isApplicationProject = FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)
        androidComponents.onVariants { variant ->
            // Application projects register the Flutter compile task here, from the public variant
            // API. Add-to-app module (library) projects still register theirs from the
            // `libraryVariants` callback in [addFlutterDepsForModule] until that path migrates
            // (https://github.com/flutter/flutter/issues/166550).
            if (isApplicationProject && shouldCompileFlutterForVariant(projectToAddTasksTo, variant)) {
                registerFlutterAssetTasks(
                    projectToAddTasksTo,
                    variant,
                    flutterGradlePlugin,
                    targetPlatforms
                )
            }
            registerFlutterJniLibsTask(projectToAddTasksTo, variant, targetPlatforms)
        }

        if (FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)) {
            val appExtension = FlutterPluginUtils.getAndroidApplicationExtension(projectToAddTasksTo)
            configureAbis(projectToAddTasksTo, appExtension)
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
                configureAbiVersionCodeOverride(variant, projectToAddTasksTo)

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
            getPluginHandler(projectToAddTasksTo).configurePlugins(engineVersion!!)
            FlutterPluginUtils.detectLowCompileSdkVersionOrNdkVersion(
                projectToAddTasksTo,
                getPluginHandler(projectToAddTasksTo).getPluginList()
            )
            FlutterPluginUtils.detectApplyingKotlinGradlePlugin(
                projectToAddTasksTo
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
                    copyFlutterAssetsTask = copyFlutterAssetsTask ?: addFlutterDepsForModule(
                        libraryVariant,
                        flutterGradlePlugin,
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
        FlutterPluginUtils.detectApplyingKotlinGradlePlugin(
            projectToAddTasksTo
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
         * The name of the [FlutterTask] (the `flutter assemble` invocation) for [variantName].
         *
         * Built identically by the functions that register the task, [registerFlutterCompileTask]
         * and [addFlutterDepsForModule], and by [registerFlutterJniLibsTask], which references the
         * task by name because it may be configured before that task is registered.
         */
        private fun flutterCompileTaskName(variantName: String): String =
            FlutterPluginUtils.toCamelCase(listOf("compile", FLUTTER_BUILD_PREFIX, variantName))

        /**
         * Configures flutter default abi support respecting flutter command line flags.
         */
        private fun configureAbis(
            projectToAddTasksTo: Project,
            androidExtension: ApplicationExtension
        ) {
            // By default, assembling APKs generates fat APKs if multiple platforms are passed.
            // Configuring split per ABI allows to generate separate APKs for each abi.
            // This is a noop when building a bundle.
            if (FlutterPluginUtils.shouldProjectSplitPerAbi(projectToAddTasksTo)) {
                androidExtension.splits.abi {
                    isEnable = true
                    reset()
                    isUniversalApk = false
                }
            } else {
                // When splits-per-abi is NOT enabled, configure abiFilters to control which
                // native libraries are included in the APK.
                //
                //  If a project includes third-party dependencies with x86 native libraries,
                // without these abiFilters, Google Play would incorrectly identify the app as supporting x86.
                // When users with x86 devices install the app, it would crash at runtime because Flutter's
                // native libraries aren't available for x86. By filtering out x86 at build time, Google Play
                // correctly excludes x86 devices from the compatible device list.
                //
                // This code does NOT affect "add-to-app" scenarios because:
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
                // If the user has specified abiFilters in their build.gradle file's DefaultConfig,
                // those settings will take precedence over these defaults.
                configureAbiWithoutSplits(projectToAddTasksTo, androidExtension)
            }
        }

        /**
         * Clears existing abi configuration and sets ABI's supported by flutter.
         */
        private fun configureAbiWithoutSplits(
            projectToAddTasksTo: Project,
            extension: ApplicationExtension
        ) {
            if (!FlutterPluginUtils.shouldProjectDisableAbiFiltering(projectToAddTasksTo)) {
                extension.defaultConfig.ndk {
                    abiFilters.clear()
                    abiFilters.addAll(PLATFORM_ABI_LIST)
                }
            }
        }

        /**
         * Whether `flutter assemble` should be wired into [variant].
         *
         * When a single `assemble<Variant>` task is named on the command line, Flutter is only
         * compiled for the variants that task can build. This keeps a release build from also
         * configuring (and therefore building) the debug Dart artifacts, which is what
         * [FlutterPluginUtils.shouldConfigureFlutterTask] exists to prevent. Removing it is
         * tracked by https://github.com/flutter/flutter/issues/109560, which also documents the
         * AGP behavior that made it necessary.
         */
        private fun shouldCompileFlutterForVariant(
            project: Project,
            variant: Variant
        ): Boolean =
            FlutterPluginUtils.shouldConfigureFlutterTask(
                project,
                "assemble${FlutterPluginUtils.capitalize(variant.name)}"
            )

        /**
         * Registers the tasks that produce Flutter's assets for [variant], and declares the
         * directory they stage into as a generated assets source directory.
         *
         * AGP then merges and packages that directory like any other assets source, which is what
         * puts `flutter_assets` into the APK.
         */
        private fun registerFlutterAssetTasks(
            project: Project,
            variant: Variant,
            flutterGradlePlugin: FlutterPlugin,
            targetPlatforms: List<String>
        ) {
            val compileTaskProvider =
                registerFlutterCompileTask(project, variant, flutterGradlePlugin, targetPlatforms)
            val copyFlutterAssetsTaskProvider: TaskProvider<CopyFlutterAssetsTask> =
                project.tasks.register(
                    "copyFlutterAssets${FlutterPluginUtils.capitalize(variant.name)}",
                    CopyFlutterAssetsTask::class.java
                ) {
                    // The compile task registered just above always sets an output directory,
                    // so this is an invariant rather than a tolerated absence. Letting the
                    // provider go absent instead would stage an empty directory and produce an
                    // APK with no flutter_assets, which fails at runtime rather than at build
                    // time.
                    intermediateDir.set(
                        project.layout.dir(
                            compileTaskProvider.map { requireNotNull(it.outputDirectory) }
                        )
                    )
                }
            // The assets source set is expected to exist for application variants; fail loudly
            // rather than silently building an APK without Flutter assets.
            val assetSources =
                variant.sources.assets
                    ?: throw GradleException(
                        "Flutter could not register its generated assets for variant " +
                            "'${variant.name}' because the Android Gradle Plugin did not " +
                            "expose an assets source set for it. Please file an issue at " +
                            "https://github.com/flutter/flutter/issues."
                    )
            assetSources.addGeneratedSourceDirectory(
                copyFlutterAssetsTaskProvider,
                CopyFlutterAssetsTask::destinationDir
            )
        }

        /**
         * Registers the task that stages Flutter's native libraries for [variant], and declares
         * the directory it stages into as a generated jniLibs source directory.
         */
        private fun registerFlutterJniLibsTask(
            project: Project,
            variant: Variant,
            targetPlatforms: List<String>
        ) {
            val compileTaskName = flutterCompileTaskName(variant.name)
            val copyJniLibsTaskProvider: TaskProvider<CopyFlutterJniLibsTask> =
                project.tasks.register(
                    "copyJniLibs$FLUTTER_BUILD_PREFIX${FlutterPluginUtils.capitalize(variant.name)}",
                    CopyFlutterJniLibsTask::class.java
                ) {
                    // The Flutter compile task is absent for variants that Flutter is not compiled
                    // for, such as an `assembleAndroidTest` build. Look it up tolerantly
                    // (findByName, not named) so this task degrades to a no-op with empty output
                    // instead of failing to be created.
                    // See https://github.com/flutter/flutter/issues/188785.
                    dependsOn(project.tasks.matching { it.name == compileTaskName })
                    intermediateDir.set(
                        project.layout.dir(
                            project.provider {
                                val compileTask = project.tasks.findByName(compileTaskName) as? FlutterTask
                                compileTask?.outputDirectory
                            }
                        )
                    )
                    this.targetPlatforms.set(targetPlatforms)
                }
            variant.sources.jniLibs?.addGeneratedSourceDirectory(
                copyJniLibsTaskProvider,
                CopyFlutterJniLibsTask::destinationDir
            )
        }

        /**
         * Registers the [FlutterTask] (the `flutter assemble` invocation) for [variant],
         * configured entirely from the public variant API. Application projects only; the
         * add-to-app module path registers its own compile task in [addFlutterDepsForModule].
         */
        private fun registerFlutterCompileTask(
            project: Project,
            variant: Variant,
            flutterGradlePlugin: FlutterPlugin,
            targetPlatforms: List<String>
        ): TaskProvider<FlutterTask> {
            // Variant-scope build-mode resolution uses the public debuggable flag so that
            // custom debuggable build types (e.g. `staging`) map to the debug engine artifacts.
            val variantBuildType =
                requireNotNull(variant.buildType) {
                    "Variant ${variant.name} has no buildType configured."
                }
            val buildMode: String =
                FlutterPluginUtils.buildModeFor(variantBuildType, variant.debuggable)
            return project.tasks.register(flutterCompileTaskName(variant.name), FlutterTask::class.java) {
                configureCompileTask(
                    project = project,
                    flutterGradlePlugin = flutterGradlePlugin,
                    buildMode = buildMode,
                    minSdkVersion = variant.minSdk.apiLevel,
                    variantName = variant.name,
                    flavorName = variant.flavorName ?: "",
                    targetPlatforms = targetPlatforms
                )
            }
        }

        /**
         * Applies the `flutter assemble` configuration that is common to the application and
         * add-to-app module paths.
         *
         * Every value the task needs from the variant is passed in, because reading it inside the
         * configuration block would resolve against the task itself: in that scope `flavor` is the
         * task's own property, not the variant's.
         */
        private fun FlutterTask.configureCompileTask(
            project: Project,
            flutterGradlePlugin: FlutterPlugin,
            buildMode: String,
            minSdkVersion: Int,
            variantName: String,
            flavorName: String,
            targetPlatforms: List<String>
        ) {
            val compileOptions = FlutterCompileOptions.from(project)
            flutterRoot = flutterGradlePlugin.flutterRoot
            flutterExecutable = flutterGradlePlugin.flutterExecutable
            this.buildMode = buildMode
            this.minSdkVersion = minSdkVersion
            localEngine = flutterGradlePlugin.localEngine
            localEngineHost = flutterGradlePlugin.localEngineHost
            localEngineSrcPath = flutterGradlePlugin.localEngineSrcPath
            targetPath = FlutterPluginUtils.getFlutterTarget(project)
            verbose = FlutterPluginUtils.isProjectVerbose(project)
            fileSystemRoots = compileOptions.fileSystemRoots?.toTypedArray()
            fileSystemScheme = compileOptions.fileSystemScheme
            trackWidgetCreation = compileOptions.trackWidgetCreation
            targetPlatformValues = targetPlatforms
            sourceDir = FlutterPluginUtils.getFlutterSourceDirectory(project)
            intermediateDir =
                project.file(
                    project.layout.buildDirectory.dir(
                        "${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/$variantName/"
                    )
                )
            frontendServerStarterPath = compileOptions.frontendServerStarterPath
            extraFrontEndOptions = compileOptions.extraFrontEndOptions
            extraGenSnapshotOptions = compileOptions.extraGenSnapshotOptions
            splitDebugInfo = compileOptions.splitDebugInfo
            treeShakeIcons = compileOptions.treeShakeIcons
            dartObfuscation = compileOptions.dartObfuscation
            dartDefines = compileOptions.dartDefines
            performanceMeasurementFile = compileOptions.performanceMeasurementFile
            codeSizeDirectory = compileOptions.codeSizeDirectory
            deferredComponents = compileOptions.deferredComponents
            validateDeferredComponents = compileOptions.validateDeferredComponents
            flavor = flavorName
        }

        /**
         * Applies the per-ABI `versionCode` offset used by `--split-per-abi` builds.
         *
         * Reads [com.android.build.gradle.api.BaseVariant], which AGP deprecated in favor of
         * `VariantOutput.versionCode`. Together with the flutter-apk copy, this is one of the two
         * remaining deprecated-API consumers on the application path.
         *
         * TODO(gmackall): Migrate to AGPs variant api.
         *  https://github.com/flutter/flutter/issues/166550
         */
        private fun configureAbiVersionCodeOverride(
            @Suppress("DEPRECATION") variant: com.android.build.gradle.api.BaseVariant,
            project: Project
        ) {
            if (!FlutterPluginUtils.shouldProjectSplitPerAbi(project)) {
                return
            }
            variant.outputs.forEach { output ->
                // need to force this as the API does not return the right thing for our use.
                @Suppress("DEPRECATION")
                output as com.android.build.gradle.api.ApkVariantOutput
                val versionCodeIfPresent: Int? = if (variant is ApkVariant) variant.versionCode else null

                @Suppress("DEPRECATION")
                val filterIdentifier: String? =
                    output.getFilter(com.android.build.VariantOutput.FilterType.ABI)
                val abiVersionCode: Int? = FlutterPluginConstants.ABI_VERSION[filterIdentifier]
                if (abiVersionCode != null && !FlutterPluginUtils.shouldForceVersionCodeIgnoringAbi(project)) {
                    output.versionCodeOverride = abiVersionCode * 1000 + (
                        versionCodeIfPresent
                            ?: variant.mergedFlavor.versionCode as Int
                    )
                }
            }
        }

        /**
         * Registers the Flutter compile and asset copy tasks for an add-to-app module (library)
         * project, and returns the asset copy task.
         *
         * Reads [com.android.build.gradle.api.BaseVariant], which AGP deprecated in favor of the
         * `onVariants` callback used by application projects in [addFlutterTasks].
         *
         * TODO(gmackall): Migrate to AGPs variant api.
         *  https://github.com/flutter/flutter/issues/166550
         */
        private fun addFlutterDepsForModule(
            @Suppress("DEPRECATION") variant: com.android.build.gradle.api.BaseVariant,
            flutterGradlePlugin: FlutterPlugin,
            targetPlatforms: List<String>
        ): Task {
            val project: Project = flutterGradlePlugin.project!!
            val buildMode: String = FlutterPluginUtils.buildModeFor(variant.buildType)
            val compileTaskProvider: TaskProvider<FlutterTask> =
                project.tasks.register(flutterCompileTaskName(variant.name), FlutterTask::class.java) {
                    configureCompileTask(
                        project = project,
                        flutterGradlePlugin = flutterGradlePlugin,
                        buildMode = buildMode,
                        minSdkVersion = variant.mergedFlavor.minSdkVersion!!.apiLevel,
                        variantName = variant.name,
                        flavorName = variant.flavorName,
                        targetPlatforms = targetPlatforms
                    )
                }
            val flutterCompileTask: FlutterTask = compileTaskProvider.get()
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
            // The following tasks use the output of copyFlutterAssetsTask,
            // so it's necessary to declare it as an dependency since Gradle 8.
            // See https://docs.gradle.org/8.1/userguide/validation_problems.html#implicit_dependency.
            addCopyFlutterAssetsDependency(project, variant.name, copyFlutterAssetsTask)
            return copyFlutterAssetsTask
        }

        /**
         * Wires the tasks that consume the output of `copyFlutterAssets<Variant>` to depend on
         * it explicitly, as required since Gradle 8. See
         * https://docs.gradle.org/8.1/userguide/validation_problems.html#implicit_dependency.
         */
        private fun addCopyFlutterAssetsDependency(
            project: Project,
            variantName: String,
            copyFlutterAssetsTask: Task
        ) {
            val tasksToCheck =
                listOf(
                    "compress${FlutterPluginUtils.capitalize(variantName)}Assets",
                    "bundle${FlutterPluginUtils.capitalize(variantName)}Aar",
                    "bundle${FlutterPluginUtils.capitalize(variantName)}LocalLintAar"
                )
            tasksToCheck.forEach { taskToCheck ->
                try {
                    project.tasks.named(taskToCheck).configure {
                        dependsOn(copyFlutterAssetsTask)
                    }
                } catch (ignored: UnknownTaskException) {
                    // ignored
                }
            }
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
