# Prebuilt executable intentionally not tracked

The uploaded integration ZIP included an x86_64 Qt desktop executable. This Git repository keeps the build reproducible from the source in `kit/brainos-qt` instead of tracking that platform-specific binary. Build with:

```bash
cmake -S kit/brainos-qt -B out/qt-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build out/qt-build --parallel
```

The binary is a glibc-linked Linux executable. It still needs the matching Qt/WebEngine runtime closure and target graphics/font/network dependencies; copying the executable alone does not make the Toybox root filesystem boot BrainOS.
