# Handy lookups to allow us to dissect register pairs
BC = {'p': 'BC', 'h': 'B', 'l': 'C'}
DE = {'p': 'DE', 'h': 'D', 'l': 'E'}
HL = {'p': 'HL', 'h': 'H', 'l': 'L'}
SP = {'p': 'SP', 'h': 'SPh', 'l': 'SPl'}

A = 'A'; B = 'B'; C = 'C'; D = 'D'; E = 'E'; H = 'H'; L = 'L';
# Constructors for runstrings for each class of operations

ADC_R = (r) -> """
	result = (r[A] + r[#{r}] + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
	r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
	r[A] = result;
	rp[PC]++; cycle += 4;
"""

ADD_R = (r) -> """
	result = (r[A] + r[#{r}]) & 0xff;
	r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
	r[A] = result;
	rp[PC]++; cycle += 4;
"""

ANA_R = (r) ->
	if r == A
		"""
			r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4;
		"""
	else
		"""
			r[A] &= r[#{r}]; r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4;
		"""

CMA = () -> """
	r[A] = ~r[A];
	rp[PC]++;
	cycle += 4;
"""

CMC = () -> """
	r[F] ^= (r[F] & Fcy);
	rp[PC]++;
	cycle += 4;
"""

CMP_R = (r) ->
	if r == A
		"""
			r[F] = szpTable[0];
			rp[PC]++;
			cycle += 4;
		"""
	else
		"""
			result = (r[A] - r[#{r}]) & 0xff;
			r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
			rp[PC]++;
			cycle += 4;
		"""

