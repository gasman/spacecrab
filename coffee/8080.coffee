{AF:AF, BC:BC, DE:DE, HL:HL, SP:SP, PC:PC} = Processor8080Definitions.registerPairs
{Fz:Fz, Fs:Fs, Fp:Fp, Fcy:Fcy, Fac:Fac} = Processor8080Definitions.flags

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

	var szpTable = Processor8080Definitions.szpTable;

	var cycle = 0;
	var interruptsEnabled = false;
	var interruptPending = false;
	var interruptOpcode;

	self.runForCycles = function(cycleCount) {
		var lo, hi, result, opcode;

		while(cycle < cycleCount) {
			if (interruptPending) {
				opcode = interruptOpcode;
				interruptPending = false;
			} else {
				opcode = memory.read(rp[#{PC.p}]++);
			}

			#{opcodeSwitch(OPCODE_RUN_STRINGS)}
		}
		cycle -= cycleCount;
	};

	self.interrupt = function(opcode) {
		if (interruptsEnabled) {
			interruptPending = true;
			interruptOpcode = opcode;
		}
	};

	self.logState = function(label) {
		console.log(label + ': ' + rp[#{AF.p}].toString(16) + ' ' + rp[#{BC.p}].toString(16) + ' ' + rp[#{DE.p}].toString(16) + ' ' + rp[#{HL.p}].toString(16) + ' ' + rp[#{PC.p}].toString(16) + ' ' + rp[#{SP.p}].toString(16) + ' at cycle ' + cycle);
	};

	return self;
}
"""

indirectEval = eval
indirectEval(define8080JS);
