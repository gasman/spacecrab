window.Processor8080Compiler = {
	compile: (memory, entryPoint) ->
		unvisitedAddresses = {}
		visitedAddresses = {}
		unvisitedAddresses[entryPoint] = true

		loop
			addr = null
			for a of unvisitedAddresses
				# retrieve an arbitrary address from unvisitedAddresses, if any exist
				addr = parseInt(a)
				break
			if addr == null
				# all done
				break

			delete unvisitedAddresses[addr]
			visitedAddresses[addr] = true
			#b = 
			opcode = OPCODES[memory.read(addr)]
			#console.log('opcode at ' + addr + ' is ' + b)
			destinations = opcode.destinations(memory, addr)
			#console.log(', has destinations: ' + destinations)
			for dest in destinations
				unvisitedAddresses[dest] = true unless dest of visitedAddresses

		addrs = []
		for i in [0...0x10000]
			addrs.push(i) if i of visitedAddresses
		console.log(addrs)
}
