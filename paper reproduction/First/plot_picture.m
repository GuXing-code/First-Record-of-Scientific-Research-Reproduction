subplot(2,1,1);
stem(h_pre);
title('prediction');
subplot(2,1,2);
stem(h_eq_true);
title('theory');
% 方法1：复相关相似度
sim1 = abs( sum(h_pre .* conj(h_eq_true)) ) / ( norm(h_pre) * norm(h_eq_true) );
% 方法2：NMSE 相似度
nmse = mean(abs(h_pre - h_eq_true).^2) / mean(abs(h_eq_true).^2);
sim2 = 1 / (1 + nmse);

fprintf('复相关相似度: %.4f\n', sim1);
fprintf('NMSE相似度   : %.4f\n', sim2);
