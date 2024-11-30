%%verilog

// decoder module
module decoder_logic(
    // we get the instruction here
    input wire [17:0] instruction,
    // afterwards, we get the opcode, which is 2 bits
    output wire [1:0] opcode,
    // operand1 is 8 bits so we allocate 8 bits into it
    output wire [7:0] operand1,
    // same as operand1, we allocate 8 bits for operand2
    output wire [7:0] operand2
);

  // we assign the first 2 bits of the instruction to the opcode
  assign opcode = instruction[17:16];
  // assign the 8 bits after the first 2 bits of the instruction
  assign operand1 = instruction[15:8];
  // assign the 8 bits after the first 10 bits (or last 8 bits) of the instruction
  assign operand2 = instruction[7:0];

endmodule

// fulladder module
module fulladder_logic(
    // add two single bits w/ a carry in, with outputs of sum and a carry-out
    // we will be needing two operands (operand1, operand2 for the single bits)
    // a carry (cin)
    // two outputs: (sum, cout)
    input operand1,
    input operand2,
    input cin,
    output sum ,
    output cout
  );

  assign sum = cin ^ operand1 ^ operand2; // we get the XOR of all bits (the sum is either 1 if it adheres to xor, 0 if not)
  assign cout = (operand1 & operand2) | (cin & (operand1 ^ operand2)); // get the AND of op1 and op2, it is then connected with an OR with the AND of cin and XOR of op1 and op2
endmodule

// 8-bit adder module
module add_8_bits(
    input [7:0] operand1,
    input [7:0] operand2,
    input Cin,
    output [7:0] sum,
    output cout
  );

  wire [7:0] carry; // Internal carry wire

  fulladder_logic fa0(operand1[0], operand2[0], Cin, sum[0], carry[0]);
  fulladder_logic fa1(operand1[1], operand2[1], carry[0], sum[1], carry[1]);
  fulladder_logic fa2(operand1[2], operand2[2], carry[1], sum[2], carry[2]);
  fulladder_logic fa3(operand1[3], operand2[3], carry[2], sum[3], carry[3]);
  fulladder_logic fa4(operand1[4], operand2[4], carry[3], sum[4], carry[4]);
  fulladder_logic fa5(operand1[5], operand2[5], carry[4], sum[5], carry[5]);
  fulladder_logic fa6(operand1[6], operand2[6], carry[5], sum[6], carry[6]);
  fulladder_logic fa7(operand1[7], operand2[7], carry[6], sum[7], cout);

endmodule

// module for the XOR for two 8 bits input
module xor_8_bits(
    input [7:0] operand1,
    input [7:0] operand2,
    output [7:0] result
);

  assign result = operand1 ^ operand2;
endmodule

// module for the NOT AND for two 8 bits input
module nand_8_bits(
    input [7:0] operand1,
    input [7:0] operand2,
    output [7:0] result
);
  assign result = ~ (operand1 & operand2);
endmodule

// module function associated for AB6L
module ab6l_8bits (
    input [7:0] A, // 8-bit input A (operand1)
    input [7:0] B, // 8-bit input B (operand2)
    output [7:0] O // 8-bit output O (output)
);

  // AB6L O = OR(A, B)-B
  assign O = (A | B) - B;
endmodule

// TEST BENCH AND MAIN MODULE ////////////////////////////////////////////

// Main module
module main(
    input wire [17:0] instruction,
    output reg [7:0] result
);

  // wires to connect to the decoder output
  wire [1:0] opcode;
  wire [7:0] operand1;
  wire [7:0] operand2;
  wire [7:0] carry_out; // Declare a wire for carry-out
  // wire outputs for the results
  wire [7:0] result_full_adder;
  wire [7:0] result_xor;
  wire [7:0] result_nand;
  wire [7:0] result_ab6l;

  // MODULE CALLS /////////////////////////////////////
  // calling decoder_logic

  decoder_logic decoder(
      .instruction(instruction),
      .opcode(opcode),
      .operand1(operand1),
      .operand2(operand2)
  );

  // calling 8-bit full adder
  add_8_bits adder(
      .operand1(operand1),
      .operand2(operand2),
      .Cin(0),
      .sum(result_full_adder),
      .cout(carry_out) // Ignoring carry-out
  );

  // calling 8-bit xor
  xor_8_bits xor_op(
      .operand1(operand1),
      .operand2(operand2),
      .result(result_xor)

  );
  // calling 8-bit nand
  nand_8_bits nand_op(
      .operand1(operand1),
      .operand2(operand2),
      .result(result_nand)
  );
  // calling 8-bit function (O = OR(A, B)-B)
  ab6l_8bits ab6l_func(
      .A(operand1),
      .B(operand2),
      .O(result_ab6l)
  );
  // menu

  always @(*) begin
    case(opcode)
      2'b00: result = result_full_adder; // FULL ADDER
      2'b01: result = result_xor;        // XOR
      2'b10: result = result_nand;       // NAND
      2'b11: result = result_ab6l;       // Custom Function
      default: result = 8'b0;            // Default case
    endcase
  end
endmodule

module testbench;
  reg [17:0] instruction; // Input instruction
  wire [7:0] result;      // Output result

  // Instantiate the DUT (Device Under Test)
  main dut (
      .instruction(instruction),
      .result(result)
  );

  // Test Cases
  initial begin
      $display("Starting Testbench...");

      // Test Full Adder (opcode 00)
      instruction = 18'b00_00000011_00000001; // Add 5+9
      #10;
      $display("Opcode: 00 | Full Adder | Instruction: %b | Result: %b ", instruction, result);

      // Test XOR (opcode 01)
      instruction = 18'b01_00000011_00000010; // XOR 3 ^ 2
      #10;
      $display("Opcode: 01 | XOR | Instruction: %b | Result: %b", instruction, result);

      // Test NAND (opcode 10)
      instruction = 18'b10_00000011_00000001; // NAND 3 & 1
      #10;
      $display("Opcode: 10 | NAND | Instruction: %b | Result: %b", instruction, result);

      // Test AB6L Custom Function (opcode 11)
      instruction = 18'b11_10000000_00000001; //
      #10;
      $display("Opcode: 11 | AB6L Func | Instruction: %b | Result: %b", instruction, result);

    $finish;
  end
endmodule

