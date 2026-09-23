`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Rajesh Panicker  
-- 
-- Create Date: 09/22/2020 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 / Basys 3
-- Tool Versions: Vivado 2019.2
-- Description: RISC-V Processor Decoder Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Interface and implementation can be modified.
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file as well as any files derived from this.
----------------------------------------------------------------------------------
*/

module Decoder(
    input [6:0] Opcode ,
    input [2:0] Funct3 ,
    input [6:0] Funct7 ,
    output reg [1:0] PCS,		// 00 for non-control, 01 for conditional branch, 10 for jal, 11 for jalr
    output reg RegWrite,		// Asserted only by instructions which write to register file (load, auipc, lui, DPImm, DPReg);
    output reg MemWrite,		// Asserted only by store (sw)
    output reg MemtoReg,		// Asserted only by load (lw)
    output reg [1:0] ALUSrcA, 	// Needed for lui, auipic. Refer to the microarchitecture for its use. Uncomment wire and port map in RV.v as well
    output reg [1:0] ALUSrcB,		// Asserted by all instructions which use an immediate (load, store, lui, auipc, DPImm). Needs to be expanded to a 2-bit signal to support link functionality for jal, jalr. Change wire width in RV.v as well
    output reg [2:0] ImmSrc, 	// 000 for U, 010 for UJ, 011 for I, 110 for S, 111 for SB.
    output reg [3:0] ALUControl	// 0000 for add, 0001 for sub, 1110 for and, 1100 for or, 0010 for sll, 1010 for srl, 1011 for sra, 0001 for branch, 0000 for all others.
    					// Note that the most significant 3 bits are Funct3 for all DP instrns. LSB is the same as Funct[5] for DPReg type and DPImm_shifts. For other DPImms, Funct[5] is 0.
    					// It is the same as sub for branches, and add for all others not mentioned in the line above.
    ); 
// Change wire to reg if assigned inside a procedural (always) block. However, where it is easy enough, use assign instead of always.
// A 2-1 multiplexing can be done easily using an assign with a ternary operator
// For multiplexing with number of inputs > 2, a case construct within an always block is a natural fit. DO NOT to use nested ternary assignment operator as it hampers the readability of your code.
    
    	// todo: Implement Decoder here
    always @(Opcode, Funct3, Funct7) begin
    case(Opcode)
        7'b0110011: begin // R-type: add, sub, xor 
            PCS = 2'b00; // non-control
            RegWrite = 1;
            MemWrite = 0;
            MemtoReg = 0;
            
            ALUSrcA = 2'bx0; // Not used for R-type, dont care
            ALUSrcB = 2'bx0;
            
            ImmSrc = 3'bxxx; // Not used for R-type, dont care
            case (Funct3)   // Determine ALUControl based on Funct3 and Funct7: ALUControl = {Funct3, Funct7[5]}; // 4-bit ALUControl: {Funct3, Funct7[5]}
                3'b000: ALUControl = (Funct7[5]) ? 4'b0001 : 4'b0000; // sub or add
                3'b100: ALUControl = 4'b1000; // xor
                default: ALUControl = 4'bxxxx; // undefined
            endcase
        end

        7'b0010011: begin // I-type: addi, xori, slti
            PCS = 2'b00; // non-control
            RegWrite = 1;
            MemWrite = 0;
            MemtoReg = 0;
            
            ALUSrcA = 2'bx0; // Not used for I-type, dont care
            ALUSrcB = 2'b11; // Use immediate for I-type
            
            ImmSrc = 3'b011; // I-type immediate
            case (Funct3)   // Determine ALUControl based on Funct3: ALUControl = {Funct3, 1'b0}; 
            //becareful: ALUControl[0] = (funct3 == 0x5)? Funct7[5] : 1'b0 (Funct7[5] = imm[10] for I-type shift instructions)
                3'b000: begin
                    ALUControl = 4'b0000; // addi
                    ALUControl[0] = (Funct3 == 3'b101)? Funct7[5] : 1'b0;
                end
                3'b100: begin
                    ALUControl = 4'b1000; // xori
                    ALUControl[0] = (Funct3 == 3'b101)? Funct7[5] : 1'b0;
                end
                3'b010: begin
                    ALUControl = 4'b0100; // slti
                    ALUControl[0] = (Funct3 == 3'b101)? Funct7[5] : 1'b0;
                end

                default: ALUControl = 4'bxxxx; // undefined
            endcase
        end

        7'b1100011: begin // B-type: beq, bne, blt, bge
            PCS = 2'b01; // non-control
            RegWrite = 0;
            MemWrite = 0;
            MemtoReg = 1'bx; // dont care for branch
            
            ALUSrcA = 2'bx0; // dont care
            ALUSrcB = 2'bx0; // Use immediate for load
            
            ImmSrc = 3'b111; // B-type immediate for load
            ALUControl = 4'b0001; // sub for branch comparison
        end

        7'b0110111: begin // U-type: lui
            PCS = 2'b00; // non-control
            RegWrite = 1;
            MemWrite = 0;
            MemtoReg = 0;
            
            ALUSrcA = 2'b01; 
            ALUSrcB = 2'b11; // Use immediate for load
            
            ImmSrc = 3'b000; // U-type immediate for load
            ALUControl = 4'b0000; // add for lui
        end

        // // Add cases for other instruction types (I-type, S-type, B-type, U-type, J-type)
        // default: begin
        //     RegWrite = 0;
        //     MemWrite = 0;
        //     MemtoReg = 0;
        //     PCS = 2'b00;
        //     ALUSrcA = 2'bx0;
        //     ALUSrcB = 2'bx0;
        //     ImmSrc = 3'bxxx; // Not used for undefined instructions
        //     ALUControl = 4'bxxxx; // undefined
        // end
    endcase
end



	    
endmodule



