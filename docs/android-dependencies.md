# Android dependency notes

The Android implementation of the Freedompay plugin now relies on the PayBox SDK
published via JitPack (`com.github.PayBox:kotlin-paybox-sdk:0.13.0`) instead of a
vendored Gradle submodule. Removing the local `:payboxsdk` project avoids stale
module references in consumers' Gradle builds.
