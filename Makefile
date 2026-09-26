.PHONY: dev clean

dev:
	nix develop -c process-compose up

clean:
	rm -rf .data
