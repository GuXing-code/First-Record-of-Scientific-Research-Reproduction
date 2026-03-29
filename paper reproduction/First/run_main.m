% 信号产生
KnowBits = 5000;
Know_bit = randi([0,1], KnowBits, 1);    % 已知训练比特
N = 10000;
tx_bit = randi([0,1], N, 1);             % 数据比特

tx_bit = [Know_bit; tx_bit];
fc = 1e7;                                % 载波频率
Rs = 1e7;                                % 码元速率
Ts = 1e-9;                               % 采样时间

% 调制（包含脉冲成形：升余弦滚降）
tx_signal = qpsk_mod(tx_bit, fc, Rs, Ts);
tx_train_signal = qpsk_mod(Know_bit, fc, Rs, Ts);
tx_train_signal = reshape(tx_train_signal.', 1, []);

% 发射
tx_signal = reshape(tx_signal.', 1, []);
rx_signal = tx_signal;

% 同步头
[rx_signal, lfm_ref] = add_lfm_Sync(rx_signal, 100 / Rs, 1 / Ts, 9e6, 11e6);

% 信道与噪声
h = [zeros(1,20),1, zeros(1,60), 0.8, zeros(1,40), 0.6];
rx_signal = conv(rx_signal, h);
rx_signal = awgn(rx_signal, 20, 'measured');

% 同步截取
rx_signal = receive_lfm_Sync(rx_signal, lfm_ref);

%解调（升余弦滚降滤波）
[Know_train_signal, ~, ~] = qpsk_demod(tx_train_signal, fc, Rs, Ts);
[rx_first, I, Q] = qpsk_demod(rx_signal, fc, Rs, Ts);

%实数域转化复数域
z_train = Know_train_signal(1:2:KnowBits) + 1j * Know_train_signal(2:2:KnowBits);
z_rx = rx_first(1:2:end) + 1j * rx_first(2:2:end);

%信道估计（基于复符号序列）
h_pre = channel_estimation(z_train, z_rx, 12, 500);

%被动时间反转（单用户）-输出是IQ混合
rx_first=time_reversal_single(z_rx,h_pre);

%理论的h（解调后）：此函数完全由ai生成
[h_eff, tap_axis, detail] = theoretical_demod_channel(h, fc, Ts, 12, false);

%自适应信道均衡判决器（保使用交织 I/Q 输入）
[I_eq, Q_eq] = rls_dfe_equalizer(Know_train_signal(1:KnowBits), rx_first, 5, 10, 0.9965, 0.5);
rx_bit = reshape([(I_eq > 0); (Q_eq > 0)], [], 1);
