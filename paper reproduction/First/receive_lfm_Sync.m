function [output] = receive_lfm_Sync(input_signal,lfm_ref)
%input_signal:输入信号
%lfm_ref：lfm参考值
[corr_out, lags] = xcorr(input_signal, lfm_ref);

threshold = 0.9 * max(corr_out);
% 找所有超过阈值的局部峰
[~, locs] = findpeaks(corr_out, 'MinPeakHeight', threshold);
index = lags(locs(1));

% [~, index] = max(abs(corr_out));
% index = lags(index);
N=length(lfm_ref);
output=input_signal(index+N+1:end);
end

