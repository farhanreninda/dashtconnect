import java.util.Properties

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val localProperties = Properties().apply {
    rootProject.file("local.properties").takeIf { it.isFile }?.inputStream()?.use { load(it) }
}
// Folder berisi androidauto/headunit.crt dan androidauto/headunit.key; tidak pernah masuk Git.
val identityDirectory = providers.environmentVariable("DASHTCONNECT_ANDROID_AUTO_IDENTITY_DIR")
    .orElse(providers.provider { localProperties.getProperty("dashtconnect.androidAutoIdentityDir") })

android {
    namespace = "io.github.farhanreninda.dashtconnect.aap"
    compileSdk = 37
    defaultConfig { minSdk = 24 }
    sourceSets.getByName("main").java.srcDirs("src/main/kotlin")
    sourceSets.getByName("test").java.srcDirs("src/test/kotlin")
    identityDirectory.orNull?.let { sourceSets.getByName("main").assets.srcDir(file(it)) }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    testImplementation("junit:junit:4.13.2")
}
