function [output] = qpsk_mod(tx_bits,fc,Rs,Ts)
%使用qpsk调制信号
%tx_bits:原始比特
%fc:载波频率
%Rs:码元速率
%Ts:采样时间
N=length(tx_bits);
tx_bits_matrix=reshape(tx_bits,2,N/2);    %两两打包成一组2行
I=tx_bits_matrix(1,:);                    %提取第一行作为I
Q=tx_bits_matrix(2,:);                    %提取第二行作为Q
I=2*I-1;                                  %0变成-1，1变成+1
Q=2*Q-1;
%加入升余弦滚降器
a=1;%滚降系数
Ns = round(1/Rs/Ts);      %一个码元周期采样点个数
span=6;%横跨6个周期
ht = rcosdesign(a, span, Ns, "sqrt");%加入升余弦滤波器
I_up = upsample(I, Ns);%在采样之间插入 n - 1 个零来提高的采样率
Q_up = upsample(Q, Ns);
I_shaped = conv(I_up, ht);%这里必须是卷积
Q_shaped = conv(Q_up, ht);
t_all = (0:length(I_shaped)-1)*Ts;

output=I_shaped.*cos(fc*t_all*2*pi)-Q_shaped.*sin(fc*t_all*2*pi);%输出结果

end
