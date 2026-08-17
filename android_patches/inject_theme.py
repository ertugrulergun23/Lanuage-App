"""
inject_theme.py  —  called by CI (.github/workflows/build.yml)
──────────────────────────────────────────────────────────────
Injects Theme.TranslatePopup into the flutter-generated styles.xml without
overwriting the LaunchTheme and NormalTheme that `flutter create` produces.

Usage:
    python3 android_patches/inject_theme.py

The script is idempotent: if Theme.TranslatePopup is already present it exits
without modifying the file.
"""

import sys
import os

STYLES_PATH = "android/app/src/main/res/values/styles.xml"

STYLE_BLOCK = """\
    <!-- Theme.TranslatePopup: injected by CI for ACTION_PROCESS_TEXT popup.
         Parent is a pure Android platform theme — no AppCompat dependency.
         windowIsFloating=true makes Android size the window like a dialog;
         TranslatePopupActivity.onStart() then calls window.setLayout(
         MATCH_PARENT, WRAP_CONTENT) so Flutter gets a proper width constraint. -->
    <style name="Theme.TranslatePopup" parent="@android:style/Theme.Translucent.NoTitleBar">
        <item name="android:windowIsFloating">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:backgroundDimEnabled">true</item>
        <item name="android:backgroundDimAmount">0.5</item>
        <item name="android:windowAnimationStyle">@android:style/Animation.Dialog</item>
        <item name="android:windowMinWidthMajor">0%</item>
        <item name="android:windowMinWidthMinor">0%</item>
    </style>
"""


def main():
    if not os.path.exists(STYLES_PATH):
        print(f"ERROR: {STYLES_PATH} not found. Run `flutter create` first.", file=sys.stderr)
        sys.exit(1)

    content = open(STYLES_PATH, encoding="utf-8").read()

    if "Theme.TranslatePopup" in content:
        print("Theme.TranslatePopup already present — skipping injection.")
        return

    if "</resources>" not in content:
        print(f"ERROR: </resources> tag not found in {STYLES_PATH}.", file=sys.stderr)
        sys.exit(1)

    # Insert the style block immediately before the closing </resources> tag
    updated = content.replace("</resources>", STYLE_BLOCK + "\n</resources>", 1)
    open(STYLES_PATH, "w", encoding="utf-8").write(updated)
    print("Theme.TranslatePopup injected into styles.xml successfully.")


if __name__ == "__main__":
    main()
