SCHEME := AQI Checker
PROJECT := Oxygenie.xcodeproj
DEST := platform=macOS
CONFIG := Debug
APP := Oxygenie.app

.PHONY: build test clean open

# Compile only (does not launch the app).
build:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination '$(DEST)' -configuration $(CONFIG) -quiet build

# Build, then open the app. Oxygenie is LSUIElement (menu bar only) — no Dock icon; check the menu bar.
open: build
	@set -e; \
	PRODUCT_DIR="$$(xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration $(CONFIG) -showBuildSettings 2>/dev/null | sed -n 's/^[[:space:]]*BUILT_PRODUCTS_DIR = //p' | head -1 | tr -d '\r')"; \
	if [ -z "$$PRODUCT_DIR" ]; then echo "Could not resolve BUILT_PRODUCTS_DIR." >&2; exit 1; fi; \
	if [ ! -d "$$PRODUCT_DIR/$(APP)" ]; then echo "Expected app at $$PRODUCT_DIR/$(APP) — build may have failed or use a different scheme." >&2; exit 1; fi; \
	echo ""; \
	echo "Opening: $$PRODUCT_DIR/$(APP)"; \
	echo "Note: Oxygenie runs in the menu bar only (no Dock icon). Look for the leaf or AQI number near the clock."; \
	echo ""; \
	open "$$PRODUCT_DIR/$(APP)"

test:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination '$(DEST)' -quiet test

clean:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination '$(DEST)' clean
