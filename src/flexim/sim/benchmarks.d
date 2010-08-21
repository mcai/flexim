/*
 * flexim/sim/benchmarks.d
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

module flexim.sim.benchmarks;

import flexim.all;

class Benchmark {
	this(string title, string cwd, string exe, string args) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.args = args;
	}
	
	this(string title, string cwd, string exe, string args, string stdin) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.args = args;
		this.stdin = stdin;
	}
	
	this(string title, string cwd, string exe, string args, string stdin, string stdout) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.args = args;
		this.stdin = stdin;
		this.stdout = stdout;
	}
	
	override string toString() {
		return format("Benchmark[title=%s, cwd=%s, exe=%s, args=%s, stdin=%s, stdout=%s, tags.length=%d]",
			this.title, this.cwd, this.exe, this.args, this.stdin, this.stdout, this.tags.length);
	}
	
	string title;
	string cwd;
	string exe;
	string args;
	string stdin;
	string stdout;
	string[] tags;
	
	BenchmarkSuite suite;
}

class BenchmarkSuite {
	static class WCETBench: BenchmarkSuite {
		this() {
			super(TITLE, "Microbenchmarks/external/wcet_bench");
			
			Benchmark benchmark_adpcm = new Benchmark("adpcm", "./", "adpcm", "");
			Benchmark benchmark_bs = new Benchmark("bs", "./", "bs", "");
			Benchmark benchmark_bsort100 = new Benchmark("bsort100", "./", "bsort100", "");
			Benchmark benchmark_cnt = new Benchmark("cnt", "./", "cnt", "");
			Benchmark benchmark_compress = new Benchmark("compress", "./", "compress", "");
			Benchmark benchmark_cover = new Benchmark("cover", "./", "cover", "");
			Benchmark benchmark_crc = new Benchmark("crc", "./", "crc", "");
			Benchmark benchmark_duff = new Benchmark("duff", "./", "duff", "");
			Benchmark benchmark_edn = new Benchmark("edn", "./", "edn", "");
			Benchmark benchmark_expint = new Benchmark("expint", "./", "expint", "");
			Benchmark benchmark_fac = new Benchmark("fac", "./", "fac", "");
			Benchmark benchmark_fdct = new Benchmark("fdct", "./", "fdct", "");
			Benchmark benchmark_fft1 = new Benchmark("fft1", "./", "fft1", "");
			Benchmark benchmark_fibcall = new Benchmark("fibcall", "./", "fibcall", "");
			Benchmark benchmark_fir = new Benchmark("fir", "./", "fir", "");
			Benchmark benchmark_insertsort = new Benchmark("insertsort", "./", "insertsort", "");
			Benchmark benchmark_janne_complex = new Benchmark("janne_complex", "./", "janne_complex", "");
			Benchmark benchmark_jfdctint = new Benchmark("jfdctint", "./", "jfdctint", "");
			Benchmark benchmark_lcdnum = new Benchmark("lcdnum", "./", "lcdnum", "");
			Benchmark benchmark_lms = new Benchmark("lms", "./", "lms", "");
			Benchmark benchmark_loop3 = new Benchmark("loop3", "./", "loop3", "");
			Benchmark benchmark_ludcmp = new Benchmark("ludcmp", "./", "ludcmp", "");
			Benchmark benchmark_matmult = new Benchmark("matmult", "./", "matmult", "");
			Benchmark benchmark_minmax = new Benchmark("minmax", "./", "minmax", "");
			Benchmark benchmark_minver = new Benchmark("minver", "./", "minver", "");
			Benchmark benchmark_ns = new Benchmark("ns", "./", "ns", "");
			Benchmark benchmark_nsichneu = new Benchmark("nsichneu", "./", "nsichneu", "");
			Benchmark benchmark_qsort_exam = new Benchmark("qsort-exam", "./", "qsort-exam", "");
			Benchmark benchmark_qurt = new Benchmark("qurt", "./", "qurt", "");
			Benchmark benchmark_select = new Benchmark("select", "./", "select", "");
			Benchmark benchmark_sqrt = new Benchmark("sqrt", "./", "sqrt", "");
			Benchmark benchmark_statemate = new Benchmark("statemate", "./", "statemate", "");
			
			this.register(benchmark_adpcm);
			this.register(benchmark_bs);
			this.register(benchmark_bsort100);
			this.register(benchmark_cnt);
			this.register(benchmark_compress);
			this.register(benchmark_cover);
			this.register(benchmark_crc);
			this.register(benchmark_duff);
			this.register(benchmark_edn);
			this.register(benchmark_expint);
			this.register(benchmark_fac);
			this.register(benchmark_fdct);
			this.register(benchmark_fft1);
			this.register(benchmark_fibcall);
			this.register(benchmark_fir);
			this.register(benchmark_insertsort);
			this.register(benchmark_janne_complex);
			this.register(benchmark_jfdctint);
			this.register(benchmark_lcdnum);
			this.register(benchmark_lms);
			this.register(benchmark_loop3);
			this.register(benchmark_ludcmp);
			this.register(benchmark_matmult);
			this.register(benchmark_minmax);
			this.register(benchmark_minver);
			this.register(benchmark_ns);
			this.register(benchmark_nsichneu);
			this.register(benchmark_qsort_exam);
			this.register(benchmark_qurt);
			this.register(benchmark_select);
			this.register(benchmark_sqrt);
			this.register(benchmark_statemate);
		}
		
		static const string TITLE = "WCETBench";
	}
	
	static class OldenCustom1 : BenchmarkSuite {
		this() {
			super(TITLE, "Olden");

			// Benchmark benchmarkMstOriginal = new Benchmark("mst_original",
			// "mst/original", "mst", "400 1");
			// Benchmark benchmarkMstPrepush = new Benchmark("mst_prepush",
			// "mst/prepush", "mst", "400 1");
//			 Benchmark benchmarkMstOriginal = new Benchmark("mst_original",
//			 "mst/original", "mst", "1024 1");
//			 Benchmark benchmarkMstPrepush = new Benchmark("mst_prepush",
//			 "mst/prepush", "mst", "1024 1");
			Benchmark benchmarkMstOriginal = new Benchmark("mst_original",
					"mst/original", "mst", "10 1");
			//Benchmark benchmarkMstPrepush = new Benchmark("mst_prepush",
			//		"mst/prepush", "mst", "10 1");

			//Benchmark benchmarkEm3dOriginal = new Benchmark("em3d_original",
			//"em3d/original", "em3d", "2000 100 75 1");
			Benchmark benchmarkEm3dOriginal = new Benchmark("em3d_original",
			"em3d/original", "em3d", "200 100 75 1");
			// Benchmark benchmarkEm3dPrepush = new Benchmark("em3d_prepush",
			// "em3d/prepush", "em3d", "2000 100 75 1");
					
			//this.register(benchmarkMstOriginal);
			//this.register(benchmarkMstPrepush);

			 this.register(benchmarkEm3dOriginal);
			// this.register(benchmarkEm3dPrepush);
		}
		
		static const string TITLE = "Olden_Custom1";
	}
	
	static class CPU2006: BenchmarkSuite {
		this() {
			super(TITLE, "CPU2006");

			Benchmark benchmark400 = new Benchmark("400.perlbench",
					"400.perlbench", "perlbench_base.i386",
					"checkspam.pl 2500 5 25 11 150 1 1 1 1", "");
			Benchmark benchmark401 = new Benchmark("401.bzip2", "401.bzip2",
					"bzip2_base.i386", "input.source 280", "");
			Benchmark benchmark403 = new Benchmark("403.gcc", "403.gcc",
					"gcc_base.i386", "166.i -o 166.s", "");
			Benchmark benchmark410 = new Benchmark("410.bwaves", "410.bwaves",
					"bwaves_base.i386", "", "");
			Benchmark benchmark429 = new Benchmark("429.mcf", "429.mcf",
					"mcf_base.i386", "inp.in", "");
			Benchmark benchmark433 = new Benchmark("433.milc", "433.milc",
					"milc_base.i386", "", "su3imp.in");
			Benchmark benchmark434 = new Benchmark("434.zeusmp", "434.zeusmp",
					"zeusmp_base.i386", "", "");
			Benchmark benchmark435 = new Benchmark("435.gromacs",
					"435.gromacs", "gromacs_base.i386",
					"-silent -deffnm gromacs -nice 0", "");
			Benchmark benchmark444 = new Benchmark("444.namd", "444.namd",
					"namd_base.i386",
					"--input namd.input --iterations 38 --output namd.out", "");
			Benchmark benchmark445 = new Benchmark("445.gobmk", "445.gobmk",
					"gobmk_base.i386", "--quiet --mode gtp", "trevord.tst");
			Benchmark benchmark447 = new Benchmark("447.dealII", "447.dealII",
					"dealII_base.i386", "23", "");
			Benchmark benchmark450 = new Benchmark("450.soplex", "450.soplex",
					"soplex_base.i386", "-m3500 ref.mps", "");
			Benchmark benchmark453 = new Benchmark("453.povray", "453.povray",
					"povray_base.i386", "SPEC-benchmark-ref.ini", "");
			Benchmark benchmark458 = new Benchmark("458.sjeng", "458.sjeng",
					"sjeng_base.i386", "ref.txt", "");
			Benchmark benchmark456 = new Benchmark(
					"456.hmmer",
					"456.hmmer",
					"hmmer_base.i386",
					"--fixed 0 --mean 500 --num 500000 --sd 350 --seed 0 retro.hmm",
					"");
			Benchmark benchmark462 = new Benchmark("462.libquantum",
					"462.libquantum", "libquantum_base.i386", "1397 8", "");
			Benchmark benchmark464 = new Benchmark("464.h264ref",
					"464.h264ref", "h264ref_base.i386",
					"-d sss_encoder_main.cfg", "");
			Benchmark benchmark470 = new Benchmark("470.lbm", "470.lbm",
					"lbm_base.i386",
					"3000 reference.dat 0 0 100_100_130_ldc.of", "");
			Benchmark benchmark471 = new Benchmark("471.omnetpp",
					"471.omnetpp", "omnetpp_base.i386", "omnetpp.ini", "");
			Benchmark benchmark473 = new Benchmark("473.astar", "473.astar",
					"astar_base.i386", "rivers.cfg", "");
			Benchmark benchmark481 = new Benchmark("481.wrf", "481.wrf",
					"wrf_base.i386", "", "");
			Benchmark benchmark483 = new Benchmark("483.xalancbmk",
					"483.xalancbmk", "xalancbmk_base.i386",
					"-v t5.xml xalanc.xsl", "");
			Benchmark benchmark998 = new Benchmark("998.specrand",
					"998.specrand", "specrand_base.i386", "1255432124 234923",
					"");
			Benchmark benchmark999 = new Benchmark("999.specrand",
					"999.specrand", "specrand_base.i386", "1255432124 234923",
					"");
			Benchmark benchmark416 = new Benchmark("416.gamess", "416.gamess",
					"gamess_base.i386", "", "triazolium.config");
			Benchmark benchmark436 = new Benchmark("436.cactusADM",
					"436.cactusADM", "cactusADM_base.i386", "benchADM.par", "");
			Benchmark benchmark437 = new Benchmark("437.leslie3d",
					"437.leslie3d", "leslie3d_base.i386", "", "leslie3d.in");
			Benchmark benchmark454 = new Benchmark("454.calculix",
					"454.calculix", "calculix_base.i386",
					"-i hyperviscoplastic", "");
			Benchmark benchmark459 = new Benchmark("459.GemsFDTD",
					"459.GemsFDTD", "GemsFDTD_base.i386", "", "");
			Benchmark benchmark465 = new Benchmark("465.tonto", "465.tonto",
					"tonto_base.i386", "", "");
			Benchmark benchmark482 = new Benchmark("482.sphinx3",
					"482.sphinx3", "sphinx3_base.i386", "ctlfile . args.an4",
					"");		
		
			this.register(benchmark400);
			this.register(benchmark401);
			this.register(benchmark403);
			this.register(benchmark410);
			this.register(benchmark429);
			this.register(benchmark433);
			this.register(benchmark434);
			this.register(benchmark435);
			this.register(benchmark444);
			this.register(benchmark445);
			this.register(benchmark447);
			this.register(benchmark450);
			this.register(benchmark453);
			this.register(benchmark458);
			this.register(benchmark456);
			this.register(benchmark462);
			this.register(benchmark464);
			this.register(benchmark470);
			this.register(benchmark471);
			this.register(benchmark473);
			this.register(benchmark481);
			this.register(benchmark483);
			this.register(benchmark998);
			this.register(benchmark999);
			this.register(benchmark416);
			this.register(benchmark436);
			this.register(benchmark437);
			this.register(benchmark454);
			this.register(benchmark459);
			this.register(benchmark465);
			this.register(benchmark482);
		}
		
		static const string TITLE = "CPU2006";
	}
	
	static class MediaBench: BenchmarkSuite {
		this() {
			super(TITLE, "MediaBench");

			Benchmark benchmarkAdpcmDec = new Benchmark("adpcm-dec",
					"adpcm-dec", "rawdaudio", "", "clinton.adpcm", "out.pcm");
			Benchmark benchmarkAdpcmEnc = new Benchmark("adpcm-enc",
					"adpcm-enc", "rawcaudio", "", "clinton.pcm", "out.adpcm");
			Benchmark benchmarkEpicDec = new Benchmark("epic-dec", "epic-dec",
					"unepic", "test_image.E");
			Benchmark benchmarkEpicEnc = new Benchmark("epic-enc", "epic-enc",
					"epic", "test_image.pgm -b 25");
			Benchmark benchmarkG721Dec = new Benchmark("g721-dec", "g721-dec",
					"decode", "-4 -l -f clinton.g721");
			Benchmark benchmarkG721Enc = new Benchmark("g721-enc", "g721-enc",
					"encode", "-4 -l -f clinton.pcm");
			Benchmark benchmarkGhostscript = new Benchmark("ghostscript",
					"ghostscript", "gs",
					"-sDEVICE=ppm -sOutputFile=test.ppm -dNOPAUSE -q -- tiger.ps");
			Benchmark benchmarkGsmDec = new Benchmark("gsm-dec", "gsm-dec",
					"untoast", "-fpl clinton.pcm.gsm");
			Benchmark benchmarkGsmEnc = new Benchmark("gsm-enc", "gsm-enc",
					"toast", "-fpl clinton.pcm");
			Benchmark benchmarkJpegDec = new Benchmark("jpeg-dec", "jpeg-dec",
					"djpeg", "-dct int -ppm -outfile testout.ppm testimg.jpg");
			Benchmark benchmarkJpegEnc = new Benchmark("jpeg-enc", "jpeg-enc",
					"cjpeg",
					"-dct int -progressive -opt -outfile testout.jpg testimg.ppm");
			Benchmark benchmarkMpegDec = new Benchmark("mpeg-dec", "mpeg-dec",
					"mpeg2decode", "-b mei16v2.m2v -r -f -o0 rec%d");
			Benchmark benchmarkMpegEnc = new Benchmark("mpeg-enc", "mpeg-enc",
					"mpeg2encode", "options.par out.m2v");
			Benchmark benchmarkPegwitDec = new Benchmark("pegwit-dec",
					"pegwit-dec", "pegwit", "-d pegwit.enc pegwit.dec",
					"my.sec");
			Benchmark benchmarkPegwitEnc = new Benchmark("pegwit-enc",
					"pegwit-enc", "pegwit",
					"-e my.pub pgptest.plain pegwit.enc", "encryption_junk");
			Benchmark benchmarkRasta = new Benchmark("rasta", "rasta", "rasta",
					"-z -A -J -S 8000 -n 12 -f map_weights.dat", "ex5_c1.wav",
					"ex5.asc");
		
			this.register(benchmarkAdpcmDec);
			this.register(benchmarkAdpcmEnc);
			this.register(benchmarkEpicDec);
			this.register(benchmarkEpicEnc);
			this.register(benchmarkG721Dec);
			this.register(benchmarkG721Enc);
			this.register(benchmarkGhostscript);
			this.register(benchmarkGsmDec);
			this.register(benchmarkGsmEnc);
			this.register(benchmarkJpegDec);
			this.register(benchmarkJpegEnc);
			this.register(benchmarkMpegDec);
			this.register(benchmarkMpegEnc);
			this.register(benchmarkPegwitDec);
			this.register(benchmarkPegwitEnc);
			this.register(benchmarkRasta);
		}
		
		static const string TITLE = "MediaBench";
	}
	
	static class Splash2: BenchmarkSuite {
		this(int threads) {
			super(TITLE, "Splash2");

			Benchmark benchmarkFft = new Benchmark("fft", "fft", "fft.i386",
					"-m18 -p" ~ to!(string)(threads) ~ " -n65536 -l4", "");
			Benchmark benchmarkLu = new Benchmark("lu", "lu", "lu.i386", "-p"
					~ to!(string)(threads) ~ " -n2048 -b16", "");
			Benchmark benchmarkRadix = new Benchmark("radix", "radix",
					"radix.i386", "-p" ~ to!(string)(threads) ~ " -r4096 -n262144 -m524288",
					"");
			Benchmark benchmarkOcean = new Benchmark("ocean", "ocean",
					"ocean.i386", "-n258 -p" ~ to!(string)(threads)
							~ " -e1e-07 -r20000 -t28800", "");
			Benchmark benchmarkWaterNsquared = new Benchmark("water-nsquared",
					"water-nsquared", "water-nsquared.i386", "" ~ to!(string)(threads) ~ "",
					"input");
			Benchmark benchmarkWaterSpatial = new Benchmark("water-spatial",
					"water-spatial", "water-spatial.i386", "" ~ to!(string)(threads) ~ "",
					"input");
			Benchmark benchmarkFmm = new Benchmark("fmm", "fmm", "fmm.i386", ""
					~ to!(string)(threads) ~ "", "input");
			Benchmark benchmarkCholesky = new Benchmark("cholesky", "cholesky",
					"cholesky.i386", "-p" ~ to!(string)(threads) ~ "", "tk14.O");
			Benchmark benchmarkRadiosity = new Benchmark("radiosity",
					"radiosity", "radiosity.i386", "-batch -room -p" ~ to!(string)(threads)
							~ "", "");
			Benchmark benchmarkRaytrace = new Benchmark("raytrace", "raytrace",
					"raytrace.i386", "-p" ~ to!(string)(threads) ~ " balls4.env", "");
			Benchmark benchmarkBarnes = new Benchmark("barnes", "barnes",
					"barnes.i386", "" ~ to!(string)(threads) ~ "", "input");
		
			this.register(benchmarkFft);
			this.register(benchmarkLu);
			this.register(benchmarkRadix);
			this.register(benchmarkOcean);
			this.register(benchmarkWaterNsquared);
			this.register(benchmarkWaterSpatial);
			this.register(benchmarkFmm);
			this.register(benchmarkCholesky);
			this.register(benchmarkRadiosity);
			this.register(benchmarkRaytrace);
			this.register(benchmarkBarnes);
		}
		
		static const string TITLE = "Splash2";		
	}
	
	static class PARSEC: BenchmarkSuite {
		this(int threads) {
			super(TITLE, "PARSEC");

			Benchmark benchmarkBodytrack = new Benchmark("bodytrack",
					"bodytrack", "bodytrack", "sequenceB_2 4 2 2000 5 0 "
							~ to!(string)(threads) ~ "", "");
			Benchmark benchmarkSwaptions = new Benchmark("swaptions",
					"swaptions", "swaptions", "-ns 32 -sm 10000 -nt " ~ to!(string)(threads)
							~ "", "");
			Benchmark benchmarkFluidanimate = new Benchmark("fluidanimate",
					"fluidanimate", "fluidanimate", "" ~ to!(string)(threads)
							~ " 5 in_100K.fluid out.fluid", "");
			Benchmark benchmarkCanneal = new Benchmark("canneal", "canneal",
					"canneal", "" ~ to!(string)(threads) ~ " 15000 2000 200000.nets", "");
			Benchmark benchmarkDedup = new Benchmark("dedup", "dedup", "dedup",
					"-c -p -f -t " ~ to!(string)(threads)
							~ " -i media.dat -o output.dat.ddp", "");
			Benchmark benchmarkStreamcluster = new Benchmark("streamcluster",
					"streamcluster", "streamcluster",
					"10 20 64 8192 8192 1000 none output.txt " ~ to!(string)(threads) ~ "",
					"");
		
			this.register(benchmarkBodytrack);
			this.register(benchmarkSwaptions);
			this.register(benchmarkFluidanimate);
			this.register(benchmarkCanneal);
			this.register(benchmarkDedup);
			this.register(benchmarkStreamcluster);
		}
		
		static const string TITLE = "PARSEC";
	}
	
	static this() {
		presets[WCETBench.TITLE] = new WCETBench();
		presets[OldenCustom1.TITLE] = new OldenCustom1();
		presets[CPU2006.TITLE] = new CPU2006();
		presets[MediaBench.TITLE] = new MediaBench();
		presets[Splash2.TITLE] = new Splash2(2);
		presets[PARSEC.TITLE] = new PARSEC(2);
	}
	
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	void register(Benchmark benchmark) {
		assert(!(benchmark.title in this.benchmarks));
		benchmark.suite = this;
		this.benchmarks[benchmark.title] = benchmark;
	}
	
	Benchmark opIndex(string index) {
		return this.benchmarks[index];
	}
	
	override string toString() {
		return format("BenchmarkSuite[title=%s, cwd=%s, benchmarks.length=%d]", this.title, this.cwd, this.benchmarks.length);
	}
	
	string title;
	string cwd;
	Benchmark[string] benchmarks;
	
	static BenchmarkSuite[string] presets;
}