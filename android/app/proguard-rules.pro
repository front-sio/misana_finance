# Keep javax.annotation classes
-keep class javax.annotation.** { *; }
-dontwarn javax.annotation.**

# Keep errorprone annotations
-keep class com.google.errorprone.annotations.** { *; }
-dontwarn com.google.errorprone.annotations.**
