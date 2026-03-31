function [z_ptr, q_est] = time_reversal(z_rx_all, h_pre_all)
% 多阵元被动时间反转
% z_rx_all: 各阵元解调抽样后的复符号序列
% h_pre_all: 各阵元估计信道
% z_ptr: 各阵元时反输出叠加后的复符号序列
% q_est: 总 q 函数

z_rx_cell = to_cell_row_vectors(z_rx_all);
h_pre_cell = to_cell_row_vectors(h_pre_all);

num_elements = numel(z_rx_cell);
if numel(h_pre_cell) ~= num_elements
    error('z_rx_all 和 h_pre_all 的阵元数量不一致。');
end

z_ptr_each = cell(1, num_elements);
ptr_len_min = inf;
q_len_max = 0;

for m = 1:num_elements
    h_tr_m = conj(flip(h_pre_cell{m}));
    z_ptr_each{m} = conv(z_rx_cell{m}, h_tr_m);
    q_len_max = max(q_len_max, length(conv(h_pre_cell{m}, h_tr_m)));
    ptr_len_min = min(ptr_len_min, length(z_ptr_each{m}));
end

z_ptr = zeros(1, ptr_len_min);
q_est = zeros(1, q_len_max);
for m = 1:num_elements
    h_tr_m = conj(flip(h_pre_cell{m}));
    z_ptr = z_ptr + z_ptr_each{m}(1:ptr_len_min);
    q_tmp = conv(h_pre_cell{m}, h_tr_m);
    q_est(1:length(q_tmp)) = q_est(1:length(q_tmp)) + q_tmp;
end
end



%其他函数：把输入统一整理成“每个阵元一条行向量，外面用 cell 装起来”的格式。
function out = to_cell_row_vectors(in)
if iscell(in)
    out = cell(1, numel(in));
    for k = 1:numel(in)
        out{k} = reshape(in{k}, 1, []);
    end
    return;
end

if isvector(in)
    out = {reshape(in, 1, [])};
    return;
end

out = cell(1, size(in, 1));
for k = 1:size(in, 1)
    out{k} = reshape(in(k, :), 1, []);
end
end
