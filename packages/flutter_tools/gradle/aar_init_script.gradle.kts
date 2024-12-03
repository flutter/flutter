// This script initializes the build in a module or plugin project using Kotlin DSL.
// It applies the Maven plugin and configures the destination of the local repository.
// The local repository will contain the AAR and POM files.

import java.nio.file.Paths

fun configureProject(project: Project, outputDir: String) {
    if (!project.hasProperty("android")) {
        throw GradleException("Android property not found.")
    }
    val android = project.extensions.getByName("android")
    if (!android.hasProperty("libraryVariants")) {
        throw GradleException("Can't generate AAR on a non Android library project.")
    }

    project.version = project.version.toString().replace("-SNAPSHOT", "")

    if (project.hasProperty("buildNumber")) {
        project.version = project.property("buildNumber").toString()
    }

    project.components.forEach { component ->
        if (component.name != "all") {
            addAarTask(project, component)
        }
    }

    project.extensions.configure<PublishingExtension> {
        repositories {
            maven {
                url = uri("file://${outputDir}/outputs/repo")
            }
        }
    }

    if (!project.property("is-plugin").toString().toBoolean()) {
        return
    }

    val storageUrl = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"

    val engineRealm = Paths.get(getFlutterRoot(project), "bin", "internal", "engine.realm")
        .toFile().readText().trim()
    val engineRealmPath = if (engineRealm.isNotEmpty()) "$engineRealm/" else ""

    project.repositories.maven {
        url = uri("$storageUrl/${engineRealmPath}download.flutter.io")
    }

    val engineVersion = Paths.get(getFlutterRoot(project), "bin", "internal", "engine.version")
        .toFile().readText().trim()
    project.dependencies.add("compileOnly", "io.flutter:flutter_embedding_release:1.0.0-$engineVersion") {
        isTransitive = false
    }
}

fun configurePlugin(project: Project, outputDir: String) {
    if (!project.hasProperty("android")) return
    configureProject(project, outputDir)
}

fun getFlutterRoot(project: Project): String {
    if (!project.hasProperty("flutter-root")) {
        throw GradleException("The `-Pflutter-root` flag must be specified.")
    }
    return project.property("flutter-root").toString()
}

fun addAarTask(project: Project, component: SoftwareComponent) {
    val variantName = component.name.capitalize()
    val taskName = "assembleAar$variantName"
    project.tasks.register(taskName) {
        if (!project.gradle.startParameter.taskNames.contains(taskName)) return@register

        project.extensions.configure<PublishingExtension> {
            publications.create<MavenPublication>(component.name) {
                groupId = this.groupId
                artifactId = "${this.artifactId}_${this.name}"
                version = this.version
                from(component)
            }
        }
        finalizedBy("publish")
    }
}

allprojects {
    apply(plugin = "maven-publish")
}

projectsEvaluated {
    check(rootProject.hasProperty("is-plugin"))
    if (rootProject.property("is-plugin").toString().toBoolean()) {
        check(rootProject.hasProperty("output-dir"))
        configureProject(rootProject, rootProject.property("output-dir").toString())
    } else {
        val moduleProject = rootProject.subprojects.find { it.name == "flutter" }
            ?: throw GradleException("Module project not found")
        configureProject(moduleProject, moduleProject.property("output-dir").toString())

        val modulePlugins = rootProject.subprojects.filter { it.name != "flutter" && it.name != "app" }
        modulePlugins.forEach { pluginProject ->
            configurePlugin(pluginProject, moduleProject.property("output-dir").toString())
            moduleProject.extensions.getByType<BaseExtension>().libraryVariants.all { variant ->
                val variantName = variant.name.capitalize()
                moduleProject.tasks.named("assembleAar$variantName").configure {
                    dependsOn(pluginProject.tasks.named("assembleAar$variantName"))
                }
            }
        }
    }
}
