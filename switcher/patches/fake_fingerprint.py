"""A fingerprint for the guest that is only a picture: ColorOS's own icon and animation, any touch unlocks.

The container shares the phone's biometric HAL (Samsung's), gatekeeper and keystore daemon, so a
real guest fingerprint is out: guest_no_biometric_cleanup.py already keeps the guest's
FingerprintService from touching the phone's templates, and the guest has no gatekeeper token to
enrol one. This patch gives the guest's FingerprintService a sensor of its own that is software
and nothing else: OneOSFakeFingerprintProvider (hand-written smali beside this file, a
ServiceProvider like the real HAL-backed one). Nothing in it leaves the guest's system_server:
no HAL, no gatekeeper, no weaver, no keystore, no template of One UI's.

What the guest then does: the lock screen sees one under-display "strong" sensor with one enrolled
finger, SystemUI shows ColorOS's own fingerprint icon and press animation (whichever style the
guest's Settings picked), and a touch on it, by a thumb, a pencil or a foot, is a match. It is NOT
protection: anybody who touches the icon gets in. The guest's own PIN (guest_local_lock.py) still
guards the first unlock after the guest starts, as ColorOS's "strong auth after boot" asks for.

Five changes, all or none:

1. FingerprintService$1.lambda$registerAuthenticators$1: the providers list is
   OneOSFakeFingerprintProvider.providers(context) instead of FingerprintService.getProviders(
   configurations), the only place that builds a HAL-backed FingerprintProvider. The phone's
   fingerprint HAL is therefore never opened by the guest.
2. FingerprintService$1.registerAuthenticators: no longer returns when the HAL lists no sensor
   ("No fingerprint sensors available."): there is no HAL sensor here, the fake one registers.
3. FingerprintService$1.setUdfpsOverlayController: SystemUI's overlay controller is also kept in
   the provider, which may register after SystemUI handed it over.
4. AuthService.registerFingerprintSensors: no longer stops at "No fingerprint sensors." when the
   phone's HAL lists none, so FingerprintService.registerAuthenticators is called at all.
5. PackageManagerService.hasSystemFeature: "android.hardware.fingerprint" is always there. The
   lock screen, SystemServer and apps look for the feature before they look for a sensor, and
   the guest may or may not carry it from the phone's vendor feature files.

The system property ColorOS reads to pick the sensor kind (persist.vendor.fingerprint.sensor_type,
"optical") is the guest's, set for the session by guest_props.sh; it is not in this patch.

The patch needs the framework shape it was written for (ColorOS 17 on Android 17: the names above,
FingerprintSensorPropertiesInternal(IIILjava/util/List;IZ), the package-private
ClientMonitorCallbackConverter). Any other shape is left alone: a note on stderr, nothing on
stdout, exit 0, so make-overlays.sh (set -e) still builds that image without the fake sensor. A tree
that already has it is left alone the same way; one that has parts of it is an error.

Usage: fake_fingerprint.py <smali root dir> [helper smali dir]
Prints the smali_* directories (dex files) it changed, one per line.
"""
import os
import re
import shutil
import sys

PKG = os.path.join("com", "android", "server", "biometrics", "sensors")
FPS_REL = os.path.join(PKG, "fingerprint", "FingerprintService$1.smali")
AUTH_REL = os.path.join("com", "android", "server", "biometrics", "AuthService.smali")
PMS_REL = os.path.join("com", "android", "server", "pm", "PackageManagerService.smali")
CONV_REL = os.path.join(PKG, "ClientMonitorCallbackConverter.smali")
HELPERS = ("OneOSFakeFingerprintProvider.smali", "OneOSFakeFingerprintProvider$Overlay.smali")

HELPER = "Lcom/android/server/biometrics/sensors/OneOSFakeFingerprintProvider;"
MARK = "# OneOS: fake fingerprint"
FS = "Lcom/android/server/biometrics/sensors/fingerprint/FingerprintService;"


class Skip(Exception):
    """This framework has another shape: leave it alone."""


def fail(msg):
    sys.exit(f"fake_fingerprint: {msg}")


def one_dir(root, rel):
    """The one smali_* directory that holds rel."""
    hits = [d for d in sorted(os.listdir(root))
            if d.startswith("smali") and os.path.isfile(os.path.join(root, d, rel))]
    if len(hits) != 1:
        raise Skip(f"{rel} found in {len(hits)} dex directories, expected one")
    return hits[0]


def read(path):
    with open(path) as f:
        return f.read()


def method(lines, header, what):
    """(first, last) line index of the one method whose .method line ends with header."""
    heads = [i for i, l in enumerate(lines)
             if l.startswith(".method ") and l.rstrip().endswith(" " + header)]
    if len(heads) != 1:
        raise Skip(f"{what}: {header} found {len(heads)} times, expected once")
    end = next(i for i in range(heads[0], len(lines)) if lines[i].strip() == ".end method")
    return heads[0], end


def only(lines, first, last, pred, what):
    hits = [i for i in range(first, last) if pred(lines[i].strip())]
    if len(hits) != 1:
        raise Skip(f"{what}: expected one match, found {len(hits)}")
    return hits[0]


