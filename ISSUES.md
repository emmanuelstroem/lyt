# Lyt App - Issues & Fixes Tracker

This document tracks build issues, platform compatibility problems, and their resolutions during development.

---

## 🐛 **Current Issues**

*No current issues - all platforms building successfully!*

---

## ✅ **Resolved Issues**

### ✅ **Issue #1: tvOS Navigation Bar Compatibility** 
**Date**: 2025-01-24  
**Platform**: tvOS  
**Status**: ✅ **RESOLVED**

**Problem**: 
Build failing for tvOS with error:
```
'navigationBarTitleDisplayMode' is unavailable in tvOS
```

**Root Cause**: 
SwiftUI's `.navigationBarTitleDisplayMode(.large)` is iOS-only API, not available on macOS or tvOS.

**Previous Fix Attempt**: 
Used `#if !os(macOS)` but this still includes tvOS which doesn't support the API.

**Final Fix**: 
Changed to `#if os(iOS)` to make it iOS-specific:
```swift
#if os(iOS)
.navigationBarTitleDisplayMode(.large)
#endif
```

**Verification**: ✅ tvOS builds successfully with comprehensive test script

---

### ✅ **Issue #2: macOS Navigation Bar Compatibility**
**Date**: 2025-01-24  
**Platform**: macOS  
**Status**: ✅ **RESOLVED**

**Problem**: 
Build failing for macOS with same `navigationBarTitleDisplayMode` error.

**Fix**: 
Initially excluded macOS with `#if !os(macOS)`, now refined to iOS-only.

**Verification**: ✅ macOS builds successfully

---

### ✅ **Issue #3: Platform-Specific Color System**
**Date**: 2025-01-24  
**Platform**: iOS, macOS, tvOS  
**Status**: ✅ **RESOLVED**

**Problem**: 
SwiftUI system colors not available across all platforms (e.g., `Color(.systemBackground)` not on macOS).

**Fix**: 
Implemented comprehensive platform-specific color system:
```swift
private var backgroundColor: Color {
    #if os(macOS)
    Color(NSColor.controlBackgroundColor)
    #elseif os(tvOS)
    Color.black
    #else // iOS
    Color(.systemBackground)
    #endif
}
```

**Verification**: ✅ All platforms build and display correctly

---

### ✅ **Issue #4: Missing Combine Import**
**Date**: 2025-01-24  
**Platform**: All  
**Status**: ✅ **RESOLVED**

**Problem**: 
Compilation errors due to missing `import Combine` for `ObservableObject` usage.

**Fix**: 
Added `import Combine` to relevant files:
- `lyt/Models/DRModels.swift`
- `lyt/Services/DRNetworkService.swift`

**Verification**: ✅ All builds successful

---

### ✅ **Issue #5: iOS Font API Compatibility**
**Date**: 2025-01-24  
**Platform**: iOS  
**Status**: ✅ **RESOLVED**

**Problem**: 
SwiftUI font API `.font(.system(.subheadline, design: .rounded, weight: .medium))` only available in iOS 16.0+, but project targeted iOS 15.6.

**Fix**: 
Changed to compatible API:
```swift
.font(.subheadline.weight(.medium))
```

**Verification**: ✅ iOS 15.6+ compatibility maintained

---

### ✅ **Issue #6: macOS Code Signing & dyld Team ID Mismatch**
**Date**: 2025-01-24  
**Platform**: macOS  
**Status**: ✅ **RESOLVED**

**Problem**: 
Complex issue with:
1. Missing executable in app bundle despite "BUILD SUCCEEDED"
2. `dyld` Team ID mismatch between main app and debug dylib
3. App failing to launch with bundle errors

**Root Cause**: 
Hidden Swift compilation errors (color compatibility) prevented executable creation, while debug dylib had different signing identity.

**Fix**: 
1. Fixed underlying Swift compilation errors (platform colors)
2. Recommended Release builds to avoid debug dylib issues
3. Used `CODE_SIGN_IDENTITY="-"` for ad-hoc signing

