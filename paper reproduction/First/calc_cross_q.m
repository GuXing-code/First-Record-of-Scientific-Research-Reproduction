function [q12,q21] = calc_cross_q(h_pre_1,h_pre_2)
%得到q12和q21
%输入用户1的预测信道和用户2的预测信道
num_elements = numel(h_pre_1);
q_len_max = 0;
for i = 1:num_elements
    q_len_max = max(q_len_max, length(h_pre_1{i}) + length(h_pre_2{i}) - 1);
end
q12 = zeros(1, q_len_max);
q21 = zeros(1, q_len_max);
for i = 1:num_elements
    h1 = reshape(h_pre_1{i}, 1, []);
    h2 = reshape(h_pre_2{i}, 1, []);
    q_tmp_12 = conv(h2, conj(flip(h1)));
    q12(1:length(q_tmp_12)) = q12(1:length(q_tmp_12)) + q_tmp_12;
    q_tmp_21 = conv(h1, conj(flip(h2)));
    q21(1:length(q_tmp_21)) = q21(1:length(q_tmp_21)) + q_tmp_21;
end

end

