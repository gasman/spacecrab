all: js/spacecrab.js

js/spacecrab.js: coffee/spacecrab.coffee
	coffee -c -o js/ coffee/spacecrab.coffee
