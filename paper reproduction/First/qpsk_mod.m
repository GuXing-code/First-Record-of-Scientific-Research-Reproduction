function [output] = qpsk_mod(tx_bits,f,Ts)
%使用qpsk调制信号
%tx_bits:原始比特
%f:载波频率
%Ts:采样时间
N=length(tx_bits);
tx_bits_matrix=reshape(tx_bits,2,N/2);    %两两打包成一组2行
I=tx_bits_matrix(1,:);                    %提取第一行作为I
Q=tx_bits_matrix(2,:);                    %提取第二行作为Q
%使用正交调相法产生QPSK信号：
t=0:Ts:1/f-Ts;                      
I=2*I-1;                                  %0变成-1，1变成+1
Q=2*Q-1;
output=I'*cos(f*t*2*pi)-Q'*sin(f*t*2*pi);%输出结果
end

