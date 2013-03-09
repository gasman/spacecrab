JSFILES = js/spacecrab.js js/8080.js js/8080_defs.js js/8080_ops.js js/8080_compiler.js

all: ${JSFILES}

js/spacecrab.js: coffee/spacecrab.coffee
	coffee -c -o js/ coffee/spacecrab.coffee

js/8080_defs.js: coffee/8080_defs.coffee
	coffee -c -o js/ coffee/8080_defs.coffee

js/8080_ops.js: coffee/8080_ops.coffee
	coffee -c -o js/ coffee/8080_ops.coffee

js/8080.js: coffee/8080.coffee
	coffee -c -o js/ coffee/8080.coffee

js/8080_compiler.js: coffee/8080_compiler.coffee
	coffee -c -o js/ coffee/8080_compiler.coffee

clean:
	rm -f ${JSFILES}
