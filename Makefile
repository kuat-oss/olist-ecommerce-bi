.PHONY: build exports serve all

build:
	mkdir -p warehouse && cd dbt && dbt seed --profiles-dir . && dbt build --profiles-dir .

exports:
	python scripts/export_powerbi.py
	python scripts/build_dashboard_data.py

serve:
	python -m http.server 8000

all: build exports
