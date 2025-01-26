`timescale 1us/1ns

module ALU (
    input          rstn,       // 复位信号
    input          clk2,       // 系统时钟
    input          enable,     // 使能信号
    input [15:0]  cout,       // 输入1
    input [15:0]  x_in,       // 输入2
    output reg done,           // 完成标志
    output reg [15:0] data_out // fp输出
);
    
    reg [31:0] yout_r;          // 输出寄存器
    // 乘法器输出
    reg [31:0] d_out;
    // 累加器部分寄存器
    reg [63:0] sum;
    // 累加完成标志
    reg [5:0] acc_count;       // 累加次数

                // 浮点数转换的阶码部分 (5位)
            reg [4:0] exponent;
            reg [9:0] mantissa;

    // 乘法逻辑
    always @(posedge clk2 or negedge rstn) begin
        if (~rstn) begin
            d_out <= 32'b0;           // 复位时将d_out清零
        end else if (enable) begin
            d_out <= cout * x_in;     // 乘法操作
        end
    end

    // 累加逻辑
    always @(posedge clk2 or negedge rstn) begin
        if (!rstn) begin
            sum <= 32'b0;             // 复位时累加器清零
            acc_count <= 6'b0;        // 累加计数器清零
        end else if (enable) begin
            if (acc_count < 6'd63) begin
                sum <= sum + d_out;   // 累加操作
                acc_count <= acc_count + 1'b1; // 增加累加次数
            end else begin
                acc_count <= 6'b0;    // 累加完成，计数器复位
                sum <= 0;   // 最后一次累加
            end
        end
    end

    // 输出逻辑
    always @(posedge clk2 or negedge rstn) begin
        if (!rstn) begin
            yout_r <= 32'b0;          // 复位时输出清零
            done <= 1'b0;             // 完成标志清零
        end else if (acc_count == 6'd63) begin
            yout_r <= sum;            // 当完成 64 次累加后，更新输出
            done <= 1'b1;             // 完成标志置位
        end
        else begin done <= 1'b0;            // 其他情况下，未完成
        end
    end

    // 输出转化逻辑
    always @(posedge clk2 or negedge rstn) begin
        if (!rstn) begin
            data_out <= 16'b0;        // 复位时输出清零
        end else if (done) begin
            // 转换 yout_r 为 16 位浮点数
            // 定点数的第22到第13位作为小数部分
            // 设置阶码为10（在浮点数格式中）


            // 阶码 = 10 -> 5 位阶码表示 10
            exponent = 5'b01010; // 十进制10

            // 小数部分取 yout_r[22:13]，并且扩展成 10 位
            mantissa = yout_r[22:13];  // 从 yout_r 取出第22到第13位

            // 将阶码与尾数拼接成16位浮点数
            // 符号位为0（正数），阶码和尾数组成数据
            data_out <= {1'b0, exponent, mantissa};
        end
    end

endmodule
