# Lyt 📻

**Listen to Radio (DK) on Apple devices**

A modern, cross-platform SwiftUI radio app for streaming Danmarks Radio (DR) channels across iOS, iPadOS, macOS, and tvOS. Features an Apple Music-inspired design with real-time program information.

---

## 🎯 **Platform Support**

| Platform | Status | Minimum Version |
|----------|--------|----------------|
| **iOS** | ✅ **Supported** | iOS 15.6+ |
| **iPadOS** | ✅ **Supported** | iPadOS 15.6+ |
| **macOS** | ✅ **Supported** | macOS 12.0+ |
| **tvOS** | ✅ **Supported** | tvOS 15.0+ |

---

## 🛠️ **Prerequisites**

- **Xcode 15+** (Xcode-beta recommended)
- **macOS** with Apple silicon or Intel processor
- **Command Line Tools** installed
- **Make** (pre-installed on macOS)

---

## 🚀 **Quick Start**

### Build All Platforms
```bash
make all
```

### Build Specific Platform
```bash
make ios      # Build iOS app
make ipados   # Build iPadOS app  
make macos    # Build macOS app
make tvos     # Build tvOS app
```

### Build and Run
```bash
make run-ios     # Build and launch iOS simulator
make run-macos   # Build and launch macOS app
```

---

## 📋 **Build System (Makefile)**

### Available Targets

| Target | Description | Output |
|--------|-------------|--------|
| `make all` | Build all platforms sequentially | iOS → iPadOS → macOS → tvOS |
| `make ios` | Build and verify iOS app | App bundle + executable check |
| `make ipados` | Build and verify iPadOS app | App bundle + executable check |
| `make macos` | Build and verify macOS app | App bundle + executable check |
| `make tvos` | Build and verify tvOS app | App bundle + executable check |
| `make clean` | Clean build artifacts | Removes build cache |
| `make info` | Show build system info | Configuration details |

### Development Targets

| Target | Description | Use Case |
|--------|-------------|----------|
| `make run-ios` | Build + launch iOS simulator | iOS development |
| `make run-macos` | Build + launch macOS app | macOS development |
| `make ios-debug` | Build iOS in Debug mode | Development builds |
| `make macos-debug` | Build macOS in Debug mode | Development builds |
| `make clean-derived-data` | Clean all DerivedData | Reset build environment |

---

## 🔧 **Development Workflow**

### Standard Development Cycle
```bash
# 1. Make code changes
# 2. Test specific platform
make ios

# 3. Test cross-platform compatibility  
make all

# 4. Run and test functionality
make run-macos
```

### Platform-Specific Development
```bash
# iOS Development
make ios-debug
make run-ios

# macOS Development  
make macos-debug
make run-macos

# Release Testing
make clean
make all
```

### Continuous Integration
```bash
# Clean build for CI/CD
make clean-derived-data
make all
```

---

## ✅ **Build Verification**

Each build target performs **comprehensive verification**:

1. **🔨 Build Success**: Confirms Swift compilation succeeds
2. **📦 Bundle Check**: Verifies `.app` bundle creation  
3. **⚙️ Executable Check**: Confirms binary executable exists

### Example Output
```bash
$ make ios
📱 Building iOS...
🔍 Verifying iOS build...
✅ iOS app bundle created: /path/to/lyt.app
✅ iOS executable created: /path/to/lyt.app/lyt
✅ iOS build verification complete
```

---

## 🎨 **Features**

- **🎵 Apple Music-style UI** - Familiar, polished interface
- **📱 Universal App** - Single codebase for all Apple platforms
- **🔴 Live Radio Streaming** - Real-time DR channel audio
- **📻 Channel Browser** - Grid-based station selection
- **ℹ️ Program Information** - Current show details and descriptions
- **🎛️ Stream Quality Options** - HLS and ICY stream support

---

## 📁 **Project Structure**

```
lyt/
├── lyt/                          # Main app source
│   ├── Models/                   # Data models (DRModels.swift)
│   ├── Services/                 # Network & mock services
│   ├── ContentView.swift         # Main SwiftUI interface
│   └── lytApp.swift             # App entry point
├── lytTests/                     # Unit tests
├── lytUITests/                   # UI tests
├── Makefile                      # Build system
├── issues.md                     # Issue tracking
└── README.md                     # This file
```

---

## 🐛 **Troubleshooting**

### Common Issues

**Build Failures:**
```bash
# Clean and rebuild
make clean
make ios

# Reset DerivedData
make clean-derived-data
make all
```

**Platform-Specific Issues:**
```bash
# Check build system info
make info

# Test individual platforms
make ios
make macos
make tvos
```

**App Launch Issues:**
```bash
# Verify executable creation
make macos
ls -la ~/Library/Developer/Xcode/DerivedData/lyt-*/Build/Products/Release/lyt.app/Contents/MacOS/

# Try debug build
make macos-debug
```

### Error Messages

| Error | Solution |
|-------|----------|
| `❌ iOS app bundle not found` | Run `make clean` then `make ios` |
| `❌ iOS executable not found` | Check compilation errors with verbose xcodebuild |
| `BUILD FAILED` | See `issues.md` for platform-specific fixes |

---

## 📖 **Documentation**

- **Build Issues**: See `issues.md` for detailed troubleshooting
- **API Information**: DR Radio API v4 documentation
- **Platform Notes**: Apple Developer documentation for SwiftUI

---

## 🧪 **Testing**

### Manual Testing
```bash
# Test all platforms
make all

# Test specific functionality
make run-ios    # Test iOS interface
make run-macos  # Test macOS interface
```

### Automated Testing
```bash
# Run unit tests (when implemented)
xcodebuild test -project lyt.xcodeproj -scheme lyt -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 🤝 **Contributing**

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** all platforms: `make all`
4. **Verify** builds pass: Check for ✅ symbols
5. **Submit** a pull request

### Development Setup
```bash
git clone https://github.com/yourusername/lyt.git
cd lyt
make info          # Verify build system
make all           # Test all platforms
```

---

## 📄 **License**

This project is open source. See the license file for details.

---

## 🚀 **Getting Started**

1. **Clone** the repository
2. **Open** Terminal in project directory  
3. **Run** `make all` to build all platforms
4. **Launch** with `make run-macos` or `make run-ios`

**Ready to listen to Danish radio on all your Apple devices! 📻🇩🇰**
