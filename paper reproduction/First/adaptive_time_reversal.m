function [z_atr, q_self, q_cross] = adaptive_time_reversal(z_rx_all, h_target_all, h_interf_all, diag_load)
% 输入：
% z_rx_all    : 各阵元接收复符号序列，cell
% h_target_all: 目标用户各阵元信道估计，cell
% h_interf_all: 干扰用户各阵元信道估计，cell
% diag_load   : 对角加载，如 1e-3
%
% 输出：
% z_atr   : 对目标用户做自适应时间反转后的时域输出
% q_self  : 目标用户自项等效响应
% q_cross : 干扰用户对目标用户的交叉等效响应

M = numel(z_rx_all);
rx_len = 0;
h_len = 0;
for m = 1:M
    rx_len = max(rx_len, numel(z_rx_all{m}));
    h_len = max(h_len, numel(h_target_all{m}));
    h_len = max(h_len, numel(h_interf_all{m}));
end

Nfft = 2^nextpow2(rx_len + h_len - 1);%方便做FFT，返回满足条件的最小2次幂

R_all = zeros(M, Nfft);
H_tar = zeros(M, Nfft);
H_int = zeros(M, Nfft);

for m = 1:M
    R_all(m, :) = fft(reshape(z_rx_all{m}, 1, []), Nfft);%做Nfft点的fft
    H_tar(m, :) = fft(reshape(h_target_all{m}, 1, []), Nfft);
    H_int(m, :) = fft(reshape(h_interf_all{m}, 1, []), Nfft);
end

Y = zeros(1, Nfft);
Qself = zeros(1, Nfft);
Qcross = zeros(1, Nfft);

for p = 1:Nfft
    h_t = H_tar(:, p);
    h_i = H_int(:, p);
    r_p = R_all(:, p);

    Rin = h_i * h_i' + diag_load * eye(M);

    tmp = Rin \ h_t;
    den = h_t' * tmp + eps;
    w = tmp / den;

    Y(p) = w' * r_p;
    Qself(p) = w' * h_t;
    Qcross(p) = w' * h_i;
end

z_atr_full = ifft(Y, Nfft);
q_self = ifft(Qself, Nfft);
q_cross = ifft(Qcross, Nfft);

z_atr= z_atr_full;
end