**Commands**: 
```bash
# Release build (recommended)
xcodebuild -project lyt.xcodeproj -scheme lyt -destination 'platform=macOS' -configuration Release build CODE_SIGN_IDENTITY="-"
```

**Verification**: ✅ macOS builds and launches successfully

---

## 🔧 **Testing Infrastructure**

### ✅ **Multi-Platform Build Test Script**
**Date**: 2025-01-24  
**Status**: ✅ **IMPLEMENTED**

**File**: `test_builds.sh`

**Platforms Tested**:
- ✅ iOS (iPhone 16, iPhone 16 Plus)
- ✅ iPadOS (iPad Pro 13-inch M4, iPad Air 11-inch M2)
- ✅ macOS
- ✅ tvOS (Apple TV, Apple TV 4K 3rd gen)

**Configurations**:
- Release builds (all platforms)
- Debug builds (iOS, macOS)

**Usage**:
```bash
./test_builds.sh
```

**Features**:
- Color-coded output
- Automatic error detection and verbose debugging
- macOS-compatible (removed timeout dependency)
- Comprehensive results summary

---

### ✅ **Makefile Build System**
**Date**: 2025-01-24  
**Status**: ✅ **IMPLEMENTED**

**File**: `Makefile`

**Available Targets**:
- `make ios` - Build and verify iOS app bundle + executable
- `make ipados` - Build and verify iPadOS app bundle + executable  
- `make macos` - Build and verify macOS app bundle + executable
- `make tvos` - Build and verify tvOS app bundle + executable
- `make all` - Build all platforms sequentially
- `make run-ios` - Build and launch iOS app in simulator
- `make run-macos` - Build and launch macOS app
- `make clean` - Clean build artifacts
- `make info` - Show build system information

**Key Features**:
- **Build Verification**: Checks for both app bundle and executable creation
- **Dynamic Path Detection**: Uses `find` to locate app bundles in DerivedData
- **Platform-Specific Executables**: Handles different executable paths (iOS/tvOS vs macOS)
- **Color-Coded Output**: Green for success, red for failure, blue for info
- **Error Handling**: Fails fast with clear error messages
- **App Launching**: Built-in targets to build and run apps

**Usage Examples**:
```bash
# Build specific platform
make ios
make tvos

# Build all platforms
make all

# Build and run
make run-macos
make run-ios

# Development workflow
make clean
make ios
```

**Verification Process**:
1. **Build**: Uses `xcodebuild` with appropriate destinations
2. **Bundle Check**: Verifies app bundle directory exists
3. **Executable Check**: Confirms executable file is present
4. **Path Detection**: Dynamically finds build artifacts in DerivedData
5. **Success Confirmation**: Clear success/failure reporting

**Platform-Specific Paths**:
- **iOS**: `Release-iphonesimulator/lyt.app/lyt`
- **iPadOS**: `Release-iphonesimulator/lyt.app/lyt` 
- **macOS**: `Release/lyt.app/Contents/MacOS/lyt`
- **tvOS**: `Release-appletvsimulator/lyt.app/lyt`

---

## 📋 **Issue Resolution Process**

1. **Identify**: Platform-specific API usage causing build failures
2. **Diagnose**: Use verbose build output to pinpoint exact compatibility issues
3. **Research**: Check Apple documentation for platform availability
4. **Fix**: Implement conditional compilation with `#if os(...)` directives
5. **Test**: Run comprehensive build test script across all platforms
6. **Document**: Record issue, fix, and verification in this tracker
7. **Verify**: Ensure fix doesn't break other platforms

---

## 🎯 **Prevention Guidelines**

1. **Always use platform checks** for platform-specific APIs
2. **Test all platforms** before considering a feature complete
3. **Use the build test script** for every significant change
4. **Prefer common APIs** over platform-specific when possible
5. **Document platform differences** in code comments when needed

---

*Last Updated: 2025-01-24*