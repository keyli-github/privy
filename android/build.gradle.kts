import com.android.build.api.variant.LibraryAndroidComponentsExtension

plugins {
    id("com.android.application") apply false
}

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

    if (name == "biometric_storage") {
        pluginManager.withPlugin("com.android.library") {
            extensions.getByType<LibraryAndroidComponentsExtension>().finalizeDsl { android ->
                // biometric_storage 5.0.1 declares API 31, but its AndroidX dependencies require 34+.
                android.compileSdk = maxOf(android.compileSdk ?: 0, 36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
