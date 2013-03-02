all: js/spacecrab.js js/8080.js

js/spacecrab.js: coffee/spacecrab.coffee
	coffee -c -o js/ coffee/spacecrab.coffee

js/8080.js: coffee/8080.coffee
	coffee -c -o js/ coffee/8080.coffee
