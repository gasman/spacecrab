{AF:AF, BC:BC, DE:DE, HL:HL, SP:SP, PC:PC} = Processor8080Definitions.registerPairs

# transform an opcodes-to-runstrings dictionary into a massive switch statement
opcodeSwitch = (runStringTable) ->
	clauses = []
	for opcode in [0...0x100]
		runString = runStringTable[opcode]
		if runString?
			clauses.push """
				case #{opcode}:
					#{runString}
					break;
			"""

	return """
		switch (opcode) {
			#{clauses.join('')}
			default:
				throw('unimplemented opcode: ' + opcode.toString(16));
		}
	"""


define8080JS = """
window.Processor8080 = function(memory, io) {
	var self = {};

	var registerBuffer = new ArrayBuffer(12);
	/* Expose registerBuffer as both register pairs and individual registers */
	var rp = new Uint16Array(registerBuffer);
	var r = new Uint8Array(registerBuffer);

	/* positions of flag bits within F */
	var Fz = 0x40; var Fs = 0x80; var Fp = 0x04; var Fcy = 0x01; var Fac = 0x10;

	/* Lookup table for setting the S, Z and P flags according to the results of an operation */
	var szpTable = new Uint8Array(0x100);

	for (var i = 0; i < 0x100; i++) {
		var j = i;
		var parity = 0;
		for (var k = 0; k < 8; k++) {
			parity ^= j & 1;
			j >>=1;
		}

		parityBit = (parity ? 0 : Fp);
		signBit = (i & 0x80 ? Fs : 0);
		zeroBit = (i === 0 ? Fz: 0);
		szpTable[i] = signBit | parityBit | zeroBit;
	}

	var cycle = 0;
	var interruptsEnabled = false;
	var interruptPending = false;
	var interruptOpcode;

	self.runForCycles = function(cycleCount, trace) {
		var lo, hi, result, opcode;

		while(cycle < cycleCount) {
			if (interruptPending) {
				opcode = interruptOpcode;
				interruptPending = false;
			} else {
				opcode = memory.read(rp[#{PC.p}]++);
			}

			#{opcodeSwitch(OPCODE_RUN_STRINGS)}

			if (trace) self.logState('trace');
		}
		cycle -= cycleCount;
	};

	self.interrupt = function(opcode) {
		if (interruptsEnabled) {
			interruptPending = true;
			interruptOpcode = opcode;
		}
	};

	self.logState = function(intCount) {
		console.log(intCount + ': ' + rp[#{AF.p}].toString(16) + ' ' + rp[#{BC.p}].toString(16) + ' ' + rp[#{DE.p}].toString(16) + ' ' + rp[#{HL.p}].toString(16) + ' ' + rp[#{PC.p}].toString(16) + ' ' + rp[#{SP.p}].toString(16) + ' at cycle ' + cycle);
	};

	return self;
}
"""

indirectEval = eval
indirectEval(define8080JS);
