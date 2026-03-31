% 信号产生
KnowBits = 1500;
Know_bit = randi([0,1], KnowBits, 1);    % 已知训练比特
N = 27000;
tx_bit = randi([0,1], N, 1);             % 数据比特

tx_bit = [Know_bit; tx_bit];
fc = 15000;                               % 载波频率
Rs = 3000;                                % 码元速率
Ts = 1/96000;                             % 采样时间

% 调制（包含脉冲成形：升余弦滚降）
tx_signal = qpsk_mod(tx_bit, fc, Rs, Ts);
tx_train_signal = qpsk_mod(Know_bit, fc, Rs, Ts);
tx_train_signal = reshape(tx_train_signal.', 1, []);

% 发射
tx_signal = reshape(tx_signal.', 1, []);
tx_signal_with_sync = tx_signal;

% 添加同步头
[tx_signal_with_sync, lfm_ref] = add_lfm_Sync(tx_signal_with_sync, 100 / Rs, 1 / Ts, 9e6, 11e6);

% 信道与噪声
num_elements = 8;
ref_element = ceil(num_elements / 2);
sound_speed = 1500;
wavelength = sound_speed / fc;
element_spacing = wavelength / 2;
element_position = ((0:num_elements-1) - (num_elements-1)/2) * element_spacing;
base_path_delay = [50, 150, 231];
base_path_gain = [1, 0.8, 0.6];
path_angle_deg = [15, -20, 35];
base_path_range = sound_speed * base_path_delay * Ts;
h_all = cell(1, num_elements);
for m = 1:num_elements
    path_delay_m = zeros(1, length(base_path_delay));
    path_gain_m = zeros(1, length(base_path_gain));
    for p = 1:length(base_path_delay)
        extra_range_mp = element_position(m) * sind(path_angle_deg(p));
        path_range_mp = base_path_range(p) + extra_range_mp;
        path_delay_m(p) = round(path_range_mp / sound_speed / Ts);
        path_gain_m(p) = base_path_gain(p) * (base_path_range(p) / path_range_mp);
    end
    h_m = zeros(1, max(path_delay_m) + 1);
    for p = 1:length(path_delay_m)
        h_m(path_delay_m(p) + 1) = h_m(path_delay_m(p) + 1) + path_gain_m(p);
    end
    h_all{m} = h_m;
end

rx_signal_all = cell(1, num_elements);
rx_first_all = cell(1, num_elements);
z_rx_all = cell(1, num_elements);
h_pre_all = cell(1, num_elements);
I_all = cell(1, num_elements);
Q_all = cell(1, num_elements);
for m = 1:num_elements
    rx_signal_all{m} = conv(tx_signal_with_sync, h_all{m});
    rx_signal_all{m} = awgn(rx_signal_all{m}, 5, 'measured');
end

% 同步截取
for m = 1:num_elements
    rx_signal_all{m} = receive_lfm_Sync(rx_signal_all{m}, lfm_ref);
end

% 解调（升余弦滚降滤波）
[Know_train_signal, ~, ~] = qpsk_demod(tx_train_signal, fc, Rs, Ts);
for m = 1:num_elements
    [rx_first_all{m}, I_all{m}, Q_all{m}] = qpsk_demod(rx_signal_all{m}, fc, Rs, Ts);
end

% 实数域转复数域
z_train = Know_train_signal(1:2:KnowBits) + 1j * Know_train_signal(2:2:KnowBits);
for m = 1:num_elements
    z_rx_all{m} = rx_first_all{m}(1:2:end) + 1j * rx_first_all{m}(2:2:end);
end

% 信道估计（基于复符号序列）
for m = 1:num_elements
    h_pre_all{m} = channel_estimation(z_train, z_rx_all{m}, 20, 200);
end

% 参考阵元的直接支路
rx_signal = rx_signal_all{ref_element};
rx_second = rx_first_all{ref_element};
I = I_all{ref_element};
Q = Q_all{ref_element};
z_rx = z_rx_all{ref_element};
h_pre = h_pre_all{ref_element};
h = h_all{ref_element};

% 被动时间反转（多阵元求和）
[z_ptr, q_est] = time_reversal(z_rx_all, h_pre_all);
[~, idx0] = max(abs(q_est));
z_ptr = z_ptr(idx0:end);
rx_first = reshape([real(z_ptr); imag(z_ptr)], [], 1);

% 自适应信道均衡判决器（使用交织 I/Q 输入）
[I_dfe, Q_dfe] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_second, 10, 10, 0.9965, 0.5);
[I_ptr_dfe, Q_ptr_dfe] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_first, 10, 10, 0.9965, 0.5);

% 计算误码率
calc_ber

% 绘制 q 函数
t_q = (0:length(q_est)-1) / Rs;
q_plot = abs(q_est);
q_plot = q_plot / max(q_plot);
figure;
plot(t_q, q_plot, 'LineWidth', 1);
xlabel('时间/s');
ylabel('幅度');
title('单用户 PTR 的 q 函数');
grid on;
