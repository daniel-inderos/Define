# Define — build & bundle
#
# `swift build` / `swift test` work directly; this Makefile exists to
# assemble the .app bundle (menu bar apps need a bundle for a stable
# identity in System Settings → Accessibility, LSUIElement, etc.).

APP_NAME := Define
BUILD_DIR := .build
BUNDLE_DIR := build/$(APP_NAME).app
CONFIG := release
SDK_VERSION := $(shell xcrun --sdk macosx --show-sdk-version)
MIN_MACOS := 14.0

# macOS ties Accessibility (TCC) grants to the app's code signature. An
# ad-hoc signature changes on every rebuild, so the grant goes stale and
# the app re-prompts. Prefer a stable identity when the machine has one:
# Developer ID first, then Apple Development; fall back to ad-hoc ("-").
# Override with: make app CODESIGN_IDENTITY=<hash-or-name>
CODESIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning 2>/dev/null | awk '/Developer ID Application/ {print $$2; exit}')
ifeq ($(strip $(CODESIGN_IDENTITY)),)
CODESIGN_IDENTITY := $(shell security find-identity -v -p codesigning 2>/dev/null | awk '/Apple Development/ {print $$2; exit}')
endif
ifeq ($(strip $(CODESIGN_IDENTITY)),)
CODESIGN_IDENTITY := -
endif

.PHONY: all app run debug test icon clean

all: app

# Build the release binary and assemble Define.app into ./build
app:
	swift build -c $(CONFIG)
	rm -rf "$(BUNDLE_DIR)"
	mkdir -p "$(BUNDLE_DIR)/Contents/MacOS" "$(BUNDLE_DIR)/Contents/Resources"
	cp "$$(swift build -c $(CONFIG) --show-bin-path)/$(APP_NAME)" "$(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)"
	# SwiftPM stamps the deployment target as the linked-SDK version, which
	# makes macOS run the app in legacy-appearance mode (no Liquid Glass).
	# Re-stamp the real SDK so the system treats it as a modern app.
	vtool -set-build-version macos $(MIN_MACOS) $(SDK_VERSION) -replace \
		-output "$(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)" "$(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)"
	cp Support/Info.plist "$(BUNDLE_DIR)/Contents/Info.plist"
	cp Support/AppIcon.icns "$(BUNDLE_DIR)/Contents/Resources/AppIcon.icns"
	codesign --force --sign "$(CODESIGN_IDENTITY)" "$(BUNDLE_DIR)"
	@echo "Built $(BUNDLE_DIR) (signed: $(CODESIGN_IDENTITY))"

# Build the bundle and launch it
run: app
	open "$(BUNDLE_DIR)"

# Quick debug run, un-bundled (Accessibility access is tracked per-binary
# in this mode and may re-prompt after rebuilds)
debug:
	swift run

test:
	swift test

# Regenerate Support/AppIcon.icns and docs/icon.png from source
icon:
	swift Scripts/generate-icon.swift

clean:
	swift package clean
	rm -rf build
