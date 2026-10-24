plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "io.github.farhanreninda.dashtconnect.receiver"
    compileSdk = 37
    defaultConfig { minSdk = 24 }
    sourceSets.getByName("main") {
        java.srcDirs("src/main/kotlin", "third_party/carplay_core/src/main/java")
        assets.srcDir("third_party/carplay_core/src/main/assets")
    }
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
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("org.bouncycastle:bcprov-jdk18on:1.79")
    implementation("org.jmdns:jmdns:3.6.3")
    testImplementation("junit:junit:4.13.2")
}
