function Processor8080(memory) {
	var self = {};

	var endianTestBuffer = new ArrayBuffer(2);
	var endianTestUint16 = new Uint16Array(endianTestBuffer);
	var endianTestUint8 = new Uint8Array(endianTestBuffer);

	endianTestUint16[0] = 0x0100;
	var isBigEndian = (endianTestUint8[0] == 0x01);

	var A, F, B, C, D, E, H, L, SPh, SPl, PCh, PCl;

	var AF = 0; var BC = 1; var DE = 2; var HL=3;
	var SP = 4; var PC = 5;

	if (isBigEndian) {
		A = 0; F = 1; B = 2; C = 3; D = 4; E = 5; H = 6; L = 7;
		SPh = 8; SPl = 9; PCh = 10; PCl = 11;
	} else {
		A = 1; F = 0; B = 3; C = 2; D = 5; E = 4; H = 7; L = 6;
		SPh = 9; SPl = 8; PCh = 11; PCl = 10;
	}

	var registerBuffer = new ArrayBuffer(12);
	/* Expose registerBuffer as both register pairs and individual registers */
	var rp = new Uint16Array(registerBuffer);
	var r = new Uint8Array(registerBuffer);

	var cycle = 0;

	self.runForCycles = function(cycleCount) {
		var lo, hi;

		while(cycle < cycleCount) {
			var opcode = memory.read(rp[PC]);
			console.log(rp[PC], cycle);
			switch(opcode) {
				case 0x00: /* NOP */
					rp[PC]++;
					cycle += 4;
					break;
				case 0x01: /* LXI BC,nnnn */
					r[C] = memory.read(++rp[PC]);
					r[B] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 10;
					break;
				case 0x03: /* INX BC */
					rp[BC]++;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x06: /* MVI B,nn */
					r[B] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x0a: /* LDAX BC */
					r[A] = memory.read(rp[BC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x0b: /* DCX BC */
					rp[BC]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x0e: /* MVI C,nn */
					r[C] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x11: /* LXI DE,nnnn */
					r[E] = memory.read(++rp[PC]);
					r[D] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 10;
					break;
				case 0x13: /* INX DE */
					rp[DE]++;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x16: /* MVI D,nn */
					r[D] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x1a: /* LDAX DE */
					r[A] = memory.read(rp[DE]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x1b: /* DCX DE */
					rp[DE]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x1e: /* MVI E,nn */
					r[E] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x21: /* LXI HL,nnnn */
					r[L] = memory.read(++rp[PC]);
					r[H] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 10;
					break;
				case 0x23: /* INX HL */
					rp[HL]++;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x26: /* MVI H,nn */
					r[H] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x2b: /* DCX HL */
					rp[HL]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x2e: /* MVI L,nn */
					r[L] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x31: /* LXI SP,nnnn */
					r[SPl] = memory.read(++rp[PC]);
					r[SPh] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 10;
					break;
				case 0x33: /* INX SP */
					rp[SP]++;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x3b: /* DCX SP */
					rp[SP]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x3e: /* MVI A,nn */
					r[A] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x70: /* MOV M,B */
					memory.write(rp[HL], r[B]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x71: /* MOV M,C */
					memory.write(rp[HL], r[C]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x72: /* MOV M,D */
					memory.write(rp[HL], r[D]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x73: /* MOV M,E */
					memory.write(rp[HL], r[E]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x74: /* MOV M,H */
					memory.write(rp[HL], r[H]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x75: /* MOV M,L */
					memory.write(rp[HL], r[L]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x77: /* MOV M,A */
					memory.write(rp[HL], r[A]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0xc3: /* JMP nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					r[PCh] = hi; r[PCl] = lo;
					cycle += 10;
					break;
				case 0xcd: /* CALL nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					r[PCh] = hi; r[PCl] = lo;
					cycle += 17;
					break;
				default:
					throw('unimplemented opcode: ' + opcode.toString(16));
			}
		}
		cycle -= cycleCount;
	};

	return self;
}
