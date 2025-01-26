`timescale 1us/1ns

module IMEM #(
    parameter DATA_WIDTH = 16,  // 数据位宽
    parameter DEPTH = 64        // 存储深度
) (
    input clk,                  // 时钟信号
    input rstn,                 // 复位信号（低电平有效）
    input start,                // 输出启动信号
    input shift_enable,         // 移位使能信号
    input [15:0] FIFO_out,      // FIFO 输出信号
    output reg [DATA_WIDTH-1:0] serial_out,  // 串行输出
    output reg shift_done,      // 移位完成信号
    output reg read_done       // 读取完成信号（已读取64次）
);

    // 内部存储器
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    reg [5:0] count;            // 6 位计数器，范围 0-63
    integer i;
    
    // 计数逻辑 每次 start 信号为高时递增计数器
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0; // 复位时计数器清零
        end else if (start) begin
            if (count == DEPTH - 1) begin
                count <= 0; // 计数器达到最大值后重置为0
            end else begin
                count <= count + 1; // 递增计数器
            end
        end
    end

    // 数据移位逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= 0; // 复位时清零所有存储器数据
            end
            shift_done <= 0; // 复位时移位完成信号清零
        end else if (shift_enable && ~shift_done) begin
            for (i = 0; i < DEPTH-1; i = i + 1) begin
                memory[i] <= memory[i+1]; // 左移操作
            end
            memory[DEPTH-1] <= FIFO_out; // 最后一位填入 FIFO 输出
            shift_done <= 1; // 每次移位后激活移位完成信号
        end else begin
            shift_done <= 0; // 如果没有移位使能，保持移位完成信号为低
        end
    end

        // 读取逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            serial_out <= 0; // 复位时串行输出清零
            read_done <= 0; // 复位时读取完成信号清零
        end else if (start) begin
            serial_out <= memory[count]; // 输出当前计数位置的数据
            if (count == DEPTH - 1) begin
                read_done <= 1; // 读取完成后，设置读取完成信号为高
                count <= 0; // 重新开始计数
            end else begin
                read_done <= 0; // 未读取完成，保持读取完成信号为低
            end
        end
    end

endmodule
