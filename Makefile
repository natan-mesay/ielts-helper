# -----------------------------------------------------------------------------
# IELTS Prep App - Automation Makefile
# -----------------------------------------------------------------------------

# Automatically detect Flutter in PATH or fallback to standard location
export PATH := /home/natan/develop/flutter/bin:$(PATH)
export ANDROID_HOME := /home/natan/Android/Sdk

.PHONY: all apk release clean test analyze run help

all: apk

## Build Production Release APK (Universal ~51 MB)
apk:
	@echo "🔨 Building Optimized Universal Release APK..."
	@flutter build apk --release
	@cp -f build/app/outputs/flutter-apk/app-release.apk ielts_app.apk
	@echo ""
	@echo "✅ Universal Release APK generated successfully!"
	@echo "  $$(pwd)/ielts_app.apk"
	@ls -lh ielts_app.apk

## Build Ultra-Compact ARM64 APK (~18 MB, for 99% of modern Android phones)
apk-arm64:
	@echo "🔨 Building Ultra-Compact ARM64 Release APK..."
	@flutter build apk --split-per-abi --release
	@cp -f build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ielts_app_arm64.apk
	@echo ""
	@echo "✅ Ultra-compact ARM64 APK generated successfully (~18.5 MB)!"
	@echo "  $$(pwd)/ielts_app_arm64.apk"
	@ls -lh ielts_app_arm64.apk

## Build Fast Debug APK (Uncompressed JIT)
apk-debug:
	@echo "🔨 Building Debug APK..."
	@flutter build apk --debug
	@echo ""
	@echo "✅ Debug APK generated in build/app/outputs/flutter-apk/app-debug.apk"
	@ls -lh build/app/outputs/flutter-apk/app-debug.apk 2>/dev/null || true

## Build Optimized Split-per-ABI APKs (15.9 MB - 20 MB per architecture)
apk-split:
	@echo "🔨 Building Split-per-ABI APKs..."
	@flutter build apk --split-per-abi --release
	@echo ""
	@echo "✅ Split APKs generated in: build/app/outputs/flutter-apk/"
	@ls -lh build/app/outputs/flutter-apk/*release.apk 2>/dev/null || true

## Run App on Device / Emulator
run:
	$(FLUTTER) run

## Run App in Brave Browser
run-brave:
	export CHROME_EXECUTABLE=/usr/bin/brave-browser && $(FLUTTER) run -d chrome

## Run Automated Test Suite & Analysis
test:
	@echo "🧪 Running Static Analysis..."
	@$(FLUTTER) analyze
	@echo "🧪 Running Unit & Widget Tests..."
	@$(FLUTTER) test

## Re-scrape IELTS Liz Vocabulary Dataset
scrape:
	@echo "🕸️ Scraping vocabulary from ieltsliz.com..."
	@python3 scraper.py
	@cp ielts_vocabulary.json assets/data/
	@cp ielts_vocabulary_topics.json assets/data/
	@echo "✅ Dataset refreshed."

## Build Web Release
build-web:
	@echo "🌐 Building Web Release..."
	@flutter build web --release

## Serve Web Release locally
serve:
	@echo "🚀 Serving Web build on http://localhost:8080..."
	@python3 -m http.server 8080 --directory build/web

## Clean Build Artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@$(FLUTTER) clean
	@rm -rf build/

## Show Available Make Targets
help:
	@echo "=================================================="
	@echo "     IELTS Prep App - Available Make Commands     "
	@echo "=================================================="
	@echo "  make apk        - Build universal Release APK (~51 MB)"
	@echo "  make apk-arm64  - Build ultra-compact ARM64 APK (~18.5 MB)"
	@echo "  make apk-split  - Build split-per-ABI APKs (15.9 MB - 20 MB)"
	@echo "  make apk-debug  - Build fast JIT Debug APK"
	@echo "  make run        - Run app on connected device"
	@echo "  make run-brave  - Run web version in Brave"
	@echo "  make test       - Run flutter analyze and tests"
	@echo "  make scrape     - Re-scrape vocabulary dataset"
	@echo "  make clean      - Clean build artifacts"
	@echo "=================================================="
