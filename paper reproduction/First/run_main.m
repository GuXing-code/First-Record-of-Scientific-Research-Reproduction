%信号产生
Know=2000;
Know_bit=randi([0,1],Know,1);      %已知信号20行1列
N=20000;
tx_bit=randi([0,1],N,1);         %N行1列
tx_bit=[Know_bit;tx_bit];
f=1e7;                           %发送bit的频率
Ts=1e-9;                         %采样输出周期，每个bit周期1/(f*Ts)个点
%调制：
tx_signal=qpsk_mod(tx_bit,f,Ts);
%发送
h = [1, zeros(1,90), 0.8, zeros(1,40), 0.5];%多径信道                        
tx_signal=reshape(tx_signal.',1,[]);        %先把tx_signal变成一行
rx_signal=tx_signal;
rx_signal=conv(rx_signal,h);                %进入多径信道
rx_signal=awgn(rx_signal,2,'measured');     %加入高斯白噪声，信噪比
%解调
[Know_signal,I,Q]=qpsk_demod(tx_signal,f,Ts);
[rx_first,I,Q]=qpsk_demod(rx_signal,f,Ts);
%自适应信道均衡判决器
[I_eq,Q_eq]=rls_dfe_equalizer(Know_signal(1:Know),rx_first,5,10,0.9965,0.5);
rx_bit=reshape([(I_eq>0);(Q_eq>0)],[],1);
