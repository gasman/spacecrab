# helper for loading a file over HTTP as an arraybuffer
loadFromUrl = (url, callback) ->
	request = new XMLHttpRequest()

	request.addEventListener('error',
		(e) -> throw('Error loading from URL: ' + url),
		false);

	request.addEventListener('load',
		(e) ->
			if (request.status == 200)
				callback(request.response);
			else
				throw('Error loading from URL: ' + url)
		, false);

	# trigger XHR
	request.open('GET', url, true)
	request.responseType = "arraybuffer"
	request.send()

Memory = () ->
	self = {}
	mem = new Uint8Array(0x4000)

	self.loadPage = (addr, data) ->
		bytes = new Uint8Array(data)
		for byte, i in bytes
			mem[addr + i] = bytes[i]

	self.read = (addr) ->
		mem[addr & 0x3fff]

	self.write = (addr, val) ->
		# only write to RAM area (0x2000-0x3fff)
		if addr & 0x2000
			mem[addr & 0x3fff] = val

	self.dump = () ->
		console.log(mem)

	return self

IO = () ->
	self = {}

	port2 = 0
	port4hi = 0
	port4lo = 0

	port1 = 0
	port2in = 0

	window.addEventListener('keydown', (e) ->
		switch e.which
			when 49  # '1' = 1 player
				port1 |= 0x04
			when 50  # '2' = 2 player
				port1 |= 0x02
			when 190  # '.' = fire
				port1 |= 0x10
				port2in |= 0x10
			when 90  # 'z' = left
				port1 |= 0x20
				port2in |= 0x20
			when 88  # 'x' = right
				port1 |= 0x40
				port2in |= 0x40
	)

	window.addEventListener('keyup', (e) ->
		switch e.which
			when 49  # '1' = 1 player
				port1 &= ~0x04
			when 50  # '2' = 2 player
				port1 &= ~0x02;
			when 67
				port1 |= 0x01  # register 'insert coin'
			when 190  # '.' = fire
				port1 &= ~0x10
				port2in &= ~0x10
			when 90  # 'z' = left
				port1 &= ~0x20
				port2in &= ~0x20
			when 88  # 'x' = right
				port1 &= ~0x40
				port2in &= ~0x40
	)

	self.read = (port) ->
		switch port
			when 1
				result = port1;
				port1 &= 0xfe  # clear 'insert coin' state
				return result
			when 2
				return port2in
			when 3
				port4 = (port4hi << 8) | port4lo
				return ((port4 << port2) >> 8) & 0xff
			else
				return 0

	self.write = (port, val) ->
		switch port
			when 2
				port2 = val
			when 4
				port4lo = port4hi
				port4hi = val

	return self


window.init = () ->
	memory = Memory()
	io = IO()
	loadedRomCount = 0
	screenCanvas = document.getElementById('screen')
	screenCtx = screenCanvas.getContext('2d')
	imageData = screenCtx.createImageData(224, 256)
	pixels = imageData.data
	proc = null

	loadRom = (url, addr) ->
		loadFromUrl(url, (data) ->
			memory.loadPage(addr, data)
			loadedRomCount++
			if loadedRomCount == 4
				allRomsLoaded()
		)

	loadRom('roms/invaders.h', 0x0000)
	loadRom('roms/invaders.g', 0x0800)
	loadRom('roms/invaders.f', 0x1000)
	loadRom('roms/invaders.e', 0x1800)

	allRomsLoaded = () ->
		proc = Processor8080(memory, io)
		runFrame()

	runFrame = () ->
		proc.runForCycles(16667)
		proc.interrupt(0xcf)  # opcode for RST 08
		proc.runForCycles(16667)
		proc.interrupt(0xd7)  # opcode for RST 10
		drawScreen()
		setTimeout(runFrame, 17)  # 60 Hz, ish

	drawScreen = () ->
		rowStep = 224 * 4  # number of bytes in one image row

		for y in [0...224]  # screen is rotated, so y actually iterates over the columns from left to right
			pos = (rowStep * 255) + (y << 2)  # index of the bottom pixel in this column
			for x in [0...32]  # x starts at the screen bottom and works up
				b = memory.read(0x2400 + (y << 5) + x)
				for i in [0...8]
					if b & 0x01
						# pixel set
						pixels[pos] = pixels[pos+1] = pixels[pos+2] = 0xff
						pixels[pos+3] = 0xff
					else
						# pixel reset
						pixels[pos] = pixels[pos+1] = pixels[pos+2] = 0x00
						pixels[pos+3] = 0xff

					b >>= 1
					pos -= rowStep  # move up one pixel row

		screenCtx.putImageData(imageData, 0, 0)
