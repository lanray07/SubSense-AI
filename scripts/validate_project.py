"""Host-independent integrity checks. Not a replacement for an Apple SDK build."""
from pathlib import Path
import json
import plistlib
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
project = (root / "SubSense.xcodeproj/project.pbxproj").read_text()
for path in (root / "SubSense").rglob("*.swift"):
    assert path.relative_to(root).as_posix() in project, f"Missing Xcode reference: {path}"
for path in (root / "SubSense/Resources").rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))
for suffix in ["*.xcstrings", "*.storekit"]:
    for path in (root / "SubSense/Resources").glob(suffix):
        json.loads(path.read_text(encoding="utf-8"))
for suffix in ["*.plist", "*.xcprivacy"]:
    for path in (root / "SubSense/Resources").glob(suffix):
        plistlib.loads(path.read_bytes())
scheme = root / "SubSense.xcodeproj/xcshareddata/xcschemes/SubSense.xcscheme"
ET.parse(scheme)
assert "AppIcon.png" in (root / "SubSense/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json").read_text()
assert (root / "SubSense/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png").exists()
defined = set(re.findall(r"^([A-F0-9]{24}) =", project, re.M))
used = set(re.findall(r"\b[A-F0-9]{24}\b", project))
assert used <= defined, f"Undefined PBX identifiers: {used - defined}"
store = json.loads((root / "SubSense/Resources/SubSense.storekit").read_text())
ids = {s["productID"] for g in store["subscriptionGroups"] for s in g["subscriptions"]}
code = (root / "SubSense/Services/StoreManager.swift").read_text()
assert all(pid in code for pid in ids)
assert len(ids) == 2
for path in (root / "SubSense").rglob("*.swift"):
    text = path.read_text(encoding="utf-8")
    assert not re.search(r"\b(TODO|FIXME|fatalError)\b", text), f"Unfinished marker: {path}"
    assert not re.search(r"sk-[A-Za-z0-9_-]{20,}", text), f"Possible secret: {path}"
print(f"PASS: {len(defined)} PBX objects, all Swift source references, JSON/plist/XML resources, icon, StoreKit IDs and source hygiene.")
