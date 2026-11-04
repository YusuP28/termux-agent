# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in the Flutter SDK's proguard-rules file.

# For more details, see
#   https://help.github.com/en/android-reducing-app-package-size
#   https://developer.android.com/studio/package-app-bundles

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.view.** { *; }
