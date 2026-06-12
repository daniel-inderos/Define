# Define — build & bundle
#
# `swift build` / `swift test` work directly; this Makefile exists to
# assemble the .app bundle (menu bar apps need a bundle for a stable
# identity in System Settings → Accessibility, LSUIElement, etc.).

APP_NAME := Define
BUILD_DIR := .build
BUNDLE_DIR := build/$(APP_NAME).app
CONFIG := release

.PHONY: all app run debug test clean

all: app

# Build the release binary and assemble Define.app into ./build
app:
	swift build -c $(CONFIG)
	rm -rf "$(BUNDLE_DIR)"
	mkdir -p "$(BUNDLE_DIR)/Contents/MacOS" "$(BUNDLE_DIR)/Contents/Resources"
	cp "$$(swift build -c $(CONFIG) --show-bin-path)/$(APP_NAME)" "$(BUNDLE_DIR)/Contents/MacOS/$(APP_NAME)"
	cp Support/Info.plist "$(BUNDLE_DIR)/Contents/Info.plist"
	codesign --force --sign - "$(BUNDLE_DIR)"
	@echo "Built $(BUNDLE_DIR)"

# Build the bundle and launch it
run: app
	open "$(BUNDLE_DIR)"

# Quick debug run, un-bundled (Accessibility access is tracked per-binary
# in this mode and may re-prompt after rebuilds)
debug:
	swift run

test:
	swift test

clean:
	swift package clean
	rm -rf build
