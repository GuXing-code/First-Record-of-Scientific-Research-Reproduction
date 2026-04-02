function [I1_dec, Q1_dec,I2_dec, Q2_dec]= ptr_sic_dfe(Know_train_signal,Know_train_signal_double, ...
    rx_first,rx_first_double,z_rx_all,h_pre_all, ...
    h_pre_all_double,KnowBits,iter_num, ...
    q11, q22, q12, q21,snr_db)
%第一次初始：
    %用户1：PTR-DFE
[I1, Q1] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_first, 10, 10, 0.9965, 0.5);
%I1，Q1是列向量,q也是列向量
I1_dec = 2 * (I1 >= 0) - 1;
Q1_dec = 2 * (Q1 >= 0) - 1;
x1 = reshape(I1_dec + 1j * Q1_dec, [], 1);
    %用户2：PTR-DFE
[I2, Q2] = rls_dfe_equalizer(Know_train_signal_double(1:KnowBits), rx_first_double, 10, 10, 0.9965, 0.5);
I2_dec = 2 * (I2 >= 0) - 1;
Q2_dec = 2 * (Q2 >= 0) - 1;
x2 = reshape(I2_dec + 1j * Q2_dec, [], 1);

cfg.KnowBits = KnowBits;
cfg.ff = 10;
cfg.fb = 10;
cfg.lambda = 0.9965;
cfg.delta = 0.5;
cfg.beta_max = 0.05;
%开始迭代——5db白噪声
for num=1:iter_num
[SIR1, SIR2, SNR1, SNR2]=calc_sir_snr(x1, x2, q11, q22, q12, q21, h_pre_all, h_pre_all_double, snr_db);
%SIR决定先迭代哪个
if SIR1 >= SIR2
    [x1, I1_dec, Q1_dec, ~] = sic_update_one_user( ...
        q12, x2, z_rx_all, h_pre_all, Know_train_signal, SIR1, SNR1, cfg);

    [x2, I2_dec, Q2_dec, ~] = sic_update_one_user( ...
        q21, x1, z_rx_all, h_pre_all_double, Know_train_signal_double, SIR2, SNR2, cfg);
else
    [x2, I2_dec, Q2_dec, ~] = sic_update_one_user( ...
        q21, x1, z_rx_all, h_pre_all_double, Know_train_signal_double, SIR2, SNR2, cfg);

    [x1, I1_dec, Q1_dec, ~] = sic_update_one_user( ...
        q12, x2, z_rx_all, h_pre_all, Know_train_signal, SIR1, SNR1, cfg);
end

end

end

%-------------------------单用户迭代
function [x_target, I_dec, Q_dec, beta_xy, alphaxy_max, Delta_xy] = sic_update_one_user( ...
    q_cross, x_interf, z_rx_all, h_pre_target, Know_train_signal_target, SIR_target, SNR_target, cfg)
%%------------------此函数经ai优化，减少了冗长，一开始的写法在本文件最后
% q_cross                  : 交叉 q 函数
% x_interf                 : 干扰用户当前判决后的复符号序列
% z_rx_all                 : 各阵元接收复符号序列
% h_pre_target             : 目标用户各阵元估计信道
% Know_train_signal_target : 目标用户训练序列
% SIR_target               : 当前目标用户 SIR
% SNR_target               : 当前目标用户 SNR
% cfg                      : DFE 与 SIC 参数
    % 默认参数
    if ~isfield(cfg, 'KnowBits'), cfg.KnowBits = numel(Know_train_signal_target); end
    if ~isfield(cfg, 'ff'),       cfg.ff = 10; end
    if ~isfield(cfg, 'fb'),       cfg.fb = 10; end
    if ~isfield(cfg, 'lambda'),   cfg.lambda = 0.9965; end
    if ~isfield(cfg, 'delta'),    cfg.delta = 0.5; end
    if ~isfield(cfg, 'beta_max'), cfg.beta_max = 0.05; end
    % 1. 干扰估计
    q_cross = reshape(q_cross, 1, []);
    x_interf = reshape(x_interf, 1, []);
    i_xy = conv(q_cross, x_interf);
    % 2. 对齐
    [i_xy_align, alphaxy_max, Delta_xy] = alignment_latency(i_xy, z_rx_all, h_pre_target);
    % 3. 计算 beta
    SINR_target = 1 / (1 / SNR_target + 1 / SIR_target);
    beta_raw = (alphaxy_max^2) * SINR_target;
    beta_xy = min(cfg.beta_max, max(0, beta_raw));
    % 4. 目标用户 PTR 输出
    [z_ptr, q_est_target] = time_reversal(z_rx_all, h_pre_target);
    [~, idx0] = max(abs(q_est_target));
    z_ptr = reshape(z_ptr(idx0:end), 1, []);
    % 5. 长度对齐后做 SIC
    L = min(length(z_ptr), length(i_xy_align));
    z_ptr_sic = z_ptr(1:L) - beta_xy * i_xy_align(1:L);
    % 6. 转回 DFE 输入格式
    rx_target = reshape([real(z_ptr_sic); imag(z_ptr_sic)], [], 1);
    % 7. DFE
    [I, Q] = rls_dfe_equalizer( ...
        Know_train_signal_target(1:cfg.KnowBits), ...
        rx_target, ...
        cfg.ff, cfg.fb, cfg.lambda, cfg.delta);
    % 8. 硬判决得到复符号
    I_dec = 2 * (I >= 0) - 1;
    Q_dec = 2 * (Q >= 0) - 1;
    x_target = reshape(I_dec + 1j * Q_dec, [], 1);