def next_code(lines, i, last):
    """Index of the next instruction after i (skips blanks, comments, directives)."""
    j = i + 1
    while j < last and (not lines[j].strip() or lines[j].strip().startswith((".line", "#", ".local", ".end local"))):
        j += 1
    return j


def patch_fps(lines):
    # 1. the providers list
    f, l = method(lines, "lambda$registerAuthenticators$1(Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)Ljava/util/List;",
                  "FingerprintService$1")
    i = only(lines, f, l, lambda s: s == f"invoke-static {{v0, p1}}, {FS}->-$$Nest$mgetProviders(" +
             f"{FS}Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)Ljava/util/List;",
             "the getProviders call")
    j = next_code(lines, i, l)
    if lines[j].strip() != "move-result-object v0":
        raise Skip("the getProviders call is not followed by move-result-object v0")
    lines[i:i + 1] = [
        f"    {MARK}: the guest's only provider is the software one; the HAL is never opened",
        f"    invoke-virtual {{v0}}, {FS}->getContext()Landroid/content/Context;",
        "",
        "    move-result-object v0",
        "",
        f"    invoke-static {{v0}}, {HELPER}->providers(Landroid/content/Context;)Ljava/util/List;",
    ]
    # 2. registerAuthenticators registers even when the HAL lists no sensor
    f, l = method(lines, "registerAuthenticators(Landroid/hardware/fingerprint/FingerprintSensorConfigurations;)V",
                  "FingerprintService$1")
    i = only(lines, f, l, lambda s: s == "invoke-virtual {p1}, Landroid/hardware/fingerprint/FingerprintSensorConfigurations;->hasSensorConfigurations()Z",
             "hasSensorConfigurations")
    j = next_code(lines, i, l)
    if lines[j].strip() != "move-result v0":
        raise Skip("hasSensorConfigurations() is not followed by move-result v0")
    lines[j + 1:j + 1] = ["", f"    {MARK}: there is no HAL sensor here, the software one registers", "    const/4 v0, 0x1"]
    # 3. SystemUI's overlay controller is kept by the provider
    f, l = method(lines, "setUdfpsOverlayController(Landroid/hardware/fingerprint/IUdfpsOverlayController;)V",
                  "FingerprintService$1")
    i = only(lines, f, l, lambda s: s.startswith("invoke-super {p0}, Landroid/hardware/fingerprint/IFingerprintService$Stub;->setUdfpsOverlayController_enforcePermission()V"),
             "the permission check")
    lines[i + 1:i + 1] = ["", f"    {MARK}", f"    invoke-static {{p1}}, {HELPER}->rememberOverlay(Landroid/hardware/fingerprint/IUdfpsOverlayController;)V"]
    return lines


def patch_auth(lines):
    f, l = method(lines, "registerFingerprintSensors([Ljava/lang/String;[Ljava/lang/String;Landroid/content/Context;"
                  "Landroid/hardware/fingerprint/IFingerprintService;Lcom/android/server/biometrics/BiometricHandlerProvider;)V",
                  "AuthService")
    m = re.match(r"\s*\.locals (\d+)$", lines[f + 1])
    if not m or int(m.group(1)) < 2:
        raise Skip("AuthService.registerFingerprintSensors has an unexpected header")
    c = only(lines, f, l, lambda s: s == 'const-string v0, "AuthService"', "the TAG constant")
    j = next_code(lines, c, l)
    if lines[j].strip() != "if-eqz p1, :cond_0":
        raise Skip("registerFingerprintSensors does not start with its sensor checks")
    # the processing path is the one :cond_1 label, right before the DEBUG_FINGER read
    lab = only(lines, f, l, lambda s: s == ":cond_1", ":cond_1")
    k = next_code(lines, lab, l)
    if "AuthService;->DEBUG_FINGER:Z" not in lines[k]:
        raise Skip(":cond_1 is not the start of the registration")
    # always taken, but a conditional, so the checks above stay reachable for the verifier
    lines[c + 1:c + 1] = ["", f"    {MARK}: register the software sensor although the HAL lists none",
                          "    const/4 v1, 0x1", "", "    if-nez v1, :cond_1"]
    return lines


