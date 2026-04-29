
module tb_top(

);
    reg clk;
    reg res;
    reg interrupt;

    top DUT(
        .clk(clk),
        .res(res),
        .interrupt(interrupt)
    );
    
    initial begin
        clk = 0; res = 0; interrupt = 0;
        #10 res = 1;
        #10 res = 0;
        #50 interrupt = 1;
        #10 interrupt = 0;
        #700 $finish;
    end

    always #5 clk = ~clk;

endmodule