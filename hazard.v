////////////////////////////////////////////////
// HAZARD.V
//
// TU/e Eindhoven University Of Technology
// Eindhoven, The Netherlands
// 
// Created: 21-11-2013
// Author: Bergmans, G (g.bergmans@student.tue.nl)
// Based on work by Sander Stuijk
// 
// Function:
//     Hazard detection unit
//
// Version:
//     (27-01-2014): initial version
//
//////////////////////////////////////////////!/

module HAZARD(
        enable,
        MEMWBRegWrite,
        EXMEMRegWrite,
        IDEXRegWrite,
        IDEXRegDst,
        IDEXWriteRegisterRt,
        IDEXWriteRegisterRd,
        EXMEMWriteRegister,
        MEMWBWriteRegister,
        Instr,
        BranchOpID,
//        BranchOpEX,
        dmem_wait,
        imem_wait,
        PCWrite,
        IFIDWrite,
        Hazard,
        pipe_en,
        imem_en,
		forward1,
		forward2,
		CtrlMemMemread,
		CtrlEXMemread
    );

    input   [0:0]   enable;
    input   [0:0]   MEMWBRegWrite;
    input   [0:0]   EXMEMRegWrite;
    input   [0:0]   IDEXRegWrite;
    input   [1:0]   IDEXRegDst;
    input   [4:0]   IDEXWriteRegisterRt;
    input   [4:0]   IDEXWriteRegisterRd;
    input   [4:0]   EXMEMWriteRegister;
    input   [4:0]   MEMWBWriteRegister;
    input   [31:0]  Instr;
    input   [1:0]   BranchOpID;
	 input	[1:0]	  CtrlMemMemread;
	 input	[1:0]	  CtrlEXMemread;