def patch_pms(lines):
    f, l = method(lines, "hasSystemFeature(Ljava/lang/String;I)Z", "PackageManagerService")
    m = re.match(r"\s*\.locals (\d+)$", lines[f + 1])
    if not m or int(m.group(1)) < 4:
        raise Skip("PackageManagerService.hasSystemFeature has an unexpected header")
    g = only(lines, f, l, lambda s: s == "invoke-virtual {v0, p1}, Landroid/util/ArrayMap;->get(Ljava/lang/Object;)Ljava/lang/Object;",
             "the feature lookup")
    # v0 = FeatureInfo, v2 = false; then: if-nez v0, :cond_1 / return v2
    i = next_code(lines, g, l)
    while lines[i].strip() != "if-nez v0, :cond_1":
        i = next_code(lines, i, l)
        if i >= l:
            raise Skip("no 'if-nez v0, :cond_1' after the feature lookup")
    r = next_code(lines, i, l)
    if lines[r].strip() != "return v2":
        raise Skip("the missing-feature path does not return v2")
    # v2 is false here (const/4 v2, 0x0 before the check); a missing fingerprint feature is a present one
    if not any(lines[x].strip() == "const/4 v2, 0x0" for x in range(g, i)):
        raise Skip("v2 is not the false constant")
    lines[r:r] = [
        f"    {MARK}: the guest always has the fingerprint feature",
        '    const-string v3, "android.hardware.fingerprint"',
        "",
        "    invoke-virtual {v3, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z",
        "",
        "    move-result v3",
        "",
        "    if-eqz v3, :oneos_fp_missing",
        "",
        "    const/4 v2, 0x1",
        "",
        "    return v2",
        "",
        "    :oneos_fp_missing",
    ]
    return lines


SENSOR_CTOR = "FingerprintSensorPropertiesInternal;-><init>(IIILjava/util/List;IZ)V"


def uses_sensor_ctor(root):
    """Does any biometrics class of this tree call the six-argument sensor constructor?"""
    for d in sorted(os.listdir(root)):
        base = os.path.join(root, d, "com", "android", "server", "biometrics")
        for dirpath, _, files in os.walk(base):
            for f in files:
                if f.endswith(".smali") and SENSOR_CTOR in read(os.path.join(dirpath, f)):
                    return True
    return False


def emptiest_dex(root):
    """The dex directory with the fewest classes. A dex holds 65536 methods and the first ones
    are full: the helper (about 50 methods and their references) goes to the one with room.
    The hooks only add two method references to the dex they sit in."""
    dexes = [d for d in sorted(os.listdir(root)) if d.startswith("smali")]

    def size(d):
        return sum(len(files) for _, _, files in os.walk(os.path.join(root, d)))
    return min(dexes, key=size)


def main(root, helper_dir):
    for h in HELPERS:
        if not os.path.isfile(os.path.join(helper_dir, h)):
            fail(f"no helper smali at {os.path.join(helper_dir, h)}")
    try:
        dirs = {rel: one_dir(root, rel) for rel in (FPS_REL, AUTH_REL, PMS_REL, CONV_REL)}
        paths = {rel: os.path.join(root, dirs[rel], rel) for rel in dirs}
        text = {rel: read(paths[rel]) for rel in (FPS_REL, AUTH_REL, PMS_REL)}
        helper_dex = emptiest_dex(root)
        out_dir = os.path.join(root, helper_dex, PKG)
        have = [MARK in text[rel] for rel in (FPS_REL, AUTH_REL, PMS_REL)]
        have += [any(os.path.isfile(os.path.join(root, d, PKG, h)) for d in os.listdir(root)
                     if d.startswith("smali")) for h in HELPERS]
        if all(have):
            print("fake_fingerprint: this services.jar already has the fake fingerprint", file=sys.stderr)
            return
        if any(have):
            fail("parts of the fake fingerprint are already in this tree")
        # the helper calls package-private methods of the converter, and builds a
        # sensor with the six-argument constructor: this framework must have both
        conv = read(paths[CONV_REL])
        for sig in (r"^\.method onAuthenticationSucceeded\(ILandroid/hardware/biometrics/BiometricAuthenticator\$Identifier;\[BIZ\)V$",
                    r"^\.method public onUdfpsPointerDown\(I\)V$", r"^\.method public onDetected\(IIZ\)V$",
                    r"^\.method public onError\(IIII\)V$"):
            if not re.search(sig, conv, re.M):
                raise Skip(f"ClientMonitorCallbackConverter has no {sig[9:40]}...")
        if not uses_sensor_ctor(root):
            raise Skip("no FingerprintSensorPropertiesInternal(IIILjava/util/List;IZ) constructor in use")
        new = {
            FPS_REL: patch_fps(text[FPS_REL].split("\n")),
            AUTH_REL: patch_auth(text[AUTH_REL].split("\n")),
            PMS_REL: patch_pms(text[PMS_REL].split("\n")),
        }
    except Skip as why:
        print(f"fake_fingerprint: {why}; this framework gets no fake fingerprint", file=sys.stderr)
        return

    for rel, lines in new.items():
        with open(paths[rel], "w") as f:
            f.write("\n".join(lines))
    os.makedirs(out_dir, exist_ok=True)
    for h in HELPERS:
        shutil.copy(os.path.join(helper_dir, h), os.path.join(out_dir, h))
    print("fake_fingerprint: FingerprintService providers, registration and overlay controller; "
          "AuthService sensor check; PackageManagerService fingerprint feature; "
          "OneOSFakeFingerprintProvider", file=sys.stderr)
    for d in sorted({dirs[FPS_REL], dirs[AUTH_REL], dirs[PMS_REL], helper_dex}):
        print(d)


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__.strip().split("\n")[-2])
    main(sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else os.path.dirname(os.path.abspath(__file__)))
