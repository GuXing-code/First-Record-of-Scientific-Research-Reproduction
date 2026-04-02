function results = inspect_sic_effect( ...
    tx_bit_1, tx_bit_2, ...
    I_before_1, Q_before_1, I_before_2, Q_before_2, ...
    I_after_1, Q_after_1, I_after_2, Q_after_2, varargin)
% inspect_sic_effect
% Standalone helper to inspect whether SIC is reducing multi-user interference.
% It does not change the original algorithm flow.
%
% Typical usage:
% results = inspect_sic_effect( ...
%     tx_bit, tx_bit_double, ...
%     I_ptr_dfe, Q_ptr_dfe, I_ptr_dfe_double, Q_ptr_dfe_double, ...
%     I1_dec, Q1_dec, I2_dec, Q2_dec, ...
%     'q11', q11, 'q22', q22, 'q12', q12, 'q21', q21, ...
%     'figure_name', 'PTR-SIC-DFE效果');

    p = inputParser;
    addParameter(p, 'q11', []);
    addParameter(p, 'q22', []);
    addParameter(p, 'q12', []);
    addParameter(p, 'q21', []);
    addParameter(p, 'figure_name', 'SIC效果');
    parse(p, varargin{:});

    q11 = p.Results.q11;
    q22 = p.Results.q22;
    q12 = p.Results.q12;
    q21 = p.Results.q21;
    figure_name = p.Results.figure_name;

    % Force column vectors.
    tx_bit_1 = tx_bit_1(:);
    tx_bit_2 = tx_bit_2(:);
    I_before_1 = I_before_1(:);
    Q_before_1 = Q_before_1(:);
    I_before_2 = I_before_2(:);
    Q_before_2 = Q_before_2(:);
    I_after_1 = I_after_1(:);
    Q_after_1 = Q_after_1(:);
    I_after_2 = I_after_2(:);
    Q_after_2 = Q_after_2(:);

    % Hard decisions in bit domain.
    rx_before_1 = reshape([(I_before_1 > 0).'; (Q_before_1 > 0).'], [], 1);
    rx_before_2 = reshape([(I_before_2 > 0).'; (Q_before_2 > 0).'], [], 1);
    rx_after_1 = reshape([(I_after_1 > 0).'; (Q_after_1 > 0).'], [], 1);
    rx_after_2 = reshape([(I_after_2 > 0).'; (Q_after_2 > 0).'], [], 1);

    % BER.
    Lb1 = min(length(tx_bit_1), length(rx_before_1));
    Lb2 = min(length(tx_bit_2), length(rx_before_2));
    La1 = min(length(tx_bit_1), length(rx_after_1));
    La2 = min(length(tx_bit_2), length(rx_after_2));

    ber_before_1 = sum(tx_bit_1(1:Lb1) ~= rx_before_1(1:Lb1)) / Lb1 * 100;
    ber_before_2 = sum(tx_bit_2(1:Lb2) ~= rx_before_2(1:Lb2)) / Lb2 * 100;
    ber_after_1 = sum(tx_bit_1(1:La1) ~= rx_after_1(1:La1)) / La1 * 100;
    ber_after_2 = sum(tx_bit_2(1:La2) ~= rx_after_2(1:La2)) / La2 * 100;

    % Complex outputs before/after SIC.
    y_before_1 = I_before_1 + 1j * Q_before_1;
    y_before_2 = I_before_2 + 1j * Q_before_2;
    y_after_1 = I_after_1 + 1j * Q_after_1;
    y_after_2 = I_after_2 + 1j * Q_after_2;

    % Ideal transmitted QPSK symbols.
    x_ref_1 = bits_to_qpsk_symbols(tx_bit_1);
    x_ref_2 = bits_to_qpsk_symbols(tx_bit_2);

    % Output equivalent SINR estimate using desired-signal projection.
    sinr_before_1 = estimate_output_sinr(y_before_1, x_ref_1);
    sinr_before_2 = estimate_output_sinr(y_before_2, x_ref_2);
    sinr_after_1 = estimate_output_sinr(y_after_1, x_ref_1);
    sinr_after_2 = estimate_output_sinr(y_after_2, x_ref_2);

    % MAI leakage proxy: correlation with the other user's ideal symbol sequence.
    leak_before_12 = estimate_leakage(y_before_1, x_ref_2);
    leak_after_12 = estimate_leakage(y_after_1, x_ref_2);
    leak_before_21 = estimate_leakage(y_before_2, x_ref_1);
    leak_after_21 = estimate_leakage(y_after_2, x_ref_1);

    results = struct();
    results.ber.before_user1 = ber_before_1;
    results.ber.before_user2 = ber_before_2;
    results.ber.after_user1 = ber_after_1;
    results.ber.after_user2 = ber_after_2;
    results.ber_gain.user1 = ber_before_1 - ber_after_1;
    results.ber_gain.user2 = ber_before_2 - ber_after_2;

    results.sinr_est.before_user1 = sinr_before_1;
    results.sinr_est.before_user2 = sinr_before_2;
    results.sinr_est.after_user1 = sinr_after_1;
    results.sinr_est.after_user2 = sinr_after_2;
    results.sinr_gain.user1_db = 10 * log10(sinr_after_1 + eps) - 10 * log10(sinr_before_1 + eps);
    results.sinr_gain.user2_db = 10 * log10(sinr_after_2 + eps) - 10 * log10(sinr_before_2 + eps);

    results.mai_leakage.user1_from_user2.before = leak_before_12;
    results.mai_leakage.user1_from_user2.after = leak_after_12;
    results.mai_leakage.user2_from_user1.before = leak_before_21;
    results.mai_leakage.user2_from_user1.after = leak_after_21;
    results.mai_suppression.user1 = leak_before_12 - leak_after_12;
    results.mai_suppression.user2 = leak_before_21 - leak_after_21;

    fprintf('用户1: SIC前 BER = %.4f%%, SIC后 BER = %.4f%%, 改善 = %.4f%%\n', ...
        ber_before_1, ber_after_1, results.ber_gain.user1);
    fprintf('用户2: SIC前 BER = %.4f%%, SIC后 BER = %.4f%%, 改善 = %.4f%%\n', ...
        ber_before_2, ber_after_2, results.ber_gain.user2);

    fprintf('用户1: 输出等效SINR前 = %.4f dB, 后 = %.4f dB, 提升 = %.4f dB\n', ...
        10 * log10(sinr_before_1 + eps), 10 * log10(sinr_after_1 + eps), results.sinr_gain.user1_db);
    fprintf('用户2: 输出等效SINR前 = %.4f dB, 后 = %.4f dB, 提升 = %.4f dB\n', ...
        10 * log10(sinr_before_2 + eps), 10 * log10(sinr_after_2 + eps), results.sinr_gain.user2_db);

    fprintf('用户1: 来自用户2的干扰泄漏前 = %.4f, 后 = %.4f, 抑制量 = %.4f\n', ...
        leak_before_12, leak_after_12, results.mai_suppression.user1);
    fprintf('用户2: 来自用户1的干扰泄漏前 = %.4f, 后 = %.4f, 抑制量 = %.4f\n', ...
        leak_before_21, leak_after_21, results.mai_suppression.user2);

    % Figure 1: BER before/after SIC.
    figure('Name', [figure_name, '_BER对比']);
    ber_mat = [ber_before_1, ber_after_1; ber_before_2, ber_after_2];
    bar(ber_mat);
    set(gca, 'XTickLabel', {'用户1', '用户2'});
    legend('SIC前', 'SIC后', 'Location', 'best');
    ylabel('BER / %');
    title([figure_name, ' BER前后对比']);
    grid on;

    % Figure 2: Output SINR and MAI leakage before/after SIC.
    figure('Name', [figure_name, '_MAI抑制效果']);

    subplot(2,1,1);
    sinr_mat_db = [10 * log10(sinr_before_1 + eps), 10 * log10(sinr_after_1 + eps); ...
                   10 * log10(sinr_before_2 + eps), 10 * log10(sinr_after_2 + eps)];
    bar(sinr_mat_db);
    set(gca, 'XTickLabel', {'用户1', '用户2'});
    legend('SIC前', 'SIC后', 'Location', 'best');
    ylabel('SINR / dB');
    title('输出等效SINR前后对比');
    grid on;

    subplot(2,1,2);
    leak_mat = [leak_before_12, leak_after_12; leak_before_21, leak_after_21];
    bar(leak_mat);
    set(gca, 'XTickLabel', {'用户1中的用户2泄漏', '用户2中的用户1泄漏'});
    legend('SIC前', 'SIC后', 'Location', 'best');
    ylabel('归一化泄漏系数');
    title('多址干扰泄漏前后对比');
    grid on;

    % Optional q-function comparison.
    has_q = ~isempty(q11) && ~isempty(q22) && ~isempty(q12) && ~isempty(q21);
    if has_q
        q11 = reshape(q11, 1, []);
        q22 = reshape(q22, 1, []);
        q12 = reshape(q12, 1, []);
        q21 = reshape(q21, 1, []);

        P1 = mean(abs(y_before_1).^2);
        P2 = mean(abs(y_before_2).^2);
        results.sir_est.user1 = P1 * sum(abs(q11).^2) / (P2 * sum(abs(q12).^2) + eps);
        results.sir_est.user2 = P2 * sum(abs(q22).^2) / (P1 * sum(abs(q21).^2) + eps);

        fprintf('用户1: 基于 q 函数的参考SIR = %.4f\n', results.sir_est.user1);
        fprintf('用户2: 基于 q 函数的参考SIR = %.4f\n', results.sir_est.user2);

        figure('Name', [figure_name, '_q函数对比']);

        subplot(2,1,1);
        scale1 = max([abs(q11), abs(q12), eps]);
        plot(abs(q11) / scale1, 'b', 'LineWidth', 1.2);
        hold on;
        plot(abs(q12) / scale1, 'r--', 'LineWidth', 1.2);
        hold off;
        title('用户1: 自项 q_{11} 与交叉项 q_{12}');
        legend('q11', 'q12', 'Location', 'best');
        ylabel('归一化幅度');
        grid on;

        subplot(2,1,2);
        scale2 = max([abs(q22), abs(q21), eps]);
        plot(abs(q22) / scale2, 'b', 'LineWidth', 1.2);
        hold on;
        plot(abs(q21) / scale2, 'r--', 'LineWidth', 1.2);
        hold off;
        title('用户2: 自项 q_{22} 与交叉项 q_{21}');
        legend('q22', 'q21', 'Location', 'best');
        ylabel('归一化幅度');
        xlabel('采样点');
        grid on;
    end

    % Figure 4: constellation comparison.
    figure('Name', [figure_name, '_判决散点对比']);
    subplot(2,2,1);
    scatter(I_before_1, Q_before_1, 8, 'filled');
    title('用户1 SIC前');
    xlabel('I');
    ylabel('Q');
    axis equal;
    grid on;

    subplot(2,2,2);
    scatter(I_after_1, Q_after_1, 8, 'filled');
    title('用户1 SIC后');
    xlabel('I');
    ylabel('Q');
    axis equal;
    grid on;

    subplot(2,2,3);
    scatter(I_before_2, Q_before_2, 8, 'filled');
    title('用户2 SIC前');
    xlabel('I');
    ylabel('Q');
    axis equal;
    grid on;

    subplot(2,2,4);
    scatter(I_after_2, Q_after_2, 8, 'filled');
    title('用户2 SIC后');
    xlabel('I');
    ylabel('Q');
    axis equal;
    grid on;
