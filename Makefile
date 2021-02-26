update-doc:
	docker run --rm -v "$$(pwd):/src" quay.io/terraform-docs/terraform-docs:0.11.2 markdown table /src > README.md
