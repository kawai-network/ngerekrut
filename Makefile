.PHONY: help pub-get analyze run seed-kv verify-kv emu-start emu-stop emu-status jobseeker recruiter clean

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

pub-get: ## Get Flutter dependencies
	flutter pub get

analyze: ## Analyze Flutter code
	flutter analyze

run: ## Run default Flutter app
	flutter run

seed-kv: ## Seed Cloudflare KV data
	bash scripts/seed-cloudflare-kv.sh

verify-kv: ## Verify Cloudflare KV data
	bash scripts/verify-cloudflare-kv.sh

# Emulator commands
emu-start: ## Start Android emulator
	@echo "Starting Android emulator..."
	@if [ -z "$$(adb devices | grep emulator)" ]; then \
		/opt/homebrew/share/android-commandlinetools/emulator/emulator -avd ngerekrut_emulator -no-snapshot & \
		echo "Waiting for emulator to boot..."; \
		for i in $$(seq 1 60); do \
			if adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; then \
				echo "Emulator is ready!"; \
				break; \
			fi; \
			sleep 1; \
		done; \
	else \
		echo "Emulator is already running"; \
	fi

emu-stop: ## Stop Android emulator
	@echo "Stopping Android emulator..."
	@adb emu kill
	@echo "Emulator stopped"

emu-status: ## Check emulator status
	@echo "Connected devices:"
	@adb devices

# Run on emulator
jobseeker: emu-start ## Run Jobseeker flavor on emulator
	@echo "Running Jobseeker flavor..."
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart

recruiter: emu-start ## Run Recruiter flavor on emulator
	@echo "Running Recruiter flavor..."
	@flutter run --flavor recruiter -t lib/main_recruiter.dart

jobseeker-debug: ## Run Jobseeker flavor (debug mode)
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart --debug

recruiter-debug: ## Run Recruiter flavor (debug mode)
	@flutter run --flavor recruiter -t lib/main_recruiter.dart --debug

jobseeker-release: ## Run Jobseeker flavor (release mode)
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart --release

recruiter-release: ## Run Recruiter flavor (release mode)
	@flutter run --flavor recruiter -t lib/main_recruiter.dart --release

# Build APKs
build-jobseeker: ## Build Jobseeker APK
	@flutter build apk --release --flavor jobseeker -t lib/main_jobseeker.dart

build-recruiter: ## Build Recruiter APK
	@flutter build apk --release --flavor recruiter -t lib/main_recruiter.dart

build-all: build-jobseeker build-recruiter ## Build all APKs

# Install to emulator
install-jobseeker: ## Install Jobseeker APK to emulator
	@flutter install --flavor jobseeker -t lib/main_jobseeker.dart

install-recruiter: ## Install Recruiter APK to emulator
	@flutter install --flavor recruiter -t lib/main_recruiter.dart

clean: ## Clean build artifacts
	@flutter clean
