// Generated by CoffeeScript 1.3.3
(function() {
  var A, B, C, D, E, F, Fac, Fcy, Fp, Fs, Fz, H, L, PCh, PCl, SPh, SPl, endianTestBuffer, endianTestUint16, endianTestUint8, i, isBigEndian, j, k, parity, parityBit, signBit, szpTable, zeroBit, _i, _j;

  endianTestBuffer = new ArrayBuffer(2);

  endianTestUint16 = new Uint16Array(endianTestBuffer);

  endianTestUint8 = new Uint8Array(endianTestBuffer);

  endianTestUint16[0] = 0x0100;

  isBigEndian = endianTestUint8[0] === 0x01;

  if (isBigEndian) {
    A = 0;
    F = 1;
    B = 2;
    C = 3;
    D = 4;
    E = 5;
    H = 6;
    L = 7;
    SPh = 8;
    SPl = 9;
    PCh = 10;
    PCl = 11;
  } else {
    A = 1;
    F = 0;
    B = 3;
    C = 2;
    D = 5;
    E = 4;
    H = 7;
    L = 6;
    SPh = 9;
    SPl = 8;
    PCh = 11;
    PCl = 10;
  }

  szpTable = new Uint8Array(0x100);

  Fz = 0x40;

  Fs = 0x80;

  Fp = 0x04;

  Fcy = 0x01;

  Fac = 0x10;

  for (i = _i = 0; 0 <= 0x100 ? _i < 0x100 : _i > 0x100; i = 0 <= 0x100 ? ++_i : --_i) {
    j = i;
    parity = 0;
    for (k = _j = 0; _j < 8; k = ++_j) {
      parity ^= j & 1;
      j >>= 1;
    }
    parityBit = parity ? 0 : Fp;
    signBit = i & 0x80 ? Fs : 0;
    zeroBit = i === 0 ? Fz : 0;
    szpTable[i] = signBit | parityBit | zeroBit;
  }

  window.Processor8080Definitions = {
    registers: {
      A: A,
      F: F,
      B: B,
      C: C,
      D: D,
      E: E,
      H: H,
      L: L,
      SPh: SPh,
      SPl: SPl,
      PCh: PCh,
      PCl: PCl
    },
    registerPairs: {
      AF: {
        'p': 0,
        'h': A,
        'l': F
      },
      BC: {
        'p': 1,
        'h': B,
        'l': C
      },
      DE: {
        'p': 2,
        'h': D,
        'l': E
      },
      HL: {
        'p': 3,
        'h': H,
        'l': L
      },
      SP: {
        'p': 4,
        'h': SPh,
        'l': SPl
      },
      PC: {
        'p': 5,
        'h': PCh,
        'l': SPl
      }
    },
    flags: {
      Fz: Fz,
      Fs: Fs,
      Fp: Fp,
      Fcy: Fcy,
      Fac: Fac
    },
    szpTable: szpTable
  };

}).call(this);