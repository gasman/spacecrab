/* helper for loading a file over HTTP as an arraybuffer */
function loadFromUrl(url, callback) {
	var request = new XMLHttpRequest();

	request.addEventListener('error', function(e) {
		throw('Error loading from URL: ' + url);
	}, false);

	request.addEventListener('load', function(e) {
		if (request.status == 200) {
			callback(request.response);
		} else {
			throw('Error loading from URL: ' + url);
		}
	}, false);

	/* trigger XHR */
	request.open('GET', url, true);
	request.responseType = "arraybuffer";
	self.isDownloading = true;
	request.send();
}

function Memory() {
	var self = {};
	var mem = new Uint8Array(0x4000);

	self.loadPage = function(addr, data) {
		var bytes = new Uint8Array(data);
		for (var i = 0; i < bytes.length; i++) {
			mem[addr + i] = bytes[i];
		}
	};
	self.read = function(addr) {
		return mem[addr & 0x3fff];
	};
	self.write = function(addr, val) {
		/* only write to RAM area (0x2000-0x3fff) */
		if (addr & 0x2000) {
			mem[addr & 0x3fff] = val;
		}
	};
	self.dump = function() {
		console.log(mem);
	};

	return self;
}

function IO() {
	var self = {};

	self.read = function(port) {
		// console.log('read from port ' + port);
	};

	self.write = function(port, val) {
		// console.log('write ' + val + ' to port ' + port);
	};

	return self;
}

function init() {
	var memory = Memory();
	var io = IO();
	var loadedRomCount = 0;
	var screenCanvas = document.getElementById('screen');
	var screenCtx = screenCanvas.getContext('2d');
	var imageData = screenCtx.createImageData(224, 256);
	var pixels = imageData.data;
	var proc;

	function loadRom(url, addr) {
		loadFromUrl(url, function(data) {
			memory.loadPage(addr, data);
			loadedRomCount++;
			if (loadedRomCount == 4) allRomsLoaded();
		});
	}

	loadRom('roms/invaders.h', 0x0000);
	loadRom('roms/invaders.g', 0x0800);
	loadRom('roms/invaders.f', 0x1000);
	loadRom('roms/invaders.e', 0x1800);

	function allRomsLoaded() {
		proc = Processor8080(memory, io);
		runFrame();
	}

	var isOddFrame = true;
	function runFrame() {
		/* run for a frame at a time, alternating between RST 08 and RST 10 as interrupt routine */
		proc.runForCycles(16667);
		drawScreen();
		proc.interrupt(isOddFrame ? 0xcf : 0xd7); /* opcode for RST 08 / RST 10 */
		isOddFrame = !isOddFrame;
		setTimeout(runFrame, 20);
	}

	function drawScreen() {
		var rowStep = 224 * 4; /* number of bytes in one image row */

		for (y = 0; y < 224; y++) { /* screen is rotated, so y actually iterates over the columns from left to right */
			var pos = (rowStep * 255) + (y << 2); /* index of the bottom pixel in this column */
			for (x = 0; x < 32; x++) { /* x starts at the screen bottom and works up */
				var b = memory.read(0x2400 + (y << 5) + x);
				for (var i = 0; i < 8; i++) {
					if (b & 0x01) {
						/* pixel set */
						pixels[pos] = pixels[pos+1] = pixels[pos+2] = 0xff;
						pixels[pos+3] = 0xff;
					} else {
						/* pixel reset */
						pixels[pos] = pixels[pos+1] = pixels[pos+2] = 0x00;
						pixels[pos+3] = 0xff;
					}
					b >>= 1;
					pos -= rowStep; /* move up one pixel row */
				}
			}
		}
		screenCtx.putImageData(imageData, 0, 0);
	}
}
