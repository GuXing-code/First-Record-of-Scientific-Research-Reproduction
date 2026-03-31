% 计算误码率 (ptr+dfe)
rx_bit_ptr_dfe = reshape([(I_ptr_dfe > 0); (Q_ptr_dfe > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_ptr_dfe));
ber_ptr_dfe = sum(tx_bit(1:L) ~= rx_bit_ptr_dfe(1:L)) / L * 100

% 计算误码率 (ptr)
I_ptr = rx_first(1:2:end);
Q_ptr = rx_first(2:2:end);
rx_bit_ptr = reshape([(I_ptr(:).' > 0); (Q_ptr(:).' > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_ptr));
ber_ptr = sum(tx_bit(1:L) ~= rx_bit_ptr(1:L)) / L * 100

% 计算误码率 (dfe)
rx_bit_dfe = reshape([(I_dfe > 0); (Q_dfe > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_dfe));
ber_dfe = sum(tx_bit(1:L) ~= rx_bit_dfe(1:L)) / L * 100

% 计算误码率 (直接解调)
rx_bit_direct = reshape([(I > 0); (Q > 0)], [], 1);
L = min(length(tx_bit), length(rx_bit_direct));
ber_direct = sum(tx_bit(1:L) ~= rx_bit_direct(1:L)) / L * 100
