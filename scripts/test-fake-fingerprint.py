#!/usr/bin/env python3
"""Test of switcher/patches/fake_fingerprint.py and OneOSFakeFingerprintProvider.smali.

  python3 -I scripts/test-fake-fingerprint.py

1. The patcher on a small smali tree made of the real method bodies of the ColorOS 17 services.jar
   (Find X9 Ultra IN): all five hooks land, the helper goes to the emptiest dex, a second run
   changes nothing, a half-patched tree is an error, another shape is left alone (exit 0, no
   stdout, nothing written).
2. The helper never reaches anything of the phone's: no HAL, gatekeeper, weaver, keystore, no
   Samsung class, no file or socket, and it implements the whole ServiceProvider interface it is
   given.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PATCHES = os.path.join(HERE, "..", "switcher", "patches")
PATCHER = os.path.join(PATCHES, "fake_fingerprint.py")
HELPER = os.path.join(PATCHES, "OneOSFakeFingerprintProvider.smali")
OVERLAY = os.path.join(PATCHES, "OneOSFakeFingerprintProvider$Overlay.smali")
PKG = "com/android/server/biometrics/sensors"
FS = "Lcom/android/server/biometrics/sensors/fingerprint/FingerprintService;"
FS1 = "Lcom/android/server/biometrics/sensors/fingerprint/FingerprintService$1;"

FPS = f""".class Lcom/android/server/biometrics/sensors/fingerprint/FingerprintService$1;
.super Landroid/hardware/fingerprint/IFingerprintService$Stub;

.method private synthetic lambda$registerAuthenticators$1(Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)Ljava/util/List;
    .locals 1
    iget-object v0, p0, {FS1}->this$0:{FS}

    invoke-static {{v0, p1}}, {FS}->-$$Nest$mgetProviders({FS}Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)Ljava/util/List;

    move-result-object v0

    return-object v0
.end method

.method public registerAuthenticators(Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)V
    .locals 3
    const-string v1, "FingerprintService"

    invoke-super {{p0}}, Landroid/hardware/fingerprint/IFingerprintService$Stub;->registerAuthenticators_enforcePermission()V

    invoke-virtual {{p1}}, Landroid/hardware/fingerprint/FingerprintSensorConfigurations;->hasSensorConfigurations()Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "No fingerprint sensors available."

    invoke-static {{v1, v0}}, Landroid/util/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    return-void

    :cond_1
    return-void
.end method

.method public setUdfpsOverlayController(Landroid/hardware/fingerprint/IUdfpsOverlayController;)V
    .locals 2
    invoke-super {{p0}}, Landroid/hardware/fingerprint/IFingerprintService$Stub;->setUdfpsOverlayController_enforcePermission()V

    iget-object v0, p0, {FS1}->this$0:{FS}

    return-void
.end method
"""

AUTH = """.class public Lcom/android/server/biometrics/AuthService;
.super Lcom/android/server/SystemService;

