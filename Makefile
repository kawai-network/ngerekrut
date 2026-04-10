.PHONY: help pub-get analyze run seed-kv verify-kv emu-start emu-stop emu-status jobseeker recruiter clean logs logs-jobseeker logs-recruiter

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
	@mkdir -p logs
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart 2>&1 | tee logs/jobseeker-$$(date +%Y%m%d-%H%M%S).log

recruiter: emu-start ## Run Recruiter flavor on emulator
	@echo "Running Recruiter flavor..."
	@mkdir -p logs
	@flutter run --flavor recruiter -t lib/main_recruiter.dart 2>&1 | tee logs/recruiter-$$(date +%Y%m%d-%H%M%S).log

jobseeker-debug: ## Run Jobseeker flavor (debug mode)
	@mkdir -p logs
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart --debug 2>&1 | tee logs/jobseeker-debug-$$(date +%Y%m%d-%H%M%S).log

recruiter-debug: ## Run Recruiter flavor (debug mode)
	@mkdir -p logs
	@flutter run --flavor recruiter -t lib/main_recruiter.dart --debug 2>&1 | tee logs/recruiter-debug-$$(date +%Y%m%d-%H%M%S).log

jobseeker-release: ## Run Jobseeker flavor (release mode)
	@mkdir -p logs
	@flutter run --flavor jobseeker -t lib/main_jobseeker.dart --release 2>&1 | tee logs/jobseeker-release-$$(date +%Y%m%d-%H%M%S).log

recruiter-release: ## Run Recruiter flavor (release mode)
	@mkdir -p logs
	@flutter run --flavor recruiter -t lib/main_recruiter.dart --release 2>&1 | tee logs/recruiter-release-$$(date +%Y%m%d-%H%M%S).log

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

clean-logs: ## Clean log files
	@rm -rf logs
	@echo "Logs cleaned"

# View logs
logs: ## List all log files
	@ls -lh logs/ 2>/dev/null || echo "No logs directory found"

logs-jobseeker: ## View latest Jobseeker log
	@tail -f $$(ls -t logs/jobseeker-*.log 2>/dev/null | head -1) 2>/dev/null || echo "No Jobseeker logs found"

logs-recruiter: ## View latest Recruiter log
	@tail -f $$(ls -t logs/recruiter-*.log 2>/dev/null | head -1) 2>/dev/null || echo "No Recruiter logs found"
