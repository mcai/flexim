/*
 * flexim/isa/mips/isa.d
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

module flexim.isa.mips.isa;

import flexim.all;

abstract class FieldDecoder {
	this(Decoder decoder, BitField field) {
		this.decoder = decoder;
		this.field = field;
	}
	
	bool decodeNext() {
		this.decoder.fieldValues[this.field] = this.decoder.machInst[this.field];		
		return this._decodeNext();
	}
	
	abstract bool _decodeNext();
	
	Decoder decoder;
	
	BitField field;
	BitField nextField;
	
	StaticInst leaf;
}

class OPCODE_HI_FieldDecoder : FieldDecoder {
	this(Decoder decoder) {
		super(decoder, OPCODE_HI);
	}
	
	override bool _decodeNext() {
		switch(this.decoder.machInst[this.field]) {
			case 0x0:
			case 0x1:
			case 0x2:
			case 0x3:
			case 0x4:
			case 0x5:
			case 0x6:
			case 0x7:
				this.nextField = OPCODE_LO;
				return false;
			default:
				assert(0);
		}
	}
}

class OPCODE_LO_FieldDecoder : FieldDecoder {
	this(Decoder decoder) {
		super(decoder, OPCODE_LO);
	}
	
	override bool _decodeNext() {
		switch(this.decoder.machInst[this.field]) {
			case 0x0:
			case 0x1:
			case 0x2:
			case 0x3:
			case 0x4:
			case 0x5:
			case 0x6:
			case 0x7:
				this.nextField = OPCODE_LO;
				return false;
			default:
				assert(0);
		}
	}
}

class Decoder {
	this(MachInst machInst) {
		this.machInst = machInst;
	}
	
	StaticInst decode() {
		return null;
	}
	
	MachInst machInst;
	uint[BitField] fieldValues;
	FieldDecoder[BitField] fieldDecoders;
}

class MipsISA : ISA {
	this() {
		
	}
	
	override StaticInst decode(MachInst machInst) {
		switch(machInst[OPCODE_HI]) {
			case 0x0:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x1:
										switch(machInst[MOVCI]) {
											case 0x0:
												return new FailUnimplemented("Movf", machInst);
											case 0x1:
												return new FailUnimplemented("Movt", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x0:
										switch(machInst[RS]) {
											case 0x0:
												switch(machInst[RT_RD]) {
													case 0x0:
														switch(machInst[SA]) {
															case 0x1:
																return new FailUnimplemented("Ssnop", machInst);
															case 0x3:
																return new FailUnimplemented("Ehb", machInst);
															default:
																return new Nop(machInst);
														}
													default:
														return new Sll(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x2:
										switch(machInst[RS_SRL]) {
											case 0x0:
												switch(machInst[SRL]) {
													case 0x0:
														return new Srl(machInst);
													case 0x1:
														return new FailUnimplemented("Rotr", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[RS]) {
											case 0x0:
												return new Sra(machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x4:
										return new Sllv(machInst);
									case 0x6:
										switch(machInst[SRLV]) {
											case 0x0:
												return new Srlv(machInst);
											case 0x1:
												return new FailUnimplemented("Rotrv", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x7:
										return new Srav(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[HINT]) {
											case 0x1:
												return new FailUnimplemented("Jr_hb", machInst);
											default:
												return new Jr(machInst);
										}
									case 0x1:
										switch(machInst[HINT]) {
											case 0x1:
												return new FailUnimplemented("Jalr_hb", machInst);
											default:
												return new Jalr(machInst);
										}
									case 0x2:
										return new FailUnimplemented("Movz", machInst);
									case 0x3:
										return new FailUnimplemented("Movn", machInst);
									case 0x4:
										return new Syscall(machInst);
									case 0x7:
										return new FailUnimplemented("Sync", machInst);
									case 0x5:
										return new FailUnimplemented("Break", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new Mfhi(machInst);
									case 0x1:
										return new Mthi(machInst);
									case 0x2:
										return new Mflo(machInst);
									case 0x3:
										return new Mtlo(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new Mult(machInst);
									case 0x1:
										return new Multu(machInst);
									case 0x2:
										return new Div(machInst);
									case 0x3:
										return new Divu(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[HINT]) {
									case 0x0:
										switch(machInst[FUNC_LO]) {
											case 0x0:
												return new Add(machInst);
											case 0x1:
												return new Addu(machInst);
											case 0x2:
												return new Sub(machInst);
											case 0x3:
												return new Subu(machInst);
											case 0x4:
												return new And(machInst);
											case 0x5:
												return new Or(machInst);
											case 0x6:
												return new Xor(machInst);
											case 0x7:
												return new Nor(machInst);
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x5:
								switch(machInst[HINT]) {
									case 0x0:
										switch(machInst[FUNC_LO]) {
											case 0x2:
												return new Slt(machInst);
											case 0x3:
												return new Sltu(machInst);
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Tge", machInst);
									case 0x1:
										return new FailUnimplemented("Tgeu", machInst);
									case 0x2:
										return new FailUnimplemented("Tlt", machInst);
									case 0x3:
										return new FailUnimplemented("Tltu", machInst);
									case 0x4:
										return new FailUnimplemented("Teq", machInst);
									case 0x6:
										return new FailUnimplemented("Tne", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x1:
						switch(machInst[REGIMM_HI]) {
							case 0x0:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new Bltz(machInst);
									case 0x1:
										return new Bgez(machInst);
									case 0x2:
										return new FailUnimplemented("Bltzl", machInst);
									case 0x3:
										return new FailUnimplemented("Bgezl", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new FailUnimplemented("Tgei", machInst);
									case 0x1:
										return new FailUnimplemented("Tgeiu", machInst);
									case 0x2:
										return new FailUnimplemented("Tlti", machInst);
									case 0x3:
										return new FailUnimplemented("Tltiu", machInst);
									case 0x4:
										return new FailUnimplemented("Teqi", machInst);
									case 0x6:
										return new FailUnimplemented("Tnei", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new Bltzal(machInst);
									case 0x1:
										switch(machInst[RS]) {
											case 0x0:
												return new Bal(machInst);
											default:
												return new Bgezal(machInst);
										}
									case 0x2:
										return new FailUnimplemented("Bltzall", machInst);
									case 0x3:
										return new FailUnimplemented("Bgezall", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[REGIMM_LO]) {
									case 0x4:
										return new FailUnimplemented("Bposge32", machInst);
									case 0x7:
										return new FailUnimplemented("WarnUnimplemented.synci", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x2:
						return new J(machInst);
					case 0x3:
						return new Jal(machInst);
					case 0x4:
						switch(machInst[RS_RT]) {
							case 0x0:
								return new B(machInst);
							default:
								return new Beq(machInst);
						}
					case 0x5:
						return new Bne(machInst);
					case 0x6:
						return new Blez(machInst);
					case 0x7:
						return new Bgtz(machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x1:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Addi(machInst);
					case 0x1:
						return new Addiu(machInst);
					case 0x2:
						return new Slti(machInst);
					case 0x3:
						switch(machInst[RS_RT_INTIMM]) {
							case 0xabc1:
								return new FailUnimplemented("Fail", machInst);
							case 0xabc2:
								return new FailUnimplemented("Pass", machInst);
							default:
								return new Sltiu(machInst);
						}
					case 0x4:
						return new Andi(machInst);
					case 0x5:
						return new Ori(machInst);
					case 0x6:
						return new Xori(machInst);
					case 0x7:
						switch(machInst[RS]) {
							case 0x0:
								return new Lui(machInst);
							default:
								return new Unknown(machInst);
						}
					default:
						return new Unknown(machInst);
				}
			case 0x2:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS]) {
									case 0x0:
										return new FailUnimplemented("Mfc0", machInst);
									case 0x4:
										return new FailUnimplemented("Mtc0", machInst);
									case 0x1:
										return new CP0Unimplemented("dmfc0", machInst);
									case 0x5:
										return new CP0Unimplemented("dmtc0", machInst);
									default:
										return new CP0Unimplemented("unknown", machInst);
									case 0x8:
										switch(machInst[MT_U]) {
											case 0x0:
												return new FailUnimplemented("Mftc0", machInst);
											case 0x1:
												switch(machInst[SEL]) {
													case 0x0:
														return new FailUnimplemented("Mftgpr", machInst);
													case 0x1:
														switch(machInst[RT]) {
															case 0x0:
																return new FailUnimplemented("Mftlo_dsp0", machInst);
															case 0x1:
																return new FailUnimplemented("Mfthi_dsp0", machInst);
															case 0x2:
																return new FailUnimplemented("Mftacx_dsp0", machInst);
															case 0x4:
																return new FailUnimplemented("Mftlo_dsp1", machInst);
															case 0x5:
																return new FailUnimplemented("Mfthi_dsp1", machInst);
															case 0x6:
																return new FailUnimplemented("Mftacx_dsp1", machInst);
															case 0x8:
																return new FailUnimplemented("Mftlo_dsp2", machInst);
															case 0x9:
																return new FailUnimplemented("Mfthi_dsp2", machInst);
															case 0x10:
																return new FailUnimplemented("Mftacx_dsp2", machInst);
															case 0x12:
																return new FailUnimplemented("Mftlo_dsp3", machInst);
															case 0x13:
																return new FailUnimplemented("Mfthi_dsp3", machInst);
															case 0x14:
																return new FailUnimplemented("Mftacx_dsp3", machInst);
															case 0x16:
																return new FailUnimplemented("Mftdsp", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													case 0x2:
														switch(machInst[MT_H]) {
															case 0x0:
																return new FailUnimplemented("Mftc1", machInst);
															case 0x1:
																return new FailUnimplemented("Mfthc1", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x3:
														return new FailUnimplemented("Cftc1", machInst);
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0xc:
										switch(machInst[MT_U]) {
											case 0x0:
												return new FailUnimplemented("Mttc0", machInst);
											case 0x1:
												switch(machInst[SEL]) {
													case 0x0:
														return new FailUnimplemented("Mttgpr", machInst);
													case 0x1:
														switch(machInst[RT]) {
															case 0x0:
																return new FailUnimplemented("Mttlo_dsp0", machInst);
															case 0x1:
																return new FailUnimplemented("Mtthi_dsp0", machInst);
															case 0x2:
																return new FailUnimplemented("Mttacx_dsp0", machInst);
															case 0x4:
																return new FailUnimplemented("Mttlo_dsp1", machInst);
															case 0x5:
																return new FailUnimplemented("Mtthi_dsp1", machInst);
															case 0x6:
																return new FailUnimplemented("Mttacx_dsp1", machInst);
															case 0x8:
																return new FailUnimplemented("Mttlo_dsp2", machInst);
															case 0x9:
																return new FailUnimplemented("Mtthi_dsp2", machInst);
															case 0x10:
																return new FailUnimplemented("Mttacx_dsp2", machInst);
															case 0x12:
																return new FailUnimplemented("Mttlo_dsp3", machInst);
															case 0x13:
																return new FailUnimplemented("Mtthi_dsp3", machInst);
															case 0x14:
																return new FailUnimplemented("Mttacx_dsp3", machInst);
															case 0x16:
																return new FailUnimplemented("Mttdsp", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													case 0x2:
														return new FailUnimplemented("Mttc1", machInst);
													case 0x3:
														return new FailUnimplemented("Cttc1", machInst);
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0xb:
										switch(machInst[RD]) {
											case 0x0:
												switch(machInst[POS]) {
													case 0x0:
														switch(machInst[SEL]) {
															case 0x1:
																switch(machInst[SC]) {
																	case 0x0:
																		return new FailUnimplemented("Dvpe", machInst);
																	case 0x1:
																		return new FailUnimplemented("Evpe", machInst);
																	default:
																		return new CP0Unimplemented("unknown", machInst);
																}
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											case 0x1:
												switch(machInst[POS]) {
													case 0xf:
														switch(machInst[SEL]) {
															case 0x1:
																switch(machInst[SC]) {
																	case 0x0:
																		return new FailUnimplemented("Dmt", machInst);
																	case 0x1:
																		return new FailUnimplemented("Emt", machInst);
																	default:
																		return new CP0Unimplemented("unknown", machInst);
																}
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											case 0xc:
												switch(machInst[POS]) {
													case 0x0:
														switch(machInst[SC]) {
															case 0x0:
																return new FailUnimplemented("Di", machInst);
															case 0x1:
																return new FailUnimplemented("Ei", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new Unknown(machInst);
												}
											default:
												return new CP0Unimplemented("unknown", machInst);
										}
									case 0xa:
										return new FailUnimplemented("Rdpgpr", machInst);
									case 0xe:
										return new FailUnimplemented("Wrpgpr", machInst);
								}
							case 0x1:
								switch(machInst[FUNC]) {
									case 0x18:
										return new FailUnimplemented("Eret", machInst);
									case 0x1f:
										return new FailUnimplemented("Deret", machInst);
									case 0x1:
										return new FailUnimplemented("Tlbr", machInst);
									case 0x2:
										return new FailUnimplemented("Tlbwi", machInst);
									case 0x6:
										return new FailUnimplemented("Tlbwr", machInst);
									case 0x8:
										return new FailUnimplemented("Tlbp", machInst);
									case 0x20:
										return new CP0Unimplemented("wait", machInst);
									default:
										return new CP0Unimplemented("unknown", machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x1:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS_HI]) {
									case 0x0:
										switch(machInst[RS_LO]) {
											case 0x0:
												return new FailUnimplemented("Mfc1", machInst);
											case 0x2:
												return new FailUnimplemented("Cfc1", machInst);
											case 0x3:
												return new FailUnimplemented("Mfhc1", machInst);
											case 0x4:
												return new FailUnimplemented("Mtc1", machInst);
											case 0x6:
												return new FailUnimplemented("Ctc1", machInst);
											case 0x7:
												return new FailUnimplemented("Mthc1", machInst);
											case 0x1:
												return new CP1Unimplemented("dmfc1", machInst);
											case 0x5:
												return new CP1Unimplemented("dmtc1", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[RS_LO]) {
											case 0x0:
												switch(machInst[ND]) {
													case 0x0:
														switch(machInst[TF]) {
															case 0x0:
																return new FailUnimplemented("Bc1f", machInst);
															case 0x1:
																return new FailUnimplemented("Bc1t", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[TF]) {
															case 0x0:
																return new FailUnimplemented("Bc1fl", machInst);
															case 0x1:
																return new FailUnimplemented("Bc1tl", machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												return new CP1Unimplemented("bc1any2", machInst);
											case 0x2:
												return new CP1Unimplemented("bc1any4", machInst);
											default:
												return new CP1Unimplemented("unknown", machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[RS_HI]) {
									case 0x2:
										switch(machInst[RS_LO]) {
											case 0x0:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Add_s", machInst);
															case 0x1:
																return new FailUnimplemented("Sub_s", machInst);
															case 0x2:
																return new FailUnimplemented("Mul_s", machInst);
															case 0x3:
																return new FailUnimplemented("Div_s", machInst);
															case 0x4:
																return new FailUnimplemented("Sqrt_s", machInst);
															case 0x5:
																return new FailUnimplemented("Abs_s", machInst);
															case 0x7:
																return new FailUnimplemented("Neg_s", machInst);
															case 0x6:
																return new FailUnimplemented("Mov_s", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Round_l_s", machInst);
															case 0x1:
																return new FailUnimplemented("Trunc_l_s", machInst);
															case 0x2:
																return new FailUnimplemented("Ceil_l_s", machInst);
															case 0x3:
																return new FailUnimplemented("Floor_l_s", machInst);
															case 0x4:
																return new FailUnimplemented("Round_w_s", machInst);
															case 0x5:
																return new FailUnimplemented("Trunc_w_s", machInst);
															case 0x6:
																return new FailUnimplemented("Ceil_w_s", machInst);
															case 0x7:
																return new FailUnimplemented("Floor_w_s", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_s", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_s", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_s", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_s", machInst);
															case 0x5:
																return new FailUnimplemented("Recip_s", machInst);
															case 0x6:
																return new FailUnimplemented("Rsqrt_s", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x3:
														return new CP1Unimplemented("unknown", machInst);
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																return new FailUnimplemented("Cvt_d_s", machInst);
															case 0x4:
																return new FailUnimplemented("Cvt_w_s", machInst);
															case 0x5:
																return new FailUnimplemented("Cvt_l_s", machInst);
															case 0x6:
																return new FailUnimplemented("Cvt_ps_s", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x5:
														return new CP1Unimplemented("unknown", machInst);
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_f_s", machInst);
															case 0x1:
																return new FailUnimplemented("C_un_s", machInst);
															case 0x2:
																return new FailUnimplemented("C_eq_s", machInst);
															case 0x3:
																return new FailUnimplemented("C_ueq_s", machInst);
															case 0x4:
																return new FailUnimplemented("C_olt_s", machInst);
															case 0x5:
																return new FailUnimplemented("C_ult_s", machInst);
															case 0x6:
																return new FailUnimplemented("C_ole_s", machInst);
															case 0x7:
																return new FailUnimplemented("C_ule_s", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_sf_s", machInst);
															case 0x1:
																return new FailUnimplemented("C_ngle_s", machInst);
															case 0x2:
																return new FailUnimplemented("C_seq_s", machInst);
															case 0x3:
																return new FailUnimplemented("C_ngl_s", machInst);
															case 0x4:
																return new FailUnimplemented("C_lt_s", machInst);
															case 0x5:
																return new FailUnimplemented("C_nge_s", machInst);
															case 0x6:
																return new FailUnimplemented("C_le_s", machInst);
															case 0x7:
																return new FailUnimplemented("C_ngt_s", machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Add_d", machInst);
															case 0x1:
																return new FailUnimplemented("Sub_d", machInst);
															case 0x2:
																return new FailUnimplemented("Mul_d", machInst);
															case 0x3:
																return new FailUnimplemented("Div_d", machInst);
															case 0x4:
																return new FailUnimplemented("Sqrt_d", machInst);
															case 0x5:
																return new FailUnimplemented("Abs_d", machInst);
															case 0x7:
																return new FailUnimplemented("Neg_d", machInst);
															case 0x6:
																return new FailUnimplemented("Mov_d", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Round_l_d", machInst);
															case 0x1:
																return new FailUnimplemented("Trunc_l_d", machInst);
															case 0x2:
																return new FailUnimplemented("Ceil_l_d", machInst);
															case 0x3:
																return new FailUnimplemented("Floor_l_d", machInst);
															case 0x4:
																return new FailUnimplemented("Round_w_d", machInst);
															case 0x5:
																return new FailUnimplemented("Trunc_w_d", machInst);
															case 0x6:
																return new FailUnimplemented("Ceil_w_d", machInst);
															case 0x7:
																return new FailUnimplemented("Floor_w_d", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_d", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_d", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_d", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_d", machInst);
															case 0x5:
																return new FailUnimplemented("Recip_d", machInst);
															case 0x6:
																return new FailUnimplemented("Rsqrt_d", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Cvt_s_d", machInst);
															case 0x4:
																return new FailUnimplemented("Cvt_w_d", machInst);
															case 0x5:
																return new FailUnimplemented("Cvt_l_d", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_f_d", machInst);
															case 0x1:
																return new FailUnimplemented("C_un_d", machInst);
															case 0x2:
																return new FailUnimplemented("C_eq_d", machInst);
															case 0x3:
																return new FailUnimplemented("C_ueq_d", machInst);
															case 0x4:
																return new FailUnimplemented("C_olt_d", machInst);
															case 0x5:
																return new FailUnimplemented("C_ult_d", machInst);
															case 0x6:
																return new FailUnimplemented("C_ole_d", machInst);
															case 0x7:
																return new FailUnimplemented("C_ule_d", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_sf_d", machInst);
															case 0x1:
																return new FailUnimplemented("C_ngle_d", machInst);
															case 0x2:
																return new FailUnimplemented("C_seq_d", machInst);
															case 0x3:
																return new FailUnimplemented("C_ngl_d", machInst);
															case 0x4:
																return new FailUnimplemented("C_lt_d", machInst);
															case 0x5:
																return new FailUnimplemented("C_nge_d", machInst);
															case 0x6:
																return new FailUnimplemented("C_le_d", machInst);
															case 0x7:
																return new FailUnimplemented("C_ngt_d", machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x2:
												return new CP1Unimplemented("unknown", machInst);
											case 0x3:
												return new CP1Unimplemented("unknown", machInst);
											case 0x7:
												return new CP1Unimplemented("unknown", machInst);
											case 0x4:
												switch(machInst[FUNC]) {
													case 0x20:
														return new FailUnimplemented("Cvt_s_w", machInst);
													case 0x21:
														return new FailUnimplemented("Cvt_d_w", machInst);
													case 0x26:
														return new CP1Unimplemented("cvt_ps_w", machInst);
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x5:
												switch(machInst[FUNC_HI]) {
													case 0x20:
														return new FailUnimplemented("Cvt_s_l", machInst);
													case 0x21:
														return new FailUnimplemented("Cvt_d_l", machInst);
													case 0x26:
														return new CP1Unimplemented("cvt_ps_l", machInst);
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x6:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Add_ps", machInst);
															case 0x1:
																return new FailUnimplemented("Sub_ps", machInst);
															case 0x2:
																return new FailUnimplemented("Mul_ps", machInst);
															case 0x5:
																return new FailUnimplemented("Abs_ps", machInst);
															case 0x6:
																return new FailUnimplemented("Mov_ps", machInst);
															case 0x7:
																return new FailUnimplemented("Neg_ps", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x1:
														return new CP1Unimplemented("unknown", machInst);
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_ps", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_ps", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_ps", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_ps", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x3:
														return new CP1Unimplemented("unknown", machInst);
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Cvt_s_pu", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x5:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Cvt_s_pl", machInst);
															case 0x4:
																return new FailUnimplemented("Pll", machInst);
															case 0x5:
																return new FailUnimplemented("Plu", machInst);
															case 0x6:
																return new FailUnimplemented("Pul", machInst);
															case 0x7:
																return new FailUnimplemented("Puu", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_f_ps", machInst);
															case 0x1:
																return new FailUnimplemented("C_un_ps", machInst);
															case 0x2:
																return new FailUnimplemented("C_eq_ps", machInst);
															case 0x3:
																return new FailUnimplemented("C_ueq_ps", machInst);
															case 0x4:
																return new FailUnimplemented("C_olt_ps", machInst);
															case 0x5:
																return new FailUnimplemented("C_ult_ps", machInst);
															case 0x6:
																return new FailUnimplemented("C_ole_ps", machInst);
															case 0x7:
																return new FailUnimplemented("C_ule_ps", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_sf_ps", machInst);
															case 0x1:
																return new FailUnimplemented("C_ngle_ps", machInst);
															case 0x2:
																return new FailUnimplemented("C_seq_ps", machInst);
															case 0x3:
																return new FailUnimplemented("C_ngl_ps", machInst);
															case 0x4:
																return new FailUnimplemented("C_lt_ps", machInst);
															case 0x5:
																return new FailUnimplemented("C_nge_ps", machInst);
															case 0x6:
																return new FailUnimplemented("C_le_ps", machInst);
															case 0x7:
																return new FailUnimplemented("C_ngt_ps", machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new CP1Unimplemented("unknown", machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x2:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS_HI]) {
									case 0x0:
										switch(machInst[RS_LO]) {
											case 0x0:
												return new CP2Unimplemented("mfc2", machInst);
											case 0x2:
												return new CP2Unimplemented("cfc2", machInst);
											case 0x3:
												return new CP2Unimplemented("mfhc2", machInst);
											case 0x4:
												return new CP2Unimplemented("mtc2", machInst);
											case 0x6:
												return new CP2Unimplemented("ctc2", machInst);
											case 0x7:
												return new CP2Unimplemented("mftc2", machInst);
											default:
												return new CP2Unimplemented("unknown", machInst);
										}
									case 0x1:
										switch(machInst[ND]) {
											case 0x0:
												switch(machInst[TF]) {
													case 0x0:
														return new CP2Unimplemented("bc2f", machInst);
													case 0x1:
														return new CP2Unimplemented("bc2t", machInst);
													default:
														return new CP2Unimplemented("unknown", machInst);
												}
											case 0x1:
												switch(machInst[TF]) {
													case 0x0:
														return new CP2Unimplemented("bc2fl", machInst);
													case 0x1:
														return new CP2Unimplemented("bc2tl", machInst);
													default:
														return new CP2Unimplemented("unknown", machInst);
												}
											default:
												return new CP2Unimplemented("unknown", machInst);
										}
									default:
										return new CP2Unimplemented("unknown", machInst);
								}
							default:
								return new CP2Unimplemented("unknown", machInst);
						}
					case 0x3:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x0: {
										return new FailUnimplemented("Lwxc1", machInst);
									}
									case 0x1: {
										return new FailUnimplemented("Ldxc1", machInst);
									}
									case 0x5: {
										return new FailUnimplemented("Luxc1", machInst);
									}
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Swxc1", machInst);
									case 0x1:
										return new FailUnimplemented("Sdxc1", machInst);
									case 0x5:
										return new FailUnimplemented("Suxc1", machInst);
									case 0x7:
										return new FailUnimplemented("Prefx", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x6:
										return new FailUnimplemented("Alnv_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Madd_s", machInst);
									case 0x1:
										return new FailUnimplemented("Madd_d", machInst);
									case 0x6:
										return new FailUnimplemented("Madd_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x5:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Msub_s", machInst);
									case 0x1:
										return new FailUnimplemented("Msub_d", machInst);
									case 0x6:
										return new FailUnimplemented("Msub_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Nmadd_s", machInst);
									case 0x1:
										return new FailUnimplemented("Nmadd_d", machInst);
									case 0x6:
										return new FailUnimplemented("Nmadd_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Nmsub_s", machInst);
									case 0x1:
										return new FailUnimplemented("Nmsub_d", machInst);
									case 0x6:
										return new FailUnimplemented("Nmsub_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x4:
						return new FailUnimplemented("Beql", machInst);
					case 0x5:
						return new FailUnimplemented("Bnel", machInst);
					case 0x6:
						return new FailUnimplemented("Blezl", machInst);
					case 0x7:
						return new FailUnimplemented("Bgtzl", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x3:
				switch(machInst[OPCODE_LO]) {
					case 0x4:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x2: {
										return new FailUnimplemented("Mul", machInst);
									}
									case 0x0:
										return new FailUnimplemented("Madd", machInst);
									case 0x1:
										return new FailUnimplemented("Maddu", machInst);
									case 0x4:
										return new FailUnimplemented("Msub", machInst);
									case 0x5:
										return new FailUnimplemented("Msubu", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Clz", machInst);
									case 0x1:
										return new FailUnimplemented("Clo", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x7:
										return new FailUnimplemented("sdbbp", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x7:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Ext", machInst);
									case 0x4:
										return new FailUnimplemented("Ins", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Fork", machInst);
									case 0x1:
										return new FailUnimplemented("Yield", machInst);
									case 0x2:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0: {
														return new FailUnimplemented("Lwx", machInst);
													}
													case 0x4: {
														return new FailUnimplemented("Lhx", machInst);
													}
													case 0x6: {
														return new FailUnimplemented("Lbux", machInst);
													}
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x4:
										return new FailUnimplemented("Insv", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addu_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Subu_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Addu_s_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Subu_s_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Muleu_s_ph_qbl", machInst);
													case 0x7:
														return new FailUnimplemented("Muleu_s_ph_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addu_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Subu_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Addq_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Subq_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Addu_s_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Subu_s_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Addq_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Subq_s_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addsc", machInst);
													case 0x1:
														return new FailUnimplemented("Addwc", machInst);
													case 0x2:
														return new FailUnimplemented("Modsub", machInst);
													case 0x4:
														return new FailUnimplemented("Raddu_w_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Addq_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Subq_s_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Muleq_s_w_phl", machInst);
													case 0x5:
														return new FailUnimplemented("Muleq_s_w_phr", machInst);
													case 0x6:
														return new FailUnimplemented("Mulq_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Mulq_rs_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmpu_eq_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Cmpu_lt_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Cmpu_le_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Pick_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Cmpgu_eq_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Cmpgu_lt_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Cmpgu_le_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmp_eq_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Cmp_lt_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Cmp_le_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Pick_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Precrq_qb_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Precr_qb_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Packrl_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Precrqu_s_qb_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Precrq_ph_w", machInst);
													case 0x5:
														return new FailUnimplemented("Precrq_rs_ph_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmpgdu_eq_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Cmpgdu_lt_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Cmpgdu_le_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Precr_sra_ph_w", machInst);
													case 0x7:
														return new FailUnimplemented("Precr_sra_r_ph_w", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x2:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Repl_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Replv_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Precequ_ph_qbl", machInst);
													case 0x5:
														return new FailUnimplemented("Precequ_ph_qbr", machInst);
													case 0x6:
														return new FailUnimplemented("Precequ_ph_qbla", machInst);
													case 0x7:
														return new FailUnimplemented("Precequ_ph_qbra", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Repl_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Replv_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Preceq_w_phl", machInst);
													case 0x5:
														return new FailUnimplemented("Preceq_w_phr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x3: {
														return new FailUnimplemented("Bitrev", machInst);
													}
													case 0x4:
														return new FailUnimplemented("Preceu_ph_qbl", machInst);
													case 0x5:
														return new FailUnimplemented("Preceu_ph_qbr", machInst);
													case 0x6:
														return new FailUnimplemented("Preceu_ph_qbla", machInst);
													case 0x7:
														return new FailUnimplemented("Preceu_ph_qbra", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Shll_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Shrl_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Shllv_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Shrlv_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Shra_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Shrav_qb", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Shll_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Shra_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Shllv_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Shrav_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Shll_s_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Shllv_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Shll_s_w", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Shllv_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Shrl_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Shrlv_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Adduh_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Subuh_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Adduh_r_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Subuh_r_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addqh_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Subqh_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Addqh_r_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Subqh_r_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Mul_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Mul_s_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addqh_w", machInst);
													case 0x1:
														return new FailUnimplemented("Subqh_w", machInst);
													case 0x2:
														return new FailUnimplemented("Addqh_r_w", machInst);
													case 0x3:
														return new FailUnimplemented("Subqh_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Mulq_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Mulq_rs_w", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[SA]) {
									case 0x2:
										return new FailUnimplemented("Wsbh", machInst);
									case 0x10:
										return new FailUnimplemented("Seb", machInst);
									case 0x18:
										return new FailUnimplemented("Seh", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpa_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dps_w_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Mulsa_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpau_h_qbl", machInst);
													case 0x4:
														return new FailUnimplemented("Dpaq_s_w_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Dpsq_s_w_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Mulsaq_s_w_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Dpau_h_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpax_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dpsx_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpsu_h_qbl", machInst);
													case 0x4:
														return new FailUnimplemented("Dpaq_sa_l_w", machInst);
													case 0x5:
														return new FailUnimplemented("Dpsq_sa_l_w", machInst);
													case 0x7:
														return new FailUnimplemented("Dpsu_h_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Maq_sa_w_phl", machInst);
													case 0x2:
														return new FailUnimplemented("Maq_sa_w_phr", machInst);
													case 0x4:
														return new FailUnimplemented("Maq_s_w_phl", machInst);
													case 0x6:
														return new FailUnimplemented("Maq_s_w_phr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpaqx_s_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dpsqx_s_w_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Dpaqx_sa_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpsqx_sa_w_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Append", machInst);
													case 0x1:
														return new FailUnimplemented("Prepend", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Balign", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Extr_w", machInst);
													case 0x1:
														return new FailUnimplemented("Extrv_w", machInst);
													case 0x2:
														return new FailUnimplemented("Extp", machInst);
													case 0x3:
														return new FailUnimplemented("Extpv", machInst);
													case 0x4:
														return new FailUnimplemented("Extr_r_w", machInst);
													case 0x5:
														return new FailUnimplemented("Extrv_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Extr_rs_w", machInst);
													case 0x7:
														return new FailUnimplemented("Extrv_rs_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Extpdp", machInst);
													case 0x3:
														return new FailUnimplemented("Extpdpv", machInst);
													case 0x6:
														return new FailUnimplemented("Extr_s_h", machInst);
													case 0x7:
														return new FailUnimplemented("Extrv_s_h", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Rddsp", machInst);
													case 0x3:
														return new FailUnimplemented("Wrdsp", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Shilo", machInst);
													case 0x3:
														return new FailUnimplemented("Shilov", machInst);
													case 0x7:
														return new FailUnimplemented("Mthlip", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[OP]) {
											case 0x0:
												switch(machInst[RD]) {
													case 0x1d:
														return new FailUnimplemented("Rdhwr", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					default:
						return new Unknown(machInst);
				}
			case 0x4:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Lb(machInst);
					case 0x1:
						return new Lh(machInst);
					case 0x3:
						return new Lw(machInst);
					case 0x4:
						return new Lbu(machInst);
					case 0x5:
						return new Lhu(machInst);
					case 0x2:
						return new Lwl(machInst);
					case 0x6:
						return new Lwr(machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x5:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Sb(machInst);
					case 0x1:
						return new Sh(machInst);
					case 0x3:
						return new Sw(machInst);
					case 0x2:
						return new Swl(machInst);
					case 0x6:
						return new Swr(machInst);
					case 0x7:
						return new FailUnimplemented("Cache", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x6:
				switch(machInst[OPCODE_LO]) {
					case 0x0: {
						return new FailUnimplemented("Ll", machInst);
					}
					case 0x1: {
						return new FailUnimplemented("Lwc1", machInst);
					}
					case 0x5:
						return new FailUnimplemented("Ldc1", machInst);
					case 0x2:
						return new CP2Unimplemented("lwc2", machInst);
					case 0x6:
						return new CP2Unimplemented("ldc2", machInst);
					case 0x3:
						return new FailUnimplemented("Pref", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x7:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new FailUnimplemented("Sc", machInst);
					case 0x1:
						return new FailUnimplemented("Swc1", machInst);
					case 0x5:
						return new FailUnimplemented("Sdc1", machInst);
					case 0x2:
						return new CP2Unimplemented("swc2", machInst);
					case 0x6:
						return new CP2Unimplemented("sdc2", machInst);
					default:
						return new Unknown(machInst);
				}
			default:
				return new Unknown(machInst);
		}
	}
}