//    input   [1:0]   BranchOpEX;
    input   dmem_wait;
    input   imem_wait;
    output  [0:0]   PCWrite;
    reg     [0:0]   PCWrite;
    output  [0:0]   IFIDWrite;
    reg     [0:0]   IFIDWrite;
    output  [0:0]   Hazard;
    reg     [0:0]   Hazard;
    output  [0:0]   pipe_en;
    reg     [0:0]   pipe_en;
    output  [0:0]   imem_en;
    reg     [0:0]   imem_en;
    reg     [0:0]   hazard;
    reg     [4:0]   ifidreadregister1;
    reg     [4:0]   ifidreadregister2;
	output	[1:0]	forward1;
	reg		[1:0]	forward1;
	output 	[1:0]   forward2;
	reg		[1:0]   forward2;

    
    always @(MEMWBRegWrite or 
                EXMEMRegWrite or 
                IDEXRegWrite or 
                IDEXRegDst or 
                IDEXWriteRegisterRt or 
                IDEXWriteRegisterRd or 
                BranchOpID or 
//                BranchOpEX or 
                EXMEMWriteRegister or 
                MEMWBWriteRegister or 
                Instr or 
                enable or 
                dmem_wait or 
                imem_wait)
        
        begin
            //Read registers
            ifidreadregister1 = Instr[25:21];
            ifidreadregister2 = Instr[20:16];
            
            // Enable the pipeline and instruction memory
            imem_en = 1'b1;
            pipe_en = 1'b1;
				
				//default
            forward1 = 0;
				forward2 = 0;
				hazard = 0;
            // Check for hazards (for simplicity assume that register zero
            // can also cause a hazard)
            if (BranchOpID != 2'b00)
                // (Control) branch hazard
                // Don't fetch a new instruction, insert a 'nop'
                hazard = 1'b1;
            else 
//				if (IDEXRegWrite == 1'b1 && ( 
//                        IDEXRegDst == 2'b00 && IDEXWriteRegisterRt == ifidreadregister1 ||
//                        IDEXRegDst == 2'b01 && IDEXWriteRegisterRd == ifidreadregister1 ||
//                        IDEXRegDst == 2'b00 && IDEXWriteRegisterRt == ifidreadregister2 ||
//                        IDEXRegDst == 2'b01 && IDEXWriteRegisterRd == ifidreadregister2))
//                // EX hazard
//                hazard = 1'b1;
//            else 
				begin //forwarding
					//check for WB stage hazard
					if (MEMWBRegWrite == 1'b1 &&
							MEMWBWriteRegister == ifidreadregister1 &&
							MEMWBWriteRegister != 0)
					begin
						forward1 = 3;
					end
					
					if(MEMWBRegWrite == 1'b1 &&
							MEMWBWriteRegister == ifidreadregister2 &&
							MEMWBWriteRegister != 0)
					begin
						forward2 = 3;
					end
					
					//check for MEM stage hazard
					if (EXMEMRegWrite == 1'b1 &&
							EXMEMWriteRegister == ifidreadregister1 &&
							EXMEMWriteRegister != 0)
					begin
						if (CtrlMemMemread != 0)
						begin
							hazard = 1;
						end
						else
						begin
							forward1 = 2;
						end
					end
					if (EXMEMRegWrite == 1'b1 &&
							EXMEMWriteRegister == ifidreadregister2 &&
							EXMEMWriteRegister != 0)
					begin
						if (CtrlMemMemread != 0)
						begin
							hazard = 1;
						end
						else
						begin
							forward2 = 2;
						end
					end
					
					//check for EX stage hazard
					if (IDEXRegWrite == 1)
					begin
						if (IDEXRegDst == 2'b00 && IDEXWriteRegisterRt == ifidreadregister1 ||
                      IDEXRegDst == 2'b01 && IDEXWriteRegisterRd == ifidreadregister1)
							 begin
								if (CtrlEXMemread != 0)
								begin
									hazard = 1;
								end
								else
								begin
									forward1 = 1;
								end
							 end
							 
						if (IDEXRegDst == 2'b00 && IDEXWriteRegisterRt == ifidreadregister2 ||
                      IDEXRegDst == 2'b01 && IDEXWriteRegisterRd == ifidreadregister2)
							 begin
								if (CtrlEXMemread != 0)
								begin
									hazard = 1;
								end
								else
								begin
									forward2 = 1;
								end
							 end
					end
					
					//if (load & forward)
					//hazard
					//voor mem
					//load van de vertraagde ctrl memread
					//voor ex
					//load direct van memread
				end
			
            
            // Write output
            if (enable[1'b0] == 0)
            begin
                // block writing if not enabled
                PCWrite     = 1'b0;
                IFIDWrite   = 1'b0;
                Hazard      = hazard;
                imem_en     = 1'b0;
                pipe_en     = 1'b0;
            end
            else if (dmem_wait || imem_wait)
            begin
                PCWrite     = 1'b0;
                IFIDWrite   = 1'b0;
                Hazard      = hazard;
                pipe_en     = 1'b0;
                if (dmem_wait)
                    imem_en = 1'b0;
            end
            else if (hazard)
            begin
                // pre-fetch next instruction if it's branch hazard
                if (BranchOpID)
                begin
                    PCWrite = 1'b1;
                    imem_en = 1'b1;
                end
                else
                begin
                    PCWrite = 1'b0;
                    imem_en = 1'b0;
                end
                IFIDWrite   = 1'b0;
                Hazard      = 1'b1;
            end
            else
            begin
                // In case this instruction is a branch, fetch the next instruction,
                // but don't change the program counter. The next instruction will
                // namely not be decoded duuring the next cycle. (we will insert a 'nop')
                if (Instr[31:26] == 6'b000100 || Instr[31:26] == 6'b000101)
                begin
                    PCWrite = 1'b0;
                    imem_en = 1'b0;
                end
                else
                begin
                    PCWrite = 1'b1;
                    imem_en = 1'b1;
                end
                IFIDWrite   = 1'b1;
                Hazard      = 1'b0;
            end
        end

endmodule
