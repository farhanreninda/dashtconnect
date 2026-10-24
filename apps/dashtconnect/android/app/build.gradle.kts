import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val receiverLocalProperties = Properties().apply {
    rootProject.file("local.properties").takeIf { it.isFile }?.inputStream()?.use { load(it) }
}
val authAssetsDirectory = providers.environmentVariable("DASHTCONNECT_AUTH_ASSETS_DIR")
    .orElse(providers.provider { receiverLocalProperties.getProperty("dashtconnect.authAssetsDir") })
val receiverBluetoothAddress = providers.environmentVariable("DASHTCONNECT_BLUETOOTH_ADDRESS")
    .orElse(providers.provider { receiverLocalProperties.getProperty("dashtconnect.bluetoothAddress") })
    .orNull.orEmpty().uppercase()
check(receiverBluetoothAddress.isEmpty() ||
    (Regex("[0-9A-F]{2}(:[0-9A-F]{2}){5}").matches(receiverBluetoothAddress) &&
        receiverBluetoothAddress !in setOf("02:00:00:00:00:00", "00:00:00:00:00:00", "FF:FF:FF:FF:FF:FF"))) {
    "DASHTCONNECT_BLUETOOTH_ADDRESS harus berupa alamat Bluetooth perangkat yang valid."
}
val validateReceiverAuthentication by tasks.registering {
    group = "verification"
    description = "Validate the explicitly configured local receiver authentication assets."
    doLast {
        val path = authAssetsDirectory.orNull
            ?: throw GradleException("Receiver belum siap: isi DASHTCONNECT_AUTH_ASSETS_DIR atau dashtconnect.authAssetsDir di local.properties sebelum membuat APK release.")
        val directory = file(path)
        check(File(path).isAbsolute) { "DASHTCONNECT_AUTH_ASSETS_DIR harus berupa path absolut." }
        val expected = setOf("offline-mfi/identity.pk8", "offline-mfi/certificate.p7b")
        for (name in expected) {
            val asset = directory.resolve(name)
            check(asset.isFile && asset.length() > 0) { "Aset autentikasi tidak ada atau kosong: $name" }
        }
        val unexpected = fileTree(directory).files.filter {
            it.relativeTo(directory).invariantSeparatorsPath !in expected
        }
        check(unexpected.isEmpty()) { "Direktori autentikasi hanya boleh berisi dua aset receiver; jangan sertakan file atau kredensial lain." }
    }
}

tasks.matching { it.name == "mergeReleaseAssets" ||
    (authAssetsDirectory.isPresent && it.name in setOf("mergeDebugAssets", "mergeProfileAssets")) }.configureEach {
    dependsOn(validateReceiverAuthentication)
}

android {
    namespace = "io.github.farhanreninda.dashtconnect"
    compileSdk = 37
    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.farhanreninda.dashtconnect"
        buildConfigField("String", "RECEIVER_BLUETOOTH_ADDRESS", "\"$receiverBluetoothAddress\"")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    authAssetsDirectory.orNull?.let {
        sourceSets.getByName("main").assets.srcDir(file(it))
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":receiver"))
}
