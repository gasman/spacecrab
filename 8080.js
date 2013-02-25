function Processor8080(memory, io) {
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

	self.runForCycles = function(cycleCount) {
		var lo, hi, result, opcode;

		while(cycle < cycleCount) {
			if (interruptPending) {
				opcode = interruptOpcode;
				interruptPending = false;
				rp[PC]--; /* compensate for PC being incremented in the execution of a regular instruction, which shouldn't happen here */
			} else {
				opcode = memory.read(rp[PC]);
			}
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
				case 0x05: /* DCR B */
					r[B]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[B]] | ((r[B] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x06: /* MVI B,nn */
					r[B] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x07: /* RLC */
					/* copy top bit of A to carry flag */
					r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
					r[A] = (r[A] << 1) | ((r[A] & 0x80) >> 7);
					rp[PC]++;
					cycle += 4;
					break;
				case 0x09: /* DAD BC */
					result = rp[HL] + rp[BC];
					r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
					rp[HL] = result;
					rp[PC]++;
					cycle += 10;
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
				case 0x0d: /* DCR C */
					r[C]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[C]] | ((r[C] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x0e: /* MVI C,nn */
					r[C] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x0f: /* RRC */
					/* copy bottom bit of A to carry flag */
					r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
					r[A] = (r[A] >> 1) | ((r[A] & 0x01) << 7);
					rp[PC]++;
					cycle += 4;
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
				case 0x15: /* DCR D */
					r[D]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[D]] | ((r[D] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x16: /* MVI D,nn */
					r[D] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x17: /* RAL */
					result = (r[A] << 1) | (r[F] & Fcy ? 1 : 0);
					/* copy top bit of A to carry flag */
					r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
					r[A] = result;
					rp[PC]++;
					cycle += 4;
					break;
				case 0x19: /* DAD DE */
					result = rp[HL] + rp[DE];
					r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
					rp[HL] = result;
					rp[PC]++;
					cycle += 10;
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
				case 0x1d: /* DCR E */
					r[E]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[E]] | ((r[E] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x1e: /* MVI E,nn */
					r[E] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x1f: /* RAR */
					result = (r[A] >> 1) | (r[F] & Fcy ? 0x80 : 0);
					/* copy bottom bit of A to carry flag */
					r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
					r[A] = result;
					rp[PC]++;
					cycle += 4;
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
				case 0x25: /* DCR H */
					r[H]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[H]] | ((r[H] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x26: /* MVI H,nn */
					r[H] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;
				case 0x29: /* DAD HL */
					result = rp[HL] + rp[HL];
					r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
					rp[HL] = result;
					rp[PC]++;
					cycle += 10;
					break;
				case 0x2a: /* LHLD nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					result = (hi << 8) | lo;
					r[L] = memory.read(result);
					r[H] = memory.read((result + 1) & 0xffff);
					rp[PC]++;
					cycle += 16;
					break;
				case 0x2b: /* DCX HL */
					rp[HL]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x2d: /* DCR L */
					r[L]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[L]] | ((r[L] & 0x0f) == 0x0f ? Fac : 0);
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
				case 0x32: /* STA nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					memory.write((hi << 8) | lo, r[A]);
					rp[PC]++;
					cycle += 13;
					break;
				case 0x33: /* INX SP */
					rp[SP]++;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x36: /* MVI M,nn */
					memory.write(rp[HL], memory.read(++rp[PC]));
					rp[PC]++;
					cycle += 10;
					break;
				case 0x35: /* DCR M */
					result = (memory.read(rp[HL]) - 1) & 0xff;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[result] | ((result & 0x0f) == 0x0f ? Fac : 0);
					memory.write(rp[HL], result);
					rp[PC]++;
					cycle += 10;
					break;
				case 0x37: /* STC */
					r[F] |= Fcy;
					rp[PC]++;
					cycle += 4;
					break;
				case 0x39: /* DAD SP */
					result = rp[HL] + rp[SP];
					r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
					rp[HL] = result;
					rp[PC]++;
					cycle += 10;
					break;
				case 0x3a: /* LDA nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					r[A] = memory.read((hi << 8) | lo);
					rp[PC]++;
					cycle += 13;
					break;
				case 0x3b: /* DCX SP */
					rp[SP]--;
					rp[PC]++;
					cycle += 5;
					break;
				case 0x3d: /* DCR A */
					r[A]--;
					/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
					r[F] = (r[F] & Fcy) | szpTable[r[A]] | ((r[A] & 0x0f) == 0x0f ? Fac : 0);
					rp[PC]++;
					cycle += 5;
					break;
				case 0x3e: /* MVI A,nn */
					r[A] = memory.read(++rp[PC]);
					rp[PC]++;
					cycle += 7;
					break;

				case 0x40: /* MOV B,B */
					rp[PC]++; cycle += 5; break;
				case 0x41: /* MOV B,C */
					r[B] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x42: /* MOV B,D */
					r[B] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x43: /* MOV B,E */
					r[B] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x44: /* MOV B,H */
					r[B] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x45: /* MOV B,L */
					r[B] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x46: /* MOV B,M */
					r[B] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x47: /* MOV B,A */
					r[B] = r[A];
					rp[PC]++; cycle += 5; break;

				case 0x48: /* MOV C,B */
					r[C] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x49: /* MOV C,C */
					rp[PC]++; cycle += 5; break;
				case 0x4a: /* MOV C,D */
					r[C] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x4b: /* MOV C,E */
					r[C] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x4c: /* MOV C,H */
					r[C] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x4d: /* MOV C,L */
					r[C] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x4e: /* MOV C,M */
					r[C] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x4f: /* MOV C,A */
					r[C] = r[A];
					rp[PC]++; cycle += 5; break;

				case 0x50: /* MOV D,B */
					r[D] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x51: /* MOV D,C */
					r[D] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x52: /* MOV D,D */
					rp[PC]++; cycle += 5; break;
				case 0x53: /* MOV D,E */
					r[D] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x54: /* MOV D,H */
					r[D] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x55: /* MOV D,L */
					r[D] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x56: /* MOV D,M */
					r[D] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x57: /* MOV D,A */
					r[D] = r[A];
					rp[PC]++; cycle += 5; break;

				case 0x58: /* MOV E,B */
					r[E] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x59: /* MOV E,C */
					r[E] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x5a: /* MOV E,D */
					r[E] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x5b: /* MOV E,E */
					rp[PC]++; cycle += 5; break;
				case 0x5c: /* MOV E,H */
					r[E] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x5d: /* MOV E,L */
					r[E] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x5e: /* MOV E,M */
					r[E] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x5f: /* MOV E,A */
					r[E] = r[A];
					rp[PC]++; cycle += 5; break;

				case 0x60: /* MOV H,B */
					r[H] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x61: /* MOV H,C */
					r[H] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x62: /* MOV H,D */
					r[H] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x63: /* MOV H,E */
					r[H] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x64: /* MOV H,H */
					rp[PC]++; cycle += 5; break;
				case 0x65: /* MOV H,L */
					r[H] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x66: /* MOV H,M */
					r[H] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x67: /* MOV H,A */
					r[H] = r[A];
					rp[PC]++; cycle += 5; break;

				case 0x68: /* MOV L,B */
					r[L] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x69: /* MOV L,C */
					r[L] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x6a: /* MOV L,D */
					r[L] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x6b: /* MOV L,E */
					r[L] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x6c: /* MOV L,H */
					r[L] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x6d: /* MOV L,L */
					rp[PC]++; cycle += 5; break;
				case 0x6e: /* MOV L,M */
					r[L] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x6f: /* MOV L,A */
					r[L] = r[A];
					rp[PC]++; cycle += 5; break;

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

				case 0x78: /* MOV A,B */
					r[A] = r[B];
					rp[PC]++; cycle += 5; break;
				case 0x79: /* MOV A,C */
					r[A] = r[C];
					rp[PC]++; cycle += 5; break;
				case 0x7a: /* MOV A,D */
					r[A] = r[D];
					rp[PC]++; cycle += 5; break;
				case 0x7b: /* MOV A,E */
					r[A] = r[E];
					rp[PC]++; cycle += 5; break;
				case 0x7c: /* MOV A,H */
					r[A] = r[H];
					rp[PC]++; cycle += 5; break;
				case 0x7d: /* MOV A,L */
					r[A] = r[L];
					rp[PC]++; cycle += 5; break;
				case 0x7e: /* MOV A,M */
					r[A] = memory.read(rp[HL]);
					rp[PC]++; cycle += 7; break;
				case 0x7f: /* MOV A,A */
					rp[PC]++; cycle += 5; break;

				case 0x80: /* ADD B */
					result = (r[A] + r[B]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x81: /* ADD C */
					result = (r[A] + r[C]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x82: /* ADD D */
					result = (r[A] + r[D]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x83: /* ADD E */
					result = (r[A] + r[E]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x84: /* ADD H */
					result = (r[A] + r[H]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x85: /* ADD L */
					result = (r[A] + r[L]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x86: /* ADD M */
					result = (r[A] + memory.read(rp[HL])) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 7; break;
				case 0x87: /* ADD A */
					result = (r[A] + r[A]) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;

				case 0x90: /* SUB B */
					result = (r[A] - r[B]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x91: /* SUB C */
					result = (r[A] - r[C]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x92: /* SUB D */
					result = (r[A] - r[D]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x93: /* SUB E */
					result = (r[A] - r[E]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x94: /* SUB H */
					result = (r[A] - r[H]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x95: /* SUB L */
					result = (r[A] - r[L]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 4; break;
				case 0x96: /* SUB M */
					result = (r[A] - memory.read(rp[HL])) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++; cycle += 7; break;
				case 0x97: /* SUB A */
					r[F] = szpTable[0];
					r[A] = 0;
					rp[PC]++; cycle += 4; break;

				case 0xa0: /* ANA B */
					r[A] &= r[B]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa1: /* ANA C */
					r[A] &= r[C]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa2: /* ANA D */
					r[A] &= r[D]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa3: /* ANA E */
					r[A] &= r[E]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa4: /* ANA H */
					r[A] &= r[H]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa5: /* ANA L */
					r[A] &= r[L]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa6: /* ANA M */
					r[A] &= memory.read(rp[HL]); r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 7; break;
				case 0xa7: /* ANA A */
					r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;

				case 0xa8: /* XRA B */
					r[A] ^= r[B]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xa9: /* XRA C */
					r[A] ^= r[C]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xaa: /* XRA D */
					r[A] ^= r[D]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xab: /* XRA E */
					r[A] ^= r[E]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xac: /* XRA H */
					r[A] ^= r[H]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xad: /* XRA L */
					r[A] ^= r[L]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xae: /* XRA M */
					r[A] ^= memory.read(rp[HL]); r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 7; break;
				case 0xaf: /* XRA A */
					r[A] = 0; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;

				case 0xb0: /* ORA B */
					r[A] |= r[B]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb1: /* ORA C */
					r[A] |= r[C]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb2: /* ORA D */
					r[A] |= r[D]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb3: /* ORA E */
					r[A] |= r[E]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb4: /* ORA H */
					r[A] |= r[H]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb5: /* ORA L */
					r[A] |= r[L]; r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;
				case 0xb6: /* ORA M */
					r[A] |= memory.read(rp[HL]); r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 7; break;
				case 0xb7: /* ORA A */
					r[F] = szpTable[r[A]];
					rp[PC]++; cycle += 4; break;

				case 0xb8: /* CMP B */
					result = (r[A] - r[B]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xb9: /* CMP C */
					result = (r[A] - r[C]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xba: /* CMP D */
					result = (r[A] - r[D]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xbb: /* CMP E */
					result = (r[A] - r[E]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xbc: /* CMP H */
					result = (r[A] - r[H]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xbd: /* CMP L */
					result = (r[A] - r[L]) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 4;
					break;
				case 0xbe: /* CMP M */
					result = (r[A] - memory.read(rp[HL])) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 7;
					break;
				case 0xbf: /* CMP A */
					r[F] = szpTable[0];
					rp[PC]++;
					cycle += 4;
					break;
				case 0xc0: /* RNZ */
					if (r[F] & Fz) {
						/* Z is set, so stay */
						rp[PC]++;
						cycle += 5;
					} else {
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					}
					break;
				case 0xc1: /* POP BC */
					r[C] = memory.read(rp[SP]++);
					r[B] = memory.read(rp[SP]++);
					rp[PC]++;
					cycle += 10;
					break;
				case 0xc2: /* JNZ nnnn */
					if (r[F] & Fz) {
						/* Z is set, so stay */
						rp[PC] += 3;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					}
					cycle += 10;
					break;
				case 0xc3: /* JMP nnnn */
					lo = memory.read(++rp[PC]);
					hi = memory.read(++rp[PC]);
					r[PCh] = hi; r[PCl] = lo;
					cycle += 10;
					break;
				case 0xc4: /* CNZ nnnn */
					if (r[F] & Fz) {
						/* Z is set, so stay */
						rp[PC] += 3;
						cycle += 11;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					}
					break;
				case 0xc5: /* PUSH BC */
					memory.write(--rp[SP], r[B]);
					memory.write(--rp[SP], r[C]);
					rp[PC]++;
					cycle += 11;
					break;
				case 0xc6: /* ADI nn */
					result = (r[A] + memory.read(++rp[PC])) & 0xff;
					r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++;
					cycle += 7;
					break;
				case 0xc7: /* RST 00 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0000;
					cycle += 11;
					break;
				case 0xc8: /* RZ */
					if (r[F] & Fz) {
						/* Z is set, so return */
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					} else {
						rp[PC]++;
						cycle += 5;
					}
					break;
				case 0xc9: /* RET */
					r[PCl] = memory.read(rp[SP]++);
					r[PCh] = memory.read(rp[SP]++);
					cycle += 10;
					break;
				case 0xca: /* JZ nnnn */
					if (r[F] & Fz) {
						/* Z is set, so jump */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					} else {
						rp[PC] += 3;
					}
					cycle += 10;
					break;
				case 0xcc: /* CZ nnnn */
					if (r[F] & Fz) {
						/* Z is set, so call */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					} else {
						rp[PC] += 3;
						cycle += 11;
					}
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
				case 0xcf: /* RST 08 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0008;
					cycle += 11;
					break;
				case 0xd0: /* RNC */
					if (r[F] & Fcy) {
						/* Cy is set, so stay */
						rp[PC]++;
						cycle += 5;
					} else {
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					}
					break;
				case 0xd1: /* POP DE */
					r[E] = memory.read(rp[SP]++);
					r[D] = memory.read(rp[SP]++);
					rp[PC]++;
					cycle += 10;
					break;
				case 0xd2: /* JNC nnnn */
					if (r[F] & Fcy) {
						/* Cy is set, so stay */
						rp[PC] += 3;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					}
					cycle += 10;
					break;
				case 0xd3: /* OUT nn */
					io.write(memory.read(++rp[PC]), r[A]);
					rp[PC]++;
					cycle += 10;
					break;
				case 0xd4: /* CNC nnnn */
					if (r[F] & Fcy) {
						/* Cy is set, so stay */
						rp[PC] += 3;
						cycle += 11;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					}
					break;
				case 0xd5: /* PUSH DE */
					memory.write(--rp[SP], r[D]);
					memory.write(--rp[SP], r[E]);
					rp[PC]++;
					cycle += 11;
					break;
				case 0xd6: /* SUI nn */
					result = (r[A] - memory.read(++rp[PC])) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					r[A] = result;
					rp[PC]++;
					cycle += 7;
					break;
				case 0xd7: /* RST 10 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0010;
					cycle += 11;
					break;
				case 0xd8: /* RC */
					if (r[F] & Fcy) {
						/* Cy is set, so return */
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					} else {
						rp[PC]++;
						cycle += 5;
					}
					break;
				case 0xda: /* JC nnnn */
					if (r[F] & Fcy) {
						/* Cy is set, so jump */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					} else {
						rp[PC] += 3;
					}
					cycle += 10;
					break;
				case 0xdb: /* IN nn */
					r[A] = io.read(memory.read(++rp[PC]));
					rp[PC]++;
					cycle += 10;
					break;
				case 0xdc: /* CC nnnn */
					if (r[F] & Fcy) {
						/* Cy is set, so call */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					} else {
						rp[PC] += 3;
						cycle += 11;
					}
					break;
				case 0xdf: /* RST 18 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0018;
					cycle += 11;
					break;
				case 0xe0: /* RPO */
					if (r[F] & Fp) {
						/* P is set, so stay */
						rp[PC]++;
						cycle += 5;
					} else {
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					}
					break;
				case 0xe1: /* POP HL */
					r[L] = memory.read(rp[SP]++);
					r[H] = memory.read(rp[SP]++);
					rp[PC]++;
					cycle += 10;
					break;
				case 0xe2: /* JPO nnnn */
					if (r[F] & Fp) {
						/* P is set, so stay */
						rp[PC] += 3;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					}
					cycle += 10;
					break;
				case 0xe3: /* XTHL */
					lo = memory.read(rp[SP]);
					hi = memory.read(rp[SP] + 1);
					memory.write(rp[SP], r[L]);
					memory.write(rp[SP] + 1, r[H]);
					r[L] = lo; r[H] = hi;
					rp[PC]++;
					cycle += 18;
					break;
				case 0xe4: /* CPO nnnn */
					if (r[F] & Fp) {
						/* P is set, so stay */
						rp[PC] += 3;
						cycle += 11;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					}
					break;
				case 0xe5: /* PUSH HL */
					memory.write(--rp[SP], r[H]);
					memory.write(--rp[SP], r[L]);
					rp[PC]++;
					cycle += 11;
					break;
				case 0xe6: /* ANI nn */
					r[A] &= memory.read(++rp[PC]);
					r[F] = szpTable[r[A]];
					rp[PC]++;
					cycle += 7;
					break;
				case 0xe7: /* RST 20 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0020;
					cycle += 11;
					break;
				case 0xe8: /* RPE */
					if (r[F] & Fp) {
						/* P is set, so return */
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					} else {
						rp[PC]++;
						cycle += 5;
					}
					break;
				case 0xe9: /* PCHL */
					rp[PC] = rp[HL];
					cycle += 5;
					break;
				case 0xea: /* JPE nnnn */
					if (r[F] & Fp) {
						/* P is set, so jump */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					} else {
						rp[PC] += 3;
					}
					cycle += 10;
					break;
				case 0xeb: /* XCHG */
					result = rp[HL];
					rp[HL] = rp[DE];
					rp[DE] = result;
					rp[PC]++;
					cycle += 5;
					break;
				case 0xec: /* CPE nnnn */
					if (r[F] & Fp) {
						/* P is set, so call */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					} else {
						rp[PC] += 3;
						cycle += 11;
					}
					break;
				case 0xee: /* XRI nn */
					r[A] ^= memory.read(++rp[PC]);
					r[F] = szpTable[r[A]];
					rp[PC]++;
					cycle += 7;
					break;
				case 0xef: /* RST 28 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0028;
					cycle += 11;
					break;
				case 0xf0: /* RP */
					if (r[F] & Fs) {
						/* S is set, so stay */
						rp[PC]++;
						cycle += 5;
					} else {
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					}
					break;
				case 0xf1: /* POP PSW */
					r[F] = memory.read(rp[SP]++);
					r[A] = memory.read(rp[SP]++);
					rp[PC]++;
					cycle += 10;
					break;
				case 0xf2: /* JP nnnn */
					if (r[F] & Fs) {
						/* S is set, so stay */
						rp[PC] += 3;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					}
					cycle += 10;
					break;
				case 0xf3: /* DI */
					interruptsEnabled = false;
					rp[PC] += 1;
					cycle += 4;
					break;
				case 0xf4: /* CP nnnn */
					if (r[F] & Fs) {
						/* S is set, so stay */
						rp[PC] += 3;
						cycle += 11;
					} else {
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					}
					break;
				case 0xf5: /* PUSH PSW */
					memory.write(--rp[SP], r[A]);
					memory.write(--rp[SP], r[F]);
					rp[PC]++;
					cycle += 11;
					break;
				case 0xf6: /* ORI nn */
					r[A] |= memory.read(++rp[PC]);
					r[F] = szpTable[r[A]];
					rp[PC]++;
					cycle += 7;
					break;
				case 0xf7: /* RST 30 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0030;
					cycle += 11;
					break;
				case 0xf8: /* RM */
					if (r[F] & Fs) {
						/* S is set, so return */
						r[PCl] = memory.read(rp[SP]++);
						r[PCh] = memory.read(rp[SP]++);
						cycle += 11;
					} else {
						rp[PC]++;
						cycle += 5;
					}
					break;
				case 0xfa: /* JC nnnn */
					if (r[F] & Fs) {
						/* S is set, so jump */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						r[PCh] = hi; r[PCl] = lo;
					} else {
						rp[PC] += 3;
					}
					cycle += 10;
					break;
				case 0xfb: /* EI */
					interruptsEnabled = true;
					rp[PC] += 1;
					cycle += 4;
					break;
				case 0xfc: /* CM nnnn */
					if (r[F] & Fs) {
						/* S is set, so call */
						lo = memory.read(++rp[PC]);
						hi = memory.read(++rp[PC]);
						rp[PC]++;
						memory.write(--rp[SP], r[PCh]);
						memory.write(--rp[SP], r[PCl]);
						r[PCh] = hi; r[PCl] = lo;
						cycle += 17;
					} else {
						rp[PC] += 3;
						cycle += 11;
					}
					break;
				case 0xfe: /* CPI nn */
					result = (r[A] - memory.read(++rp[PC])) & 0xff;
					r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
					rp[PC]++;
					cycle += 7;
					break;
				case 0xff: /* RST 38 */
					rp[PC]++;
					memory.write(--rp[SP], r[PCh]);
					memory.write(--rp[SP], r[PCl]);
					rp[PC] = 0x0038;
					cycle += 11;
					break;
				default:
					throw('unimplemented opcode: ' + opcode.toString(16));
			}
		}
		cycle -= cycleCount;
	};

	self.interrupt = function(opcode) {
		if (interruptsEnabled) {
			interruptPending = true;
			interruptOpcode = opcode;
		}
	};

	self.logState = function() {
		console.log(rp[AF].toString(16) + ' ' + rp[BC].toString(16) + ' ' + rp[DE].toString(16) + ' ' + rp[HL].toString(16) + ' ' + rp[PC].toString(16) + ' ' + rp[SP].toString(16) + ' at cycle ' + cycle);
	};

	return self;
}
