function [I_eq,Q_eq] = rls_dfe_equalizer(Know_signal,rx_first,K1,K2,lambda_rls,delta_rls)
%Know_signal：已知信号bit对应的符号值
%rx_first：直接解调出来的信号符号值
%K1:前向滤波器的抽头加权系数个数
%K2:反馈滤波器的抽头加权系数个数
%lambda_rls：遗忘因子（RLS算法中的）
%delta_rls：是一个常数（系统参数的初始化中的），默认0.5
%I_eq,Q_eq：均衡后的符号值
I_train = Know_signal(1:2:end);
Q_train = Know_signal(2:2:end);
z_train = I_train + 1j*Q_train;
I_first = rx_first(1:2:end);
Q_first = rx_first(2:2:end);
z_first = I_first + 1j*Q_first;

%前面的已知信号来训练：
N=K1+K2;%N:滤波器长度
Know_N=length(z_train);
%滤波器系数初始化
%n=0
P_n=(1/delta_rls)*eye(N);%N阶矩阵 P0
W_n=zeros(K1+K2,1);%W0
Y_n=zeros(K1+K2,1);%Y0
E_n=0;
for n=1:1:Know_N
Y_n_Now=circshift(Y_n, 1);
Y_n_Now(1)=z_first(n);
if n>1 Y_n_Now(K1+1)=z_train(n-1);end
K_n=(P_n*Y_n_Now)/(lambda_rls+Y_n_Now'*P_n*Y_n_Now);%H认为是转置
E_n=z_train(n)-W_n'*Y_n_Now;
W_n=W_n+K_n*conj(E_n);
P_n=(1/lambda_rls)*(P_n-K_n*Y_n_Now'*P_n);
Y_n=Y_n_Now;
end

z_eq=zeros(1,length(z_first)-Know_N);
% 从训练符号里估计当前符号域的典型幅度
A_I = mean(abs(real(z_train)));
A_Q = mean(abs(imag(z_train)));
%训练了前面的已知信号之后就输出预测信号
All_N=length(z_first);
prev_decision = z_train(end);
for n=Know_N+1:1:All_N
Y_n_Now=circshift(Y_n, 1);
Y_n_Now(1)=z_first(n);
Y_n_Now(K1+1) = prev_decision;
d_n = W_n' * Y_n_Now;%输出
% 内部符号切片：只判象限，幅度取训练参考的平均值
    if real(d_n) >= 0
        I_hat = A_I;
    else
        I_hat = -A_I;
    end

    if imag(d_n) >= 0
        Q_hat = A_Q;
    else
        Q_hat = -A_Q;
    end
prev_decision = I_hat + 1j * Q_hat;   % 反馈判决后的历史符号
%调整系数
K_n = (P_n*Y_n_Now)/(lambda_rls + Y_n_Now'*P_n*Y_n_Now);
E_n = prev_decision - W_n'*Y_n_Now;%prev_decision已经是当前判决符号
W_n = W_n + K_n*conj(E_n);
P_n = (1/lambda_rls)*(P_n - K_n*Y_n_Now'*P_n);
Y_n=Y_n_Now;
z_eq(n-Know_N)=d_n;
end
z_eq = [z_train.', z_eq];
I_eq = real(z_eq);
Q_eq = imag(z_eq);
end