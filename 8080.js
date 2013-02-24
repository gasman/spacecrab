function Processor8080(memory) {
	var self = {};

	var endianTestBuffer = new ArrayBuffer(2);
	var endianTestUint16 = new Uint16Array(endianTestBuffer);
	var endianTestUint8 = new Uint8Array(endianTestBuffer);

	endianTestUint16[0] = 0x0100;
	var isBigEndian = (endianTestUint8[0] == 0x01);

	var A, F, B, C, D, E, H, L;

	var AF = 0; var BC = 2; var DE = 4; var HL=6;
	var SP = 8; var PC = 10;

	if (isBigEndian) {
		A = 0; F = 1; B = 2; C = 3; D = 4; E = 5; H = 6; L = 7;
	} else {
		A = 1; F = 0; B = 3; C = 2; D = 5; E = 4; H = 7; L = 6;
	}

	var registerBuffer = new ArrayBuffer(12);
	/* Expose registerBuffer as both register pairs and individual registers */
	var rp = new Uint16Array(registerBuffer);
	var r = new Uint8Array(registerBuffer);

	var cycle = 0;

	self.runForCycles = function(cycleCount) {
		while(cycle < cycleCount) {
			var opcode = memory.read(rp[PC]);
			switch(opcode) {
				default:
					throw('unimplemented opcode: ' + opcode);
			}
		}
		cycle -= cycleCount;
	};

	return self;
}
