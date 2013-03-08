all: js/spacecrab.js js/8080.js js/register_allocation.js js/8080_ops.js

js/spacecrab.js: coffee/spacecrab.coffee
	coffee -c -o js/ coffee/spacecrab.coffee

js/register_allocation.js: coffee/register_allocation.coffee
	coffee -c -o js/ coffee/register_allocation.coffee

js/8080_ops.js: coffee/8080_ops.coffee
	coffee -c -o js/ coffee/8080_ops.coffee

js/8080.js: coffee/8080.coffee
	coffee -c -o js/ coffee/8080.coffee