DAA = () -> """
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

DAD_RR = (rr) -> """
	result = rp[HL] + rp[#{rr.p}];
	r[F] = (r[F] & ~Fcy) | (result & 0x10000 ? Fcy : 0);
	rp[HL] = result;
	rp[PC]++;
	cycle += 10;
"""

DCR_M = () -> """
	result = (memory.read(rp[HL]) - 1) & 0xff;
	/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
	r[F] = (r[F] & Fcy) | szpTable[result] | ((result & 0x0f) == 0x0f ? Fac : 0);
	memory.write(rp[HL], result);
	rp[PC]++;
	cycle += 10;
"""

DCR_R = (r) -> """
	r[#{r}]--;
	/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become f */
	r[F] = (r[F] & Fcy) | szpTable[r[#{r}]] | ((r[#{r}] & 0x0f) == 0x0f ? Fac : 0);
	rp[PC]++;
	cycle += 5;
"""

DCX_RR = (rr) -> """
	rp[#{rr.p}]--;
	rp[PC]++;
	cycle += 5;
"""

INX_RR = (rr) -> """
	rp[#{rr.p}]++;
	rp[PC]++;
	cycle += 5;
"""

INR_M = () -> """
	result = (memory.read(rp[HL]) + 1) & 0xff;
	/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
	r[F] = (r[F] & Fcy) | szpTable[result] | ((result & 0x0f) ? 0 : Fac);
	memory.write(rp[HL], result);
	rp[PC]++;
	cycle += 10;
"""

INR_R = (r) -> """
	r[#{r}]++;
	/* preserve carry; take S, Z, P from lookup table; set AC iff lower nibble has become 0 */
	r[F] = (r[F] & Fcy) | szpTable[r[#{r}]] | ((r[#{r}] & 0x0f) ? 0 : Fac);
	rp[PC]++;
	cycle += 5;
"""

LDA_NNNN = () -> """
	lo = memory.read(++rp[PC]);
	hi = memory.read(++rp[PC]);
	r[A] = memory.read((hi << 8) | lo);
	rp[PC]++;
	cycle += 13;
"""

LDAX_RR = (rr) -> """
	r[A] = memory.read(rp[#{rr.p}]);
	rp[PC]++;
	cycle += 7;
"""

LHLD_NNNN = () -> """
	lo = memory.read(++rp[PC]);
	hi = memory.read(++rp[PC]);
	result = (hi << 8) | lo;
	r[L] = memory.read(result);
	r[H] = memory.read((result + 1) & 0xffff);
	rp[PC]++;
	cycle += 16;
"""

LXI_RR_NNNN = (rr) -> """
	r[#{rr.l}] = memory.read(++rp[PC]);
	r[#{rr.h}] = memory.read(++rp[PC]);
	rp[PC]++;
	cycle += 10;
"""

MOV_M_R = (r) -> """
	memory.write(rp[HL], r[#{r}]);
	rp[PC]++;
	cycle += 7;
"""

MOV_R_M = (r) -> """
	r[#{r}] = memory.read(rp[HL]);
	rp[PC]++; cycle += 7;
"""

MOV_R_R = (r1, r2) ->
	if r1 == r2
		"""
			rp[PC]++; cycle += 5;
		"""
	else
		"""
			r[#{r1}] = r[#{r2}];
			rp[PC]++; cycle += 5;
		"""

MVI_M_NN = () -> """
	memory.write(rp[HL], memory.read(++rp[PC]));
	rp[PC]++;
	cycle += 10;
"""

MVI_R_NN = (r) -> """
	r[#{r}] = memory.read(++rp[PC]);
	rp[PC]++;
	cycle += 7;
"""

NOP = () -> """
	rp[PC]++;
	cycle += 4;
"""

ORA_R = (r) ->
	if r == A
		"""
			r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4; break;
		"""
	else
		"""
			r[A] |= r[B]; r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4; break;
		"""

RAL = () -> """
	result = (r[A] << 1) | (r[F] & Fcy ? 1 : 0);
	/* copy top bit of A to carry flag */
	r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
	r[A] = result;
	rp[PC]++;
	cycle += 4;
"""

RAR = () -> """
	result = (r[A] >> 1) | (r[F] & Fcy ? 0x80 : 0);
	/* copy bottom bit of A to carry flag */
	r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
	r[A] = result;
	rp[PC]++;
	cycle += 4;
"""

RLC = () -> """
	/* copy top bit of A to carry flag */
	r[F] = (r[A] & 0x80) ? (r[F] | Fcy) : (r[F] & ~Fcy);
	r[A] = (r[A] << 1) | ((r[A] & 0x80) >> 7);
	rp[PC]++;
	cycle += 4;
"""

RRC = () -> """
	/* copy bottom bit of A to carry flag */
	r[F] = (r[A] & 0x01) ? (r[F] | Fcy) : (r[F] & ~Fcy);
	r[A] = (r[A] >> 1) | ((r[A] & 0x01) << 7);
	rp[PC]++;
	cycle += 4;
"""

SBB_R = (r) -> """
	result = (r[A] - r[#{r}] - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
	r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
	r[A] = result;
	rp[PC]++; cycle += 4;
"""

SHLD_NNNN = () -> """
	lo = memory.read(++rp[PC]);
	hi = memory.read(++rp[PC]);
	result = (hi << 8) | lo;
	memory.write(result, r[L]);
	memory.write((result + 1) & 0xffff, r[H]);
	rp[PC]++;
	cycle += 16;
"""

STA_NNNN = () -> """
	lo = memory.read(++rp[PC]);
	hi = memory.read(++rp[PC]);
	memory.write((hi << 8) | lo, r[A]);
	rp[PC]++;
	cycle += 13;
"""

STAX_RR = (rr) -> """
	memory.write(rp[#{rr.p}], r[A]);
	rp[PC]++;
	cycle += 7;
"""

STC = () -> """
	r[F] |= Fcy;
	rp[PC]++;
	cycle += 4;
"""

SUB_R = (r) -> """
	result = (r[A] - r[#{r}]) & 0xff;
	r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
	r[A] = result;
	rp[PC]++; cycle += 4;
"""

XRA_R = (r) ->
	if r == A
		"""
			r[A] = 0; r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4;
		"""
	else
		"""
			r[A] ^= r[#{r}]; r[F] = szpTable[r[A]];
			rp[PC]++; cycle += 4;
		"""

# A mapping from opcodes to Javascript strings that perform them
OPCODE_RUN_STRINGS = {
	0x00: NOP()              # NOP
	0x01: LXI_RR_NNNN(BC)    # LXI BC,nnnn
	0x02: STAX_RR(BC)        # STAX BC
	0x03: INX_RR(BC)         # INX BC
	0x04: INR_R(B)           # INR B
	0x05: DCR_R(B)           # DCR B
	0x06: MVI_R_NN(B)        # MVI B,nn
	0x07: RLC()              # RLC
	0x09: DAD_RR(BC)         # DAD BC
	0x0a: LDAX_RR(BC)        # LDAX BC
	0x0b: DCX_RR(BC)         # DCX BC
	0x0c: INR_R(C)           # INR C
	0x0d: DCR_R(C)           # DCR C
	0x0e: MVI_R_NN(C)        # MVI C,nn
	0x0f: RRC()              # RRC
	0x11: LXI_RR_NNNN(DE)    # LXI DE,nnnn
	0x12: STAX_RR(DE)        # STAX DE
	0x13: INX_RR(DE)         # INX DE
	0x14: INR_R(D)           # INR D
	0x15: DCR_R(D)           # DCR D
	0x16: MVI_R_NN(D)        # MVI D,nn
	0x17: RAL()              # RAL
	0x19: DAD_RR(DE)         # DAD DE
	0x1a: LDAX_RR(DE)        # LDAX DE
	0x1b: DCX_RR(DE)         # DCX DE
	0x1c: INR_R(E)           # INR E
	0x1d: DCR_R(E)           # DCR E
	0x1e: MVI_R_NN(E)        # MVI E,nn
	0x1f: RAR()              # RAR
	0x21: LXI_RR_NNNN(HL)    # LXI HL,nnnn
	0x22: SHLD_NNNN()        # SHLD nnnn
	0x23: INX_RR(HL)         # INX HL
	0x24: INR_R(H)           # INR H
	0x25: DCR_R(H)           # DCR H
	0x26: MVI_R_NN(H)        # MVI H,nn
	0x27: DAA()              # DAA
	0x29: DAD_RR(HL)         # DAD HL
	0x2a: LHLD_NNNN()        # LHLD nnnn
	0x2b: DCX_RR(HL)         # DCX HL
	0x2c: INR_R(L)           # INR L
	0x2d: DCR_R(L)           # DCR L
	0x2e: MVI_R_NN(L)        # MVI L,nn
	0x2f: CMA()              # CMA
	0x31: LXI_RR_NNNN(SP)    # LXI SP,nnnn
	0x32: STA_NNNN()         # STA nnnn
	0x33: INX_RR(SP)         # INX SP
	0x34: INR_M()            # INR M
	0x35: DCR_M()            # DCR M
	0x36: MVI_M_NN()         # MVI M,nn
	0x37: STC()              # STC
	0x39: DAD_RR(SP)         # DAD SP
	0x3a: LDA_NNNN()         # LDA nnnn
	0x3b: DCX_RR(SP)         # DCX SP
	0x3c: INR_R(A)           # INR A
	0x3d: DCR_R(A)           # DCR A
	0x3e: MVI_R_NN(A)        # MVI A,nn
	0x3f: CMC()              # CMC
	0x40: MOV_R_R(B, B)      # MOV B,B
	0x41: MOV_R_R(B, C)      # MOV B,C
	0x42: MOV_R_R(B, D)      # MOV B,D
	0x43: MOV_R_R(B, E)      # MOV B,E
	0x44: MOV_R_R(B, H)      # MOV B,H
	0x45: MOV_R_R(B, L)      # MOV B,L
	0x46: MOV_R_M(B)         # MOV B,M
	0x47: MOV_R_R(B, A)      # MOV B,A
	0x48: MOV_R_R(C, B)      # MOV C,B
	0x49: MOV_R_R(C, C)      # MOV C,C
	0x4a: MOV_R_R(C, D)      # MOV C,D
	0x4b: MOV_R_R(C, E)      # MOV C,E
	0x4c: MOV_R_R(C, H)      # MOV C,H
	0x4d: MOV_R_R(C, L)      # MOV C,L
	0x4e: MOV_R_M(C)         # MOV C,M
	0x4f: MOV_R_R(C, A)      # MOV C,A
	0x50: MOV_R_R(D, B)      # MOV D,B
	0x51: MOV_R_R(D, C)      # MOV D,C
	0x52: MOV_R_R(D, D)      # MOV D,D
	0x53: MOV_R_R(D, E)      # MOV D,E
	0x54: MOV_R_R(D, H)      # MOV D,H
	0x55: MOV_R_R(D, L)      # MOV D,L
	0x56: MOV_R_M(D)         # MOV D,M
	0x57: MOV_R_R(D, A)      # MOV D,A
	0x58: MOV_R_R(E, B)      # MOV E,B
	0x59: MOV_R_R(E, C)      # MOV E,C
	0x5a: MOV_R_R(E, D)      # MOV E,D
	0x5b: MOV_R_R(E, E)      # MOV E,E
	0x5c: MOV_R_R(E, H)      # MOV E,H
	0x5d: MOV_R_R(E, L)      # MOV E,L
	0x5e: MOV_R_M(E)         # MOV E,M
	0x5f: MOV_R_R(E, A)      # MOV E,A
	0x60: MOV_R_R(H, B)      # MOV H,B
	0x61: MOV_R_R(H, C)      # MOV H,C
	0x62: MOV_R_R(H, D)      # MOV H,D
	0x63: MOV_R_R(H, E)      # MOV H,E
	0x64: MOV_R_R(H, H)      # MOV H,H
	0x65: MOV_R_R(H, L)      # MOV H,L
	0x66: MOV_R_M(H)         # MOV H,M
	0x67: MOV_R_R(H, A)      # MOV H,A
	0x68: MOV_R_R(L, B)      # MOV L,B
	0x69: MOV_R_R(L, C)      # MOV L,C
	0x6a: MOV_R_R(L, D)      # MOV L,D
	0x6b: MOV_R_R(L, E)      # MOV L,E
	0x6c: MOV_R_R(L, H)      # MOV L,H
	0x6d: MOV_R_R(L, L)      # MOV L,L
	0x6e: MOV_R_M(L)         # MOV L,M
	0x6f: MOV_R_R(L, A)      # MOV L,A
	0x70: MOV_M_R(B)         # MOV M,B
	0x71: MOV_M_R(C)         # MOV M,C
	0x72: MOV_M_R(D)         # MOV M,D
	0x73: MOV_M_R(E)         # MOV M,E
	0x74: MOV_M_R(H)         # MOV M,H
	0x75: MOV_M_R(L)         # MOV M,L

	0x77: MOV_M_R(A)         # MOV M,A
	0x78: MOV_R_R(A, B)      # MOV A,B
	0x79: MOV_R_R(A, C)      # MOV A,C
	0x7a: MOV_R_R(A, D)      # MOV A,D
	0x7b: MOV_R_R(A, E)      # MOV A,E
	0x7c: MOV_R_R(A, H)      # MOV A,H
	0x7d: MOV_R_R(A, L)      # MOV A,L
	0x7e: MOV_R_M(A)         # MOV A,M
	0x7f: MOV_R_R(A, A)      # MOV A,A
	0x80: ADD_R(B)           # ADD B
	0x81: ADD_R(C)           # ADD C
	0x82: ADD_R(D)           # ADD D
	0x83: ADD_R(E)           # ADD E
	0x84: ADD_R(H)           # ADD H
	0x85: ADD_R(L)           # ADD L
	# ADD M
	0x86: """
		result = (r[A] + memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7;
	"""
	0x87: ADD_R(A)           # ADD A
	0x88: ADC_R(B)           # ADC B
	0x89: ADC_R(C)           # ADC C
	0x8a: ADC_R(D)           # ADC D
	0x8b: ADC_R(E)           # ADC E
	0x8c: ADC_R(H)           # ADC H
	0x8d: ADC_R(L)           # ADC L
	# ADC M
	0x8e: """
		result = (r[A] + memory.read(rp[HL]) + ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result < r[A] ? Fcy : 0) | ((result & 0x0f) < (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7;
	"""
	0x8f: ADC_R(A)           # ADC A
	0x90: SUB_R(B)           # SUB B
	0x91: SUB_R(C)           # SUB C
	0x92: SUB_R(D)           # SUB D
	0x93: SUB_R(E)           # SUB E
	0x94: SUB_R(H)           # SUB H
	0x95: SUB_R(L)           # SUB L
	# SUB M
	0x96: """
		result = (r[A] - memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7;
	"""
	0x97: SUB_R(A)           # SUB A
	0x98: SBB_R(B)           # SBB B
	0x99: SBB_R(C)           # SBB C
	0x9a: SBB_R(D)           # SBB D
	0x9b: SBB_R(E)           # SBB E
	0x9c: SBB_R(H)           # SBB H
	0x9d: SBB_R(L)           # SBB L
	# SBB M
	0x9e: """
		result = (r[A] - memory.read(rp[HL]) - ((r[F] & Fcy) ? 1 : 0)) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		r[A] = result;
		rp[PC]++; cycle += 7;
	"""
	0x9f: SBB_R(A)           # SBB A
	0xa0: ANA_R(B)           # ANA B
	0xa1: ANA_R(C)           # ANA C
	0xa2: ANA_R(D)           # ANA D
	0xa3: ANA_R(E)           # ANA E
	0xa4: ANA_R(H)           # ANA H
	0xa5: ANA_R(L)           # ANA L
	# ANA M
	0xa6: """
		r[A] &= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	0xa7: ANA_R(A)           # ANA A
	0xa8: XRA_R(B)           # XRA B
	0xa9: XRA_R(C)           # XRA C
	0xaa: XRA_R(D)           # XRA D
	0xab: XRA_R(E)           # XRA E
	0xac: XRA_R(H)           # XRA H
	0xad: XRA_R(L)           # XRA L
	# XRA M
	0xae: """
		r[A] ^= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	0xaf: XRA_R(A)           # XRA A
	0xb0: ORA_R(B)           # ORA B
	0xb1: ORA_R(C)           # ORA C
	0xb2: ORA_R(D)           # ORA D
	0xb3: ORA_R(E)           # ORA E
	0xb4: ORA_R(H)           # ORA H
	0xb5: ORA_R(L)           # ORA L
	# ORA M
	0xb6: """
		r[A] |= memory.read(rp[HL]); r[F] = szpTable[r[A]];
		rp[PC]++; cycle += 7; break;
	"""
	0xb7: ORA_R(A)           # ORA A
	0xb8: CMP_R(B)           # CMP B
	0xb9: CMP_R(C)           # CMP C
	0xba: CMP_R(D)           # CMP D
	0xbb: CMP_R(E)           # CMP E
	0xbc: CMP_R(H)           # CMP H
	0xbd: CMP_R(L)           # CMP L
	# CMP M
	0xbe: """
		result = (r[A] - memory.read(rp[HL])) & 0xff;
		r[F] = szpTable[result] | (result > r[A] ? Fcy : 0) | ((result & 0x0f) > (r[A] & 0x0f) ? Fac : 0);
		rp[PC]++;
		cycle += 7;
	"""
	0xbf: CMP_R(A)           # CMP A
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
