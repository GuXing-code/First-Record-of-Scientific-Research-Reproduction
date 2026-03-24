%产生要调制的信号
N=2000;
tx_bit=randi([0,1],N,1);%N行1列或者1行N列都可以
f=1e7;                  %发送bit的频率
Ts=1e-9;                %采样输出周期，每个bit周期1/(f*Ts)个点
%调制：
tx_signal=qpsk_mod(tx_bit,f,Ts);%signal是一个0.5N列的数组
%发送
h=[0,1,zeros(1,50),0.3,0,0.5];                        
tx_signal=reshape(tx_signal.',1,[]);        %先把tx_signal变成一行
tx_signal=conv(tx_signal,h);                %进入多径信道
tx_signal=awgn(tx_signal,5,'measured');    %加入高斯白噪声
rx_signal=tx_signal;
%解调
rx_bit=qpsk_demod(rx_signal,f,Ts);
% 计算误码率
ber_percent  = sum(tx_bit ~= rx_bit) / length(tx_bit)* 100
