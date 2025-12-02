module controller #(parameter WIDTH = 16,
                    parameter INSTR_LEN = 20,
                    parameter ADDR = 5) (
    input  logic                clk,
    input  logic                reset,
    input  logic                go,
    input  logic [INSTR_LEN-1:0] instruction,
    input  logic                done,
    output logic                enable,
    output logic [ADDR-1:0]     pc,
    output logic [3:0]          opcode,
    output logic [7:0]          a, b,
    output logic                invalid_opcode
);

    localparam logic [3:0] HALT_OP = 4'b1111;
    
    typedef enum logic [1:0] {
        S_WAIT,
        S_FETCH,
        S_DECODE,
        S_EXECUTE
    } state_t;
    
    state_t state, next_state;
    
    logic [ADDR-1:0] pc_reg;
    logic [3:0] opcode_reg;
    logic [7:0] a_reg, b_reg;
    
    logic [3:0] current_opcode;
    logic is_halt, is_valid;
    
    assign current_opcode = instruction[INSTR_LEN-1 -: 4];
    assign is_halt = (current_opcode == HALT_OP);
    assign is_valid = (current_opcode == 4'b0001) ||
                      (current_opcode == 4'b0010) ||
                      (current_opcode == 4'b0011) ||
                      (current_opcode == 4'b1011) ||
                      (current_opcode == HALT_OP);
    
    assign pc = pc_reg;
    assign opcode = opcode_reg;
    assign a = a_reg;
    assign b = b_reg;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_WAIT;
            pc_reg <= '0;
            opcode_reg <= '0;
            a_reg <= '0;
            b_reg <= '0;
        end
        else begin
            state <= next_state;
            
            if (state == S_FETCH) begin
                opcode_reg <= instruction[INSTR_LEN-1 -: 4];
                a_reg <= instruction[15:8];
                b_reg <= instruction[7:0];
            end
            
            if ((state == S_EXECUTE && done) || (state == S_DECODE && (is_halt || !is_valid))) begin
                pc_reg <= pc_reg + 1'b1;
            end
        end
    end
    
    always_comb begin
        next_state = state;
        enable = 1'b0;
        invalid_opcode = 1'b0;
        
        case (state)
            S_WAIT: begin
                if (go)
                    next_state = S_FETCH;
            end
            
            S_FETCH: begin
                next_state = S_DECODE;
            end
            
            S_DECODE: begin
                if (is_halt) begin
                    enable = 1'b1;
                    next_state = S_WAIT;
                end
                else if (is_valid) begin
                    next_state = S_EXECUTE;
                end
                else begin
                    invalid_opcode = 1'b1;
                    enable = 1'b1;
                    next_state = S_WAIT;
                end
            end
            
            S_EXECUTE: begin
                enable = 1'b1;
                if (done) begin
                    next_state = S_WAIT;
                end
            end
            
            default: begin
                next_state = S_WAIT;
            end
        endcase
    end

endmodule