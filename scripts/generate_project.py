"""Generate a dependency-free Xcode project. Run from any host with Python 3."""
from pathlib import Path
import hashlib
import json
import plistlib
import re

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SubSense.xcodeproj"
PROJECT.mkdir(exist_ok=True)

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

objects = {}
def obj(name, value):
    key = uid(name)
    objects[key] = value
    return key

def quoted(text):
    return '"' + str(text).replace('\\', '\\\\').replace('"', '\\"') + '"'

def array(values):
    return "(" + ", ".join(values) + ")"

def config_list(name, settings):
    configs = []
    for mode in ["Debug", "Release"]:
        merged = dict(settings)
        merged["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone" if mode == "Debug" else "-O"
        if mode == "Debug":
            merged["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
            merged["ENABLE_TESTABILITY"] = "YES"
        body = " ".join(f"{k} = {quoted(v)};" for k, v in merged.items())
        configs.append(obj(name + mode, f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {mode};'))
    return obj(name + "ConfigList", f'isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

def file_ref(path, kind):
    return obj("file:" + path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quoted(path)}; sourceTree = SOURCE_ROOT;')

source_paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "SubSense").rglob("*.swift"))
test_paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "SubSenseUITests").glob("*.swift"))
refs = []
def build_sources(paths, target):
    buildfiles = []
    for path in paths:
        ref = file_ref(path, "sourcecode.swift"); refs.append(ref)
        buildfiles.append(obj("build:" + path, f'isa = PBXBuildFile; fileRef = {ref};'))
    return obj(target + "Sources", f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(buildfiles)}; runOnlyForDeploymentPostprocessing = 0;')

app_sources = build_sources(source_paths, "App")
test_sources = build_sources(test_paths, "UITests")
resource_files = []
for path, kind in [("SubSense/Resources/Assets.xcassets", "folder.assetcatalog"), ("SubSense/Resources/Localizable.xcstrings", "text.json.xcstrings"), ("SubSense/Resources/PrivacyInfo.xcprivacy", "text.xml")]:
    ref = file_ref(path, kind); refs.append(ref)
    resource_files.append(obj("build:" + path, f'isa = PBXBuildFile; fileRef = {ref};'))
resources = obj("Resources", f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(resource_files)}; runOnlyForDeploymentPostprocessing = 0;')
refs.append(file_ref("SubSense/Resources/SubSense.storekit", "text"))
package = obj("LocalPackage", 'isa = XCLocalSwiftPackageReference; relativePath = .;')
package_product = obj("CoreProduct", f'isa = XCSwiftPackageProductDependency; package = {package}; productName = SubSenseCore;')
package_build = obj("CoreBuild", f'isa = PBXBuildFile; productRef = {package_product};')
frameworks = obj("Frameworks", f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({package_build}); runOnlyForDeploymentPostprocessing = 0;')
empty_frameworks = obj("TestFrameworks", 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
app_product = obj("AppProduct", 'isa = PBXFileReference; explicitFileType = wrapper.application; path = SubSense.app; sourceTree = BUILT_PRODUCTS_DIR;')
test_product = obj("UITestProduct", 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = SubSenseUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
products = obj("Products", f'isa = PBXGroup; children = ({app_product}, {test_product}); name = Products; sourceTree = "<group>";')
main_group = obj("MainGroup", f'isa = PBXGroup; children = {array(refs + [products])}; sourceTree = "<group>";')
base = {"SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "SWIFT_VERSION": "5.0", "CLANG_ENABLE_MODULES": "YES", "CODE_SIGN_STYLE": "Automatic", "TARGETED_DEVICE_FAMILY": "1,2", "SUPPORTS_MACCATALYST": "NO", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "GENERATE_INFOPLIST_FILE": "YES"}
app_settings = dict(base, PRODUCT_BUNDLE_IDENTIFIER="com.subsenseai.app", PRODUCT_NAME="SubSense", MARKETING_VERSION="1.0", CURRENT_PROJECT_VERSION="1", INFOPLIST_FILE="SubSense/Resources/Info.plist", ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon", INFOPLIST_KEY_UILaunchScreen_Generation="YES", INFOPLIST_KEY_UIApplicationSceneManifest_Generation="YES", SWIFT_EMIT_LOC_STRINGS="YES", LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/Frameworks")
app_config = config_list("App", app_settings)
test_config = config_list("UITests", dict(base, PRODUCT_BUNDLE_IDENTIFIER="com.subsenseai.app.uitests", PRODUCT_NAME="SubSenseUITests", TEST_TARGET_NAME="SubSense", LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/Frameworks @loader_path/Frameworks"))
project_config = config_list("Project", {"CLANG_ENABLE_MODULES": "YES", "IPHONEOS_DEPLOYMENT_TARGET": "17.0"})
app = obj("AppTarget", f'isa = PBXNativeTarget; buildConfigurationList = {app_config}; buildPhases = ({app_sources}, {frameworks}, {resources}); buildRules = (); dependencies = (); name = SubSense; packageProductDependencies = ({package_product}); productName = SubSense; productReference = {app_product}; productType = "com.apple.product-type.application";')
proxy = obj("Proxy", f'isa = PBXContainerItemProxy; containerPortal = {uid("Project")}; proxyType = 1; remoteGlobalIDString = {app}; remoteInfo = SubSense;')
dependency = obj("TestDependency", f'isa = PBXTargetDependency; target = {app}; targetProxy = {proxy};')
test = obj("TestTarget", f'isa = PBXNativeTarget; buildConfigurationList = {test_config}; buildPhases = ({test_sources}, {empty_frameworks}); buildRules = (); dependencies = ({dependency}); name = SubSenseUITests; productName = SubSenseUITests; productReference = {test_product}; productType = "com.apple.product-type.bundle.ui-testing";')
project = obj("Project", f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {project_config}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main_group}; packageReferences = ({package}); productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({app}, {test});')
content = '// !$*UTF8*$!\n{\narchiveVersion = 1; classes = {}; objectVersion = 56;\nobjects = {\n'
content += '\n'.join(f'{key} = {{ {value} }};' for key, value in objects.items())
content += f'\n}}; rootObject = {project};\n}}\n'
(PROJECT / "project.pbxproj").write_text(content, encoding="utf-8")
scheme_path = PROJECT / "xcshareddata" / "xcschemes"
scheme_path.mkdir(parents=True, exist_ok=True)
build_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app}" BuildableName="SubSense.app" BlueprintName="SubSense" ReferencedContainer="container:SubSense.xcodeproj"/>'
test_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test}" BuildableName="SubSenseUITests.xctest" BlueprintName="SubSenseUITests" ReferencedContainer="container:SubSense.xcodeproj"/>'
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{build_ref}</BuildActionEntry></BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref}</BuildableProductRunnable><StoreKitConfigurationFileReference identifier="../../SubSense/Resources/SubSense.storekit"/></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(scheme_path / "SubSense.xcscheme").write_text(scheme, encoding="utf-8")
print(f"Generated Xcode project: {len(source_paths)} app Swift files, {len(test_paths)} UI test files.")
