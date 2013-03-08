# Test endianness of host processor, so that we can arrange the register buffer
# appropriately for access as individual registers or register pairs

endianTestBuffer = new ArrayBuffer(2)
endianTestUint16 = new Uint16Array(endianTestBuffer)
endianTestUint8 = new Uint8Array(endianTestBuffer)

endianTestUint16[0] = 0x0100
isBigEndian = (endianTestUint8[0] == 0x01)

# Define positions of individual registers within the register buffer
if isBigEndian
	A = 0; F = 1; B = 2; C = 3; D = 4; E = 5; H = 6; L = 7;
	SPh = 8; SPl = 9; PCh = 10; PCl = 11;
else
	A = 1; F = 0; B = 3; C = 2; D = 5; E = 4; H = 7; L = 6;
	SPh = 9; SPl = 8; PCh = 11; PCl = 10;

# Lookup table for setting the S, Z and P flags according to the results of an operation
szpTable = new Uint8Array(0x100)

Fz = 0x40; Fs = 0x80; Fp = 0x04; Fcy = 0x01; Fac = 0x10

for i in [0...0x100]
	j = i
	parity = 0
	for k in [0...8]
		parity ^= j & 1
		j >>=1

	parityBit = if parity then 0 else Fp
	signBit = if i & 0x80 then Fs else 0
	zeroBit = if i == 0 then Fz else 0
	szpTable[i] = signBit | parityBit | zeroBit

# export these local variables in a pretty dumb way so that 8080 internals can import them
# as their own locals
window.Processor8080Definitions = {
	registers: {
		A:A, F:F, B:B, C:C, D:D, E:E, H:H, L:L,
		SPh:SPh, SPl:SPl, PCh:PCh, PCl:PCl
	},
	registerPairs: {
		# Define positions of register pairs and their component parts within the register buffer
		AF: {'p': 0, 'h': A, 'l': F}
		BC: {'p': 1, 'h': B, 'l': C}
		DE: {'p': 2, 'h': D, 'l': E}
		HL: {'p': 3, 'h': H, 'l': L}
		SP: {'p': 4, 'h': SPh, 'l': SPl}
		PC: {'p': 5, 'h': PCh, 'l': SPl}
	},
	flags: {
		Fz:Fz, Fs:Fs, Fp:Fp, Fcy:Fcy, Fac:Fac
	},
	szpTable: szpTable
}
