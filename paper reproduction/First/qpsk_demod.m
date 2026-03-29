function [output,I_sym,Q_sym] = qpsk_demod(rx_signal,fc,Rs,Ts)
% rx_signal: 接收通带信号
% fc: 载波频率
% Rs: 码元速率
% Ts: 采样时间

Ns = round(1/Rs/Ts);   % 每码元采样点数
a = 1;                 % 滚降系数
span = 6;              % 滤波器跨度

% 和发端保持一致的RC滤波器，保证信号能正常通过
ht = rcosdesign(a, span, Ns, "sqrt");

% 整条接收波形的时间轴
t = (0:length(rx_signal)-1) * Ts;

%提取原来发送函数
I_bb = 2 * rx_signal .* cos(2*pi*fc*t);
Q_bb = -2 * rx_signal .* sin(2*pi*fc*t);

%用ht做为低通滤波器
I_filt = conv(I_bb, ht);
Q_filt = conv(Q_bb, ht);

%补偿总延迟
% 发端 RC 一次延迟: span*Ns/2
% 收端这里再滤一次延迟: span*Ns/2
% 总延迟 = span*Ns
delay = span * Ns;
I_valid = I_filt(delay+1:end);
Q_valid = Q_filt(delay+1:end);

%按每码元抽样
I_sym = I_valid(1:Ns:end);
Q_sym = Q_valid(1:Ns:end);
output = reshape([I_sym; Q_sym], [], 1);
end
