%产生要调制的信号
N=100;
tx_bit=randi([0,1],N,1);%N行1列或者1行N列都可以
f=1e7;                  %发送bit的频率
Ts=1e-9;                %采样输出周期，每个bit周期1/(f*Ts)个点
%调制：
tx_signal=my_qpsk_mod(tx_bit,f,Ts);%signal是一个0.5N列的数组
%发送
rx_signal=tx_signal;
%解调
rx_bit=my_qpsk_demod(rx_signal,f,Ts);
%计算误码率
ber_percent  = sum(tx_bit ~= rx_bit) / length(tx_bit)* 100
%绘图：
subplot(2,1,1);
signal_row_order = reshape(tx_signal', 1, []);%转成1行-reshape函数是按列读取
plot(signal_row_order);
axis([0 1000 -1.5 1.5]); % 只看前 1000 个点
title(['tx signal']);
subplot(2,1,2);
N_show=min(50, length(tx_bit));
stem(tx_bit(1:N_show), 'b');   % 蓝色
hold on
stem(rx_bit(1:N_show)+0.03, 'r');   % 红色
legend('tx bit','rx bits');
title([num2str(N_show), ' bits comparison']);