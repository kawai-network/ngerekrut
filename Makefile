.PHONY: pub-get analyze run seed-kv verify-kv

pub-get:
	flutter pub get

analyze:
	flutter analyze

run:
	flutter run

seed-kv:
	bash scripts/seed-cloudflare-kv.sh

verify-kv:
	bash scripts/verify-cloudflare-kv.sh
