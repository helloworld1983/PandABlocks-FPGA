////////////////////////////////////////////////////////////////////////////////
// Timing testbench: testblock - Second test
// Block simulation for test
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module testblock_2_tb;

reg clk_i = 0;
always #4 clk_i = ~clk_i;

// Inputs from initialisation file
reg         INPA;
reg  [1:0]  A;
reg  [31:0] FUNC;

//Outputs
reg         OUT;		//Output from ini file
wire        OUT_uut;	//Output from UUT
reg         OUT_err;	//Error signal

// Write Strobes
reg         FUNC_wstb;

//Signals used within test
reg         test_result = 0;
integer     fid;
integer     r;
integer     timestamp = 0;

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read synchronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//

initial begin
    repeat (5) @(posedge clk_i);
    while (1) begin
        timestamp <= timestamp + 1;
        @(posedge clk_i);
    end
end

//
// Read expected values file
//
integer ignore[18:0];
integer data_in[5:0];
reg is_file_end=0;
integer i;
initial for (i=0; i<=18; i=i+1) ignore[i]=0;

initial begin
    FUNC = 0;
    FUNC_wstb = 0;
    A = 0;
    INPA = 0;
    OUT = 0;

    @(posedge clk_i);
    fid=$fopen("2testblockexpected.csv","r");
    // Read and ignore description field
    r=$fgets(ignore, fid);
	// Read and store the expected data from the csv file
    while (!$feof(fid)) begin
        r=$fscanf(fid,"%d %d %d %d %d %d\n",
            data_in[5],
            data_in[4],
            data_in[3],
            data_in[2],
            data_in[1],
            data_in[0]
        );
        if (r != 6) begin
            $display("\n    error reading file \n");
            test_result <= 1;
            @(negedge clk_i);
            $finish(2);
        end
        wait (timestamp == data_in[5]) begin
            	FUNC <= data_in[4];
            	FUNC_wstb <= data_in[3];
            	A <= data_in[2];
            	INPA <= data_in[1];
            	OUT <= data_in[0];
        end
        @(posedge clk_i);
    end
    repeat(100) @(posedge clk_i);
    is_file_end = 1;
end

//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin
    if (~is_file_end) begin
    // If not equal, display an error.
    // If the io file signal contains an 0 when the UUT signal is zero, the
    // test should not error, but for other io signal values display an error
    	if (OUT != OUT_uut || (OUT > 0 && ^OUT_uut === 1'bx)) begin
    	    $display("OUT error detected at timestamp %d\n", timestamp);
    	    OUT_err = 1;
    	    test_result = 1;
        end
    end
end

// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i)
begin
    if (is_file_end) begin
        $display("Simulation has finished");
        $finish(2);
    end
end


// Instantiate the Unit Under Test (UUT)
testblock uut (

		.FUNC          (FUNC),
		.FUNC_wstb     (FUNC_wstb),
		.A          (A),
		.INPA_i        (INPA),
	 	.OUT_o        (OUT_uut),
    	.clk_i      (clk_i)
);

endmodule