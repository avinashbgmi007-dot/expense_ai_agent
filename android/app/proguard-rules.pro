# Rules for Google ML Kit and MediaPipe
-keep class com.google.mediapipe.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Preserve the line numbers so that the stack traces
# are meaningful
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep model classes
-keep class com.example.expense_ai_agent.models.** { *; }
-keep class com.example.expense_ai_agent.services.** { *; }

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Add this for OCR and vision models
-dontwarn com.google.mlkit.**
-dontwarn com.google.mediapipe.**
