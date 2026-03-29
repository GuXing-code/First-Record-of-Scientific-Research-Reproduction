function [output] = receive_lfm_Sync(input_signal,lfm_ref)
%input_signal:输入信号
%lfm_ref：lfm参考值
[corr_out, lags] = xcorr(input_signal, lfm_ref);
[~, index] = max(abs(corr_out));
index = lags(index);
N=length(lfm_ref);
output=input_signal(index+N+1:end);
end

