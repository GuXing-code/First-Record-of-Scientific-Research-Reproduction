function [h_pre] = channel_estimation(know_signal, obverse_signal, L, N_b)
% know_signal: 已知训练复符号序列
% obverse_signal: 观测到的复符号序列
% L: 需要估计的等效信道长度（单位：符号）
% N_b: 用于估计的观测符号长度


%使用LS估计信道
know_signal = reshape(know_signal,1,[]);
obverse_signal = reshape(obverse_signal,1,[]);

x = know_signal(1:N_b + L - 1);
Y = obverse_signal(L+N_b-1:-1:L).';

X = complex(zeros(N_b, L));
for i = 1:N_b
    X(N_b-i+1,:) = x(i+L-1:-1:i);
end

h_pre = (X' * X) \ (X' * Y);


%加入LMMSE估计信道：

%1.使用LS得到初步信道估计h_pre
%2.估计噪声方差
sigma=sum((Y-X*h_pre).^2)/N_b;
%3.构建信道协方差——>没有历史数据:R_hh=E单位矩阵
R_hh=eye(L,L);
%4.代入LMMSE公式
h_pre=R_hh*X'*(X*R_hh*X'+sigma*eye(N_b))^(-1)*Y;
end
