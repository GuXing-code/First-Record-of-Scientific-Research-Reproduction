function [h_eff, tap_axis, detail] = theoretical_demod_channel(h, Rs, Ts, num_taps, do_plot)
%THEORETICAL_DEMOD_CHANNEL
% Compute the theoretical effective discrete channel after:
% tx sqrt-RC shaping -> physical channel -> rx sqrt-RC matched filtering
% -> symbol-rate sampling.

if nargin < 4 || isempty(num_taps)
    num_taps = [];
end
if nargin < 5 || isempty(do_plot)
    do_plot = false;
end

h = reshape(h, 1, []);

a = 1;
Ns = round(1 / Rs / Ts);
span = 6;
ht = rcosdesign(a, span, Ns, "sqrt");

% Total pulse response seen at symbol-rate sampling.
g = conv(ht, ht);

% qpsk_demod compensates the total tx/rx filter delay.
delay = span * Ns;

if isempty(num_taps)
    num_taps = 2 * span + ceil((length(h) - 1) / Ns) + 2;
end

h_eff = zeros(num_taps, 1);
tap_axis = (0:num_taps-1).';

for n = 0:num_taps-1
    acc = 0;
    for m = 0:length(h)-1
        idx = delay + n * Ns - m + 1;
        if idx >= 1 && idx <= length(g)
            acc = acc + h(m + 1) * g(idx);
        end
    end
    h_eff(n + 1) = acc;
end

detail = struct();
detail.Ns = Ns;
detail.rolloff = a;
detail.span = span;
detail.ht = ht;
detail.g = g;
detail.delay = delay;
detail.path_delay_samples = find(abs(h) > 0) - 1;
detail.path_delay_symbols = detail.path_delay_samples / Ns;
detail.path_gain = h(abs(h) > 0);

if do_plot
    figure('Color', 'w');
    stem(tap_axis, abs(h_eff), 'filled', 'LineWidth', 1.1, ...
        'Color', [0.12, 0.41, 0.70], 'MarkerFaceColor', [0.12, 0.41, 0.70]);
    grid on;
    xlabel('Symbol tap index');
    ylabel('|h_{eff}|');
    title('Theoretical Effective Channel After Demodulation');
end
end
