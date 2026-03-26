function [output,I,Q] = qpsk_demod(rx_signal,f,Ts)
%rx_signal：接收到的信号
%f：载波频率
%Ts：采样间隔
%output：硬判决出来的bit
%I，Q：判决前的符号观测值
Ns=round(1/f/Ts);%一个符号对应的点数
nSym = floor(length(rx_signal) / Ns); % 能分出的完整符号数
rx_signal=rx_signal(1:nSym*Ns);% 丢掉最后不完整的部分
rx_signal=reshape(rx_signal,Ns,nSym);
t=(0:Ns-1)*Ts;
I=cos(2*pi*t*f)*rx_signal;%rx_signal每一列是一个符号，出来是一个1行的向量
Q=-sin(2*pi*t*f)*rx_signal;
output=reshape([I;Q],[],1);%转成1列，转成1行应该也可以
end

