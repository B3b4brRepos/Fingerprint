.class public final Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;
.super Ljava/lang/Object;
.source "OneOSFakeFingerprintProvider.java"

# OneOS: a fingerprint that is only a picture. Hand-written smali, added to the guest's
# services.jar by patches/fake_fingerprint.py; there is no Java source for it.
#
# One software-only sensor (id 0, under-display, "strong") with one enrolled finger. It
# never opens a HAL, never calls gatekeeper, weaver or keystore, and never lists, adds or
# removes a template of the phone: nothing in here leaves the guest's system_server.
# SystemUI draws the ColorOS fingerprint icon and animation because a UDFPS overlay is
# shown for it; any touch on that overlay (a pencil, a foot, a thumb) counts as a match.
# The package is the converter's (its success and error methods are package private).

.implements Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;
.implements Ljava/lang/Runnable;


# static fields
.field private static final TAG:Ljava/lang/String; = "OneOSFakeFingerprint"

.field private static sOverlay:Landroid/hardware/fingerprint/IUdfpsOverlayController;


# instance fields
.field private final mCallback:Landroid/hardware/fingerprint/IUdfpsOverlayControllerCallback;

.field private final mContext:Landroid/content/Context;

.field private final mHandler:Landroid/os/Handler;

.field private final mProps:Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

.field private mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

.field private mCookie:I

.field private mDetect:Z

.field private mNextId:J

.field private mReason:I

.field private mReq:J

.field private mUser:I


