DART=dart
DART2JS=dart2js
DART2JS_FLAGS='--minify'


build:
	@$(DART2JS) $(DART2JS_FLAGS) -o web/openzoom.js web/openzoom.dart

install:
	@pub install

clean:
	@rm web/openzoom.js

test:
	@$(DART) test/openzoom.dart


.PHONY: build install clean lint test
