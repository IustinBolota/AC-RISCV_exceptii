module data_path(
	input clk,
	input res,
	
	input PCWriteCond,
	input PCWrite,
	input IorD,
	input MemRead,
	input MemWrite,
	input MemtoReg,
	input IRWrite,
	input RegWrite, 
	input ALUSrcA, 
	input [1:0] ALUSrcB, 
	input [1:0] ALUOp, 
	input [1:0]PCSource,
	input EPCWrite,
	input [2:0] SelCause,
	input CauseWrite,
	
	output [6:0] op_code,
	output invalid_adress,
	output overflow_detect
);

reg [31:0] PC;
reg [31:0] IR;

reg [31:0] ALUout;

reg [31:0] A;

reg [31:0] B;

reg [31:0] MDR;

reg [7:0] mem [0:1023];

reg [31:0] regs [0:31];

reg [7:0] exc_routines [0:15];

wire [31:0] addr_mem;

wire Zero;

wire [31:0] da;

wire [31:0] db;

reg [31:0] alu;

wire [31:0] opA;

wire [31:0] opB;

wire [4:0] rc;

reg [31:0] imm32;

reg [31:0] EPC;

reg [2:0] Cause;

reg [31:0] EAddr;

reg [31:0] cause_code;

reg [31:0] PC_offset;

reg overflow;

reg[31:0] instr_beq;

assign Zero = (alu == 0) ? 1 : 0;

assign opA = (ALUSrcA == 1) ? A : PC;

