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

ulong singleToDouble(double fp_val) {
    double sdouble_val = fp_val;
    ulong sdp_bits = *cast(ulong *)(&sdouble_val);
    return sdp_bits;
}

ulong singleToWord(double fp_val) {
    int sword_val = cast(int) fp_val;
    ulong sword_bits = *cast(uint *) (&sword_val);
    return sword_bits;
}

uint wordToSingle(double fp_val) {
    float wfloat_val = fp_val;
	uint wfloat_bits = *cast(uint *) (&wfloat_val);
    return wfloat_bits;
}

ulong wordToDouble(double fp_val) {
    double wdouble_val = fp_val;
    ulong wdp_bits = *cast(ulong *) (&wdouble_val);
    return wdp_bits;
}

uint longToSingle(double fp_val) {
    float wfloat_val = fp_val;
	uint wfloat_bits = *cast(uint *) (&wfloat_val);
    return wfloat_bits;
}

ulong longToDouble(double fp_val) {
    double wdouble_val = fp_val;
    ulong wdp_bits = *cast(ulong *) (&wdouble_val);
    return wdp_bits;
}

double roundFP(double val, int digits) {
    double digit_offset = pow(10.0,digits);
    val = val * digit_offset;
    val = val + 0.5;
    val = floor(val);
    val = val / digit_offset;
    return val;
}

double truncFP(double val)
{
    int trunc_val = cast(int) val;
    return cast(double) trunc_val;
}

bool getCondCode(uint fcsr, int cc_idx)
{
    int shift = (cc_idx == 0) ? 23 : cc_idx + 24;
    bool cc_val = (fcsr >> shift) & 0x00000001;
    return cc_val;
}

uint genCCVector(uint fcsr, int cc_num, uint cc_val)
{
    int cc_idx = (cc_num == 0) ? 23 : cc_num + 24;

    fcsr = bits(fcsr, 31, cc_idx + 1) << (cc_idx + 1) |
           cc_val << cc_idx |
           bits(fcsr, cc_idx - 1, 0);

    return fcsr;
}

uint genInvalidVector(uint fcsr_bits)
{
    //Set FCSR invalid in "flag" field
    int invalid_offset = FCSRBits.Invalid + FCSRFields.Flag_Field;
    fcsr_bits = fcsr_bits | (1 << invalid_offset);

    //Set FCSR invalid in "cause" flag
    int cause_offset = FCSRBits.Invalid + FCSRFields.Cause_Field;
    fcsr_bits = fcsr_bits | (1 << cause_offset);

    return fcsr_bits;
}

bool isNan(void* val_ptr, int size)
{
    switch (size)
    {
      case 32:
		uint val_bits = *cast(uint *) val_ptr;
		return (bits(val_bits, 30, 23) == 0xFF);
      case 64:
		ulong val_bits = *cast(ulong *) val_ptr;
    	return (bits64(val_bits, 62, 52) == 0x7FF);
      default:
		logging.panic(LogCategory.MISC, "Type unsupported. Size mismatch.");
    	return false;
    }
}

bool isQnan(void* val_ptr, int size)
{
    switch (size)
    {
      case 32:
    	uint val_bits = *cast(uint *) val_ptr;
    	return (bits(val_bits, 30, 22) == 0x1FE);
      case 64:
    	ulong val_bits = *cast(ulong *) val_ptr;
    	return (bits64(val_bits, 62, 51) == 0xFFE);
      default:
		logging.panic(LogCategory.MISC, "Type unsupported. Size mismatch.");
		return false;
    }
}

bool isSnan(void* val_ptr, int size)
{
    switch (size)
    {
      case 32:
    	uint val_bits = *cast(uint *) val_ptr;
    	return (bits(val_bits, 30, 22) == 0x1FF);
      case 64:
    	ulong val_bits = *cast(ulong *) val_ptr;
    	return (bits64(val_bits, 62, 51) == 0xFFF);
      default:
		logging.panic(LogCategory.MISC, "Type unsupported. Size mismatch.");
		return false;
    }
}