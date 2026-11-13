# The guest's fake fingerprint

ColorOS guests (Find N6, Find X9 Ultra IN) get a fingerprint that is **only a picture**: the lock
screen shows ColorOS's own fingerprint icon and press animation, and a touch on it unlocks. Any
touch counts: a thumb, a pencil, a foot.

**It is not security.** Anybody who touches the icon gets in. The guest's own PIN
(`docs/guest-screen-lock.md`) still guards the first unlock after the guest starts, because ColorOS
asks for a PIN once after every boot before it accepts a fingerprint. Use the fake fingerprint for
the look and the convenience, not to keep anyone out.

## Nothing of the phone's is touched

The guest shares the phone's biometric HAL (Samsung's), gatekeeper, weaver and keystore daemon.
The fake fingerprint uses none of them:

* the guest's `FingerprintService` is given one provider, `OneOSFakeFingerprintProvider`, written in
  plain framework calls: no HAL, no gatekeeper, no weaver, no keystore, no file, no socket;
* the one code path that builds a HAL-backed provider (`FingerprintService.getProviders`) is no
  longer called, so the phone's fingerprint HAL is never opened by the guest;
* no template of One UI's is listed, added, matched or removed; the single enrolled finger exists
  only in the provider's memory;
* the property that tells ColorOS which sensor kind to draw is set for the session only, and is not
  touched at all if the phone itself defines it (`guest_props.sh`).

`scripts/test-fake-fingerprint.py` fails if the helper ever names a HAL, gatekeeper, weaver,
keystore, Samsung class, file or socket.

## What it does

| Piece | Where | What |
|---|---|---|
| Software sensor | `switcher/patches/OneOSFakeFingerprintProvider.smali` (hand-written smali; no Java source) | A `ServiceProvider` with one under-display ("optical"), strong sensor, id 0, and one enrolled finger. |
| Registration | `patches/fake_fingerprint.py`, hooks 1 to 4 | `FingerprintService` registers it instead of the HAL providers; it registers even when the phone's HAL lists no sensor; `AuthService` no longer stops at "No fingerprint sensors."; SystemUI's overlay controller is also kept by the provider. |
| Feature flag | `fake_fingerprint.py`, hook 5 | `PackageManagerService.hasSystemFeature("android.hardware.fingerprint")` is true. |
| Icon and animation | `guest_props.sh` | `persist.vendor.fingerprint.sensor_type=optical` for the session, which is what makes ColorOS's SystemUI draw its under-display fingerprint UI. The animation style is whatever the guest's Settings picked; nothing in the `SystemUIFingerprintRes_*` overlays is changed. |

A touch on the icon reaches the provider as `onPointerDown`; 200 ms later the provider answers with
a match (or "finger detected" when the lock screen only asks for detection). A cancel is answered
with `ERROR_CANCELED`, as the real client does, so the lock screen listens again. Settings' "add
fingerprint" finishes at once. Biometric prompts of apps see a strong fingerprint and get a match
without a hardware token (so nothing is ever given to keystore); a key that an app binds to a
fingerprint will therefore not work, as it does not in the rest of the guest.

## Switches and limits

* `ONEOS_GUEST_FAKE_FP=0` leaves the sensor-type property unset (the lock screen then shows no
  fingerprint UI; the software sensor is still registered but invisible).
* A framework of another shape (names, the package-private `ClientMonitorCallbackConverter`
  methods, the six-argument `FingerprintSensorPropertiesInternal` constructor) is left alone: a note on
  stderr and the image builds without the fake sensor. A tree that has it is left alone; one that has
  parts of it is an error.
* The first dex of the Find X9 Ultra IN `services.jar` is at 65535 of its 65536 method references.
  The hooks add two there, so it just fits; the 48-method helper therefore goes into the emptiest
  dex. A build that adds more to that first dex will not assemble (`Unsigned short value out of
  range`): move that other change, not this one.
* Not tested on a device by me: the patched `services.jar` was rebuilt and disassembled again from
  the real ColorOS 17 files, and the patcher and helper are covered by the test below. Boot a guest
  and read `logcat -s OneOSFakeFingerprint` once: a working run logs "software-only fingerprint
  sensor 0" at start.

Test: `python3 -I scripts/test-fake-fingerprint.py`.