assign opB = (ALUSrcB == 2'b00) ? 	B :
			 ((ALUSrcB == 2'b01) ? 	4 :
			 ((ALUSrcB == 2'b10) ? 	imm32 : 0 ));
			 
assign PCSource =(Cause != 0) ? 11 : PCSource;

assign invalid_adress = (A[1:0]!=2'b0) ? 1'b1 : 1'b0;

assign overflow_detect = overflow;

// imm32 model
always@(IR) begin
	case(IR[6:0])
        7'b0000011,
        7'b0001111,
        7'b0011011,
        7'b1100111,
        7'b1110011,
        7'b0010011: imm32 = { {20{IR[31]}}, IR[31:20]};
        7'b0100011: imm32 = { {20{IR[31]}}, IR[31:25], IR[11:7]};
        7'b1100011: imm32 = { {20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};            
        7'b1101111: imm32 = { {12{IR[31]}}, IR[19:12], IR[20], IR[30:25], IR[11:8], 1'b0};            
        7'b0010111,
        7'b0110111: imm32 = { IR[31:12], {12{1'b0}}}; 
        default:
            imm32 = 32'h0000_0000;
	endcase
end

// ALU model
always@(ALUOp or IR[31:25] or IR[14:12] or opA or opB)
    casex({ALUOp, IR[31:25], IR[14:12]})
        12'b00_xxxxxxx_xxx: alu = opA + opB; // lw sw
        12'b01_xxxxxxx_xxx: alu = opA - opB; // beq
            
        12'b10_0000000_000: begin
                                alu = opA + opB; // add
                                overflow = (~(opA[31] ^ opB[31]) && ~(alu[31] ^ opB[31])) ? 1'b0 : 1'b1;
                            end
        12'b10_0100000_000: alu = opA - opB; // sub            
        12'b10_0000000_111: alu = opA & opB; // and
        12'b10_0000000_110: alu = opA | opB; // or
        12'b10_0000000_100: alu = opA ^ opB; // xor
            
        12'b11_xxxxxxx_000: begin
                                alu = opA + opB; // addi
                                overflow = (~(opA[31] ^ opB[31]) && ~(alu[31] ^ opB[31])) ? 1'b0 : 1'b1;
                            end
        12'b11_xxxxxxx_111: alu = opA & opB; // andi
        12'b11_xxxxxxx_110: alu = opA | opB; // ori
        12'b11_xxxxxxx_100: alu = opA ^ opB; // xori           
            
        default:
            alu = 32'b0;
	endcase

//Cause selection
always@(SelCause)
    casex({SelCause})
        3'b001: begin
                    cause_code <= 32'd1; //unknown opcode
                    EAddr <= 32'd248;
                end
        3'b010: begin
                    cause_code <= 32'd2; //invalid memory adress
                    EAddr <= 32'd248;
                end
        3'b011: begin
                    cause_code <= 32'd3; //overflow la adunare
                    EAddr <= 32'd248;
                end
        3'b100: begin
                    cause_code <= 32'd4; //intrerupere
                    EAddr <= 32'd248;
                end
        default: cause_code <=32'b0;
    endcase
    
// PC model
always@(posedge clk)
	if (res == 1) 
	begin
		PC <= 0;
		EPC <= 0;
    end
	else
	begin
		casex({PCWrite, PCWriteCond, IR[14:12], Zero, PCSource, EPCWrite, CauseWrite})
		  10'b1_x_xxx_x_00_0_0: begin
		                          PC <= alu;
		                          PC_offset <= EPC - PC - 4;
		                          //EAddr <= alu;
		                      end
		  10'b1_x_xxx_x_01_0_0: begin
		                          PC <= ALUout;
		                          PC_offset <= EPC - PC - 4;
		                          //EAddr <= ALUout;
		                      end
		  10'b0_1_000_1_00_0_0: begin
		                          PC <= alu;
		                          PC_offset <= EPC - PC - 4;
		                          //EAddr <= alu;
		                      end
		  10'b0_1_000_1_01_0_0: begin
		                          PC <= ALUout - 4;
		                          PC_offset <= EPC - PC - 4;
		                          //EAddr <= ALUout - 4;
		                      end
		  10'b0_1_001_0_00_0_0: begin
		                          PC <= alu;
		                          PC_offset <= EPC - PC - 4;
		                          //EAddr <= alu;
		                      end
		  10'b0_1_001_0_01_0_0: begin
		                          PC <= ALUout - 4;
		                          PC_offset <= EPC - PC -4;
		                          //EAddr <= ALUout - 4;
		                      end	
		  10'bx_x_xxx_x_xx_1_1: begin
		                          EPC <= PC;
		                          Cause <= cause_code;
		                          PC <= EAddr;
		                      end 

		  default:
		      begin
		          PC <= PC;
		      end
		endcase
    end

// IR model
always@(posedge clk)
	casex({res, IRWrite})
		2'b1_x : IR <= 0;
		2'b0_1 : begin 
			IR[31:24] 	<= mem[addr_mem+3];
			IR[23:16] 	<= mem[addr_mem+2];
			IR[15:8] 	<= mem[addr_mem+1];
			IR[7:0] 	<= mem[addr_mem];
			end
	endcase

assign addr_mem = (IorD == 0) ? PC : ALUout;

always@(posedge clk)
	ALUout <= alu;

always@(posedge clk)
	A <= da;

always@(posedge clk)
	B <= db;

always@(posedge clk) begin
	MDR[31:24] 	<= mem[addr_mem+3];
	MDR[23:16] 	<= mem[addr_mem+2];
	MDR[15:8] 	<= mem[addr_mem+1];
	MDR[7:0] 	<= mem[addr_mem];	
end

wire [4:0] ra = IR[19:15];

assign da = regs[ra];

wire [4:0] rb = IR[24:20];

assign db = regs[rb];	

assign rc = IR[11:7];

// Register file model
always@(posedge clk)
	if (res == 1) begin
		regs[0] <= 0; regs[1] <= 0; regs[2] <= 0; regs[3] <= 0; regs[4] <= 0; regs[5] <= 0;
		regs[6] <= 0; regs[7] <= 0; regs[8] <= 0; regs[9] <= 0; regs[10] <= 0; regs[11] <= 0;
		regs[12] <= 0; regs[13] <= 0; regs[14] <= 0; regs[15] <= 0; regs[16] <= 0; regs[17] <= 0;
		regs[18] <= 0; regs[19] <= 0; regs[20] <= 0; regs[21] <= 0; regs[22] <= 0; regs[23] <= 0;
		regs[24] <= 0; regs[25] <= 0; regs[26] <= 0; regs[27] <= 0; regs[28] <= 0; regs[29] <= 0;
		regs[30] <= 0; regs[31] <= 0;
	end else if (rc != 0 && RegWrite == 1) 
		regs[rc] <= (MemtoReg == 1) ? MDR : ALUout; 

// memory write operation
always@(posedge clk)
begin
	if (MemWrite == 1) begin
		mem[addr_mem+3]	<= B[31:24];
		mem[addr_mem+2] <= B[23:16];
		mem[addr_mem+1] <= B[15:8];
		mem[addr_mem+0] <= B[7:0];	
	end
	instr_beq = {PC_offset[12], PC_offset[10:5], 5'd0, 5'd0, 3'b000, PC_offset[4:1], PC_offset[11], 7'b1100011};
	mem[255] = instr_beq[31:24]; mem[254] = instr_beq[23:16]; mem[253] = instr_beq[15:8]; mem[252] = instr_beq[7:0];
end
assign op_code = IR[6:0];
	
integer i;
reg [31:0] temp_mem [0:512];  // Adjust depth as needed
initial begin
	$readmemh("mem.mem", temp_mem);
    `define TEXT_OFFSET 0
    `define TEXT_WORDS 64
    `define DATA_OFFSET 256
    `define DATA_WORDS (1024-`DATA_OFFSET)
    for (i = 0; i < `TEXT_WORDS; i = i + 1) begin
     	mem[i*4 + 3+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][31:24];
      mem[i*4 + 2+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][23:16];
      mem[i*4 + 1+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][15:8];
      mem[i*4 + 0+`TEXT_OFFSET] = temp_mem[i+`TEXT_OFFSET][7:0];
    end
    for (i = 0; i < `DATA_WORDS; i = i + 1) begin
      mem[i*4 + 3+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][31:24];
      mem[i*4 + 2+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][23:16];
      mem[i*4 + 1+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][15:8];
      mem[i*4 + 0+`DATA_OFFSET] = temp_mem[i+`DATA_OFFSET][7:0];
    end
    
    mem[248] = 8'h13; mem[249] = 8'h00; mem[250] = 8'h00; mem[251] = 8'h00;
    mem[200] = 8'hff; mem[201] = 8'hff; mem[202] = 8'hff; mem[203] = 8'h7f; 
end

endmodule