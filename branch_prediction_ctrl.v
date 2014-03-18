//////////////////////////////////////////////////////////////////////////////////
// TU/e Eindhoven University Of Technology
// Eindhoven, The Netherlands
// 
// Created 14-3-2014
// Author Frank Boerman
//////////////////////////////////////////////////////////////////////////////////
module BRANCH_PREDICTION_CTRL(
        DataReg1,
		  DataReg2,
		  BranchOp,
//		  Address_current,
//		  BranchAddress_old,
		  BranchAddress_mux,
		  AdderMux,
		  Flush,
		  clk
    );
	 //ins and outs
    input  [31:0] DataReg1;
	 input  [31:0] DataReg2;
	 input  [1:0]  BranchOp;
	 input         clk;
//	 input  [31:0] Address_current;
//	 output [31:0] BranchAddress_old;
//	 reg    [31:0] BranchAddress_old;
	 output        BranchAddress_mux;
	 reg           BranchAddress_mux;
	 output        AdderMux;
	 reg           AdderMux;
	 output			Flush;
	 reg				Flush;
	 
	 //for internal use
	 reg    [1:0]  BranchOp_prev;
	 
    always @(posedge clk)//BranchOp or DataReg1 or DataReg2)
	 begin
	   //default
		BranchAddress_mux = 0;
		AdderMux 			= 0;
		Flush 				= 0;
		
		if (BranchOp == 1 || BranchOp == 2) // branch on equal or branch on non equal
		begin
			BranchAddress_mux = 1; //select new addres of the branch
			BranchOp_prev = BranchOp; //save the op code
//			BranchAddress_old = Address_current; //and save the current address
		end
		else if (BranchOp == 0 || BranchOp == 3) //no branch or jump
		begin
			case(BranchOp_prev)//check if there was a branch before
				1: //branch equal
				begin
					if (DataReg1 != DataReg2) //check if the condition to take the branch is false
					begin
						//if so than flush
						Flush = 1;
						//and calculate the correct address
						AdderMux = 1;
						//finally reset the branchop save
						BranchOp_prev = 0;
					end
				end
				2: //branch non equal
				begin //same logic as above
					if (DataReg1 == DataReg2)
					begin
						Flush = 1;
						AdderMux = 1;
						BranchOp_prev = 0;
					end
				end
			endcase
		end

	 end
endmodule
