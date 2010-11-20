/*
 * flexim/all.d
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

module flexim.all;

public
{
	import std.algorithm;
	import std.array;
	import std.container;
	import std.conv;
	import std.datetime;
	import std.math;
	import std.random;
	import std.range;
	import std.stdio;
	import std.string;
	import std.typecons;

	import flexim.cpu;
	import flexim.isa;
	import flexim.kernel;
	import flexim.main;
	import flexim.mem;
	import flexim.misc;
	import flexim.sim;
}
