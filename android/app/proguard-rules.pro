# Flutter Gemma - MediaPipe GenAI ProGuard Rules
# Required for release builds with R8 minification

# Keep all MediaPipe classes
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Keep MediaPipe proto classes
-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.proto.**

# Keep LiteRT-LM classes (if using LiteRT-LM engine)
-keep class com.google.ai.edge.litertlm.** { *; }
-dontwarn com.google.ai.edge.litertlm.**

# Keep Flutter Gemma plugin classes
-keep class dev.flutterberlin.flutter_gemma.** { *; }
-dontwarn dev.flutterberlin.flutter_gemma.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
