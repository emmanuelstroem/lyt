# Lyt App - Multi-Platform Build Makefile
# Provides clean targets for building and verifying all Apple platforms

# Project configuration
PROJECT = lyt.xcodeproj
SCHEME = lyt
CONFIG = Release
CODE_SIGN = CODE_SIGN_IDENTITY="-"

# DerivedData base path (simplified approach)
DERIVED_DATA_BASE = ~/Library/Developer/Xcode/DerivedData/lyt-*/Build/Products

# App bundle paths
IOS_APP = $(shell find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-iphonesimulator*" 2>/dev/null | head -1)
IPADOS_APP = $(shell find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-iphonesimulator*" 2>/dev/null | head -1)
MACOS_APP = $(shell find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)/*" -not -path "*simulator*" 2>/dev/null | head -1)
TVOS_APP = $(shell find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-appletvsimulator*" 2>/dev/null | head -1)

# Platform-specific destinations
IOS_DEST = "platform=iOS Simulator,name=iPhone 16"
IPADOS_DEST = "platform=iOS Simulator,name=iPad Pro 13-inch (M4)"
MACOS_DEST = "platform=macOS"
TVOS_DEST = "platform=tvOS Simulator,name=Apple TV"

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
BLUE = \033[0;34m
YELLOW = \033[1;33m
NC = \033[0m

# Default target
.PHONY: all
all: ios ipados macos tvos
	@echo "$(GREEN)🎉 All platform builds completed successfully!$(NC)"
	@echo "$(BLUE)📱 iOS, iPadOS, macOS, and tvOS are ready$(NC)"

# iOS target
.PHONY: ios
ios:
	@echo "$(BLUE)📱 Building iOS...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(IOS_DEST) \
		-configuration $(CONFIG) \
		build -quiet
	@$(MAKE) verify-ios

.PHONY: verify-ios
verify-ios:
	@echo "$(YELLOW)🔍 Verifying iOS build...$(NC)"
	@IOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-iphonesimulator*" 2>/dev/null | head -1); \
	if [ -n "$$IOS_APP_PATH" ] && [ -d "$$IOS_APP_PATH" ]; then \
		echo "$(GREEN)✅ iOS app bundle created: $$IOS_APP_PATH$(NC)"; \
		if [ -f "$$IOS_APP_PATH/lyt" ]; then \
			echo "$(GREEN)✅ iOS executable created: $$IOS_APP_PATH/lyt$(NC)"; \
		else \
			echo "$(RED)❌ iOS executable not found$(NC)"; exit 1; \
		fi; \
	else \
		echo "$(RED)❌ iOS app bundle not found$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)✅ iOS build verification complete$(NC)"

# iPadOS target
.PHONY: ipados
ipados:
	@echo "$(BLUE)📱 Building iPadOS...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(IPADOS_DEST) \
		-configuration $(CONFIG) \
		build -quiet
	@$(MAKE) verify-ipados

.PHONY: verify-ipados
verify-ipados:
	@echo "$(YELLOW)🔍 Verifying iPadOS build...$(NC)"
	@IPADOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-iphonesimulator*" 2>/dev/null | head -1); \
	if [ -n "$$IPADOS_APP_PATH" ] && [ -d "$$IPADOS_APP_PATH" ]; then \
		echo "$(GREEN)✅ iPadOS app bundle created: $$IPADOS_APP_PATH$(NC)"; \
		if [ -f "$$IPADOS_APP_PATH/lyt" ]; then \
			echo "$(GREEN)✅ iPadOS executable created: $$IPADOS_APP_PATH/lyt$(NC)"; \
		else \
			echo "$(RED)❌ iPadOS executable not found$(NC)"; exit 1; \
		fi; \
	else \
		echo "$(RED)❌ iPadOS app bundle not found$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)✅ iPadOS build verification complete$(NC)"

# macOS target
.PHONY: macos
macos:
	@echo "$(BLUE)💻 Building macOS...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(MACOS_DEST) \
		-configuration $(CONFIG) \
		build $(CODE_SIGN) -quiet
	@$(MAKE) verify-macos

.PHONY: verify-macos
verify-macos:
	@echo "$(YELLOW)🔍 Verifying macOS build...$(NC)"
	@MACOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)/*" -not -path "*simulator*" 2>/dev/null | head -1); \
	if [ -n "$$MACOS_APP_PATH" ] && [ -d "$$MACOS_APP_PATH" ]; then \
		echo "$(GREEN)✅ macOS app bundle created: $$MACOS_APP_PATH$(NC)"; \
		if [ -f "$$MACOS_APP_PATH/Contents/MacOS/lyt" ]; then \
			echo "$(GREEN)✅ macOS executable created: $$MACOS_APP_PATH/Contents/MacOS/lyt$(NC)"; \
		else \
			echo "$(RED)❌ macOS executable not found$(NC)"; exit 1; \
		fi; \
	else \
		echo "$(RED)❌ macOS app bundle not found$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)✅ macOS build verification complete$(NC)"

# tvOS target
.PHONY: tvos
tvos:
	@echo "$(BLUE)📺 Building tvOS...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(TVOS_DEST) \
		-configuration $(CONFIG) \
		build $(CODE_SIGN) -quiet
	@$(MAKE) verify-tvos

.PHONY: verify-tvos
verify-tvos:
	@echo "$(YELLOW)🔍 Verifying tvOS build...$(NC)"
	@TVOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-appletvsimulator*" 2>/dev/null | head -1); \
	if [ -n "$$TVOS_APP_PATH" ] && [ -d "$$TVOS_APP_PATH" ]; then \
		echo "$(GREEN)✅ tvOS app bundle created: $$TVOS_APP_PATH$(NC)"; \
		if [ -f "$$TVOS_APP_PATH/lyt" ]; then \
			echo "$(GREEN)✅ tvOS executable created: $$TVOS_APP_PATH/lyt$(NC)"; \
		else \
			echo "$(RED)❌ tvOS executable not found$(NC)"; exit 1; \
		fi; \
	else \
		echo "$(RED)❌ tvOS app bundle not found$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)✅ tvOS build verification complete$(NC)"

# Debug builds for development
.PHONY: ios-debug
ios-debug:
	@echo "$(BLUE)📱 Building iOS (Debug)...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(IOS_DEST) \
		-configuration Debug \
		build -quiet
	@echo "$(GREEN)✅ iOS Debug build complete$(NC)"

.PHONY: macos-debug
macos-debug:
	@echo "$(BLUE)💻 Building macOS (Debug)...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination $(MACOS_DEST) \
		-configuration Debug \
		build $(CODE_SIGN) -quiet
	@echo "$(GREEN)✅ macOS Debug build complete$(NC)"

# Clean targets
.PHONY: clean
clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean -quiet
	@echo "$(GREEN)✅ Clean complete$(NC)"

.PHONY: clean-derived-data
clean-derived-data:
	@echo "$(YELLOW)🧹 Cleaning derived data...$(NC)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/lyt-*
	@echo "$(GREEN)✅ Derived data cleaned$(NC)"

# Utility targets
.PHONY: info
info:
	@echo "$(BLUE)📋 Lyt Build System Information$(NC)"
	@echo "Project: $(PROJECT)"
	@echo "Scheme: $(SCHEME)"
	@echo "Configuration: $(CONFIG)"
	@echo ""
	@echo "$(BLUE)Available targets:$(NC)"
	@echo "  make ios      - Build and verify iOS"
	@echo "  make ipados   - Build and verify iPadOS"  
	@echo "  make macos    - Build and verify macOS"
	@echo "  make tvos     - Build and verify tvOS"
	@echo "  make all      - Build all platforms"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make info     - Show this information"

.PHONY: run-ios
run-ios: ios
	@echo "$(BLUE)🚀 Launching iOS app...$(NC)"
	@xcrun simctl boot "iPhone 16" || true
	@IOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)-iphonesimulator*" 2>/dev/null | head -1); \
	if [ -n "$$IOS_APP_PATH" ]; then \
		xcrun simctl install "iPhone 16" "$$IOS_APP_PATH" && \
		xcrun simctl launch "iPhone 16" com.yourcompany.lyt; \
	else \
		echo "$(RED)❌ iOS app not found for launch$(NC)"; exit 1; \
	fi

.PHONY: run-macos
run-macos: macos
	@echo "$(BLUE)🚀 Launching macOS app...$(NC)"
	@MACOS_APP_PATH=$$(find $(DERIVED_DATA_BASE) -name "lyt.app" -path "*$(CONFIG)/*" -not -path "*simulator*" 2>/dev/null | head -1); \
	if [ -n "$$MACOS_APP_PATH" ]; then \
		open "$$MACOS_APP_PATH"; \
	else \
		echo "$(RED)❌ macOS app not found for launch$(NC)"; exit 1; \
	fi

# Help target
.PHONY: help
help: info 