function [output] = my_qpsk_demod(rx_signal,f,Ts)
%使用qpsk解调信号
%rx_signal：接收到的信号，默认是第i行对应第i个信息
%f：载波频率
%Ts：采样间隔
t=(0:Ts:1/f-Ts)'; %t变成列向量，这里其实只要一半就行了
I=rx_signal*cos(2*pi*t*f);%每一行代表第i个信息积分的值
Q=-rx_signal*sin(2*pi*t*f);
I=(I>0);                %把数值变成0和1,I是列向量
Q=(Q>0);
output=reshape([I';Q'],[],1);%转成1列，转成1行应该也可以
end

