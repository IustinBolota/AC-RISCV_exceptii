`timescale 1ns / 1ps

module top(
    input clk,
    input res,
    input interrupt
    );
    
	wire PCWriteCond;
	wire PCWrite;
	wire IorD;
	wire MemRead;
	wire MemWrite;
	wire MemtoReg;
	wire IRWrite;
	wire RegWrite; 
	wire ALUSrcA;
	wire [1:0] ALUSrcB; 
	wire [1:0] ALUOp; 
	wire [1:0]PCSource;
	wire EPCWrite;
	wire [2:0] SelCause;
	wire CauseWrite;
	
	wire [6:0] op_code;
	wire invalid_adress;
	wire overflow_detect;
	
    data_path DP(
	   clk,
	   res,
	
       PCWriteCond,
       PCWrite,
       IorD,
       MemRead,
       MemWrite,
       MemtoReg,
       IRWrite,
       RegWrite, 
       ALUSrcA, 
       ALUSrcB, 
       ALUOp, 
       PCSource,
       EPCWrite,
       SelCause,
       CauseWrite,
        
       op_code,
       invalid_adress,
       overflow_detect
    );

    control_path CP(
	   clk,
	   res,
	   interrupt,
	
       PCWriteCond,
       PCWrite,
       IorD,
       MemRead,
       MemWrite,
       MemtoReg,
       IRWrite,
       RegWrite, 
       ALUSrcA, 
       ALUSrcB, 
       ALUOp, 
       PCSource,
       EPCWrite,
       SelCause,
       CauseWrite,
        
       op_code,
       invalid_adress,
       overflow_detect
    );	    
endmodule