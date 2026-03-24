%绘图：
figure(1);
plot(rx_signal);
axis([0 200 -2 2]);
title(['rx signal']);
figure(2);
stem(tx_bit,'Color','b');
hold on;
stem(rx_bit+0.03,'Color','r');
