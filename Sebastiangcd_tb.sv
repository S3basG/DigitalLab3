`timescale 1ns / 1ps

module Sebastiangcd_tb;

  // Parameters
  localparam int WIDTH = 8;
  localparam time TIMEOUT = 1ms;

  // Signals
  logic clk = 0;
  logic clkEn = 1;
  logic rst = 1;
  logic go = 0;
  logic done;
  logic [WIDTH-1:0] x = 0;
  logic [WIDTH-1:0] y = 0;
  logic [WIDTH-1:0] out;
  time start_time;

  // Clock generation
  always #20 if (clkEn) clk = ~clk;

  // DUT instantiation
//   gcd #(
//    .WIDTH(WIDTH)
//  ) uut (
 
  hlamgcd uut (
    .clk(clk),
    .reset(rst),
    .start(go),
    .done(done),
    .a(x),
    .b(y),
    .result(out)
  );

  // GCD reference function
  function automatic logic [WIDTH-1:0] compute_gcd(input int a, input int b);
    int x, y;
    begin
      x = a;
      y = b;
      while (x != y) begin
        if (x < y)
          y = y - x;
        else
          x = x - y;
      end
      compute_gcd = x;
    end
  endfunction

  // Test process
  initial begin
    // Reset
    clkEn <= 1;
    rst   <= 1;
    go    <= 0;
    x     <= 0;
    y     <= 0;
    repeat (10) @(posedge clk);
    rst <= 0;
    repeat (5) @(posedge clk);

    // Loop through test vectors
    for (int i = 1; i < 16; i++) begin
      for (int j = 1; j < 16; j++) begin
        @(posedge clk);
        x  <= i;
        y  <= j;
        go <= 1;

        @(posedge clk);  // pulse 'go' for 1 cycle
        go <= 0;
         @(posedge clk);
        // Wait for done or timeout
        start_time = $time;
        wait (done || $time - start_time >= TIMEOUT);

        if (!done) begin
          $warning("Timeout: done never asserted for x=%0d, y=%0d", i, j);
        end
        else begin
          logic [WIDTH-1:0] expected;
           
          expected = compute_gcd(i, j);
          if (out !== expected) begin
            $warning("Incorrect GCD for x=%0d, y=%0d. Expected %0d, Got %0d", 
                     i, j, expected, out);
          end
        end

        @(posedge clk);  // wait one cycle before next test
      end
    end

    clkEn <= 0;
   

    $display("All tests completed.");
    $finish;
  end

 // 1. Once 'done' is asserted, it should not stay high forever (done should eventually go low)
assert property (@(posedge clk) disable iff (rst)
    go |=> !go);
    

// 2. 'done' falling edge implies that 'go' was high exactly one clock before
      assert property (@(posedge clk) disable iff (rst) $fell(done) |-> $past(go, 1));
      
endmodule
