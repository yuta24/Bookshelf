.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":[^#]*? #| #"}; {printf "%-42s%s\n", $$1 $$3, $$2}'

.PHONY: bootstrap
bootstrap: # bootstrap: setup project dependencies
	@bundle config path vendor/bundle
	@bundle install --jobs 4
	./scripts/tool/install-licenseplist.sh
	./scripts/tool/install-sourcery.sh
	./scripts/tool/install-swiftlint.sh
	./scripts/tool/install-xcbeautify.sh
	./scripts/decrypt-secret.sh
	./scripts/generate-code.sh

.PHONY: create-simulator-app
create-simulator-app: # create-simulator-app: create app for iOS Simulator
	./scripts/create-simulator-app.sh

.PHONY: generate
generate: # generate: generate code and license file
	./scripts/generate-code.sh
	./scripts/generate-license.sh

.PHONY: unit-test
unit-test: # unit-test: run test
	./scripts/run-unit-tests.sh

.PHONY: screenshot
screenshot: # screenshot: capture screenshot
	bundle exec fastlane ios create_screenshots
