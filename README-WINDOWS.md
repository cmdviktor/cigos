# Sung – Windows

Kicsomagolás után indítsd a `sung.exe`-t (nem kell telepíteni semmit: a Qt, a Python-runtime és az ffmpeg a csomagban van).

## Az .exe elkészítése (két mód)

**A) GitHub Actions (nem kell semmit telepíteni a gépedre)**
1. Töltsd fel ezt a mappát egy GitHub-repóba.
2. Actions → "Windows build" → *Run workflow*.
3. A futás végén az *Sung-Windows* artifactban ott a `Sung-Windows.zip`.

**B) Helyben**
Kell: Qt 6.8+ (MinGW kit), CMake, Ninja; a Qt `bin` és a MinGW `bin` mappa legyen a PATH-ban.
`powershell -ExecutionPolicy Bypass -File scripts\package-windows.ps1` → `dist\Sung\sung.exe`, `dist\Sung-Windows.zip`.

## Mi változott a Linuxos Sunghoz képest
- A CMake már Windowson is épít; a D-Bus/MPRIS (médiabillentyű-integráció) és az asztali értesítések Windowson nincsenek meg.
- A hangeszköz-leválasztás figyelése (pactl) és a kimeneti spektrum (parec) Linux-only, Windowson nem működik.
- A helper (YouTube Music, helyi könyvtár) a csomagolt Pythonnal és ffmpeg-gel fut, konzolablak nélkül.
- Jelszótár (secret-tool) nincs: a szerver- és scrobble-jelszavakat Windowson nem menti a program.
