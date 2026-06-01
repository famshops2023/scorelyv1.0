extra["kotlin_version"] = "2.2.20"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val applyNamespace: Project.() -> Unit = {
        if (extensions.findByName("android") != null) {
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                if (name == "isar_flutter_libs") {
                    android.namespace = "dev.isar.isar_flutter_libs"
                } else {
                    android.namespace = "com.example.scorely_test.${name.replace("-", "_").replace(".", "_")}"
                }
            }
        }
    }

    if (project.state.executed) {
        project.applyNamespace()
    } else {
        project.afterEvaluate { applyNamespace() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
