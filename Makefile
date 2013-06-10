BROWSERIFY = node_modules/.bin/browserify
COFFEE = node_modules/.bin/coffee
COFFEELINT = node_modules/.bin/coffeelint

source_files := $(shell find lib -type f -name '*.coffee')


watch:
	@$(BROWSERIFY) -w -o lib/openzoom.js lib/openzoom.coffee

install:
	@npm install --registry=http://registry.npmjs.org

clean:
	@rm lib/openzoom.js

lint:
	@$(COFFEELINT) $(source_files)

test:
	@open test/index.html

server:
	@$(COFFEE) support/server.coffee

.PHONY: watch install clean test server