# direct methods
.method private constructor <init>(Landroid/content/Context;)V
    .locals 8

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mContext:Landroid/content/Context;

    const-wide/16 v0, 0x1

    iput-wide v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mNextId:J

    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mHandler:Landroid/os/Handler;

    new-instance v0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider$Overlay;

    invoke-direct {v0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider$Overlay;-><init>()V

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCallback:Landroid/hardware/fingerprint/IUdfpsOverlayControllerCallback;

    # sensor 0, STRENGTH_STRONG (2), 5 fingers, no components, TYPE_UDFPS_OPTICAL (3)
    new-instance v0, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    invoke-static {}, Ljava/util/Collections;->emptyList()Ljava/util/List;

    move-result-object v4

    const/4 v1, 0x0

    const/4 v2, 0x2

    const/4 v3, 0x5

    const/4 v5, 0x3

    const/4 v6, 0x0

    invoke-direct/range {v0 .. v6}, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;-><init>(IIILjava/util/List;IZ)V

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mProps:Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    const-string v0, "OneOSFakeFingerprint"

    const-string v1, "software-only fingerprint sensor 0 (no HAL, no gatekeeper, no keystore)"

    invoke-static {v0, v1}, Landroid/util/Slog;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

# The registry's supplier: this is the only provider the guest's FingerprintService gets.
.method public static providers(Landroid/content/Context;)Ljava/util/List;
    .locals 2
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Landroid/content/Context;",
            ")",
            "Ljava/util/List<",
            "Lcom/android/server/biometrics/sensors/fingerprint/ServiceProvider;",
            ">;"
        }
    .end annotation

    new-instance v0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;

    invoke-direct {v0, p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;-><init>(Landroid/content/Context;)V

    invoke-static {v0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    return-object v0
.end method

# SystemUI hands its overlay controller over once; a provider registered after that
# would never hear of it, so FingerprintService.setUdfpsOverlayController keeps it here.
.method public static rememberOverlay(Landroid/hardware/fingerprint/IUdfpsOverlayController;)V
    .locals 0

    sput-object p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->sOverlay:Landroid/hardware/fingerprint/IUdfpsOverlayController;

    return-void
.end method

.method private declared-synchronized beginAuth(Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;IJ)V
    .locals 1

    iput-object p1, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    iput p2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mUser:I

    iput-wide p3, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReq:J

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mHandler:Landroid/os/Handler;

    invoke-virtual {v0, p0}, Landroid/os/Handler;->removeCallbacks(Ljava/lang/Runnable;)V

    return-void
.end method

# 3 = biometric prompt, 4 = keyguard, 5 = anything else (the numbers the real client uses).
.method private reasonFor(Ljava/lang/String;I)I
    .locals 2

    if-eqz p2, :cond_0

    const/4 v0, 0x3

    return v0

    :cond_0
    :try_start_0
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mContext:Landroid/content/Context;

    invoke-static {v0, p1}, Lcom/android/server/biometrics/Utils;->isKeyguard(Landroid/content/Context;Ljava/lang/String;)Z

    move-result v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v0, :cond_1

    const/4 v0, 0x4

    return v0

    :catchall_0
    move-exception v0

    :cond_1
    const/4 v0, 0x5

    return v0
.end method

.method private showOverlay(I)V
    .locals 6

    sget-object v0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->sOverlay:Landroid/hardware/fingerprint/IUdfpsOverlayController;

    if-eqz v0, :cond_0

    iget-wide v1, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReq:J

    const/4 v3, 0x0

    move v4, p1

    iget-object v5, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCallback:Landroid/hardware/fingerprint/IUdfpsOverlayControllerCallback;

    :try_start_0
    invoke-interface/range {v0 .. v5}, Landroid/hardware/fingerprint/IUdfpsOverlayController;->showUdfpsOverlay(JIILandroid/hardware/fingerprint/IUdfpsOverlayControllerCallback;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    return-void

    :catchall_0
    move-exception v0

    const-string v1, "OneOSFakeFingerprint"

    const-string v2, "showUdfpsOverlay failed"

    invoke-static {v1, v2, v0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method private hideOverlay()V
    .locals 3

    sget-object v0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->sOverlay:Landroid/hardware/fingerprint/IUdfpsOverlayController;

    if-eqz v0, :cond_0

    const/4 v1, 0x0

    :try_start_0
    invoke-interface {v0, v1}, Landroid/hardware/fingerprint/IUdfpsOverlayController;->hideUdfpsOverlay(I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    return-void

    :catchall_0
    move-exception v0

    const-string v1, "OneOSFakeFingerprint"

    const-string v2, "hideUdfpsOverlay failed"

    invoke-static {v1, v2, v0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method private declared-synchronized nextId()J
    .locals 4

    iget-wide v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mNextId:J

    const-wide/16 v2, 0x1

    add-long/2addr v2, v0

    iput-wide v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mNextId:J

    return-wide v0
.end method

# The one finger there is.
.method private finger()Landroid/hardware/fingerprint/Fingerprint;
    .locals 6

    new-instance v0, Landroid/hardware/fingerprint/Fingerprint;

    const-string v1, "OneOS"

    const/4 v2, 0x1

    const-wide/16 v3, 0x0

    invoke-direct {v0, v1, v2, v3, v4}, Landroid/hardware/fingerprint/Fingerprint;-><init>(Ljava/lang/CharSequence;IJ)V

    return-object v0
.end method


# virtual methods
# --- the delayed answer to a touch: match (or "detected" when only detecting) ---
.method public declared-synchronized run()V
    .locals 6

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    if-nez v0, :cond_0

    return-void

    :cond_0
    :try_start_0
    # v1 = sensor 0, v2 = the finger, v3 = no hardware token, v4 = user, v5 = strong
    const/4 v1, 0x0

    const/4 v3, 0x0

    iget v4, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mUser:I

    const/4 v5, 0x1

    iget-boolean v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mDetect:Z

    if-eqz v2, :cond_1

    invoke-virtual {v0, v1, v4, v5}, Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;->onDetected(IIZ)V

    goto :goto_0

    :cond_1
    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->finger()Landroid/hardware/fingerprint/Fingerprint;

    move-result-object v2

    invoke-virtual/range {v0 .. v5}, Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;->onAuthenticationSucceeded(ILandroid/hardware/biometrics/BiometricAuthenticator$Identifier;[BIZ)V

    :goto_0
    const/4 v0, 0x0

    iput-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->hideOverlay()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-void

    :catchall_0
    move-exception v0

    const-string v1, "OneOSFakeFingerprint"

    const-string v2, "answering a touch failed"

    invoke-static {v1, v2, v0}, Landroid/util/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

# --- BiometricServiceProvider ---
.method public containsSensor(I)Z
    .locals 1

    if-nez p1, :cond_0

    const/4 v0, 0x1

    return v0

    :cond_0
    const/4 v0, 0x0

    return v0
.end method

.method public dumpInternal(ILjava/io/PrintWriter;)V
    .locals 1

    const-string v0, "OneOS fake fingerprint (software only)"

    invoke-virtual {p2, v0}, Ljava/io/PrintWriter;->println(Ljava/lang/String;)V

    return-void
.end method

.method public dumpProtoMetrics(ILjava/io/FileDescriptor;)V
    .locals 0

    return-void
.end method

.method public dumpProtoState(ILandroid/util/proto/ProtoOutputStream;Z)V
    .locals 0

    return-void
.end method

.method public getAuthenticatorId(II)J
    .locals 2

    const-wide/16 v0, 0x0

    return-wide v0
.end method

.method public getLockoutModeForUser(II)I
    .locals 1

    const/4 v0, 0x0

    return v0
.end method

.method public getSensorProperties(I)Landroid/hardware/biometrics/SensorPropertiesInternal;
    .locals 1

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mProps:Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    return-object v0
.end method

.method public getSensorProperties()Ljava/util/List;
    .locals 1
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "()",
            "Ljava/util/List<",
            "Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;",
            ">;"
        }
    .end annotation

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mProps:Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;

    invoke-static {v0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    return-object v0
.end method

.method public hasEnrollments(II)Z
    .locals 1

    const/4 v0, 0x1

    return v0
.end method

.method public isHardwareDetected(I)Z
    .locals 1

    const/4 v0, 0x1

    return v0
.end method

# --- ServiceProvider ---
# A cancel ends the client the way the real one does (ERROR_CANCELED, 5): the lock screen
# waits for it before it listens again.
.method public declared-synchronized cancelAuthentication(ILandroid/os/IBinder;J)V
    .locals 5

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    const/4 v1, 0x0

    iput-object v1, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    iget-object v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mHandler:Landroid/os/Handler;

    invoke-virtual {v2, p0}, Landroid/os/Handler;->removeCallbacks(Ljava/lang/Runnable;)V

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->hideOverlay()V

    if-eqz v0, :cond_0

    :try_start_0
    iget v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCookie:I

    const/4 v3, 0x5

    const/4 v4, 0x0

    invoke-virtual {v0, p1, v2, v3, v4}, Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;->onError(IIII)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    return-void

    :catchall_0
    move-exception v0

    return-void
.end method

.method public cancelEnrollment(ILandroid/os/IBinder;J)V
    .locals 0

    return-void
.end method

.method public createTestSession(ILandroid/hardware/biometrics/ITestSessionCallback;Ljava/lang/String;)Landroid/hardware/biometrics/ITestSession;
    .locals 1

    const/4 v0, 0x0

    return-object v0
.end method

.method public getEnrolledFingerprints(II)Ljava/util/List;
    .locals 1
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(II)",
            "Ljava/util/List<",
            "Landroid/hardware/fingerprint/Fingerprint;",
            ">;"
        }
    .end annotation

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->finger()Landroid/hardware/fingerprint/Fingerprint;

    move-result-object v0

    invoke-static {v0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    return-object v0
.end method

.method public getServiceProviderAidlEx()Lcom/android/server/biometrics/sensors/fingerprint/aidl/IFingerprintServiceProviderExt;
    .locals 1

    const/4 v0, 0x0

    return-object v0
.end method

.method public getServiceProviderEx()Lcom/android/server/biometrics/sensors/fingerprint/hidl/IOplusHidlToAidlCallbackConverterExt;
    .locals 1

    const/4 v0, 0x0

    return-object v0
.end method

# A touch on the overlay: the lock screen is told, and one beat later it is a match.
.method public declared-synchronized onPointerDown(JILandroid/hardware/biometrics/fingerprint/PointerContext;)V
    .locals 4

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    if-nez v0, :cond_0

    return-void

    :cond_0
    :try_start_0
    invoke-virtual {v0, p3}, Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;->onUdfpsPointerDown(I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :goto_0
    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mHandler:Landroid/os/Handler;

    invoke-virtual {v0, p0}, Landroid/os/Handler;->removeCallbacks(Ljava/lang/Runnable;)V

    const-wide/16 v1, 0xc8

    invoke-virtual {v0, p0, v1, v2}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void

    :catchall_0
    move-exception v0

    goto :goto_0
.end method

.method public declared-synchronized onPointerUp(JILandroid/hardware/biometrics/fingerprint/PointerContext;)V
    .locals 2

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    if-eqz v0, :cond_0

    :try_start_0
    invoke-virtual {v0, p3}, Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;->onUdfpsPointerUp(I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    :goto_0
    return-void

    :catchall_0
    move-exception v0

    goto :goto_0
.end method

.method public onPowerPressed()V
    .locals 0

    return-void
.end method

.method public onUdfpsUiEvent(IJI)V
    .locals 0

    return-void
.end method

.method public rename(IIILjava/lang/String;)V
    .locals 0

    return-void
.end method

# Keyguard path: the overlay (icon and animation) goes up at once.
.method public declared-synchronized scheduleAuthenticate(Landroid/os/IBinder;JILcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;ZIZ)J
    .locals 3

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->nextId()J

    move-result-wide v0

    invoke-virtual {p6}, Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;->getOpPackageName()Ljava/lang/String;

    move-result-object v2

    invoke-direct {p0, v2, p4}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->reasonFor(Ljava/lang/String;I)I

    move-result v2

    iput v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    iput p4, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCookie:I

    const/4 v2, 0x0

    iput-boolean v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mDetect:Z

    invoke-virtual {p6}, Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;->getUserId()I

    move-result v2

    invoke-direct {p0, p5, v2, v0, v1}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->beginAuth(Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;IJ)V

    iget v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    invoke-direct {p0, v2}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->showOverlay(I)V

    return-wide v0
.end method

# Biometric prompt path: prepared now, the overlay goes up in startPreparedClient.
.method public declared-synchronized scheduleAuthenticate(Landroid/os/IBinder;JILcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;JZIZ)V
    .locals 2

    invoke-virtual {p6}, Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;->getOpPackageName()Ljava/lang/String;

    move-result-object v0

    invoke-direct {p0, v0, p4}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->reasonFor(Ljava/lang/String;I)I

    move-result v0

    iput v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    iput p4, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCookie:I

    const/4 v0, 0x0

    iput-boolean v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mDetect:Z

    invoke-virtual {p6}, Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;->getUserId()I

    move-result v0

    invoke-direct {p0, p5, v0, p7, p8}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->beginAuth(Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;IJ)V

    return-void
.end method

.method public declared-synchronized startPreparedClient(II)V
    .locals 1

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    if-eqz v0, :cond_0

    iget v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    invoke-direct {p0, v0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->showOverlay(I)V

    :cond_0
    return-void
.end method

# Finger detection (the lock screen's "a finger is here" while a PIN is still required).
.method public declared-synchronized scheduleFingerDetect(Landroid/os/IBinder;Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;I)J
    .locals 3

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->nextId()J

    move-result-wide v0

    const/4 v2, 0x4

    iput v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    const/4 v2, 0x0

    iput v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mCookie:I

    const/4 v2, 0x1

    iput-boolean v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mDetect:Z

    invoke-virtual {p3}, Landroid/hardware/fingerprint/FingerprintAuthenticateOptions;->getUserId()I

    move-result v2

    invoke-direct {p0, p2, v2, v0, v1}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->beginAuth(Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;IJ)V

    iget v2, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    invoke-direct {p0, v2}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->showOverlay(I)V

    return-wide v0
.end method

# Settings' "add fingerprint" finishes at once: the one finger is there already.
.method public scheduleEnroll(ILandroid/os/IBinder;[BILandroid/hardware/fingerprint/IFingerprintServiceReceiver;Ljava/lang/String;ILandroid/hardware/fingerprint/FingerprintEnrollOptions;)J
    .locals 4

    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->nextId()J

    move-result-wide v0

    :try_start_0
    invoke-direct {p0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->finger()Landroid/hardware/fingerprint/Fingerprint;

    move-result-object v2

    const/4 v3, 0x0

    invoke-interface {p5, v2, v3}, Landroid/hardware/fingerprint/IFingerprintServiceReceiver;->onEnrollResult(Landroid/hardware/fingerprint/Fingerprint;I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-wide v0

    :catchall_0
    move-exception v2

    return-wide v0
.end method

.method public scheduleGenerateChallenge(IILandroid/os/IBinder;Landroid/hardware/fingerprint/IFingerprintServiceReceiver;Ljava/lang/String;)V
    .locals 2

    :try_start_0
    const-wide/16 v0, 0x1

    invoke-interface {p4, p1, p2, v0, v1}, Landroid/hardware/fingerprint/IFingerprintServiceReceiver;->onChallengeGenerated(IIJ)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-void

    :catchall_0
    move-exception v0

    return-void
.end method

.method public scheduleInternalCleanup(IILcom/android/server/biometrics/sensors/ClientMonitorCallback;)V
    .locals 0

    return-void
.end method

.method public scheduleInternalCleanup(IILcom/android/server/biometrics/sensors/ClientMonitorCallback;Z)V
    .locals 0

    return-void
.end method

.method public scheduleInvalidateAuthenticatorId(IILandroid/hardware/biometrics/IInvalidationCallback;)V
    .locals 1

    if-eqz p3, :cond_0

    :try_start_0
    invoke-interface {p3}, Landroid/hardware/biometrics/IInvalidationCallback;->onCompleted()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    return-void

    :catchall_0
    move-exception v0

    return-void
.end method

.method public scheduleRemove(ILandroid/os/IBinder;Landroid/hardware/fingerprint/IFingerprintServiceReceiver;IILjava/lang/String;)V
    .locals 0

    return-void
.end method

.method public scheduleRemoveAll(ILandroid/os/IBinder;Landroid/hardware/fingerprint/IFingerprintServiceReceiver;ILjava/lang/String;)V
    .locals 0

    return-void
.end method

.method public scheduleResetLockout(II[B)V
    .locals 0

    return-void
.end method

.method public scheduleRevokeChallenge(IILandroid/os/IBinder;Ljava/lang/String;J)V
    .locals 0

    return-void
.end method

.method public setIgnoreDisplayTouches(JIZ)V
    .locals 0

    return-void
.end method

# SystemUI's overlay controller, handed over now (see rememberOverlay); if a client is
# already waiting, its overlay goes up.
.method public declared-synchronized setUdfpsOverlayController(Landroid/hardware/fingerprint/IUdfpsOverlayController;)V
    .locals 1

    sput-object p1, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->sOverlay:Landroid/hardware/fingerprint/IUdfpsOverlayController;

    iget-object v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mConv:Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;

    if-eqz v0, :cond_0

    iget v0, p0, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->mReason:I

    invoke-direct {p0, v0}, Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;->showOverlay(I)V

    :cond_0
    return-void
.end method
