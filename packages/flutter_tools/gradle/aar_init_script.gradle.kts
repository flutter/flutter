import java.nio.file.Paths
import org.gradle.api.Project
import org.gradle.api.artifacts.repositories.MavenArtifactRepository
import org.gradle.api.publish.PublishingExtension
import org.gradle.api.publish.maven.MavenPublication
import org.gradle.api.tasks.bundling.Jar
import org.gradle.api.plugins.ExtensionContainer
import org.gradle.api.component.SoftwareComponent
import org.gradle.api.tasks.TaskProvider

fun configureProject(project: Project, outputDir: String) {
    // Ensure Android extension is present
    if (project.findProperty("android") == null) {
        throw GradleException("Android property not found.")
    }

    // Validate if the project is an Android library
    if (project.findProperty("libraryVariants") == null) {
        throw GradleException("Can't generate AAR on a non-Android library project.")
    }

    // Update version by removing SNAPSHOT if present
    project.version = project.version.toString().replace("-SNAPSHOT", "")

    // Check for buildNumber and update version if available
    if (project.hasProperty("buildNumber")) {
        project.version = project.property("buildNumber").toString()
    }

    // Register AAR task for each component
    project.components.forEach { component ->
        if (component.name != "all") {
            addAarTask(project, component)
        }
    }

    // Configure Maven publishing repository
    project.extensions.configure<PublishingExtension> {
        repositories {
            maven {
                url = uri("file://${outputDir}/outputs/repo")
            }
        }
    }

    // Handle Flutter plugin-specific logic
    if (project.property("is-plugin").toString().toBoolean()) {
        configureFlutterPlugin(project)
    }
}

fun configureFlutterPlugin(project: Project) {
    val storageUrl = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
    val flutterRoot = getFlutterRoot(project)
    val engineRealm = Paths.get(flutterRoot, "bin", "internal", "engine.realm")
        .toFile().readText().trim()
    val engineRealmPath = if (engineRealm.isNotEmpty()) "$engineRealm/" else ""

    // Set repository for Flutter engine dependencies
    project.repositories.maven {
        url = uri("$storageUrl/${engineRealmPath}download.flutter.io")
    }

    // Get Flutter engine version and add as compileOnly dependency
    val engineVersion = Paths.get(flutterRoot, "bin", "internal", "engine.version")
        .toFile().readText().trim()
    project.dependencies.add("compileOnly", "io.flutter:flutter_embedding_release:1.0.0-$engineVersion") {
        isTransitive = false
    }
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

        // Configure Maven publication for the component
        project.extensions.configure<PublishingExtension> {
            publications.create<MavenPublication>(component.name) {
                groupId = project.group.toString()
                artifactId = "${project.name}_${component.name}"
                version = project.version.toString()
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
            ?: throw GradleException("Module project 'flutter' not found")
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

fun configurePlugin(project: Project, outputDir: String) {
    if (!project.hasProperty("android")) return
    configureProject(project, outputDir)
}

