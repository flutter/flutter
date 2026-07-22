// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

import com.android.build.api.artifact.SingleArtifact
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.BuildType
import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.api.variant.ApplicationVariant
import com.android.build.api.variant.FilterConfiguration
import com.android.build.api.variant.Variant
import com.flutter.gradle.FlutterPluginConstants.PLATFORM_ABI_LIST
import com.flutter.gradle.FlutterPluginUtils.readPropertiesIfExist
import com.flutter.gradle.plugins.PluginHandler
import com.flutter.gradle.tasks.CopyFlutterApksTask
import com.flutter.gradle.tasks.CopyFlutterAssetsTask
import com.flutter.gradle.tasks.CopyFlutterJniLibsTask
import com.flutter.gradle.tasks.FlutterTask
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.TaskProvider
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
        val debugBuildType: BuildType = FlutterPluginUtils.getAndroidExtension(project).buildTypes.getByName("debug")
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
            val releaseBuildType: BuildType = FlutterPluginUtils.getAndroidExtension(project).buildTypes.getByName("release")
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

    private fun addFlutterDependencies(buildType: BuildType) {
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
        }

        val targetPlatforms: List<String> =
            FlutterPluginUtils.getTargetPlatforms(projectToAddTasksTo)

        // The Android Gradle Plugin is always applied to Flutter Android projects, so its components
        // extension is expected to be present. Use getByType (not findByType) so a misconfiguration
        // fails loudly rather than silently skipping libapp.so registration.
        val androidComponents = projectToAddTasksTo.extensions.getByType(AndroidComponentsExtension::class.java)
        val targetPlatformsList = targetPlatforms
        val flutterPlugin = this
        val isAppProject = FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)
        androidComponents.onVariants { variant ->
            val capitalizeVariantName = FlutterPluginUtils.capitalize(variant.name)
            val compileTaskName = flutterCompileTaskName(variant.name)

            val copyJniLibsTaskProvider: TaskProvider<CopyFlutterJniLibsTask> =
                projectToAddTasksTo.tasks.register(
                    "copyJniLibs${FLUTTER_BUILD_PREFIX}$capitalizeVariantName",
                    CopyFlutterJniLibsTask::class.java
                ) {
                    // The Flutter compile task is only registered (below) for variants that
                    // are actually built as a Flutter app. It is absent for e.g. an
                    // `assembleAndroidTest` build, where `shouldConfigureFlutterTask` returns false.
                    // Look it up tolerantly (findByName, not named) so this task degrades to a no-op
                    // with empty output instead of failing to be created when there is no Flutter
                    // build for the variant. See https://github.com/flutter/flutter/issues/188785.
                    dependsOn(projectToAddTasksTo.tasks.matching { it.name == compileTaskName })
                    intermediateDir.set(
                        projectToAddTasksTo.layout.dir(
                            projectToAddTasksTo.provider {
                                val compileTask = projectToAddTasksTo.tasks.findByName(compileTaskName) as? FlutterTask
                                compileTask?.outputDirectory
                            }
                        )
                    )
                    this.targetPlatforms.set(targetPlatformsList)
                }
            variant.sources.jniLibs?.addGeneratedSourceDirectory(
                copyJniLibsTaskProvider,
                CopyFlutterJniLibsTask::destinationDir
            )

            // The Flutter compile task and the generated-assets wiring are registered here,
            // lazily, from the public variant API, for both application projects and
            // add-to-app module (library) projects. Application variants honor the
            // shouldConfigureFlutterTask CLI gating; module projects always configure their
            // (at most three) variants, because which module variant a host build consumes
            // is decided by AGP's variant matching, not by the CLI task name.
            val shouldConfigureVariant =
                !isAppProject ||
                    FlutterPluginUtils.shouldConfigureFlutterTask(
                        projectToAddTasksTo,
                        "assemble$capitalizeVariantName"
                    )
            if (shouldConfigureVariant) {
                val compileTaskProvider =
                    registerFlutterCompileTask(
                        projectToAddTasksTo,
                        variant,
                        flutterPlugin,
                        targetPlatformsList
                    )
                val copyFlutterAssetsTaskProvider: TaskProvider<CopyFlutterAssetsTask> =
                    projectToAddTasksTo.tasks.register(
                        "copyFlutterAssets$capitalizeVariantName",
                        CopyFlutterAssetsTask::class.java
                    ) {
                        dependsOn(compileTaskProvider)
                        intermediateDir.set(
                            projectToAddTasksTo.layout.dir(
                                compileTaskProvider.map { requireNotNull(it.outputDirectory) }
                            )
                        )
                    }
                // Flutter's assets are delivered as a generated assets source directory, so
                // AGP merges and packages them like any other assets source (and, for
                // add-to-app module projects, the host application consumes them through
                // normal library packaging). The assets source set is expected to exist;
                // fail loudly rather than silently building without Flutter assets.
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

                if (!isAppProject) {
                    // For add-to-app module (library) projects, the generated assets and
                    // jniLibs sources above are everything: the host application consumes
                    // them through AGP's normal library packaging and variant matching.
                    return@onVariants
                }

                // Per-ABI versionCode for --split-per-abi builds: read the merged versionCode
                // AGP seeded on each variant output and offset it by the ABI constant.
                // (Read-then-set with a plain get, not a self-referential lazy map.)
                val appliedAbiVersionCodes = mutableMapOf<String, Int>()
                if (FlutterPluginUtils.shouldProjectSplitPerAbi(projectToAddTasksTo) &&
                    !FlutterPluginUtils.shouldForceVersionCodeIgnoringAbi(projectToAddTasksTo)
                ) {
                    (variant as? ApplicationVariant)?.outputs?.forEach { output ->
                        val abi: String? =
                            output.filters
                                .find { it.filterType == FilterConfiguration.FilterType.ABI }
                                ?.identifier
                        val abiVersionCode: Int? = FlutterPluginConstants.ABI_VERSION[abi]
                        val baseVersionCode: Int? = output.versionCode.orNull
                        if (abi != null && abiVersionCode != null && baseVersionCode != null) {
                            val newVersionCode = abiVersionCode * 1000 + baseVersionCode
                            output.versionCode.set(newVersionCode)
                            appliedAbiVersionCodes[abi] = newVersionCode
                        }
                    }
                }

                // Copy the output APKs into a known location, so `flutter run` or
                // `flutter build apk` can discover them. By default, this is
                // `<app-dir>/build/app/outputs/flutter-apk/<filename>.apk`, where the
                // filename is `app<-abi>?<-flavor-name>?-<build-mode>.apk` (unchanged from
                // the pre-migration assemble.doLast copy).
                val variantBuildModeName =
                    FlutterPluginUtils.buildModeFor(variant.buildType ?: variant.name, variant.debuggable)
                val flutterApkDir =
                    projectToAddTasksTo.layout.buildDirectory.dir("outputs/flutter-apk")
                val apkOutputFileNames =
                    flutterApkOutputFileNames(projectToAddTasksTo, variant.flavorName, variantBuildModeName)
                val copyFlutterApksTaskProvider: TaskProvider<CopyFlutterApksTask> =
                    projectToAddTasksTo.tasks.register(
                        "copyFlutterApks$capitalizeVariantName",
                        CopyFlutterApksTask::class.java
                    ) {
                        apkDirectory.set(variant.artifacts.get(SingleArtifact.APK))
                        builtArtifactsLoader.set(variant.artifacts.getBuiltArtifactsLoader())
                        buildModeName.set(variantBuildModeName)
                        flavorName.set(variant.flavorName ?: "")
                        destinationDir.set(flutterApkDir)
                        outputApks.from(apkOutputFileNames.map { name -> flutterApkDir.map { dir -> dir.file(name) } })
                        expectedVersionCodes.set(appliedAbiVersionCodes)
                    }
                // The flutter-apk copy must run whenever the variant is assembled. The
                // assemble task does not exist yet at variant-API time, so match it by name,
                // and assert after evaluation that it was found: a silent no-match would mean
                // `flutter run`/`flutter build apk` no longer find their APKs.
                val assembleTaskName = "assemble$capitalizeVariantName"
                projectToAddTasksTo.tasks
                    .matching { it.name == assembleTaskName }
                    .configureEach { finalizedBy(copyFlutterApksTaskProvider) }
                projectToAddTasksTo.gradle.projectsEvaluated {
                    if (projectToAddTasksTo.tasks.findByName(assembleTaskName) == null) {
                        throw GradleException(
                            "Flutter expected the Android Gradle Plugin to create the " +
                                "'$assembleTaskName' task, but it does not exist, so the " +
                                "flutter-apk copy for variant '${variant.name}' could not be " +
                                "attached. Please file an issue at " +
                                "https://github.com/flutter/flutter/issues."
                        )
                    }
                }
            }
        }

        if (FlutterPluginUtils.isFlutterAppProject(projectToAddTasksTo)) {
            val appExtension = FlutterPluginUtils.getAndroidApplicationExtension(projectToAddTasksTo)
            configureAbis(projectToAddTasksTo, appExtension)
        } else if (projectToAddTasksTo.rootProject.hasProperty("flutter.hostAppProjectName")) {
            // Add-to-app used to look the host application project up (to wire Flutter's
            // asset copy into the host's asset merging by hand). Flutter's assets are now a
            // generated assets source directory of the module's own library variants, which
            // the host consumes like any other library assets, so there is nothing left to
            // look up.
            projectToAddTasksTo.logger.warn(
                "Warning: the `flutter.hostAppProjectName` gradle property no longer has " +
                    "any effect and will be removed in a future Flutter release. Remove it " +
                    "from gradle.properties."
            )
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
         * Built identically by [addFlutterDeps], which registers the task, and by the variant API
         * callback in [addFlutterTasks], which references it by name (because that callback runs
         * before the task is registered).
         */
        private fun flutterCompileTaskName(variantName: String): String =
            FlutterPluginUtils.toCamelCase(listOf("compile", FLUTTER_BUILD_PREFIX, variantName))

        /**
         * The flutter-apk file names a variant build produces, predictable at configuration
         * time: one per target ABI for `--split-per-abi` builds (universal APKs are disabled
         * for those, see [configureAbis]), or the single fat-APK name otherwise.
         */
        private fun flutterApkOutputFileNames(
            project: Project,
            flavorName: String?,
            buildModeName: String
        ): List<String> {
            val flavorPart =
                if (flavorName.isNullOrEmpty()) "" else "-${FlutterPluginUtils.lowercase(flavorName)}"
            return if (FlutterPluginUtils.shouldProjectSplitPerAbi(project)) {
                FlutterPluginUtils.getTargetPlatforms(project).map { platform ->
                    val abi = FlutterPluginConstants.PLATFORM_ARCH_MAP[platform]
                    "app-$abi$flavorPart-$buildModeName.apk"
                }
            } else {
                listOf("app$flavorPart-$buildModeName.apk")
            }
        }

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
         * Registers the [FlutterTask] (the `flutter assemble` invocation) for [variant],
         * configured entirely from the public variant API, for both application and
         * add-to-app module (library) projects.
         */
        private fun registerFlutterCompileTask(
            project: Project,
            variant: Variant,
            flutterPlugin: FlutterPlugin,
            targetPlatforms: List<String>
        ): TaskProvider<FlutterTask> {
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

            // Variant-scope build-mode resolution uses the public debuggable flag so that
            // custom debuggable build types (e.g. `staging`) map to the debug engine artifacts.
            val variantBuildMode: String =
                FlutterPluginUtils.buildModeFor(variant.buildType ?: variant.name, variant.debuggable)
            val flavorValue: String? = variant.flavorName
            val variantNameValue: String = variant.name
            val minSdkVersionValue: Int = variant.minSdk.apiLevel

            return project.tasks.register(flutterCompileTaskName(variant.name), FlutterTask::class.java) {
                flutterRoot = flutterPlugin.flutterRoot
                flutterExecutable = flutterPlugin.flutterExecutable
                buildMode = variantBuildMode
                minSdkVersion = minSdkVersionValue
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
                        project.layout.buildDirectory.dir("${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/$variantNameValue/")
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
