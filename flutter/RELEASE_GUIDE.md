# Release Guide for Darooyar

This guide provides instructions for preparing the Darooyar app for release.

## Package Name Change

The package name has been changed from `com.example.darooyar` to `com.bezidev.darooyar`. The following files have been updated:

- Android build.gradle
- MainActivity.kt
- Linux CMakeLists.txt
- macOS configuration files

## Generating a Keystore for App Signing

To sign your app for release, you need to generate a keystore file. Follow these steps:

1. Open a terminal and navigate to a secure location to store your keystore.

2. Run the following command to generate a keystore:

```bash
keytool -genkey -v -keystore darooyar.keystore -alias darooyar -keyalg RSA -keysize 2048 -validity 10000
```

3. You will be prompted to enter a password for the keystore and provide some information about yourself or your organization.

4. Keep the keystore file and passwords secure. If you lose them, you won't be able to update your app on the Play Store.

## Configuring Gradle for App Signing

1. Create a file named `key.properties` in the `android/` directory with the following content:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=darooyar
storeFile=<path-to-your-keystore-file>
```

2. Update the `android/app/build.gradle` file to use the keystore for signing:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

## Building the Release APK

To build a release APK, run:

```bash
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## Building the Release App Bundle (AAB)

To build a release App Bundle for the Google Play Store, run:

```bash
flutter build appbundle --release
```

The AAB will be located at `build/app/outputs/bundle/release/app-release.aab`.

## Building for Myket

Since the app is configured for Myket IAP, you can use the same signed APK for distribution on Myket.

## Important Notes

- Always keep your keystore file and passwords secure.
- Make sure to test the release build thoroughly before distribution.
- Update the version number in `pubspec.yaml` before each release.
