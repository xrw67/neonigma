#!/usr/bin/env python3
"""生成 Neonigma.xcodeproj/project.pbxproj(Xcode 16+ 同步文件夹式工程,XML plist 格式)。
注意:pbxproj 的 legacy unarchiver 要求所有标量均为字符串;Xcode 打开后会改写为 OpenStep 格式。"""

import plistlib

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
DEBUG = {**COMMON, "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG"}
RELEASE = {**COMMON, "ENABLE_NS_ASSERTIONS": "NO", "VALIDATE_PRODUCT": "YES"}

objects = {
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

plist = {
    "archiveVersion": "1",
    "objectVersion": "77",
    "classes": {},
    "objects": objects,
    "rootObject": A1,
}

with open("Neonigma.xcodeproj/project.pbxproj", "wb") as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_XML, sort_keys=False)

print("✓ project.pbxproj 已生成(XML plist,标量全字符串)")