end

%-------------------------对齐延迟
function [i_xy_align,alphaxy_max,derta_xy]=alignment_latency(i_xy,z_rx_all,h_pre_all)
i_xy = reshape(i_xy, 1, []);% 保证是行向量
[z_ptr, q_est_double] = time_reversal(z_rx_all, h_pre_all);
[~, idx0] = max(abs(q_est_double));
y_x = z_ptr(idx0:end);
y_x = reshape(y_x,  1, []);
% 相关，估计对齐时延
alphaxy = xcorr(y_x, i_xy);
[alphaxy_max, idx_max] = max(abs(alphaxy));
alphaxy_max = alphaxy_max / (sqrt(sum(abs(y_x).^2) * sum(abs(i_xy).^2)) + eps);
alphaxy_max = min(1, max(0, alphaxy_max));%限定幅度
lags = -(length(i_xy)-1):(length(y_x)-1);
Deltaxy = lags(idx_max);
derta_xy=Deltaxy;
% 按时延对齐干扰
if Deltaxy >= 0
    i_xy_align = [zeros(1, Deltaxy), i_xy];
else
    i_xy_align = i_xy(1-Deltaxy:end);
end
% 截断或补零到和 y_x 一样长
if length(i_xy_align) < length(y_x)
    i_xy_align = [i_xy_align, zeros(1, length(y_x)-length(i_xy_align))];
else
    i_xy_align = i_xy_align(1:length(y_x));
end

end

%-------------------------SIR SNR计算
function [SIR1, SIR2, SNR1, SNR2] = calc_sir_snr(x1, x2, q11, q22, q12, q21, h_pre_1, h_pre_2, snr_db)
P1 = mean(abs(x1).^2);
P2 = mean(abs(x2).^2);
SIR1 = P1 * sum(abs(q11).^2) / (P2 * sum(abs(q12).^2));
SIR2 = P2 * sum(abs(q22).^2) / (P1 * sum(abs(q21).^2));
% 5 dB 高斯白噪声对应的线性 SNR
snr_linear = 10^(snr_db / 10);
% 用平均发射功率近似反推 N0
P_avg = (P1 + P2) / 2;
N0 = P_avg / snr_linear;
Eh1 = 0;
for i = 1:numel(h_pre_1)
    h1 = reshape(h_pre_1{i}, 1, []);
    Eh1 = Eh1 + sum(abs(h1).^2);
end
Eh2 = 0;
for i = 1:numel(h_pre_2)
    h2 = reshape(h_pre_2{i}, 1, []);
    Eh2 = Eh2 + sum(abs(h2).^2);
end
SNR1 = (P1 / N0) * (sum(abs(q11).^2) / Eh1);
SNR2 = (P2 / N0) * (sum(abs(q22).^2) / Eh2);
end


% % 用户2：利用用户1的结果做SIC
% i21=conv(q21,x1);
% [i21_align,alphaxy_max,~]=alignment_latency(i21,z_rx_all,h_pre_all_double);
% SINR2=(SNR2^(-1)+SIR2^(-1))^(-1);
% beta_21=(alphaxy_max^2)*SINR2;
% [z_ptr, q_est_double] = time_reversal(z_rx_all, h_pre_all_double);
% [~, idx0] = max(abs(q_est_double));
% z_ptr = z_ptr(idx0:end);
% z_ptr = z_ptr - beta_21 * i21_align;
% rx_first_double = reshape([real(z_ptr); imag(z_ptr)], [], 1);
% [I2, Q2] = rls_dfe_equalizer(Know_train_signal_double(1:KnowBits), rx_first_double, 10, 10, 0.9965, 0.5);
% I2_dec = 2 * (I2 >= 0) - 1;
% Q2_dec = 2 * (Q2 >= 0) - 1;
% x2 = reshape(I2_dec + 1j * Q2_dec, [], 1);


% %用户1：利用用户2的结果做SIC
% i12=conv(q12,x2);
% [i12_align,alphaxy_max,~]=alignment_latency(i12,z_rx_all,h_pre_all);
% SINR1=(SNR1^(-1)+SIR1^(-1))^(-1);
% beta_12=(alphaxy_max^2)*SINR1;
% [z_ptr, q_est_double] = time_reversal(z_rx_all, h_pre_all);
% [~, idx0] = max(abs(q_est_double));
% z_ptr = z_ptr(idx0:end);
% z_ptr = z_ptr - beta_12 * i12_align;
% rx_first = reshape([real(z_ptr); imag(z_ptr)], [], 1);
% [I1, Q1] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_first, 10, 10, 0.9965, 0.5);
% I1_dec = 2 * (I1 >= 0) - 1;
% Q1_dec = 2 * (Q1 >= 0) - 1;
% x1 = reshape(I1_dec + 1j * Q1_dec, [], 1);