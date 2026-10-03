#!/usr/bin/env python3
"""生成 Neonigma.xcodeproj/project.pbxproj(Xcode 27 同步文件夹式工程,XML plist 格式)。
注意:pbxproj 的 legacy unarchiver 要求所有标量均为字符串;Xcode 打开后会改写为 OpenStep 格式。"""

import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Neonigma.xcodeproj"
PROJECT.mkdir(parents=True, exist_ok=True)

A1 = "0000000000000000000000A1"  # PBXProject
A2 = "0000000000000000000000A2"  # mainGroup
A3 = "0000000000000000000000A3"  # Products group
A4 = "0000000000000000000000A4"  # Neonigma.app product
A5 = "0000000000000000000000A5"  # 同步根组 Neonigma/
A6 = "0000000000000000000000A6"  # Frameworks phase
A7 = "0000000000000000000000A7"  # Sources phase
A8 = "0000000000000000000000A8"  # Resources phase
A9 = "0000000000000000000000A9"  # Native target
AA = "0000000000000000000000AA"  # target config list
AB = "0000000000000000000000AB"  # project config list
AC = "0000000000000000000000AC"  # target Debug
AD = "0000000000000000000000AD"  # target Release
AE = "0000000000000000000000AE"  # project Debug
AF = "0000000000000000000000AF"  # project Release
B0 = "0000000000000000000000B0"  # Core build file
B1 = "0000000000000000000000B1"  # Core product dependency
B2 = "0000000000000000000000B2"  # Core local package ref

COMMON = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "霓虹密码机",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations~ipad":
        "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
    "MARKETING_VERSION": "0.1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.xrw67.neonigma",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SDKROOT": "iphoneos",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SUPPORTS_MACCATALYST": "NO",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
}
DEBUG = {**COMMON, "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG", "ONLY_ACTIVE_ARCH": "YES", "ENABLE_TESTABILITY": "YES", "SWIFT_OPTIMIZATION_LEVEL": "-Onone"}
RELEASE = {**COMMON, "ENABLE_NS_ASSERTIONS": "NO", "VALIDATE_PRODUCT": "YES", "ONLY_ACTIVE_ARCH": "NO"}

objects = {
    A4: {"isa": "PBXFileReference", "explicitFileType": "wrapper.application",
         "includeInIndex": "0", "path": "Neonigma.app", "sourceTree": "BUILT_PRODUCTS_DIR"},
    B0: {"isa": "PBXBuildFile", "productRef": B1},
    A5: {"isa": "PBXFileSystemSynchronizedRootGroup", "path": "Neonigma", "sourceTree": "<group>"},
    A6: {"isa": "PBXFrameworksBuildPhase", "buildActionMask": "2147483647",
         "files": [B0], "runOnlyForDeploymentPostprocessing": "0"},
    A2: {"isa": "PBXGroup", "children": [A5, A3], "sourceTree": "<group>"},
    A3: {"isa": "PBXGroup", "children": [A4], "name": "Products", "sourceTree": "<group>"},
    B2: {"isa": "XCLocalSwiftPackageReference", "relativePath": "Core"},
    A9: {"isa": "PBXNativeTarget",
         "buildConfigurationList": AA,
         "buildPhases": [A7, A6, A8],
         "buildRules": [],
         "dependencies": [],
         "fileSystemSynchronizedGroups": [A5],
         "name": "Neonigma",
         "packageProductDependencies": [B1],
         "productName": "Neonigma",
         "productReference": A4,
         "productType": "com.apple.product-type.application"},
    A1: {"isa": "PBXProject",
         "attributes": {"BuildIndependentTargetsInParallel": "1",
                        "LastSwiftUpdateCheck": "2700", "LastUpgradeCheck": "2700"},
         "buildConfigurationList": AB,
         "developmentRegion": "zh-Hans",
         "hasScannedForEncodings": "0",
         "knownRegions": ["zh-Hans", "en", "Base"],
         "mainGroup": A2,
         "minimizedProjectReferenceProxies": "1",
         "packageReferences": [B2],
         "preferredProjectObjectVersion": "77",
         "productRefGroup": A3,
         "projectDirPath": "",
         "projectRoot": "",
         "targets": [A9]},
    A8: {"isa": "PBXResourcesBuildPhase", "buildActionMask": "2147483647",
         "files": [], "runOnlyForDeploymentPostprocessing": "0"},
    A7: {"isa": "PBXSourcesBuildPhase", "buildActionMask": "2147483647",
         "files": [], "runOnlyForDeploymentPostprocessing": "0"},
    AC: {"isa": "XCBuildConfiguration", "buildSettings": DEBUG, "name": "Debug"},
    AD: {"isa": "XCBuildConfiguration", "buildSettings": RELEASE, "name": "Release"},
    AE: {"isa": "XCBuildConfiguration", "buildSettings": {}, "name": "Debug"},
    AF: {"isa": "XCBuildConfiguration", "buildSettings": {}, "name": "Release"},
    AA: {"isa": "XCConfigurationList", "buildConfigurations": [AC, AD],
         "defaultConfigurationIsVisible": "0", "defaultConfigurationName": "Release"},
    AB: {"isa": "XCConfigurationList", "buildConfigurations": [AE, AF],
         "defaultConfigurationIsVisible": "0", "defaultConfigurationName": "Release"},
    B1: {"isa": "XCSwiftPackageProductDependency", "package": B2, "productName": "Core"},
}

