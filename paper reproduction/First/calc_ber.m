%训练之后的
rx_bit=reshape([(I_eq>0);(Q_eq>0)],[],1);
L = min(length(tx_bit), length(rx_bit));
ber_train = sum(tx_bit(1:L) ~= rx_bit(1:L)) / L*100
% 计算误码率-(直接解调)
rx_bit_direct=reshape([(I>0);(Q>0)],[],1);
L = min(length(tx_bit), length(rx_bit_direct));
ber_direct = sum(tx_bit(1:L) ~= rx_bit_direct(1:L)) / L * 100

