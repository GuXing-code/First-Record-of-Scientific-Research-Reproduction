function [h_eq, tap_axis, detail] = true_equivalent_channel(h, fc, Rs, Ts, num_taps, lfm_ref, sync_index, order_mode)
%TRUE_EQUIVALENT_CHANNEL
% Compute the theoretical equivalent channel of the CURRENT implementation
% chain without using channel_estimation.
%
% Method:
% 1) Build the exact passband Tx/Rx chain used in the project.
% 2) Send a unit impulse in the complex-symbol domain through the chain.
% 3) Subtract the zero-data baseline caused by the LFM header.
% 4) The post-demodulated response is the theoretical h_eq.
%
% Inputs:
%   h          physical sample-domain channel
%   fc, Rs, Ts current system parameters
%   num_taps   desired number of equivalent taps
%   lfm_ref    optional LFM header used by the current sync logic
%   sync_index optional manual sync index; if empty and lfm_ref is given,
%              infer it from the same correlation rule as receive_lfm_Sync
%   order_mode "paper" (default) or "natural"
%
% Outputs:
%   h_eq       theoretical equivalent channel in complex-symbol domain
%   tap_axis   tap indices
%   detail     debug information

if nargin < 5 || isempty(num_taps)
    num_taps = 20;
end
if nargin < 6
    lfm_ref = [];
end
if nargin < 7
    sync_index = [];
end
if nargin < 8 || isempty(order_mode)
    order_mode = "paper";
end

h = reshape(h, 1, []);
if ~isempty(lfm_ref)
    lfm_ref = reshape(lfm_ref, 1, []);
end

extra_syms = 12;
probe_len = num_taps + extra_syms;

z0 = complex(zeros(1, probe_len));
z1 = complex([1, zeros(1, probe_len - 1)]);

tx0 = mod_complex_symbols(z0, fc, Rs, Ts);
tx1 = mod_complex_symbols(z1, fc, Rs, Ts);

if ~isempty(lfm_ref)
    tx0 = [lfm_ref, tx0];
    tx1 = [lfm_ref, tx1];
end

rx0 = conv(tx0, h);
rx1 = conv(tx1, h);

if ~isempty(lfm_ref)
    if isempty(sync_index)
        sync_index = infer_sync_index(rx1, lfm_ref);
    end

    Nlfm = length(lfm_ref);
    start_idx = sync_index + Nlfm + 1;
    rx0 = rx0(start_idx:end);
    rx1 = rx1(start_idx:end);
else
    sync_index = 0;
end

[y0_iq, ~, ~] = qpsk_demod(rx0, fc, Rs, Ts);
[y1_iq, ~, ~] = qpsk_demod(rx1, fc, Rs, Ts);

zrx0 = iq_to_complex(y0_iq);
zrx1 = iq_to_complex(y1_iq);

Lout = min(length(zrx0), length(zrx1));
zresp = zrx1(1:Lout) - zrx0(1:Lout);

h_nat = zresp(1:min(num_taps, length(zresp)));
if length(h_nat) < num_taps
    h_nat(end+1:num_taps, 1) = 0;
end

tap_axis = (0:num_taps-1).';
switch lower(string(order_mode))
    case "paper"
        h_eq = flipud(h_nat);
        tap_axis = (num_taps-1:-1:0).';
    case "natural"
        h_eq = h_nat;
    otherwise
        error('order_mode must be "paper" or "natural".');
end

detail = struct();
detail.h_raw = h;
detail.sync_index = sync_index;
detail.order_mode = char(order_mode);
detail.h_eq_natural = h_nat;
detail.h_eq_output = h_eq;
detail.baseline = zrx0;
detail.impulse_response = zresp;
end

function tx = mod_complex_symbols(z, fc, Rs, Ts)
z = reshape(z, 1, []);
Ns = round(1 / Rs / Ts);
a = 1;
span = 6;
ht = rcosdesign(a, span, Ns, "sqrt");

I_up = upsample(real(z), Ns);
Q_up = upsample(imag(z), Ns);
I_shaped = conv(I_up, ht);
Q_shaped = conv(Q_up, ht);
t = (0:length(I_shaped)-1) * Ts;

tx = I_shaped .* cos(2 * pi * fc * t) - Q_shaped .* sin(2 * pi * fc * t);
end

function z = iq_to_complex(y_iq)
y_iq = y_iq(:);
z = y_iq(1:2:end) + 1j * y_iq(2:2:end);
end

function sync_index = infer_sync_index(rx_signal, lfm_ref)
[corr_out, lags] = xcorr(rx_signal, lfm_ref);
threshold = 0.9 * max(corr_out);
[~, locs] = findpeaks(corr_out, 'MinPeakHeight', threshold);

if isempty(locs)
    [~, idx_max] = max(corr_out);
    sync_index = lags(idx_max);
else
    sync_index = lags(locs(1));
end
end
