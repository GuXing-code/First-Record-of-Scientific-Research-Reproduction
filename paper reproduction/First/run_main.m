% 信号产生
fc = 15000;                               % 载波频率
Rs = 3000;                                % 码元速率
Ts = 1/96000;                             % 采样时间
KnowBits = 1500;
N = 27000;
%用户1
Know_bit = randi([0,1], KnowBits, 1);    % 已知训练比特
tx_bit = randi([0,1], N, 1);             % 数据比特
tx_bit = [Know_bit; tx_bit];
%用户2
Know_bit_double = randi([0,1], KnowBits, 1);
tx_bit_double = randi([0,1], N, 1);
tx_bit_double = [Know_bit_double; tx_bit_double];

% 调制（包含脉冲成形：升余弦滚降）
%用户1
tx_signal = qpsk_mod(tx_bit, fc, Rs, Ts);
tx_train_signal = qpsk_mod(Know_bit, fc, Rs, Ts);
tx_train_signal = reshape(tx_train_signal.', 1, []);
%用户2
tx_signal_double = qpsk_mod(tx_bit_double, fc, Rs, Ts);
tx_train_signal_double = qpsk_mod(Know_bit_double, fc, Rs, Ts);
tx_train_signal_double = reshape(tx_train_signal_double.', 1, []);

% 发射
%用户1
tx_signal = reshape(tx_signal.', 1, []);
tx_signal_with_sync = tx_signal;
%用户2
tx_signal_double = reshape(tx_signal_double.', 1, []);
tx_signal_with_sync_double = tx_signal_double;

% 添加同步头
%用户1
[tx_signal_with_sync, lfm_ref] = add_lfm_Sync(tx_signal_with_sync, 100 / Rs, 1 / Ts, 9e6, 11e6);
%用户2
[tx_signal_with_sync_double, lfm_ref_double] = add_lfm_Sync(tx_signal_with_sync_double, 100 / Rs, 1 / Ts, 9e6, 11e6);

% 信道与噪声
num_elements = 8;                        % 接收阵元数量，一共有 8 个水听器
ref_element = ceil(num_elements / 2);    % 参考阵元
sound_speed = 1500;                      % 水下声速，单位 m/s
wavelength = sound_speed / fc;           % 载波频率 fc 的波长
element_spacing = wavelength / 2;        % 阵元间距，通常取半波长间距
element_position = ((0:num_elements-1) - (num_elements-1)/2) * element_spacing;% 各阵元相对于阵列中心的位置，形成一个对称线阵
%用户1
base_path_delay = [50, 150, 231];        % 各条路径在参考位置处的时延（单位：采样点）
base_path_gain = [1, 0.8, 0.6];          % 各条路径的增益
path_angle_deg = [15, -20, 35];          % 各条路径的到达角（单位：度）
base_path_range = sound_speed * base_path_delay * Ts;% 将参考时延换算成传播距离，便于后面结合阵元位置计算各阵元的实际路径长度
h_all = cell(1, num_elements);           % 用 cell 保存每个阵元的信道冲激响应
for m = 1:num_elements
    path_delay_m = zeros(1, length(base_path_delay));   % 第 m 个阵元上每条路径的时延
    path_gain_m = zeros(1, length(base_path_gain));     % 第 m 个阵元上每条路径的增益
    for p = 1:length(base_path_delay)
        extra_range_mp = element_position(m) * sind(path_angle_deg(p));% 由阵元位置和到达角带来的额外传播路程差
        path_range_mp = base_path_range(p) + extra_range_mp;% 第 p 条路径到第 m 个阵元的总传播距离
        path_delay_m(p) = round(path_range_mp / sound_speed / Ts);% 将传播距离换成离散采样时延
        path_gain_m(p) = base_path_gain(p) * (base_path_range(p) / path_range_mp);% 根据传播距离对路径增益做一个简单缩放，距离越远增益越小
    end
    h_m = zeros(1, max(path_delay_m) + 1);  % 构造第 m 个阵元的离散信道冲激响应
    for p = 1:length(path_delay_m)
        h_m(path_delay_m(p) + 1) = h_m(path_delay_m(p) + 1) + path_gain_m(p);% 把每条路径的增益加到对应的时延位置上
    end
    h_all{m} = h_m;   % 保存第 m 个阵元的信道
end
%用户2
base_path_delay = [40, 120, 280];        % 各条路径在参考位置处的时延（单位：采样点）
base_path_gain = [0.9, 0.8, 0.7];          % 各条路径的增益
path_angle_deg = [75, 30, -45];          % 各条路径的到达角（单位：度）
base_path_range = sound_speed * base_path_delay * Ts;% 将参考时延换算成传播距离，便于后面结合阵元位置计算各阵元的实际路径长度
h_all_double = cell(1, num_elements);           % 用 cell 保存每个阵元的信道冲激响应
for m = 1:num_elements
    path_delay_m = zeros(1, length(base_path_delay));   % 第 m 个阵元上每条路径的时延
    path_gain_m = zeros(1, length(base_path_gain));     % 第 m 个阵元上每条路径的增益
    for p = 1:length(base_path_delay)
        extra_range_mp = element_position(m) * sind(path_angle_deg(p));% 由阵元位置和到达角带来的额外传播路程差
        path_range_mp = base_path_range(p) + extra_range_mp;% 第 p 条路径到第 m 个阵元的总传播距离
        path_delay_m(p) = round(path_range_mp / sound_speed / Ts);% 将传播距离换成离散采样时延
        path_gain_m(p) = base_path_gain(p) * (base_path_range(p) / path_range_mp);% 根据传播距离对路径增益做一个简单缩放，距离越远增益越小
    end
    h_m = zeros(1, max(path_delay_m) + 1);  % 构造第 m 个阵元的离散信道冲激响应
    for p = 1:length(path_delay_m)
        h_m(path_delay_m(p) + 1) = h_m(path_delay_m(p) + 1) + path_gain_m(p);% 把每条路径的增益加到对应的时延位置上
    end
    h_all_double{m} = h_m;   % 保存第 m 个阵元的信道
end

rx_signal_all = cell(1, num_elements);   % 各阵元接收到的原始信号（含信道和噪声）
rx_first_all = cell(1, num_elements);    % 各阵元解调后的实信号
z_rx_all = cell(1, num_elements);        % 各阵元降采样后的复符号序列
h_pre_all = cell(1, num_elements);       % 用户1各阵元估计得到的信道
h_pre_all_double = cell(1, num_elements);% 用户2各阵元估计得到的信道
I_all = cell(1, num_elements);           % 各阵元解调后的 I 路
Q_all = cell(1, num_elements);           % 各阵元解调后的 Q 路
for m = 1:num_elements
    sig1 = conv(tx_signal_with_sync, h_all{m});
    sig2 = conv(tx_signal_with_sync_double, h_all_double{m});
    L = max(length(sig1), length(sig2));
    sig1 = [sig1, zeros(1, L - length(sig1))];
    sig2 = [sig2, zeros(1, L - length(sig2))];
    rx_signal_all{m} = sig1 + sig2;
    rx_signal_all{m} = awgn(rx_signal_all{m}, 1, 'measured');
end

% 同步截取
for m = 1:num_elements
    rx_signal_all{m} = receive_lfm_Sync(rx_signal_all{m}, lfm_ref);
end

% 解调（升余弦滚降滤波）
[Know_train_signal, ~, ~] = qpsk_demod(tx_train_signal, fc, Rs, Ts);
[Know_train_signal_double, ~, ~] = qpsk_demod(tx_train_signal_double, fc, Rs, Ts);
for m = 1:num_elements
    [rx_first_all{m}, I_all{m}, Q_all{m}] = qpsk_demod(rx_signal_all{m}, fc, Rs, Ts);
end

% 实数域转复数域
z_train = Know_train_signal(1:2:KnowBits) + 1j * Know_train_signal(2:2:KnowBits);
z_train_double = Know_train_signal_double(1:2:KnowBits) + 1j * Know_train_signal_double(2:2:KnowBits);
for m = 1:num_elements
    z_rx_all{m} = rx_first_all{m}(1:2:end) + 1j * rx_first_all{m}(2:2:end);
end

% 信道估计（基于复符号序列）
for m = 1:num_elements
    h_pre_all{m} = channel_estimation(z_train, z_rx_all{m}, 20, 200);
    h_pre_all_double{m} = channel_estimation(z_train_double, z_rx_all{m}, 20, 200);
end

% 参考阵元的直接支路
rx_signal = rx_signal_all{ref_element};
rx_second = rx_first_all{ref_element};
I = I_all{ref_element};
Q = Q_all{ref_element};
z_rx = z_rx_all{ref_element};
%用户1
h_pre = h_pre_all{ref_element};
h = h_all{ref_element};
%用户2
h_pre_double = h_pre_all_double{ref_element};
h_double = h_all_double{ref_element};

% 被动时间反转（多阵元求和）
%用户1
[z_ptr, q_est] = time_reversal(z_rx_all, h_pre_all);
[~, idx0] = max(abs(q_est));
z_ptr = z_ptr(idx0:end);
rx_first = reshape([real(z_ptr); imag(z_ptr)], [], 1);
%用户2
[z_ptr, q_est_double] = time_reversal(z_rx_all, h_pre_all_double);
[~, idx0] = max(abs(q_est_double));
z_ptr = z_ptr(idx0:end);
rx_first_double = reshape([real(z_ptr); imag(z_ptr)], [], 1);
%q12和q21
[q12,q21]=calc_cross_q(h_pre_all,h_pre_all_double);
q11 = q_est;
q22 = q_est_double;

%atr_dfe
[z_atr_1, q11_atr, q12_atr] = adaptive_time_reversal( ...
    z_rx_all, h_pre_all, h_pre_all_double, 1e-3);
[z_atr_2, q22_atr, q21_atr] = adaptive_time_reversal( ...
    z_rx_all, h_pre_all_double, h_pre_all, 1e-3);
rx_atr_1 = reshape([real(z_atr_1); imag(z_atr_1)], [], 1);
rx_atr_2 = reshape([real(z_atr_2); imag(z_atr_2)], [], 1);
[I_atr_dfe_1, Q_atr_dfe_1] = rls_dfe_equalizer( ...
    Know_train_signal(1:KnowBits), rx_atr_1, 10, 10, 0.9965, 0.5);
[I_atr_dfe_2, Q_atr_dfe_2] = rls_dfe_equalizer( ...
    Know_train_signal_double(1:KnowBits), rx_atr_2, 10, 10, 0.9965, 0.5);

% 自适应信道均衡判决器（使用交织 I/Q 输入）
%用户1
% [I_dfe, Q_dfe] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_second, 10, 10, 0.9965, 0.5);
[I_ptr_dfe, Q_ptr_dfe] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_first, 10, 10, 0.9965, 0.5);
%用户2
% [I_dfe_double, Q_dfe_double] = rls_dfe_equalizer(Know_train_signal_double(1:KnowBits), rx_second, 10, 10, 0.9965, 0.5);
[I_ptr_dfe_double, Q_ptr_dfe_double] = rls_dfe_equalizer(Know_train_signal_double(1:KnowBits), rx_first_double, 10, 10, 0.9965, 0.5);

%ptr_sic_dfe
[I1_dec, Q1_dec,I2_dec, Q2_dec]=ptr_sic_dfe(Know_train_signal(1:KnowBits),Know_train_signal_double(1:KnowBits), ...
    rx_first,rx_first_double,z_rx_all,h_pre_all, ...
    h_pre_all_double,KnowBits,3, ...%迭代3轮
    q11, q22, q12, q21,1);%5db高斯噪声作为基准噪声N0


% 计算误码率
calc_ber

% 观察 SIC 前后效果（单独辅助分析，不影响原有主流程）
% sic_effect_results = inspect_sic_effect( ...
%     tx_bit, tx_bit_double, ...
%     I_ptr_dfe, Q_ptr_dfe, I_ptr_dfe_double, Q_ptr_dfe_double, ...
%     I1_dec, Q1_dec, I2_dec, Q2_dec, ...
%     'q11', q11, 'q22', q22, 'q12', q12, 'q21', q21, ...
%     'figure_name', 'PTR-SIC-DFE效果');