# App 测试使用宿主,UI 测试通过独立进程控制应用;同步文件夹不混入 App。
TEST_TARGETS = []
for index, (name, kind) in enumerate([("NeonigmaTests", "unit-test"), ("NeonigmaUITests", "ui-testing")]):
    base = 0xC0 + index * 0x20
    ids = [f"{base + n:024X}" for n in range(12)]
    target, group, product, sources, frameworks, config_list, debug, release, proxy, dependency, package, build = ids
    objects[group] = {"isa": "PBXFileSystemSynchronizedRootGroup", "path": name, "sourceTree": "<group>"}
    objects[product] = {"isa": "PBXFileReference", "explicitFileType": "wrapper.cfbundle", "path": name + ".xctest", "sourceTree": "BUILT_PRODUCTS_DIR"}
    objects[sources] = {"isa": "PBXSourcesBuildPhase", "buildActionMask": "2147483647", "files": [], "runOnlyForDeploymentPostprocessing": "0"}
    objects[frameworks] = {"isa": "PBXFrameworksBuildPhase", "buildActionMask": "2147483647", "files": [build], "runOnlyForDeploymentPostprocessing": "0"}
    objects[package] = {"isa": "XCSwiftPackageProductDependency", "package": B2, "productName": "Core"}
    objects[build] = {"isa": "PBXBuildFile", "productRef": package}
    objects[proxy] = {"isa": "PBXContainerItemProxy", "containerPortal": A1, "proxyType": "1", "remoteGlobalIDString": A9, "remoteInfo": "Neonigma"}
    objects[dependency] = {"isa": "PBXTargetDependency", "target": A9, "targetProxy": proxy}
    for config, label in [(debug, "Debug"), (release, "Release")]:
        settings = {**COMMON, "PRODUCT_NAME": name, "PRODUCT_BUNDLE_IDENTIFIER": "com.xrw67." + name,
                    "SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated", "ENABLE_TESTABILITY": "YES", "ONLY_ACTIVE_ARCH": "YES", "SWIFT_OPTIMIZATION_LEVEL": "-Onone", "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if label == "Debug" else ""}
        settings.pop("ASSETCATALOG_COMPILER_APPICON_NAME", None)
        if kind == "unit-test":
            settings.update({"TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Neonigma.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Neonigma", "BUNDLE_LOADER": "$(TEST_HOST)"})
        else:
            settings["TEST_TARGET_NAME"] = "Neonigma"
        objects[config] = {"isa": "XCBuildConfiguration", "buildSettings": settings, "name": label}
    objects[config_list] = {"isa": "XCConfigurationList", "buildConfigurations": [debug, release], "defaultConfigurationIsVisible": "0", "defaultConfigurationName": "Release"}
    objects[target] = {"isa": "PBXNativeTarget", "name": name, "productName": name, "productType": "com.apple.product-type.bundle." + kind,
                       "productReference": product, "buildConfigurationList": config_list, "buildPhases": [sources, frameworks], "buildRules": [],
                       "dependencies": [dependency], "fileSystemSynchronizedGroups": [group], "packageProductDependencies": [package]}
    objects[A1]["targets"].append(target)
    objects[A2]["children"].append(group)
    objects[A3]["children"].append(product)
    TEST_TARGETS.append((target, name))

plist = {
    "archiveVersion": "1",
    "objectVersion": "77",
    "classes": {},
    "objects": objects,
    "rootObject": A1,
}

with open(PROJECT / "project.pbxproj", "wb") as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_XML, sort_keys=False)

# ---------- 共享 Scheme(保证 ⌘R 的 Run 动作存在且指向 App target) ----------
import os

SCHEME = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2700"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{A9}"
               BuildableName = "Neonigma.app"
               BlueprintName = "Neonigma"
               ReferencedContainer = "container:Neonigma.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.Debugger"
      selectedLauncherIdentifier = "Xcode.Debugger"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.Debugger"
      selectedLauncherIdentifier = "Xcode.Debugger"
      launchStyle = "0"
      askForAppToLaunch = "NO"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      runUnitTestsAfterAppLaunch = "NO">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{A9}"
            BuildableName = "Neonigma.app"
            BlueprintName = "Neonigma"
            ReferencedContainer = "container:Neonigma.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{A9}"
            BuildableName = "Neonigma.app"
            BlueprintName = "Neonigma"
            ReferencedContainer = "container:Neonigma.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

testables = "\n".join(f'''        <TestableReference skipped="NO">
          <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{name}.xctest" BlueprintName="{name}" ReferencedContainer="container:Neonigma.xcodeproj" />
        </TestableReference>''' for target, name in TEST_TARGETS)
SCHEME = SCHEME.replace("      <Testables>\n", "      <Testables>\n" + testables + "\n")

scheme_dir = PROJECT / "xcshareddata/xcschemes"
os.makedirs(scheme_dir, exist_ok=True)
with open(os.path.join(scheme_dir, "Neonigma.xcscheme"), "w") as f:
    f.write(SCHEME)

print("✓ project.pbxproj 已生成(XML plist,标量全字符串)")
print("✓ 共享 Scheme 已生成(Neonigma.xcscheme)")
