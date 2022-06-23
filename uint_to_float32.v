//Unsigned int to F32 converter

module uint_to_float32 #(parameter DATA_IN_WIDTH = 8)(
  //clock
  input clk,
  //active low reset
  input reset_n,
  //inputs 
  input i_data_in_valid,
  input [DATA_IN_WIDTH-1:0] i_data_in,
  //outputs
  output reg [31:0] o_data_out,
  output reg o_data_out_valid
);

//state machine states
localparam INITIAL=3'd0,
      FILL_F32_FIELDS=3'd1,
      SHIFT_LEADING_ZEROS=3'd2,
      PACK_DATA_OUT = 3'd3,
      DONE = 3'd4;

localparam MANTISSA_WIDTH = 24, EXPONENT_WIDTH = 8, BIAS=127;

//internal signal declarations
reg [2:0] current_state;

//registered input 
reg [DATA_IN_WIDTH-1:0] w_data_in_reg;
//mantissa
reg [MANTISSA_WIDTH-1:0] w_m;
//exponent
reg [EXPONENT_WIDTH-1:0] w_e;
//sign
reg w_s;

//conversion state machine
always @(posedge clk)
begin
  if(!reset_n)
  begin
    current_state <= INITIAL;
    w_data_in_reg <= 0;
    w_m <= 0;
    w_e <= 0;
    w_s <= 0;
    o_data_out_valid <= 0;
  end
  else 
  begin
    case(current_state)
      INITIAL:
      begin
        if(i_data_in_valid)
        begin
          w_data_in_reg <= i_data_in;
          current_state <= FILL_F32_FIELDS;
        end
      end

      FILL_F32_FIELDS:
      begin
        if(w_data_in_reg == 0)
        begin
          w_e <= -BIAS;
          w_m <= 0;
          w_s <= 0;
          current_state <= PACK_DATA_OUT;
        end
        else
        begin
          w_e <= DATA_IN_WIDTH-1;
          w_m <= {w_data_in_reg, {(MANTISSA_WIDTH-DATA_IN_WIDTH){1'b0}}};
          current_state <= SHIFT_LEADING_ZEROS;
        end
      end

      SHIFT_LEADING_ZEROS:
      begin
        if(!w_m[MANTISSA_WIDTH-1])
        begin
          w_e <= w_e - 1;
          w_m <= w_m << 1;
          current_state <= SHIFT_LEADING_ZEROS;
        end
        else
        begin
          current_state <= PACK_DATA_OUT;
        end
      end

      PACK_DATA_OUT:
      begin
        o_data_out[22:0] <= w_m[MANTISSA_WIDTH-2:0];
        o_data_out[30:23] <= w_e + BIAS;
        o_data_out[31] <= 0;
        o_data_out_valid <= 1;
        current_state <= DONE;
      end

      DONE:
      begin
        o_data_out_valid <= 1;
        if(o_data_out_valid)
        begin
          o_data_out_valid <= 0;
          current_state <= INITIAL;
        end
      end
    endcase 
  end
end

endmodule