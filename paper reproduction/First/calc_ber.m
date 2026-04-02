%用户1
% 计算误码率 (ptr+dfe)
rx_bit_ptr_dfe = reshape([(I_ptr_dfe > 0); (Q_ptr_dfe > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_ptr_dfe));
ber_ptr_dfe = sum(tx_bit(1:L) ~= rx_bit_ptr_dfe(1:L)) / L * 100;
fprintf("用户1:ptr_dfe误码率：%.4f\n",ber_ptr_dfe);
% 计算误码率 (ptr)
% I_ptr = rx_first(1:2:end);
% Q_ptr = rx_first(2:2:end);
% rx_bit_ptr = reshape([(I_ptr(:).' > 0); (Q_ptr(:).' > 0)], [], 1);
% L = min(length(tx_bit), length(rx_bit_ptr));
% ber_ptr = sum(tx_bit(1:L) ~= rx_bit_ptr(1:L)) / L * 100;
% fprintf("用户1:    ptr误码率：%.4f\n",ber_ptr);
% 计算误码率 (dfe)
% rx_bit_dfe = reshape([(I_dfe > 0); (Q_dfe > 0)], [], 1);
% L = min(length(tx_bit), length(rx_bit_dfe));
% ber_dfe = sum(tx_bit(1:L) ~= rx_bit_dfe(1:L)) / L * 100

% 计算误码率 (直接解调)
rx_bit_direct = reshape([(I > 0); (Q > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_direct));
ber_direct = sum(tx_bit(1:L) ~= rx_bit_direct(1:L)) / L * 100;
fprintf("用户1:直接解调误码率：%.4f\n",ber_direct);

%用户2
% (ptr+dfe)
rx_bit_ptr_dfe = reshape([(I_ptr_dfe_double > 0); (Q_ptr_dfe_double > 0)], [], 1);
L = min(length(tx_bit_double), length(rx_bit_ptr_dfe));
ber_ptr_dfe_double = sum(tx_bit_double(1:L) ~= rx_bit_ptr_dfe(1:L)) / L * 100;
fprintf("用户2:ptr_dfe误码率：%.4f\n",ber_ptr_dfe_double);
% (ptr)
% I_ptr_double = rx_first_double(1:2:end);
% Q_ptr_double = rx_first_double(2:2:end);
% rx_bit_ptr = reshape([(I_ptr_double(:).' > 0); (Q_ptr_double(:).' > 0)], [], 1);
% L = min(length(tx_bit_double), length(rx_bit_ptr));
% ber_ptr_double = sum(tx_bit_double(1:L) ~= rx_bit_ptr(1:L)) / L * 100;
% fprintf("用户2:    ptr误码率：%.4f\n",ber_ptr_double);
% (dfe)
% rx_bit_dfe = reshape([(I_dfe_double > 0); (Q_dfe_double > 0)], [], 1);
% L = min(length(tx_bit_double), length(rx_bit_dfe));
% ber_dfe_double = sum(tx_bit_double(1:L) ~= rx_bit_dfe(1:L)) / L * 100

% (直接解调)
rx_bit_direct = reshape([(I > 0); (Q > 0)], [], 1);
L = min(length(tx_bit_double), length(rx_bit_direct));
ber_direct_double = sum(tx_bit_double(1:L) ~= rx_bit_direct(1:L)) / L * 100;
fprintf("用户2:直接解调误码率：%.4f\n",ber_direct_double);

%输出SIC 结果：
%用户1
rx_bit_ptr_sic_dfe = reshape([(I1_dec>0);(Q1_dec>0)], [], 1);
L = min(length(tx_bit), length(rx_bit_ptr_sic_dfe));
ber_ptr_sic_dfe_double = sum(tx_bit(1:L) ~= rx_bit_ptr_sic_dfe(1:L)) / L * 100;
fprintf("用户1:ptr_sic_dfe误码率：%.4f\n",ber_ptr_sic_dfe_double);
%用户2
rx_bit_ptr_sic_dfe = reshape([(I2_dec>0);(Q2_dec>0)], [], 1);
L = min(length(tx_bit), length(rx_bit_ptr_sic_dfe));
ber_ptr_sic_dfe_double = sum(tx_bit_double(1:L) ~= rx_bit_ptr_sic_dfe(1:L)) / L * 100;
fprintf("用户2:ptr_sic_dfe误码率：%.4f\n",ber_ptr_sic_dfe_double);

% % 绘制 q 函数
% %用户1
% t_q1 = (0:length(q12)-1) / Rs;
% q_plot1 = abs(q12);
% q_plot1 = q_plot1 / max(q_plot1);
% 
% t_q2 = (0:length(q21)-1) / Rs;
% q_plot2 = abs(q21);
% q_plot2 = q_plot2 / max(q_plot2);
% 
% figure;
% plot(t_q1, q_plot1, 'b', 'LineWidth', 1.5);
% hold on;
% plot(t_q2, q_plot2, 'r', 'LineWidth', 1.5);
% hold off;
% 
% xlabel('时间/s');
% ylabel('归一化幅度');
% title('双用户 PTR 的 q 函数');
% legend('q12', 'q21');
% grid on;