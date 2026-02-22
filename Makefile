# POILog – CLI Build System
# Usage: make help

PROJECT      := POILog.xcodeproj
SCHEME       := POILog
BUNDLE_ID    := com.poilogger.app
TEAM_ID      := U8A4E46MT9

CONFIGURATION ?= Debug
SIMULATOR     ?= iPhone 17 Pro
DERIVED_DATA  := $(CURDIR)/.deriveddata
ARCHIVE_PATH  := $(CURDIR)/.build/POILog.xcarchive
IPA_DIR       := $(CURDIR)/.build/ipa

XCBEAUTIFY := $(shell command -v xcbeautify 2>/dev/null)
ifdef XCBEAUTIFY
  PIPE := | xcbeautify
else
  PIPE :=
endif

.PHONY: generate build build-device build-release run run-device \
        test test-quick archive export export-appstore upload \
        clean clean-all sim-list sim-boot sim-shutdown \
        device-list lint lint-fix check-tools install-tools help

# === PROJECT GENERATION ===

generate: ## Regenerate .xcodeproj from project.yml
	xcodegen generate

# === BUILD ===

build: generate ## Build debug for simulator
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-derivedDataPath $(DERIVED_DATA) \
		$(PIPE)

build-device: generate ## Build debug for physical device
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates \
		$(PIPE)

build-release: generate ## Build release
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA) \
		$(PIPE)

# === RUN ===

run: build sim-boot ## Build and run on simulator
	$(eval APP := $(shell find $(DERIVED_DATA) -name 'POILog.app' -path '*/Debug-iphonesimulator/*' | head -1))
	xcrun simctl install booted "$(APP)"
	xcrun simctl launch booted $(BUNDLE_ID)

run-device: build-device ## Build and run on physical device
	$(eval APP := $(shell find $(DERIVED_DATA) -name 'POILog.app' -path '*/Debug-iphoneos/*' | head -1))
	$(eval DEVICE := $(shell xcrun devicectl list devices 2>/dev/null | grep -m1 'iPhone\|iPad' | awk '{print $$NF}'))
	xcrun devicectl device install app --device $(DEVICE) "$(APP)"
	xcrun devicectl device process launch --device $(DEVICE) $(BUNDLE_ID)

# === TEST ===

test: generate ## Run unit tests on simulator
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-derivedDataPath $(DERIVED_DATA) \
		$(PIPE)

test-quick: ## Run tests without rebuilding
	xcodebuild test-without-building \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-derivedDataPath $(DERIVED_DATA) \
		$(PIPE)

# === ARCHIVE & DISTRIBUTE ===

archive: generate ## Create release archive
	mkdir -p $(dir $(ARCHIVE_PATH))
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-archivePath $(ARCHIVE_PATH) \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates \
		$(PIPE)

export: archive ## Archive and export development IPA
	mkdir -p $(IPA_DIR)
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(IPA_DIR) \
		-exportOptionsPlist ExportOptions-development.plist \
		-allowProvisioningUpdates

export-appstore: archive ## Archive and export for App Store
	mkdir -p $(IPA_DIR)
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(IPA_DIR) \
		-exportOptionsPlist ExportOptions-appstore.plist \
		-allowProvisioningUpdates

upload: export-appstore ## Upload to App Store Connect (requires ASC_KEY_ID + ASC_ISSUER_ID)
	xcrun altool --upload-app \
		-f $(IPA_DIR)/POILog.ipa \
		-t ios \
		--apiKey $(ASC_KEY_ID) \
		--apiIssuer $(ASC_ISSUER_ID)

# === SIMULATOR ===

sim-list: ## List available simulators
	xcrun simctl list devices available

sim-boot: ## Boot the default simulator
	@xcrun simctl boot '$(SIMULATOR)' 2>/dev/null || true
	@open -a Simulator

sim-shutdown: ## Shutdown all simulators
	xcrun simctl shutdown all

# === DEVICE ===

device-list: ## List connected physical devices
	xcrun devicectl list devices

# === CLEAN ===

clean: ## Clean build artifacts
	rm -rf $(DERIVED_DATA)

clean-all: clean ## Clean everything including archives and IPA
	rm -rf .build

# === LINT ===

lint: ## Run SwiftLint
	swiftlint lint

lint-fix: ## Auto-fix SwiftLint violations
	swiftlint lint --fix

# === TOOLS ===

check-tools: ## Check which tools are installed
	@echo "=== Required ==="
	@which xcodebuild && xcodebuild -version || echo "MISSING: xcodebuild"
	@which xcodegen && echo "xcodegen: $$(xcodegen --version)" || echo "MISSING: xcodegen (brew install xcodegen)"
	@echo ""
	@echo "=== Optional ==="
	@which xcbeautify && echo "xcbeautify: installed" || echo "xcbeautify: not installed (brew install xcbeautify)"
	@which swiftlint && echo "swiftlint: installed" || echo "swiftlint: not installed (brew install swiftlint)"

install-tools: ## Install required + optional tools via Homebrew
	brew install xcodegen xcbeautify swiftlint

# === HELP ===

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