end

function x_ref = bits_to_qpsk_symbols(tx_bits)
    tx_bits = tx_bits(:);
    L = floor(length(tx_bits) / 2) * 2;
    tx_bits = tx_bits(1:L);
    tx_bits_matrix = reshape(tx_bits, 2, []);
    I_ref = 2 * tx_bits_matrix(1, :) - 1;
    Q_ref = 2 * tx_bits_matrix(2, :) - 1;
    x_ref = (I_ref(:) + 1j * Q_ref(:));
end

function sinr_est = estimate_output_sinr(y_est, x_ref)
    y_est = y_est(:);
    x_ref = x_ref(:);
    L = min(length(y_est), length(x_ref));
    y_est = y_est(1:L);
    x_ref = x_ref(1:L);

    gain = (x_ref' * y_est) / (x_ref' * x_ref + eps);
    y_des = gain * x_ref;
    y_err = y_est - y_des;
    sinr_est = sum(abs(y_des).^2) / (sum(abs(y_err).^2) + eps);
end

function leakage = estimate_leakage(y_est, x_other)
    y_est = y_est(:);
    x_other = x_other(:);
    L = min(length(y_est), length(x_other));
    y_est = y_est(1:L);
    x_other = x_other(1:L);

    leakage = abs(sum(y_est .* conj(x_other))) / (norm(y_est) * norm(x_other) + eps);
end
