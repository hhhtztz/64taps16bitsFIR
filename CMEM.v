`timescale 1us/1ns

// coefficient_memory

module CMEM #(
    parameter DATA_WIDTH = 16,  // 数据位宽
    parameter DEPTH = 64        // 存储深度
) (
    input clk,                  // 时钟信号
    input rstn,                 // 复位信号（低电平有效）
    input cload,                // 写入使能
    input [$clog2(DEPTH)-1:0] caddr, // 地址信号 [5:0]caddr
    input [DATA_WIDTH-1:0] cin, // 写入数据 [15:0]cin
    input rd_en,                // 读取使能
    output reg [DATA_WIDTH-1:0] data_out, // 读取数据 [15:0]data_out
    output reg readco_done      // 读取完成信号
);

    // 存储器数组
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1]; // [15:0] memory [0:63]

    // 内部计数器
    reg [6:0] count;  // 计数器，用于跟踪当前读取的地址

    // 写入逻辑（通过 cload 使能写入）
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 可选：复位时初始化存储器
        end else if (cload) begin
            memory[caddr] <= cin; // 从文件加载的数据写入指定地址
        end
    end

    // 读取逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_out <= 0;
            readco_done <= 0; // 复位时读取完成信号为低
        end else if (rd_en) begin
            data_out <= memory[count]; // 从存储器中读取数据

            // 读取完成后设置 `readco_done` 信号
            if (count == DEPTH - 1) begin
                readco_done <= 1; // 完成64次读取
                //count <= 0; // 重新开始计数
            end else begin
                readco_done <= 0; // 尚未完成所有读取
            end
        end
    end

    // 计数器逻辑：每次 `rd_en` 为高时递增计数器
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0; // 复位时计数器清零
        end else if (rd_en) begin
            if (count == DEPTH - 1) begin
                count <= 0; // 计数器达到最大值后重置为0
            end else begin
                count <= count + 1; // 递增计数器
            end
        end
    end

endmodule
