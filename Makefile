update-doc:
	docker run --rm -v "$$(pwd):/src" quay.io/terraform-docs/terraform-docs:0.16.0 markdown table /src > README.md