.method private static registerFingerprintSensors([Ljava/lang/String;[Ljava/lang/String;Landroid/content/Context;Landroid/hardware/fingerprint/IFingerprintService;Lcom/android/server/biometrics/BiometricHandlerProvider;)V
    .locals 4
    const-string v0, "AuthService"

    if-eqz p1, :cond_0

    array-length v1, p1

    if-nez v1, :cond_1

    :cond_0
    if-eqz p0, :cond_3

    array-length v1, p0

    if-nez v1, :cond_1

    goto :goto_0

    :cond_1
    sget-boolean v1, Lcom/android/server/biometrics/AuthService;->DEBUG_FINGER:Z

    return-void

    :cond_3
    :goto_0
    const-string v1, "No fingerprint sensors."

    return-void
.end method
"""

PMS = """.class public Lcom/android/server/pm/PackageManagerService;
.super Landroid/content/pm/IPackageManagerBase;

.method public hasSystemFeature(Ljava/lang/String;I)Z
    .locals 4
    iget-object v0, p0, Lcom/android/server/pm/PackageManagerService;->mAvailableFeatures:Landroid/util/ArrayMap;

    invoke-virtual {v0, p1}, Landroid/util/ArrayMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/content/pm/FeatureInfo;

    const/4 v2, 0x0

    if-nez v0, :cond_1

    return v2

    :cond_1
    iget v3, v0, Landroid/content/pm/FeatureInfo;->version:I

    if-lt v3, p2, :cond_2

    const/4 v2, 0x1

    :cond_2
    return v2
.end method
"""

CONV = """.class public Lcom/android/server/biometrics/sensors/ClientMonitorCallbackConverter;
.super Ljava/lang/Object;

.method onAuthenticationSucceeded(ILandroid/hardware/biometrics/BiometricAuthenticator$Identifier;[BIZ)V
    .locals 0
    return-void
.end method

.method public onUdfpsPointerDown(I)V
    .locals 0
    return-void
.end method

.method public onDetected(IIZ)V
    .locals 0
    return-void
.end method

.method public onError(IIII)V
    .locals 0
    return-void
.end method
"""

CTOR = """.class public Lcom/android/server/biometrics/AuthServiceFixtureUser;
.super Ljava/lang/Object;
.method x()V
    .locals 0
    invoke-direct/range {v0 .. v6}, Landroid/hardware/fingerprint/FingerprintSensorPropertiesInternal;-><init>(IIILjava/util/List;IZ)V
    return-void
.end method
"""

FILES = {
    "smali": {  # big dex: the hooks sit here
        f"{PKG}/fingerprint/FingerprintService$1.smali": FPS,
        "com/android/server/biometrics/AuthService.smali": AUTH,
        f"{PKG}/ClientMonitorCallbackConverter.smali": CONV,
        "com/android/server/biometrics/AuthServiceFixtureUser.smali": CTOR,
        "filler/A.smali": ".class public Lfiller/A;\n.super Ljava/lang/Object;\n",
        "filler/B.smali": ".class public Lfiller/B;\n.super Ljava/lang/Object;\n",
    },
    "smali_classes2": {  # the emptier one: the helper goes here
        "com/android/server/pm/PackageManagerService.smali": PMS,
    },
}

failures = []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        failures.append(what)


def make_tree(root, mutate=None):
    for dex, files in FILES.items():
        for rel, text in files.items():
            if mutate:
                text = mutate(rel, text)
            path = os.path.join(root, dex, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(text)


def run(root):
    return subprocess.run([sys.executable, "-I", PATCHER, root], capture_output=True, text=True)


def snapshot(root):
    snap = {}
    for dp, _, fs in os.walk(root):
        for f in fs:
            p = os.path.join(dp, f)
            snap[os.path.relpath(p, root)] = open(p).read()
    return snap


def read(root, dex, rel):
    with open(os.path.join(root, dex, rel)) as f:
        return f.read()


def test_patcher():
    tmp = tempfile.mkdtemp()
    try:
        root = os.path.join(tmp, "services")
        make_tree(root)
        r = run(root)
        check(r.returncode == 0, "the patcher succeeds on the real method shapes: " + r.stderr.strip()[:120])
        check(r.stdout.split() == ["smali", "smali_classes2"], f"it names the dex dirs it changed: {r.stdout.split()}")
        fps = read(root, "smali", f"{PKG}/fingerprint/FingerprintService$1.smali")
        check("OneOSFakeFingerprintProvider;->providers(Landroid/content/Context;)Ljava/util/List;" in fps
              and "-$$Nest$mgetProviders" not in fps,
              "the providers list is the software provider; the HAL-backed getProviders is not called")
        check(re.search(r"hasSensorConfigurations\(\)Z\s+move-result v0\s+# OneOS[^\n]*\n\s+const/4 v0, 0x1\s+if-nez v0, :cond_1", fps) is not None,
              "registerAuthenticators registers although the HAL lists no sensor")
        check(re.search(r"setUdfpsOverlayController_enforcePermission\(\)V\s+# OneOS[^\n]*\n\s+invoke-static \{p1\}, [^\n]*rememberOverlay", fps) is not None,
              "SystemUI's overlay controller is kept by the provider")
        auth = read(root, "smali", "com/android/server/biometrics/AuthService.smali")
        check(re.search(r'const-string v0, "AuthService"\s+# OneOS[^\n]*\n\s+const/4 v1, 0x1\s+if-nez v1, :cond_1\s+if-eqz p1, :cond_0', auth) is not None,
              "AuthService no longer stops at 'No fingerprint sensors.'")
        pms = read(root, "smali_classes2", "com/android/server/pm/PackageManagerService.smali")
        check(re.search(r'const/4 v2, 0x0\s+if-nez v0, :cond_1\s+# OneOS[^\n]*\n\s+const-string v3, "android.hardware.fingerprint"[\s\S]*?const/4 v2, 0x1\s+return v2\s+:oneos_fp_missing\s+return v2', pms) is not None,
              "PackageManagerService reports android.hardware.fingerprint")
        for h in ("OneOSFakeFingerprintProvider.smali", "OneOSFakeFingerprintProvider$Overlay.smali"):
            check(os.path.isfile(os.path.join(root, "smali_classes2", PKG, h)), f"{h} is in the emptiest dex")
        check(not os.path.exists(os.path.join(root, "smali", PKG, "OneOSFakeFingerprintProvider.smali")),
              "and not in the full one")

        before = snapshot(root)
        r = run(root)
        check(r.returncode == 0 and r.stdout == "" and snapshot(root) == before,
              "a second run changes nothing and prints nothing")

        os.remove(os.path.join(root, "smali_classes2", PKG, "OneOSFakeFingerprintProvider$Overlay.smali"))
        r = run(root)
        check(r.returncode != 0, "a half-patched tree is an error")
    finally:
        shutil.rmtree(tmp)

    for what, mutate in (
        ("a different getProviders call", lambda rel, t: t.replace("-$$Nest$mgetProviders", "-$$Nest$mgetOtherProviders")),
        ("no six-argument sensor constructor", lambda rel, t: t.replace("(IIILjava/util/List;IZ)V", "(IILjava/util/List;IZ)V")),
        ("a converter whose success method is gone", lambda rel, t: t.replace("onAuthenticationSucceeded(ILandroid", "onAuthenticationOk(ILandroid")),
        ("an AuthService of another shape", lambda rel, t: t.replace("if-eqz p1, :cond_0", "if-eqz p0, :cond_0")),
    ):
        tmp = tempfile.mkdtemp()
        try:
            root = os.path.join(tmp, "services")
            make_tree(root, mutate)
            before = snapshot(root)
            r = run(root)
            check(r.returncode == 0 and r.stdout == "" and "no fake fingerprint" in r.stderr and snapshot(root) == before,
                  f"{what}: left alone, exit 0, nothing printed, nothing written")
        finally:
            shutil.rmtree(tmp)


# Everything of the phone's (or of a shared daemon) the helper must never name.
FORBIDDEN = ("IFingerprint;", "android/hardware/biometrics/fingerprint/IFingerprint", "gatekeeper", "Gatekeeper",
             "weaver", "Weaver", "keystore", "KeyStore", "Keystore", "ServiceManager", "samsung", "Samsung", "sec/",
             "Ljava/io/File;", "Ljava/io/FileInputStream;", "Ljava/io/FileOutputStream;", "LocalSocket",
             "Landroid/os/Binder;->", "SystemProperties", "Runtime;->exec", "HalAidl", "getDeclaredInstances",
             "addAuthToken", "/aidl/FingerprintProvider;", "/hidl/", "Fingerprint21")


def test_helper():
    # code only: the comments say what the helper does NOT use
    # (and the log texts, and the one return type the interface forces on getServiceProviderEx,
    # whose body returns null)
    text = "\n".join(l for l in (open(HELPER).read() + open(OVERLAY).read()).split("\n")
                     if not l.lstrip().startswith(("#", "const-string"))
                     and not l.startswith(".method public getServiceProviderEx()"))
    for bad in FORBIDDEN:
        check(bad not in text, f"the helper never names {bad!r}")
    only_calls = set(re.findall(r"invoke-[a-z/]+ \{[^}]*\}, (L[^;]+;)->", text))
    allowed = ("Ljava/", "Landroid/os/Handler;", "Landroid/os/Looper;", "Landroid/util/Slog;", "Landroid/hardware/fingerprint/",
               "Lcom/android/server/biometrics/sensors/", "Lcom/android/server/biometrics/Utils;", "Landroid/hardware/biometrics/IInvalidationCallback;")
    odd = sorted(c for c in only_calls if not c.startswith(allowed))
    check(not odd, f"it only calls the framework's value and callback classes, nothing else: {odd}")
    raw = open(HELPER).read() + open(OVERLAY).read()
    methods = len(re.findall(r"^\.method ", raw, re.M))
    check(methods == len(re.findall(r"^\.end method", raw, re.M)), f"{methods} methods, balanced")
    check(not re.search(r"invoke-(?!static|[a-z]+/range)[a-z]+ \{[^}]*,[^}]*,[^}]*,[^}]*,[^}]*,[^}]*\}", text),
          "no invoke names more than five registers (those need /range)")
    for must in ("onAuthenticationSucceeded", "onUdfpsPointerDown", "showUdfpsOverlay", "hideUdfpsOverlay", "onError"):
        check(must in text, f"the helper does {must}")
    # the only thing that decides a match is a touch on the overlay
    run_body = text[text.index(".method public declared-synchronized run()V"):]
    run_body = run_body[:run_body.index(".end method")]
    check("onAuthenticationSucceeded" in run_body, "a match is answered in run(), the delayed touch")
    check(text.count("onAuthenticationSucceeded") == 1, "and nowhere else")


if __name__ == "__main__":
    test_patcher()
    test_helper()
    if failures:
        sys.exit(f"{len(failures)} failed")
    print("all ok")
