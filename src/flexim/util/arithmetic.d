/*
 * flexim/util/arithmetic.d
 * 
 * Copyright (c) 2010 Min Cai <itecgo@163.com>. 
 * 
 * This file is part of the Flexim multicore architectural simulator.
 * 
 * Flexim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Flexim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flexim.  If not, see <http ://www.gnu.org/licenses/>.
 */

module flexim.util.arithmetic;

import flexim.all;

/// Generate a 32-bit mask of 'nbits' 1s, right justified.
uint mask(int nbits) {
	return (nbits == 32) ? cast(uint) -1 : (1U << nbits) - 1;
}

/// Generate a 64-bit mask of 'nbits' 1s, right justified.
ulong mask64(int nbits) {
	return (nbits == 64) ? cast(ulong) -1 : (1UL << nbits) - 1;
}

/// Extract the bitfield from position 'first' to 'last' (inclusive)
/// from 'val' and right justify it.  MSB is numbered 31, LSB is 0.
uint bits(uint val, int first, int last) {
	int nbits = first - last + 1;
	return (val >> last) & mask(nbits);
}

/// Extract the bitfield from position 'first' to 'last' (inclusive)
/// from 'val' and right justify it.  MSB is numbered 63, LSB is 0.
ulong bits64(ulong val, int first, int last) {
	int nbits = first - last + 1;
	return (val >> last) & mask(nbits);
}

/// Extract the bit from this position from 'val' and right justify it.
uint bits(uint val, int bit) {
	return bits(val, bit, bit);
}

/// Extract the bit from this position from 'val' and right justify it.
ulong bits64(ulong val, int bit) {
	return bits64(val, bit, bit);
}

/// Mask off the given bits in place like bits() but without shifting.
/// MSB is numbered 31, LSB is 0.
uint mbits(uint val, int first, int last) {
	return val & (mask(first + 1) & ~mask(last));
}

/// Mask off the given bits in place like bits() but without shifting.
/// MSB is numbered 63, LSB is 0.
ulong mbits64(ulong val, int first, int last) {
	return val & (mask64(first + 1) & ~mask(last));
}

uint mask(int first, int last) {
	return mbits(cast(uint) -1, first, last);
}

ulong mask64(int first, int last) {
	return mbits64(cast(ulong) -1, first, last);
}

/// Sign-extend an N-bit value to 32 bits.
int sext(uint val, int n) {
	int sign_bit = bits(val, n - 1, n - 1);
	return sign_bit ? (val | ~mask(n)) : val;
}

/// Sign-extend an N-bit value to 32 bits.
long sext64(ulong val, int n) {
	long sign_bit = bits64(val, n - 1, n - 1);
	return sign_bit ? (val | ~mask64(n)) : val;
}

template Rounding(T) {
	T roundUp(T n, uint alignment) {
		return (n + cast(T) (alignment - 1)) & ~cast(T) (alignment - 1);
	}

	T roundDown(T n, uint alignment) {
		return n & ~(alignment - 1);
	}
}

/// 32 bit is assumed.
uint aligned(uint n, uint i) {
	alias Rounding!(uint) util;
	return util.roundDown(n, i);
}

/// 32 bit is assumed.
uint aligned(uint n) {
	alias Rounding!(uint) util;
	return util.roundDown(n, 4);
}

/// 32 bit is assumed.
uint getBit(uint x, uint b) {
	return x & (1U << b);
}

/// 32 bit is assumed.
uint setBit(uint x, uint b) {
	return x | (1U << b);
}

/// 32 bit is assumed.
uint clearBit(uint x, uint b) {
	return x & ~(1U << b);
}

/// 32 bit is assumed.
uint setBitValue(uint x, uint b, bool v) {
	return v ? setBit(x, b) : clearBit(x, b);
}

uint mod(uint x, uint y) {
	return (x + y) % y;
}

bool getFCC1(uint fcsr, int cc)
{
	if(cc == 0)
		return cast(bool) (fcsr & 0x800000);
	else
		return cast(bool) (fcsr & (0x1000000 << cc));
}

bool getFCC(uint fcsr, int cc_idx)
{
    int shift = (cc_idx == 0) ? 23 : cc_idx + 24;
    bool cc_val = (fcsr >> shift) & 0x00000001;
    return cc_val;
}

void setFCC(ref uint fcsr, int cc) {
	if(cc == 0)
		fcsr=(fcsr | 0x800000);
	else 
		fcsr=(fcsr | (0x1000000 << cc));
}

void clearFCC(ref uint fcsr, int cc) {
	if(cc == 0)
		fcsr=(fcsr & 0xFF7FFFFF); 
	else
		fcsr=(fcsr & (0xFEFFFFFF << cc));
}

uint
genCCVector(uint fcsr, int cc_num, uint cc_val)
{
    int cc_idx = (cc_num == 0) ? 23 : cc_num + 24;

    fcsr = bits(fcsr, 31, cc_idx + 1) << (cc_idx + 1) |
           cc_val << cc_idx |
           bits(fcsr, cc_idx - 1, 0);

    return fcsr;
}