module FIFO #(
    parameter DATA_WIDTH = 16,  // 数据位宽
    parameter DEPTH = 4         // FIFO 深度
) (
    input clk_wr,               // 写入时钟
    input clk_rd,               // 读取时钟
    input rstn,                 // 复位信号（低电平有效）
    input wr_en,                // 写入使能
    input rd_en,                // 读取使能
    input [DATA_WIDTH-1:0] data_in, // 输入数据
    output reg [DATA_WIDTH-1:0] FIFO_out, // 输出数据
    output full,                // FIFO 满信号
    output empty                // FIFO 空信号
);

    // FIFO 存储器
    reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];

    // 写指针、读指针、计数器
    reg [$clog2(DEPTH):0] write_pointer;
    reg [$clog2(DEPTH):0] read_pointer;
    reg [$clog2(DEPTH):0] wr_counter; // 写入计数器
    reg [$clog2(DEPTH):0] rd_counter; // 读取计数器

    // 数据量计算
    wire [$clog2(DEPTH):0] fifo_count = wr_counter - rd_counter;

    // 满信号和空信号
    assign full = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);

    // 写入逻辑
    always @(posedge clk_wr or negedge rstn) begin
        if (!rstn) begin
            write_pointer <= 0;
            wr_counter <= 0;
        end else if (wr_en && !full) begin
            fifo[write_pointer] <= data_in;               // 写入数据
            write_pointer <= (write_pointer + 1) % DEPTH; // 写指针递增（循环）
            wr_counter <= wr_counter + 1;                // 写计数器递增
        end
    end

    // 读取逻辑
    always @(posedge clk_rd or negedge rstn) begin
        if (!rstn) begin
            read_pointer <= 0;
            FIFO_out <= 0;
            rd_counter <= 0;
        end else if (rd_en && !empty) begin
            FIFO_out <= fifo[read_pointer];               // 读取数据
            read_pointer <= (read_pointer + 1) % DEPTH;   // 读指针递增（循环）
            rd_counter <= rd_counter + 1;                // 读计数器递增
        end
    end



endmodule
