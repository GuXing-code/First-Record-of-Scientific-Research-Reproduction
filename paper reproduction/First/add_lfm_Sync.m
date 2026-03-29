function [output,lfm_ref] =add_lfm_Sync(input_signal,T_lfm,Fs,f0,f1)
%input_signal:输入信号
%T_lfm:时长
%Fs：采样率
%f0：起始频率
%f1：中止频率
%N: 加入的点数
N=round(T_lfm*Fs);%有N个点
K=(f1-f0)/T_lfm;
t = (0:N-1)/Fs;
lfm_ref = sin(2*pi*(f0*t + 0.5*K*t.^2));
input_signal=reshape(input_signal,1,[]);%保证input_signal是行向量
output = [lfm_ref,  input_signal];
end

