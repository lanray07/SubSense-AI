"""Create reproducible vector-derived icon assets, string catalog and local StoreKit fixture."""
from pathlib import Path
import json
import math
import re
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
resources = ROOT / "SubSense" / "Resources"
assets = resources / "Assets.xcassets"
icon = assets / "AppIcon.appiconset"
icon.mkdir(parents=True, exist_ok=True)
(assets / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
(icon / "Contents.json").write_text(json.dumps({"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, indent=2))
# Simple, code-native brand geometry. No generated artwork or third-party logos.
size = 2048
image = Image.new("RGB", (size, size), "#192E26")
draw = ImageDraw.Draw(image)
box = (440, 440, 1608, 1608)
draw.arc(box, start=26, end=325, fill="#CDE8AE", width=124)
angle = math.radians(26)
tip = (1024 + 584 * math.cos(angle), 1024 + 584 * math.sin(angle))
draw.polygon([(tip[0]-183, tip[1]-26), (tip[0]+99, tip[1]-139), (tip[0]+83, tip[1]+168)], fill="#CDE8AE")
draw.polygon([(1050, 715), (1120, 939), (1344, 1009), (1120, 1079), (1050, 1303), (980, 1079), (756, 1009), (980, 939)], fill="#F7F8EF")
image.resize((1024, 1024), Image.Resampling.LANCZOS).save(icon / "AppIcon.png")
svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#192e26"/><path d="M 750 345 A 292 292 0 1 0 774 640" fill="none" stroke="#cde8ae" stroke-width="62" stroke-linecap="round"/><path d="M700 635 L829 577 L818 730Z" fill="#cde8ae"/><path d="M525 357L560 470L672 505L560 540L525 652L490 540L378 505L490 470Z" fill="#f7f8ef"/></svg>'''
(resources / "AppIcon-concept.svg").write_text(svg)
# Catalog initial static English strings. Xcode extracts additional interpolated keys on Apple builds.
keys = set()
for path in (ROOT / "SubSense").rglob("*.swift"):
    for match in re.finditer(r'(?:Text|Button|Label|Section|navigationTitle|accessibilityLabel)\(\s*"((?:[^"\\]|\\.)*)"', path.read_text(encoding="utf-8")):
        value = match.group(1)
        if "\\(" not in value:
            keys.add(value.replace("\\n", "\n").replace('\\"', '"'))
catalog = {"sourceLanguage": "en", "strings": {key: {"localizations": {"en": {"stringUnit": {"state": "translated", "value": key}}}} for key in sorted(keys)}, "version": "1.0"}
(resources / "Localizable.xcstrings").write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
storekit = {
    "identifier": "867420D0-351C-477D-A68B-F2D6BDB923FE",
    "nonRenewingSubscriptions": [], "products": [],
    "settings": {"_applicationInternalID": "", "_developerTeamID": "", "_failTransactionsEnabled": False, "_locale": "en_GB", "_storefront": "GBR", "_storeKitErrors": []},
    "subscriptionGroups": [{"id": "21110101", "localizations": [{"description": "Premium subscription clarity", "displayName": "SubSense Pro", "locale": "en_GB"}], "name": "SubSense Pro", "subscriptions": []}],
    "version": {"major": 3, "minor": 0}
}
for name, price, period, pid, internal in [("Pro Monthly", "4.99", "P1M", "com.subsense.pro.monthly", "21110102"), ("Pro Annual", "34.99", "P1Y", "com.subsense.pro.annual", "21110103")]:
    storekit["subscriptionGroups"][0]["subscriptions"].append({
        "adHocOffers": [], "codeOffers": [], "displayPrice": price, "familyShareable": False, "groupNumber": 1,
        "internalID": internal, "introductoryOffer": None,
        "localizations": [{"description": "Unlimited subscriptions and savings insights", "displayName": name, "locale": "en_GB"}],
        "productID": pid, "recurringSubscriptionPeriod": period, "referenceName": name,
        "subscriptionGroupID": "21110101", "type": "RecurringSubscription", "winBackOffers": []
    })
(resources / "SubSense.storekit").write_text(json.dumps(storekit, indent=2), encoding="utf-8")
print(f"Generated 1024px RGB app icon, {len(keys)} English catalog entries and two local StoreKit products.")
