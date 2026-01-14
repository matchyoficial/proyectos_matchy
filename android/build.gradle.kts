// 📂 android/build.gradle.kts
// ✅ Firebase — declaración correcta del plugin Google Services (Kotlin DSL)

import org.gradle.api.file.Directory

// 🔴 CHINCHE FIREBASE 2 — declarar versión del plugin (NO se aplica aquí)
plugins {
    id("com.google.gms.google-services") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔴 CHINCHE BUILD DIR 1 — build fuera de android/
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

// 🔴 CHINCHE BUILD DIR 2 — subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔴 CHINCHE DEPENDENCY ORDER
subprojects {
    project.evaluationDependsOn(":app")
}

// 🔴 CHINCHE CLEAN
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
