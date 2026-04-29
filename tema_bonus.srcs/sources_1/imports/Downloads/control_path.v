`timescale 1ns / 1ps

module control_path(
	input clk,
	input res,
	input interrupt,
	
	output PCWriteCond,
	output PCWrite,
	output IorD,
	output MemRead,
	output MemWrite,
	output MemtoReg,
	output IRWrite,
	output RegWrite, 
	output ALUSrcA, 
	output [1:0] ALUSrcB, 
	output [1:0] ALUOp, 
	output [1:0]PCSource,
	output EPCWrite,
	output [2:0] SelCause,
	output CauseWrite,
	
	input [6:0] op_code,
	input invalid_adress,
	input overflow_detect
    );
    
    reg [3:0] cs;
    reg [3:0] ns;
    
    
    reg [19:0] control; 
    
    assign {PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource, EPCWrite, CauseWrite, SelCause} = control; 
    
    // compute next state
    always@(cs or op_code)
        casex({cs,op_code})
            11'b0000_xxxxxxx: begin
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 1;
                              end                      
            
            11'b0001_0000011,         // lw
            11'b0001_0100011: begin   // sw
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 2;
                              end  
            11'b0001_0110011: begin  // R
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 6;
                              end  
            11'b0001_1100011: begin  // beq
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 8;
                              end
            11'b0001_0010011: begin  // I (some) -- similar to R
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 9;
                              end
            11'b0001_xxxxxxx: begin
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 11; //Unknown opcode
                              end
            
            11'b0010_0000011: begin
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = (invalid_adress != 0) ? 12 : 3; // lw
                              end
            11'b0010_0100011: begin
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = (invalid_adress != 0) ? 12 : 5; // sw
                              end      
            11'b0011_xxxxxxx: begin   // lw
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 4;
                              end
            
            11'b0100_xxxxxxx: begin  // lw
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
            
            11'b0101_xxxxxxx: begin  // sw
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
            
            11'b0110_xxxxxxx: begin  // R
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 7;
                              end 
                          
            11'b0111_xxxxxxx: begin   // R
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    if(overflow_detect!=1'b0)
                                        ns = 13;
                                    else
                                        ns = 0;
                              end
            
            11'b1000_xxxxxxx: begin  // beq
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
            
            11'b1001_xxxxxxx: begin  // I (some)
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 10;
                              end
                           
            11'b1010_xxxxxxx: begin   // I(some)
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    if(overflow_detect!=1'b0)
                                        ns = 13;
                                    else
                                        ns = 0;
                              end
            
            11'b1011_xxxxxxx: begin  // Unknown opcode
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
            
            11'b1100_xxxxxxx: begin  // Invalid memory acces
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
                              
            11'b1101_xxxxxxx: begin  // Overflow
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
                              
            11'b1110_xxxxxxx: begin  // Interrupt
                                if(interrupt != 0)
                                    ns = 14;
                                else
                                    ns = 0;
                              end
            
            default:
                ns = 0;
                                    
        endcase
              
    // update current state
    always @(posedge clk)
        if (res == 1)
            cs <= 0;
        else
            cs <= ns; 
    
    // compute (and generate) outputs
    always @(cs)
        case(cs)  // PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource, EPCWrite, CauseWrite, SelCause
            4'b0000: control = 20'b0_1_0_1_0_0_1_0_0_01_00_00_0_0_000;
            4'b0001: control = 20'b0_0_0_0_0_0_0_0_0_10_00_xx_0_0_000;
            4'b0010: control = 20'b0_0_0_0_0_0_0_0_1_10_00_xx_0_0_000;
            4'b0011: control = 20'b0_0_1_1_0_0_0_0_x_xx_xx_xx_0_0_000;
            4'b0100: control = 20'b0_0_0_0_0_1_0_1_x_xx_xx_xx_0_0_000;
            4'b0101: control = 20'b0_0_1_0_1_0_0_0_x_xx_xx_xx_0_0_000;
            4'b0110: control = 20'b0_0_0_0_0_0_0_0_1_00_10_xx_0_0_000;
            4'b0111: control = 20'b0_0_0_0_0_0_0_1_x_xx_xx_xx_0_0_000;
            4'b1000: control = 20'b1_0_0_0_0_0_0_0_1_00_01_01_0_0_000;
            4'b1001: control = 20'b0_0_0_0_0_0_0_0_1_10_11_xx_0_0_000;
            4'b1010: control = 20'b0_0_0_0_0_0_0_1_x_xx_xx_xx_0_0_000;
            4'b1011: control = 20'b0_0_0_0_0_0_0_0_x_xx_xx_10_1_1_001;
            4'b1100: control = 20'b0_0_0_0_0_0_0_0_x_xx_xx_10_1_1_010;
            4'b1101: control = 20'b0_0_0_0_0_0_0_0_x_xx_xx_10_1_1_011;
            4'b1110: control = 20'b0_0_0_0_0_0_0_0_x_xx_xx_10_1_1_100;
            default:
                control = 20'b0;            
            
        endcase
                
endmodule