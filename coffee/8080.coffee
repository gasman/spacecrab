# A mapping from opcodes to Javascript strings that perform them
OPCODE_RUN_STRINGS = {
	# NOP
	0x00: """
		rp[PC]++;
		cycle += 4;
	"""
	# LXI BC,nnnn
	0x01: """
		r[C] = memory.read(++rp[PC]);
		r[B] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 10;
	"""
	# STAX BC
	0x02: """
		memory.write(rp[BC], r[A]);
		rp[PC]++;
		cycle += 7;
	"""
	# INX BC
	0x03: """
		rp[BC]++;
		rp[PC]++;
		cycle += 5;
	"""
	# INR B
	0x04: """
		r[B]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[B]] | ((r[B] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR B
	0x05: """
		r[B]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[B]] | ((r[B] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI B,nn
	0x06: """
		r[B] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# RLC
	0x07: """
		/* copy top bit of A to carry flag */
		r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
		r[A] = (r[A] << 1) | ((r[A] & 0x80) >> 7);
		rp[PC]++;
		cycle += 4;
	"""
	# DAD BC
	0x09: """
		result = rp[HL] + rp[BC];
		r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
		rp[HL] = result;
		rp[PC]++;
		cycle += 10;
	"""
	# LDAX BC
	0x0a: """
		r[A] = memory.read(rp[BC]);
		rp[PC]++;
		cycle += 7;
	"""
	# DCX BC
	0x0b: """
		rp[BC]--;
		rp[PC]++;
		cycle += 5;
	"""
	# INR C
	0x0c: """
		r[C]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[C]] | ((r[C] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR C
	0x0d: """
		r[C]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[C]] | ((r[C] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI C,nn
	0x0e: """
		r[C] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# RRC
	0x0f: """
		/* copy bottom bit of A to carry flag */
		r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
		r[A] = (r[A] >> 1) | ((r[A] & 0x01) << 7);
		rp[PC]++;
		cycle += 4;
	"""
	# LXI DE,nnnn
	0x11: """
		r[E] = memory.read(++rp[PC]);
		r[D] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 10;
	"""
	# STAX DE
	0x12: """
		memory.write(rp[DE], r[A]);
		rp[PC]++;
		cycle += 7;
	"""
	# INX DE
	0x13: """
		rp[DE]++;
		rp[PC]++;
		cycle += 5;
	"""
	# INR D
	0x14: """
		r[D]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[D]] | ((r[D] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR D
	0x15: """
		r[D]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[D]] | ((r[D] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI D,nn
	0x16: """
		r[D] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# RAL
	0x17: """
		result = (r[A] << 1) | (r[F] & Fcy ? 1 : 0);
		/* copy top bit of A to carry flag */
		r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
		r[A] = result;
		rp[PC]++;
		cycle += 4;
	"""
	# DAD DE
	0x19: """
		result = rp[HL] + rp[DE];
		r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
		rp[HL] = result;
		rp[PC]++;
		cycle += 10;
	"""
	# LDAX DE
	0x1a: """
		r[A] = memory.read(rp[DE]);
		rp[PC]++;
		cycle += 7;
	"""
	# DCX DE
	0x1b: """
		rp[DE]--;
		rp[PC]++;
		cycle += 5;
	"""
	# INR E
	0x1c: """
		r[E]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[E]] | ((r[E] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR E
	0x1d: """
		r[E]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[E]] | ((r[E] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI E,nn
	0x1e: """
		r[E] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# RAR
	0x1f: """
		result = (r[A] >> 1) | (r[F] & Fcy ? 0x80 : 0);
		/* copy bottom bit of A to carry flag */
		r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
		r[A] = result;
		rp[PC]++;
		cycle += 4;
	"""
	# LXI HL,nnnn
	0x21: """
		r[L] = memory.read(++rp[PC]);
		r[H] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 10;
	"""
	# SHLD nnnn
	0x22: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		result = (hi << 8) | lo;
		memory.write(result, r[L]);
		memory.write((result + 1) & 0xffff, r[H]);
		rp[PC]++;
		cycle += 16;
	"""
	# INX HL
	0x23: """
		rp[HL]++;
		rp[PC]++;
		cycle += 5;
	"""
	# INR H
	0x24: """
		r[H]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[H]] | ((r[H] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR H
	0x25: """
		r[H]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[H]] | ((r[H] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI H,nn
	0x26: """
		r[H] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# DAA
	0x27: """
		var newF = 0;
		if (((r[A] & 0x0f) > 0x09) || (r[F] & Fac)) {
			/* add 6 to A; set AC if this causes overflow from bit 3 (i.e. bottom four bits are >= A) */
			newF |= ((r[A] & 0x0f) >= 0x0a) ? Fac : 0;
			r[A] += 0x06;
		}
		if (((r[A] & 0xf0) > 0x90) || (r[F] & Fcy)) {
			newF |= ((r[A] & 0xf0) >= 0xa0) ? Fcy : 0;
			r[A] += 0x60;
		}
		r[F] = newF | szpTable[r[A]];
		rp[PC]++;
		cycle += 4;
	"""
	# DAD HL
	0x29: """
		result = rp[HL] + rp[HL];
		r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
		rp[HL] = result;
		rp[PC]++;
		cycle += 10;
	"""
	# LHLD nnnn
	0x2a: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		result = (hi << 8) | lo;
		r[L] = memory.read(result);
		r[H] = memory.read((result + 1) & 0xffff);
		rp[PC]++;
		cycle += 16;
	"""
	# DCX HL
	0x2b: """
		rp[HL]--;
		rp[PC]++;
		cycle += 5;
	"""
	# INR L
	0x2c: """
		r[L]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[L]] | ((r[L] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR L
	0x2d: """
		r[L]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[L]] | ((r[L] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI L,nn
	0x2e: """
		r[L] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# CMA
	0x2f: """
		r[A] = ~r[A];
		rp[PC]++;
		cycle += 4;
	"""
	# LXI SP,nnnn
	0x31: """
		r[SPl] = memory.read(++rp[PC]);
		r[SPh] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 10;
	"""
	# STA nnnn
	0x32: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		memory.write((hi << 8) | lo, r[A]);
		rp[PC]++;
		cycle += 13;
	"""
	# INX SP
	0x33: """
		rp[SP]++;
		rp[PC]++;
		cycle += 5;
	"""
	# INR M
	0x34: """
		result = (memory.read(rp[HL]) + 1) & 0xff;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[result] | ((result & 0x0f) ? 0 : Fac);
		memory.write(rp[HL], result);
		rp[PC]++;
		cycle += 10;
	"""
	# DCR M
	0x35: """
		result = (memory.read(rp[HL]) - 1) & 0xff;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[result] | ((result & 0x0f) == 0x0f ? Fac : 0);
		memory.write(rp[HL], result);
		rp[PC]++;
		cycle += 10;
	"""
	# MVI M,nn
	0x36: """
		memory.write(rp[HL], memory.read(++rp[PC]));
		rp[PC]++;
		cycle += 10;
	"""
	# STC
	0x37: """
		r[F] |= Fcy;
		rp[PC]++;
		cycle += 4;
	"""
	# DAD SP
	0x39: """
		result = rp[HL] + rp[SP];
		r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
		rp[HL] = result;
		rp[PC]++;
		cycle += 10;
	"""
	# LDA nnnn
	0x3a: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		r[A] = memory.read((hi << 8) | lo);
		rp[PC]++;
		cycle += 13;
	"""
	# DCX SP
	0x3b: """
		rp[SP]--;
		rp[PC]++;
		cycle += 5;
	"""
	# INR A
	0x3c: """
		r[A]++;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
		r[F] = (r[F] & Fcy) | szpTable[r[A]] | ((r[A] & 0x0f) ? 0 : Fac);
		rp[PC]++;
		cycle += 5;
	"""
	# DCR A
	0x3d: """
		r[A]--;
		/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
		r[F] = (r[F] & Fcy) | szpTable[r[A]] | ((r[A] & 0x0f) == 0x0f ? Fac : 0);
		rp[PC]++;
		cycle += 5;
	"""
	# MVI A,nn
	0x3e: """
		r[A] = memory.read(++rp[PC]);
		rp[PC]++;
		cycle += 7;
	"""
	# CMC
	0x3f: """
		r[F] ^= (r[F] & Fcy);
		rp[PC]++;
		cycle += 4;

	"""
	# MOV B,B
	0x40: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,C
	0x41: """
		r[B] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,D
	0x42: """
		r[B] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,E
	0x43: """
		r[B] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,H
	0x44: """
		r[B] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,L
	0x45: """
		r[B] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV B,M
	0x46: """
		r[B] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV B,A
	0x47: """
		r[B] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV C,B
	0x48: """
		r[C] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,C
	0x49: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,D
	0x4a: """
		r[C] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,E
	0x4b: """
		r[C] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,H
	0x4c: """
		r[C] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,L
	0x4d: """
		r[C] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV C,M
	0x4e: """
		r[C] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV C,A
	0x4f: """
		r[C] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV D,B
	0x50: """
		r[D] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,C
	0x51: """
		r[D] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,D
	0x52: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,E
	0x53: """
		r[D] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,H
	0x54: """
		r[D] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,L
	0x55: """
		r[D] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV D,M
	0x56: """
		r[D] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV D,A
	0x57: """
		r[D] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV E,B
	0x58: """
		r[E] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,C
	0x59: """
		r[E] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,D
	0x5a: """
		r[E] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,E
	0x5b: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,H
	0x5c: """
		r[E] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,L
	0x5d: """
		r[E] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV E,M
	0x5e: """
		r[E] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV E,A
	0x5f: """
		r[E] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV H,B
	0x60: """
		r[H] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,C
	0x61: """
		r[H] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,D
	0x62: """
		r[H] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,E
	0x63: """
		r[H] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,H
	0x64: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,L
	0x65: """
		r[H] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV H,M
	0x66: """
		r[H] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV H,A
	0x67: """
		r[H] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV L,B
	0x68: """
		r[L] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,C
	0x69: """
		r[L] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,D
	0x6a: """
		r[L] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,E
	0x6b: """
		r[L] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,H
	0x6c: """
		r[L] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,L
	0x6d: """
		rp[PC]++; cycle += 5; break;
	"""
	# MOV L,M
	0x6e: """
		r[L] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV L,A
	0x6f: """
		r[L] = r[A];
		rp[PC]++; cycle += 5; break;

	"""
	# MOV M,B
	0x70: """
		memory.write(rp[HL], r[B]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,C
	0x71: """
		memory.write(rp[HL], r[C]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,D
	0x72: """
		memory.write(rp[HL], r[D]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,E
	0x73: """
		memory.write(rp[HL], r[E]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,H
	0x74: """
		memory.write(rp[HL], r[H]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,L
	0x75: """
		memory.write(rp[HL], r[L]);
		rp[PC]++;
		cycle += 7;
	"""
	# MOV M,A
	0x77: """
		memory.write(rp[HL], r[A]);
		rp[PC]++;
		cycle += 7;

	"""
	# MOV A,B
	0x78: """
		r[A] = r[B];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,C
	0x79: """
		r[A] = r[C];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,D
	0x7a: """
		r[A] = r[D];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,E
	0x7b: """
		r[A] = r[E];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,H
	0x7c: """
		r[A] = r[H];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,L
	0x7d: """
		r[A] = r[L];
		rp[PC]++; cycle += 5; break;
	"""
	# MOV A,M
	0x7e: """
		r[A] = memory.read(rp[HL]);
		rp[PC]++; cycle += 7; break;
	"""
	# MOV A,A
	0x7f: """
		rp[PC]++; cycle += 5; break;

	"""
	# ADD B
	0x80: """
		result = (r[A] + r[B]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD C
	0x81: """
		result = (r[A] + r[C]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD D
	0x82: """
		result = (r[A] + r[D]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD E
	0x83: """
		result = (r[A] + r[E]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD H
	0x84: """
		result = (r[A] + r[H]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD L
	0x85: """
		result = (r[A] + r[L]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADD M
	0x86: """
		result = (r[A] + memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7; break;
	"""
	# ADD A
	0x87: """
		result = (r[A] + r[A]) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;

	"""
	# ADC B
	0x88: """
		result = (r[A] + r[B] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC C
	0x89: """
		result = (r[A] + r[C] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC D
	0x8a: """
		result = (r[A] + r[D] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC E
	0x8b: """
		result = (r[A] + r[E] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC H
	0x8c: """
		result = (r[A] + r[H] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC L
	0x8d: """
		result = (r[A] + r[L] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# ADC M
	0x8e: """
		result = (r[A] + memory.read(rp[HL]) + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7; break;
	"""
	# ADC A
	0x8f: """
		result = (r[A] + r[A] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;

	"""
	# SUB B
	0x90: """
		result = (r[A] - r[B]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB C
	0x91: """
		result = (r[A] - r[C]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB D
	0x92: """
		result = (r[A] - r[D]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB E
	0x93: """
		result = (r[A] - r[E]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB H
	0x94: """
		result = (r[A] - r[H]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB L
	0x95: """
		result = (r[A] - r[L]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SUB M
	0x96: """
		result = (r[A] - memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7; break;
	"""
	# SUB A
	0x97: """
		r[F] = szpTable[0];
		r[A] = 0;
		rp[PC]++; cycle += 4; break;

	"""
	# SBB B
	0x98: """
		result = (r[A] - r[B] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB C
	0x99: """
		result = (r[A] - r[C] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB D
	0x9a: """
		result = (r[A] - r[D] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB E
	0x9b: """
		result = (r[A] - r[E] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB H
	0x9c: """
		result = (r[A] - r[H] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB L
	0x9d: """
		result = (r[A] - r[L] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;
	"""
	# SBB M
	0x9e: """
		result = (r[A] - memory.read(rp[HL]) - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7; break;
	"""
	# SBB A
	0x9f: """
		result = (r[F] & Fcy) ? 0xff : 0;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 4; break;

	"""
	# ANA B
	0xa0: """
		r[A] &= r[B]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA C
	0xa1: """
		r[A] &= r[C]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA D
	0xa2: """
		r[A] &= r[D]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA E
	0xa3: """
		r[A] &= r[E]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA H
	0xa4: """
		r[A] &= r[H]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA L
	0xa5: """
		r[A] &= r[L]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ANA M
	0xa6: """
		r[A] &= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	# ANA A
	0xa7: """
		r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;

	"""
	# XRA B
	0xa8: """
		r[A] ^= r[B]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA C
	0xa9: """
		r[A] ^= r[C]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA D
	0xaa: """
		r[A] ^= r[D]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA E
	0xab: """
		r[A] ^= r[E]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA H
	0xac: """
		r[A] ^= r[H]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA L
	0xad: """
		r[A] ^= r[L]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# XRA M
	0xae: """
		r[A] ^= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	# XRA A
	0xaf: """
		r[A] = 0; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;

	"""
	# ORA B
	0xb0: """
		r[A] |= r[B]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA C
	0xb1: """
		r[A] |= r[C]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA D
	0xb2: """
		r[A] |= r[D]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA E
	0xb3: """
		r[A] |= r[E]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA H
	0xb4: """
		r[A] |= r[H]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA L
	0xb5: """
		r[A] |= r[L]; r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;
	"""
	# ORA M
	0xb6: """
		r[A] |= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	# ORA A
	0xb7: """
		r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 4; break;

	"""
	# CMP B
	0xb8: """
		result = (r[A] - r[B]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP C
	0xb9: """
		result = (r[A] - r[C]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP D
	0xba: """
		result = (r[A] - r[D]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP E
	0xbb: """
		result = (r[A] - r[E]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP H
	0xbc: """
		result = (r[A] - r[H]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP L
	0xbd: """
		result = (r[A] - r[L]) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 4;
	"""
	# CMP M
	0xbe: """
		result = (r[A] - memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 7;
	"""
	# CMP A
	0xbf: """
		r[F] = szpTable[0];
		rp[PC]++;
		cycle += 4;
	"""
	# RNZ
	0xc0: """
		if (r[F] & Fz) {
			/* Z is set, so stay */
			rp[PC]++;
			cycle += 5;
		} else {
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		}
	"""
	# POP BC
	0xc1: """
		r[C] = memory.read(rp[SP]++);
		r[B] = memory.read(rp[SP]++);
		rp[PC]++;
		cycle += 10;
	"""
	# JNZ nnnn
	0xc2: """
		if (r[F] & Fz) {
			/* Z is set, so stay */
			rp[PC] += 3;
		} else {
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		}
		cycle += 10;
	"""
	# JMP nnnn
	0xc3: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		r[PCh] = hi; r[PCl] = lo;
		cycle += 10;
	"""
	# CNZ nnnn
	0xc4: """
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
	"""
	# PUSH BC
	0xc5: """
		memory.write(--rp[SP], r[B]);
		memory.write(--rp[SP], r[C]);
		rp[PC]++;
		cycle += 11;
	"""
	# ADI nn
	0xc6: """
		result = (r[A] + memory.read(++rp[PC])) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++;
		cycle += 7;
	"""
	# RST 00
	0xc7: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0000;
		cycle += 11;
	"""
	# RZ
	0xc8: """
		if (r[F] & Fz) {
			/* Z is set, so return */
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		} else {
			rp[PC]++;
			cycle += 5;
		}
	"""
	# RET
	0xc9: """
		r[PCl] = memory.read(rp[SP]++);
		r[PCh] = memory.read(rp[SP]++);
		cycle += 10;
	"""
	# JZ nnnn
	0xca: """
		if (r[F] & Fz) {
			/* Z is set, so jump */
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		} else {
			rp[PC] += 3;
		}
		cycle += 10;
	"""
	# CZ nnnn
	0xcc: """
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
	"""
	# CALL nnnn
	0xcd: """
		lo = memory.read(++rp[PC]);
		hi = memory.read(++rp[PC]);
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		r[PCh] = hi; r[PCl] = lo;
		cycle += 17;
	"""
	# ACI nn
	0xce: """
		result = (r[A] + memory.read(++rp[PC]) + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7; break;
	"""
	# RST 08
	0xcf: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0008;
		cycle += 11;
	"""
	# RNC
	0xd0: """
		if (r[F] & Fcy) {
			/* Cy is set, so stay */
			rp[PC]++;
			cycle += 5;
		} else {
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		}
	"""
	# POP DE
	0xd1: """
		r[E] = memory.read(rp[SP]++);
		r[D] = memory.read(rp[SP]++);
		rp[PC]++;
		cycle += 10;
	"""
	# JNC nnnn
	0xd2: """
		if (r[F] & Fcy) {
			/* Cy is set, so stay */
			rp[PC] += 3;
		} else {
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		}
		cycle += 10;
	"""
	# OUT nn
	0xd3: """
		io.write(memory.read(++rp[PC]), r[A]);
		rp[PC]++;
		cycle += 10;
	"""
	# CNC nnnn
	0xd4: """
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
	"""
	# PUSH DE
	0xd5: """
		memory.write(--rp[SP], r[D]);
		memory.write(--rp[SP], r[E]);
		rp[PC]++;
		cycle += 11;
	"""
	# SUI nn
	0xd6: """
		result = (r[A] - memory.read(++rp[PC])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++;
		cycle += 7;
	"""
	# RST 10
	0xd7: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0010;
		cycle += 11;
	"""
	# RC
	0xd8: """
		if (r[F] & Fcy) {
			/* Cy is set, so return */
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		} else {
			rp[PC]++;
			cycle += 5;
		}
	"""
	# JC nnnn
	0xda: """
		if (r[F] & Fcy) {
			/* Cy is set, so jump */
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		} else {
			rp[PC] += 3;
		}
		cycle += 10;
	"""
	# IN nn
	0xdb: """
		r[A] = io.read(memory.read(++rp[PC]));
		rp[PC]++;
		cycle += 10;
	"""
	# CC nnnn
	0xdc: """
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
	"""
	# SBI nn
	0xde: """
		result = (r[A] - memory.read(++rp[PC]) - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++;
		cycle += 7;
	"""
	# RST 18
	0xdf: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0018;
		cycle += 11;
	"""
	# RPO
	0xe0: """
		if (r[F] & Fp) {
			/* P is set, so stay */
			rp[PC]++;
			cycle += 5;
		} else {
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		}
	"""
	# POP HL
	0xe1: """
		r[L] = memory.read(rp[SP]++);
		r[H] = memory.read(rp[SP]++);
		rp[PC]++;
		cycle += 10;
	"""
	# JPO nnnn
	0xe2: """
		if (r[F] & Fp) {
			/* P is set, so stay */
			rp[PC] += 3;
		} else {
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		}
		cycle += 10;
	"""
	# XTHL
	0xe3: """
		lo = memory.read(rp[SP]);
		hi = memory.read(rp[SP] + 1);
		memory.write(rp[SP], r[L]);
		memory.write(rp[SP] + 1, r[H]);
		r[L] = lo; r[H] = hi;
		rp[PC]++;
		cycle += 18;
	"""
	# CPO nnnn
	0xe4: """
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
	"""
	# PUSH HL
	0xe5: """
		memory.write(--rp[SP], r[H]);
		memory.write(--rp[SP], r[L]);
		rp[PC]++;
		cycle += 11;
	"""
	# ANI nn
	0xe6: """
		r[A] &= memory.read(++rp[PC]);
		r[F] = szpTable[r[A]];
		rp[PC]++;
		cycle += 7;
	"""
	# RST 20
	0xe7: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0020;
		cycle += 11;
	"""
	# RPE
	0xe8: """
		if (r[F] & Fp) {
			/* P is set, so return */
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		} else {
			rp[PC]++;
			cycle += 5;
		}
	"""
	# PCHL
	0xe9: """
		rp[PC] = rp[HL];
		cycle += 5;
	"""
	# JPE nnnn
	0xea: """
		if (r[F] & Fp) {
			/* P is set, so jump */
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		} else {
			rp[PC] += 3;
		}
		cycle += 10;
	"""
	# XCHG
	0xeb: """
		result = rp[HL];
		rp[HL] = rp[DE];
		rp[DE] = result;
		rp[PC]++;
		cycle += 5;
	"""
	# CPE nnnn
	0xec: """
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
	"""
	# XRI nn
	0xee: """
		r[A] ^= memory.read(++rp[PC]);
		r[F] = szpTable[r[A]];
		rp[PC]++;
		cycle += 7;
	"""
	# RST 28
	0xef: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0028;
		cycle += 11;
	"""
	# RP
	0xf0: """
		if (r[F] & Fs) {
			/* S is set, so stay */
			rp[PC]++;
			cycle += 5;
		} else {
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		}
	"""
	# POP PSW
	0xf1: """
		r[F] = memory.read(rp[SP]++);
		r[A] = memory.read(rp[SP]++);
		rp[PC]++;
		cycle += 10;
	"""
	# JP nnnn
	0xf2: """
		if (r[F] & Fs) {
			/* S is set, so stay */
			rp[PC] += 3;
		} else {
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		}
		cycle += 10;
	"""
	# DI
	0xf3: """
		interruptsEnabled = false;
		rp[PC] += 1;
		cycle += 4;
	"""
	# CP nnnn
	0xf4: """
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
	"""
	# PUSH PSW
	0xf5: """
		memory.write(--rp[SP], r[A]);
		memory.write(--rp[SP], r[F]);
		rp[PC]++;
		cycle += 11;
	"""
	# ORI nn
	0xf6: """
		r[A] |= memory.read(++rp[PC]);
		r[F] = szpTable[r[A]];
		rp[PC]++;
		cycle += 7;
	"""
	# RST 30
	0xf7: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0030;
		cycle += 11;
	"""
	# RM
	0xf8: """
		if (r[F] & Fs) {
			/* S is set, so return */
			r[PCl] = memory.read(rp[SP]++);
			r[PCh] = memory.read(rp[SP]++);
			cycle += 11;
		} else {
			rp[PC]++;
			cycle += 5;
		}
	"""
	# SPHL
	0xf9: """
		rp[SP] = rp[HL];
		rp[PC]++;
		cycle += 5;
	"""
	# JC nnnn
	0xfa: """
		if (r[F] & Fs) {
			/* S is set, so jump */
			lo = memory.read(++rp[PC]);
			hi = memory.read(++rp[PC]);
			r[PCh] = hi; r[PCl] = lo;
		} else {
			rp[PC] += 3;
		}
		cycle += 10;
	"""
	# EI
	0xfb: """
		interruptsEnabled = true;
		rp[PC] += 1;
		cycle += 4;
	"""
	# CM nnnn
	0xfc: """
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
	"""
	# CPI nn
	0xfe: """
		result = (r[A] - memory.read(++rp[PC])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 7;
	"""
	# RST 38
	0xff: """
		rp[PC]++;
		memory.write(--rp[SP], r[PCh]);
		memory.write(--rp[SP], r[PCl]);
		rp[PC] = 0x0038;
		cycle += 11;
	"""
}

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

	self.runForCycles = function(cycleCount, trace) {
		var lo, hi, result, opcode;

		while(cycle < cycleCount) {
			if (interruptPending) {
				opcode = interruptOpcode;
				interruptPending = false;
				rp[PC]--; /* compensate for PC being incremented in the execution of a regular instruction, which shouldn't happen here */
			} else {
				opcode = memory.read(rp[PC]);
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
		console.log(intCount + ': ' + rp[AF].toString(16) + ' ' + rp[BC].toString(16) + ' ' + rp[DE].toString(16) + ' ' + rp[HL].toString(16) + ' ' + rp[PC].toString(16) + ' ' + rp[SP].toString(16) + ' at cycle ' + cycle);
	};

	return self;
}
"""

indirectEval = eval
indirectEval(define8080JS);
