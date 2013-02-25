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
		console.log('read from port ' + port);
	};

	self.write = function(port, val) {
		console.log('write ' + val + ' to port ' + port);
	};

	return self;
}

function init() {
	var memory = Memory();
	var io = IO();
	var loadedRomCount = 0;

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
		for (var i = 0; i < 1000; i++) {
			/* run for a frame at a time, alternating between RST 08 and RST 10 as interrupt routine */
			proc.runForCycles(16667);
			proc.logState();
			proc.interrupt(0xcf); /* opcode for RST 08 */

			proc.runForCycles(16667);
			proc.logState();
			proc.interrupt(0xd7); /* opcode for RST 10 */
		}
	}
}
