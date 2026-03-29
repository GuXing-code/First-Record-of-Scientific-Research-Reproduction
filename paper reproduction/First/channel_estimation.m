function [h_pre] = channel_estimation(know_signal, obverse_signal, L, N_b)
% know_signal：已知训练复符号序列
% obverse_signal：观测到的复符号序列
% L：需要估计的等效信道长度（单位：符号）
% N_b：用于估计的观测符号长度
know_signal = reshape(know_signal,1,[]);
obverse_signal = reshape(obverse_signal,1,[]);

x = know_signal(1:N_b + L - 1);
Y = obverse_signal(N_b:-1:1).';

X = complex(zeros(N_b, L));
for i = 1:N_b
    X(i,:) = x((N_b-i) + L: -1 : (N_b-i)+1);
end

%h_pre = (inv(X' * X))* X' * Y;
% h_pre = (X' * X) \ (X' * Y);
reg = 1e-4;
h_pre = (X' * X + reg * eye(L)) \ (X' * Y);
end
