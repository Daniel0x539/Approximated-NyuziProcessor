`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: TU Wien
// Engineer: Daniel Blattner
// 
// Create Date: 11.05.2023 09:35:48
// Design Name: Logarithmic based approximate floating point multiplier
// Module Name: LB_AFPM_lite
// Project Name: AFPM
// Target Devices: -
// Tool Versions: -
// Description: -
// 
// Dependencies: -
// 
// Revision:
// Revision 0.01 - File Created
// Revision 1.0 (11.05.2023) - First version
// Revision 1.1 (10.07.2023) - Changed code for implementation in Nyuzi-Core
// Additional Comments: The algorithm for the approximate floating point multiplier is based on the paper by Zijing et al. 
//                      https://doi.org/10.1145/3453688.3461509
//                      This is a copy of the LB_AFPM.sv, which only includes the significant multiplier.
//                      The interface is adjusted to the Nyuzi-Core
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.svh"

import defines::*;

module LB_AFPM_lite(
    input logic[31:0]   fp_sig_multiplier,
    input logic[31:0]   fp_sig_multiplicand,
    output logic[63:0]  fp_sig_product);
    
    /*logic multiplier_is_nan;
    logic multiplicand_is_nan;
    logic multiplier_is_inf;
    logic multiplicand_is_inf;
    logic multiplier_is_zero;
    logic multiplicand_is_zero;
    logic multiplier_hidden_bit;
    logic multiplicand_hidden_bit;
    logic mul_is_nan;
    
    assign multiplier_is_nan = fp_multiplier.exponent == 8'hff && fp_multiplier.significand != 0;
    assign multiplicand_is_nan = fp_multiplicand.exponent == 8'hff && fp_multiplicand.significand != 0;
    assign multiplier_is_inf = fp_multiplier.exponent == 8'hff && fp_multiplier.significand == 0;
    assign multiplicand_is_inf = fp_multiplicand.exponent == 8'hff && fp_multiplicand.significand == 0;
    assign multiplier_is_zero = fp_multiplier.exponent == 0 && fp_multiplier.significand == 0;
    assign multiplicand_is_zero = fp_multiplicand.exponent == 0 && fp_multiplicand.significand == 0;
    assign multiplier_hidden_bit = fp_multiplier.exponent != 0;         // 0 -> Subnormal number
    assign multiplicand_hidden_bit = fp_multiplicand.exponent != 0;
    // Result is NaN if one number is NaN or a 0.0*inf multiplication occur
    assign mul_is_nan = multiplier_is_nan || multiplicand_is_nan || 
                        (multiplier_is_zero && multiplicand_is_inf) || 
                        (multiplicand_is_zero && multiplier_is_inf);

    logic[FLOAT32_EXP_WIDTH-1:0] mul_exponent;
    logic mul_exponent_underflow;
    logic mul_exponent_carry;
    */
    
    // Bit for the normalization of result
    logic mul_exponent_cin;

    // The full significant of the floating point
    logic[FLOAT32_SIG_WIDTH:0] multiplier_full_significand;
    logic[FLOAT32_SIG_WIDTH:0] multiplicand_full_significand;
    
    assign multiplier_full_significand = fp_sig_multiplier[FLOAT32_SIG_WIDTH:0];
    assign multiplicand_full_significand = fp_sig_multiplicand[FLOAT32_SIG_WIDTH:0];
    
    // Proposed floating-point logarithm estimator of the paper
    function logic[FLOAT32_SIG_WIDTH:0] fp_le (input logic[FLOAT32_SIG_WIDTH:0] full_significand);
        case (full_significand[FLOAT32_SIG_WIDTH-1])
            0       : fp_le = {1'b0,full_significand[FLOAT32_SIG_WIDTH-1:0]};
            1       : fp_le = {2'h3,full_significand[FLOAT32_SIG_WIDTH-1:1]};
            default : fp_le = 24'h0;
        endcase
    endfunction
    
    logic[FLOAT32_SIG_WIDTH:0] multiplier_log_significand;
    logic[FLOAT32_SIG_WIDTH:0] multiplicand_log_significand;
    logic[FLOAT32_SIG_WIDTH:0] mul_log_significand;
    logic[FLOAT32_SIG_WIDTH-1:0] mul_significand;
    logic hidden_bit;
    
    // Significant calculation
    always_comb begin
        // Logarithm approximation
        multiplier_log_significand = fp_le(multiplier_full_significand);
        multiplicand_log_significand = fp_le(multiplicand_full_significand);
        
        mul_log_significand = multiplier_log_significand + multiplicand_log_significand;
        // Anti-logarithm approximation 
        case(mul_log_significand[FLOAT32_SIG_WIDTH])
            0       : mul_significand = mul_log_significand[FLOAT32_SIG_WIDTH-1:0];
            1       : mul_significand = {mul_log_significand[FLOAT32_SIG_WIDTH-2:0],1'b0};
            default : mul_significand = 23'h0;
        endcase
        mul_exponent_cin = ~(~(fp_sig_multiplier[FLOAT32_SIG_WIDTH-1] & fp_sig_multiplicand[FLOAT32_SIG_WIDTH-1]) & 
                        (~(fp_sig_multiplier[FLOAT32_SIG_WIDTH-1] | fp_sig_multiplicand[FLOAT32_SIG_WIDTH-1]) | 
                        mul_log_significand[FLOAT32_SIG_WIDTH]));
        hidden_bit = fp_sig_multiplier[FLOAT32_SIG_WIDTH] && fp_sig_multiplicand[FLOAT32_SIG_WIDTH];
        fp_sig_product = mul_exponent_cin ? {16'b0,hidden_bit,mul_significand,24'b0} : {17'b0,hidden_bit,mul_significand,23'b0};
    end
      
    // Normalizing bit calculation
    /*assign mul_exponent_cin = ~(~(fp_sig_multiplier[FLOAT32_SIG_WIDTH-1] & fp_sig_multiplicand[FLOAT32_SIG_WIDTH-1]) & 
                            (~(fp_sig_multiplier[FLOAT32_SIG_WIDTH-1] | fp_sig_multiplicand[FLOAT32_SIG_WIDTH-1]) | 
                            mul_log_significand[FLOAT32_SIG_WIDTH]));*/

    // Pack result into output
    // The product of the significant should be a 48 bit result, therefore the multiplication result will be placed accordingly
    // mul_exponent is at fp_sig_product[47], for the normalizing in the later stage
    // Rounding bit are set to zero due to the approximation of the multiplication
    //assign fp_sig_product = mul_exponent_cin ? {16'b0,1'b1,mul_significand,24'b0} : {17'b0,1'b1,mul_significand,23'b0};
    /*logic res_is_null;
    assign res_is_null = (fp_sig_multiplier == 32'b0) || (fp_sig_multiplicand == 32'b0);
    logic hidden_bit;
    assign hidden_bit = fp_sig_multiplier[FLOAT32_SIG_WIDTH] && fp_sig_multiplicand[FLOAT32_SIG_WIDTH];
    logic[63:0] mul_product;
    assign mul_product = mul_exponent_cin ? {16'b0,hidden_bit,mul_significand,24'b0} : {17'b0,hidden_bit,mul_significand,23'b0};
    assign fp_sig_product = res_is_null ? 64'b0 : mul_product;*/
    
    
    /*assign {mul_exponent_underflow, mul_exponent_carry, mul_exponent}
            =  {2'd0, fp_multiplier.exponent} + {2'd0, fp_multiplicand.exponent} - 10'd127 + mul_exponent_cin;  
      
    // Result handeling
    always_comb begin
        if (mul_is_nan) begin
            // Internal NaN encoding
            fp_product.sign = 1'b0;
            fp_product.exponent = 8'hff;
            fp_product.significand = 23'h7FFFFF;
        end else begin
            // Sign bit
            fp_product.sign = fp_multiplier.sign ^ fp_multiplicand.sign;
            if (mul_exponent_underflow) begin
                // Result is zero
                fp_product.exponent = 8'h0;
                fp_product.significand = 23'h0;
            end else begin
                if (mul_exponent_carry) begin
                    // Result is inf
                    fp_product.exponent = 8'hff;
                    fp_product.significand = 23'h0;
                end else begin
                    // Result of approximation
                    fp_product.exponent = mul_exponent;
                    fp_product.significand = mul_significand;
                end
            end
        end
    end*/
    
endmodule
