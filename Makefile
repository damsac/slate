.DEFAULT_GOAL := help
SCHEME := Slate
# Read APP_GROUP_IDENTIFIER from project.local.yml if present, otherwise use default
APP_GROUP := $(shell grep 'APP_GROUP_IDENTIFIER:' project.local.yml 2>/dev/null | awk '{print $$2}' || echo "group.com.damsac.slate.shared")
ENTITLEMENTS := Slate/Slate.entitlements SlateWidget/SlateWidget.entitlements

.PHONY: generate build test lint clean help

generate: ## Generate Xcode project and validate entitlements
	@test -f project.local.yml || touch project.local.yml
	xcodegen generate
	@for f in $(ENTITLEMENTS); do \
		if ! grep -q '$(APP_GROUP)' "$$f" 2>/dev/null; then \
			echo "ERROR: $$f missing App Group '$(APP_GROUP)'" >&2; \
			echo "Check project.yml entitlements.properties for both targets." >&2; \
			exit 1; \
		fi; \
	done
	@echo "Project generated — entitlements validated."

build: generate ## Build for simulator (no code signing required)
	set -o pipefail && xcodebuild \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
		-configuration Debug \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGNING_REQUIRED=NO \
		build 2>&1 | xcbeautify

test: generate ## Run unit tests on simulator
	set -o pipefail && xcodebuild \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
		-configuration Debug \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGNING_REQUIRED=NO \
		test 2>&1 | xcbeautify

lint: ## Lint Swift sources
	swiftlint lint Slate/ SlateWidget/

clean: ## Remove build artifacts
	xcodebuild clean -scheme $(SCHEME) 2>/dev/null || true
	rm -rf build/ DerivedData/

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
