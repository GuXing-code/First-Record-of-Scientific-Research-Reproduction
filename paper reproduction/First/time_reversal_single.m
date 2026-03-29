function [output] = time_reversal_single(z_rx,h_pre)
%output是I和Q混合的结构，输出行向量
%此函数仅针对单用户时间反转，输入复数和预测信道
z_ptr=conv(z_rx,fliplr(h_pre));
output=reshape([real(z_ptr.');imag(z_ptr.')],1,[]);
end

