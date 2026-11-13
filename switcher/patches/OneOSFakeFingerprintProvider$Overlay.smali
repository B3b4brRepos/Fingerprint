.class public final Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider$Overlay;
.super Landroid/hardware/fingerprint/IUdfpsOverlayControllerCallback$Stub;
.source "OneOSFakeFingerprintProvider.java"

# OneOS: SystemUI's overlay needs a callback to report "the user cancelled"; the
# biometric prompt cancels through cancelAuthentication anyway, so this one only exists.

.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Landroid/hardware/fingerprint/IUdfpsOverlayControllerCallback$Stub;-><init>()V

    return-void
.end method

.method public onUserCanceled()V
    .locals 0

    return-void
.end method
