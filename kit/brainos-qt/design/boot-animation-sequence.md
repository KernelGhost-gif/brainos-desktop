# BrainOS boot logo animation

The boot sequence is implemented in `qml/components/BootSplash.qml` and uses the provided BrainOS mark.

1. **0–540 ms — ambient field:** black background and a restrained violet glow establish depth.
2. **540–1080 ms — mark arrival:** the compact logo fades and scales in with a soft `OutBack` settle.
3. **1080–1620 ms — system message:** `Preparing BrainOS` fades in below the mark.
4. **1620 ms onward — progress pulse:** three small dots pulse asynchronously without percentages.
5. **Desktop ready — handoff:** the splash fades out over 480 ms while the desktop fades in underneath.

The sequence avoids a giant logo, mascot animation, numeric progress, and abrupt scene changes.
