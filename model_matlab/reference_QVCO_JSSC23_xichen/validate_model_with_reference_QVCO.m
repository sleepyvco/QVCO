%% QVCO_total_plot_Fig3_Fig5_only.m
% Simplified open/release version derived from QVCO_total_plot_V44.m.
%
% This script keeps ONLY the two requested figures:
%
%   Figure 3:
%     2-by-2 K_GS result for C_S = 450 fF and 500 fF.
%     Top row    : |K_GS(q)| in linear ohms.
%     Bottom row : unwrapped phase of K_GS(q).
%
%   Figure 5:
%     2-by-3 C_S-domain summary:
%       (a) predicted mode frequencies and quadrature phase
%       (b) phase shifts
%       (c) normalized source-voltage ratios
%       (d) |Z_S| at f_PSS
%       (e) open-loop Q
%       (f) R_p
%
% Removed from V44:
%   - original 3-by-3 Figure 1
%   - 2-by-3 K_GS variant
%   - 1-by-2 |Z_S| variant
%   - standalone K_GS-magnitude summary
%   - unrelated legacy plotting helper functions
%
% Requirement:
%   MATLAB RF Toolbox (sparameters).
%   Place this script in the same folder as the referenced .s9p files.


clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
if ~isempty(scriptDir)
    cd(scriptDir);
else
    scriptDir = pwd;
end

%% ===================== User settings ====================================
files = string({ ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_150f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_200f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_250f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_300f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_350f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_400f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_450f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_500f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_550f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_600f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_650f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_700f.s9p'; ...
    'QVCO_Xichen_Cs_nch_lvt_dnw_750f.s9p'  ...
});

Cs_fF = [150 200 250 300 350 400 450 500 550 600 650 700 750].';
fPSS_GHz = [9.956 9.929 9.879 9.822 9.759 9.686 9.598 10.48 10.47 10.46 10.45 10.43 10.42].';

% KGS selected branch convention:
%   minus -> omega_L, plus -> omega_H.
pssMode = [ ...
    "minus" "minus" "minus" "minus" "minus" "minus" "minus" ...
    "plus"  "plus"  "plus"  "plus"  "plus"  "plus"  ...
].';

% Source-impedance selected branch convention:
%   L -> omega_L, H -> omega_H.
sourceMode = repmat("L", numel(Cs_fF), 1);
sourceMode(Cs_fF >= 500) = "H";

% Quadrature phase sign used for the mode-jump overlay in Figure 3.
% Low-frequency selected branch:  omega_L -> -90 deg
% High-frequency selected branch: omega_H -> +90 deg
quadPhase_deg = -90 * ones(size(Cs_fF));
quadPhase_deg(sourceMode == "H") = +90;

% ADE/PSS selected-mode source-fraction ratios from the PSS table.
% These are simulation references for Figure 2:
%   pss_mag_VS_over_VD = |V_S|/|V_D| at fPSS, selected mode only
%   pss_mag_VS_over_VG = |V_S|/|V_G| at fPSS, selected mode only
pss_mag_VS_over_VG = [ ...
    0.2633 0.2791 0.2986 0.3207 0.3457 0.3745 0.4082 ...
    0.1013 0.1097 0.1191 0.1287 0.1389 0.1491 ...
].';

pss_mag_VS_over_VD = [ ...
    0.5525 0.5858 0.6237 0.6661 0.7138 0.7675 0.8280 ...
    0.2266 0.2457 0.2671 0.2890 0.3121 0.3347 ...
].';

% V17: ADE/PSS paper-frame phase data for the publication-style phase summary.
% These are the selected-mode phase shifts exported from ADE/PSS.
pss_Phi_GD_deg = [ ...
    -10.15 -10.27 -10.43 -10.63 -10.88 -11.19 -11.57 ...
    -10.14 -10.24 -10.37 -10.57 -10.81 -11.12 ...
].';

pss_Phi_SG_deg = [ ...
    -13.79 -14.35 -15.79 -17.34 -18.98 -20.82 -23.06 ...
      1.713 -0.6195 -3.191 -6.301 -9.736 -13.65 ...
].';

compareCs = [450 500 750];
fmin_plot = 9e9;
fmax_plot = 12e9;
fmin_peak = 9e9;
fmax_peak = 12e9;

% KGS settings.
correctionMode = 'removeReal';
phaseConvention = 'rawK';
phaseTargetDeg = -180;
phaseYLabel = 'Unwrapped phase of K (deg)';

% V13: phase-slope effective-Q extraction window for the new Q-vs-Cs figure.
phaseSlopeFitHalfBW_Hz = 100e6;

% Source-impedance mode convention.
qL = -1j;
qH = +1j;

% Output options.
outDir = scriptDir;
if ~exist(outDir,'dir'); mkdir(outDir); end
saveFig = false;

% Style.
fontName = 'Arial';
fsAxis  = 14;
fsLabel = 14;
fsTitle = 14;
lwMain  = 1.8;

% V36 quick toggle for Figure 1 x-axis label weight.
% Use 'normal' for non-bold xlabel, or change to 'bold' if you want bold xlabel later.
fig1XLabelFontWeight = 'normal';

clrMinus = [0.0000 0.4470 0.7410];% #0072BD, blue
clrPlus  = [0.8500 0.3250 0.0980];% #D95319, orange
clrPSS   = [0.20 0.20 0.20];
clrSelf  = [0.9290 0.6940 0.1250];% #EDB120, yellow
clrCross = [0.4940 0.1840 0.5560];% #7E2F8E, purple

%% ===================== KGS calculation ==================================
% Corrected connection mapping, from QVCO_Cs_sweep_KGS_plot_v8.
p.DI = 1; p.GI = 2; p.SI = 3;
p.DQ = 4; p.GQ = 5; p.SQ = 6;
p.DM = 7; p.GM = 8; p.SM = 9;

PEI = zeros(3,6);
PEI(1,p.DI) = +1;
PEI(2,p.GI) = +1;
PEI(3,p.SQ) = +1;

PEQ = zeros(3,6);
PEQ(1,p.DQ) = +1;
PEQ(2,p.GQ) = +1;
PEQ(3,p.SI) = -1;

PTI = zeros(3,6);
PTI(1,p.DI) = +1;
PTI(2,p.GI) = -1;
PTI(3,p.SQ) = +1;

PTQ = zeros(3,6);
PTQ(1,p.DQ) = +1;
PTQ(2,p.GQ) = -1;
PTQ(3,p.SI) = -1;

Lobs = zeros(2,6);
Lobs(1,:) = PTI(2,:) - PTI(3,:);   % VGS_I = -GI - SQ
Lobs(2,:) = PTQ(2,:) - PTQ(3,:);   % VGS_Q = -GQ + SI

Rinj = zeros(6,2);
Rinj(p.DI,1) = +1;
Rinj(p.SQ,1) = -1;
Rinj(p.DQ,2) = +1;
Rinj(p.SI,2) = +1;

Ncase = numel(files);
DataKGS = cell(Ncase,1);
fKplusPeak_GHz  = nan(Ncase,1);
fKminusPeak_GHz = nan(Ncase,1);
KplusAtPSS_dBOhm  = nan(Ncase,1);
KminusAtPSS_dBOhm = nan(Ncase,1);
phaseKplusAtPSS_deg  = nan(Ncase,1);
phaseKminusAtPSS_deg = nan(Ncase,1);

% V13: phase-slope effective Q at actual PSS frequency.
QphiKplusAtPSS  = nan(Ncase,1);
QphiKminusAtPSS = nan(Ncase,1);
phaseSlopeKplusAtPSS_degPerGHz  = nan(Ncase,1);
phaseSlopeKminusAtPSS_degPerGHz = nan(Ncase,1);

% Phase-target frequency arrays for the new V4 Figure 3.
% Target is phaseTargetDeg, normally -180 deg under rawK convention.
fKplusPhaseTarget_GHz  = nan(Ncase,1);
fKminusPhaseTarget_GHz = nan(Ncase,1);

fprintf('\n================ QVCO total plot V4: KGS calculation ================\n');
for ic = 1:Ncase
    fileName = files(ic);
    fPSS = fPSS_GHz(ic) * 1e9;

    if ~isfile(fileName)
        warning('KGS file not found: %s. This case is skipped.', fileName);
        continue;
    end

    R = calc_one_case(fileName, PEI, PEQ, Lobs, Rinj, correctionMode);
    switch phaseConvention
        case 'rawK'
            R.KplusPhaseObj  = R.Kplus;
            R.KminusPhaseObj = R.Kminus;
        case 'loopMinusK'
            R.KplusPhaseObj  = -R.Kplus;
            R.KminusPhaseObj = -R.Kminus;
        otherwise
            error('Unknown phaseConvention: %s', phaseConvention);
    end

    plotMask = (R.freq >= fmin_plot) & (R.freq <= fmax_plot);
    R.phaseKplusUnwrapped  = unwrap_phase_for_display(R.KplusPhaseObj,  plotMask, phaseConvention);
    R.phaseKminusUnwrapped = unwrap_phase_for_display(R.KminusPhaseObj, plotMask, phaseConvention);
    DataKGS{ic} = R;

    peakMask = (R.freq >= fmin_peak) & (R.freq <= fmax_peak);
    idxList = find(peakMask);
    [~, idxPpkLocal] = max(abs(R.Kplus(peakMask)));
    [~, idxMpkLocal] = max(abs(R.Kminus(peakMask)));
    idxPpk = idxList(idxPpkLocal);
    idxMpk = idxList(idxMpkLocal);
    fKplusPeak_GHz(ic)  = R.freq(idxPpk)/1e9;
    fKminusPeak_GHz(ic) = R.freq(idxMpk)/1e9;

    KpAtPSS = complex_interp(R.freq, R.Kplus, fPSS);
    KmAtPSS = complex_interp(R.freq, R.Kminus, fPSS);
    KplusAtPSS_dBOhm(ic)  = 20*log10(abs(KpAtPSS));
    KminusAtPSS_dBOhm(ic) = 20*log10(abs(KmAtPSS));
    phaseKplusAtPSS_deg(ic)  = interp1(R.freq, R.phaseKplusUnwrapped,  fPSS, 'pchip', 'extrap');
    phaseKminusAtPSS_deg(ic) = interp1(R.freq, R.phaseKminusUnwrapped, fPSS, 'pchip', 'extrap');

    % V13: phase-slope effective Q at the actual PSS frequency.
    [QphiKplusAtPSS(ic), phaseSlopeKplusAtPSS_degPerGHz(ic)] = ...
        phase_slope_Q_at_freq(R.freq, R.phaseKplusUnwrapped, fPSS, phaseSlopeFitHalfBW_Hz);
    [QphiKminusAtPSS(ic), phaseSlopeKminusAtPSS_degPerGHz(ic)] = ...
        phase_slope_Q_at_freq(R.freq, R.phaseKminusUnwrapped, fPSS, phaseSlopeFitHalfBW_Hz);

    % Frequency where each effective mode phase reaches the target.
    fKplusPhaseTarget_GHz(ic) = phase_target_frequency(R.freq, R.phaseKplusUnwrapped, ...
        phaseTargetDeg, fmin_plot, fmax_plot, fPSS);
    fKminusPhaseTarget_GHz(ic) = phase_target_frequency(R.freq, R.phaseKminusUnwrapped, ...
        phaseTargetDeg, fmin_plot, fmax_plot, fPSS);
end

%% ===================== Source-impedance calculation ======================
fprintf('\n================ QVCO total plot V2: source-impedance calculation ================\n');
DataSrc = cell(Ncase,1);
for ic = 1:Ncase
    fileName = char(files(ic));
    if ~isfile(fileName)
        warning('Source file not found: %s. This case is skipped.', fileName);
        continue;
    end
    res = calc_source_impedance_one_file(fileName, fPSS_GHz(ic)*1e9, fmin_plot, fmax_plot, qL, qH);
    if sourceMode(ic) == "H"
        res.modeSelected = 'H';
    else
        res.modeSelected = 'L';
    end
    DataSrc{ic} = res;
end



%% ===================== Figure 3: KGS_freq_2x2 only =======================
% Retained from V44 Figure 3.
% Columns: C_S = 450 fF and 500 fF.
% Top row: |K_GS(q)| in linear ohms.
% Bottom row: unwrapped phase of K_GS(q).
%
% The panel labels remain column-wise:
%   left column  -> (a), (b)
%   right column -> (c), (d)

compareCs = [450 500 750];
compareIdx = nan(numel(compareCs),1);
for kk = 1:numel(compareCs)
    [~, compareIdx(kk)] = min(abs(Cs_fF - compareCs(kk)));
end

idxUse = compareIdx(1:2);
nCol = numel(idxUse);

% Shared y-limit for the top row in linear ohms.
magLinearAll = [];
for jj = 1:numel(idxUse)
    Rtmp = DataKGS{idxUse(jj)};
    if isempty(Rtmp); continue; end
    maskTmp = (Rtmp.freq >= fmin_plot) & (Rtmp.freq <= fmax_plot);
    magLinearAll = [magLinearAll; ...
        abs(Rtmp.Kminus(maskTmp)); ...
        abs(Rtmp.Kplus(maskTmp))]; %#ok<AGROW>
end
magLinearAll = magLinearAll(isfinite(magLinearAll));

if isempty(magLinearAll)
    magVariantYLim = [];
else
    magLinearSpan = max(magLinearAll) - min(magLinearAll);
    magLinearMargin = max(5, 0.08*(magLinearSpan + eps));
    magVariantYLim = [max(0, min(magLinearAll)-magLinearMargin), ...
                      max(magLinearAll)+magLinearMargin];
end

fig3 = figure(3);
clf(fig3);
set(fig3,'Color','w','Position',[30 30 1280 820]);
tl3 = tiledlayout(fig3, 2, nCol, 'TileSpacing','compact', 'Padding','compact');

for kk = 1:nCol
    ic = idxUse(kk);
    R = DataKGS{ic};

    %% Top row: |K_GS(q)| in linear ohms
    ax = nexttile(tl3, kk);
    hold(ax,'on'); grid(ax,'on'); box(ax,'on');

    if isempty(R)
        text(ax,0.5,0.5,sprintf('C_S = %.0f fF KGS file missing', Cs_fF(ic)), ...
            'Units','normalized','HorizontalAlignment','center');
        axis(ax,'off');
    else
        fGHz = R.freq/1e9;
        mask = (R.freq >= fmin_plot) & (R.freq <= fmax_plot);

        yKminus = abs(R.Kminus(mask));
        yKplus  = abs(R.Kplus(mask));

        plot(ax, fGHz(mask), yKminus, ...
            'Color',clrMinus, 'LineWidth',lwMain, 'DisplayName','|Kminus|');
        plot(ax, fGHz(mask), yKplus, ...
            'Color',clrPlus,  'LineWidth',lwMain, 'DisplayName','|Kplus|');

        xline(ax, fPSS_GHz(ic), '--', 'PSS', ...
            'Color',clrPSS, 'LineWidth',1.2, ...
            'LabelOrientation','horizontal', ...
            'LabelVerticalAlignment','bottom', ...
            'HandleVisibility','off');

        xline(ax, fKminusPeak_GHz(ic), ':', ...
            'Color',clrMinus, 'LineWidth',1.0, 'HandleVisibility','off');
        xline(ax, fKplusPeak_GHz(ic), ':', ...
            'Color',clrPlus, 'LineWidth',1.0, 'HandleVisibility','off');

        markerMinus = 10.^(KminusAtPSS_dBOhm(ic)/20);
        markerPlus  = 10.^(KplusAtPSS_dBOhm(ic)/20);

        if strcmpi(pssMode(ic), "minus")
            plot(ax, fPSS_GHz(ic), markerMinus, 'o', ...
                'Color',clrMinus, 'MarkerFaceColor',clrMinus, ...
                'MarkerSize',6, 'HandleVisibility','off');
        else
            plot(ax, fPSS_GHz(ic), markerPlus, 'o', ...
                'Color',clrPlus, 'MarkerFaceColor',clrPlus, ...
                'MarkerSize',6, 'HandleVisibility','off');
        end

        xlim(ax,[fmin_plot fmax_plot]/1e9);
        if ~isempty(magVariantYLim); ylim(ax,magVariantYLim); end

        hY = ylabel(ax,'|\itK\rm_{GS}(\itq\rm)| (\Omega)', ...
            'FontName',fontName,'FontSize',fsLabel, ...
            'FontWeight','normal','Interpreter','tex');
        hX = xlabel(ax,'Frequency (GHz)', ...
            'FontName',fontName,'FontSize',fsLabel, ...
            'FontWeight',fig1XLabelFontWeight);

        set(ax,'FontName',fontName,'FontSize',fsAxis, ...
            'FontWeight','bold','LineWidth',1.5);
        ax.XAxis.FontWeight = 'bold';
        ax.YAxis.FontWeight = 'bold';
        hY.FontWeight = 'normal';
        hX.FontWeight = fig1XLabelFontWeight;
    end

    add_panel_label(ax, sprintf('(%c)', char('a' + (kk-1)*2)), ...
        fontName, fsLabel);

    %% Bottom row: phase of K_GS(q)
    ax = nexttile(tl3, nCol + kk);
    hold(ax,'on'); grid(ax,'on'); box(ax,'on');

    if isempty(R)
        axis(ax,'off');
    else
        fGHz = R.freq/1e9;
        mask = (R.freq >= fmin_plot) & (R.freq <= fmax_plot);

        plot(ax, fGHz(mask), R.phaseKminusUnwrapped(mask), ...
            'Color',clrMinus, 'LineWidth',lwMain, 'DisplayName','Kminus phase');
        plot(ax, fGHz(mask), R.phaseKplusUnwrapped(mask), ...
            'Color',clrPlus, 'LineWidth',lwMain, 'DisplayName','Kplus phase');

        yline(ax, phaseTargetDeg, 'k:', ...
            'LineWidth',1.0, 'HandleVisibility','off');
        xline(ax, fPSS_GHz(ic), '--', 'PSS', ...
            'Color',clrPSS, 'LineWidth',1.2, ...
            'LabelOrientation','horizontal', ...
            'LabelVerticalAlignment','bottom', ...
            'HandleVisibility','off');

        if strcmpi(pssMode(ic), "minus")
            plot(ax, fPSS_GHz(ic), phaseKminusAtPSS_deg(ic), 'o', ...
                'Color',clrMinus, 'MarkerFaceColor',clrMinus, ...
                'MarkerSize',6, 'HandleVisibility','off');
        else
            plot(ax, fPSS_GHz(ic), phaseKplusAtPSS_deg(ic), 'o', ...
                'Color',clrPlus, 'MarkerFaceColor',clrPlus, ...
                'MarkerSize',6, 'HandleVisibility','off');
        end

        xlim(ax,[fmin_plot fmax_plot]/1e9);
        ylim(ax,[-360 0]);
        yticks(ax,-360:60:0);

        hY = ylabel(ax,'\angle\itK\rm_{GS}(\itq\rm) (^\circ)', ...
            'FontName',fontName,'FontSize',fsLabel, ...
            'FontWeight','normal','Interpreter','tex');
        hX = xlabel(ax,'Frequency (GHz)', ...
            'FontName',fontName,'FontSize',fsLabel, ...
            'FontWeight',fig1XLabelFontWeight);

        set(ax,'FontName',fontName,'FontSize',fsAxis, ...
            'FontWeight','bold','LineWidth',1.5);
        ax.XAxis.FontWeight = 'bold';
        ax.YAxis.FontWeight = 'bold';
        hY.FontWeight = 'normal';
        hX.FontWeight = fig1XLabelFontWeight;
    end

    add_panel_label(ax, sprintf('(%c)', char('a' + (kk-1)*2 + 1)), ...
        fontName, fsLabel);
end

if saveFig
    export_pdf_and_svg_from_pdf_v25(fig3, outDir, 'KGS_freq_2x2');
end

%% ===================== Figure 5: six summary panels only =================
% Retained from V44 Figure 5:
%   (a) mode-frequency prediction + quadrature phase jump
%   (b) phase-shift comparison
%   (c) normalized source-voltage ratios
%   (d) |Z_S| at f_PSS
%   (e) open-loop Q
%   (f) R_p

plot_six_summary_panel_V20(DataSrc, Cs_fF, sourceMode, fPSS_GHz, ...
    fKminusPhaseTarget_GHz, fKplusPhaseTarget_GHz, quadPhase_deg, ...
    pss_mag_VS_over_VG, pss_mag_VS_over_VD, ...
    pss_Phi_SG_deg, pss_Phi_GD_deg, ...
    QphiKminusAtPSS, QphiKplusAtPSS, ...
    phaseTargetDeg, outDir, saveFig, fontName, fsAxis, fsLabel, fsTitle, ...
    lwMain, clrMinus, clrPlus);

% Always export ONLY Figure 5(a) as a standalone vector PDF.
export_figure5a_pdf(Cs_fF, sourceMode, fPSS_GHz, ...
    fKminusPhaseTarget_GHz, fKplusPhaseTarget_GHz, quadPhase_deg, ...
    outDir, fontName, fsAxis, fsLabel, lwMain, clrMinus, clrPlus);

fprintf('\nDone. Figure 3 and Figure 5 are displayed. Only Figure5a.pdf is exported.\n');


%% ===================== Local functions ==================================

function export_figure5a_pdf(Cs_fF, sourceMode, fPSS_GHz, ...
    fKminusPhaseTarget_GHz, fKplusPhaseTarget_GHz, phi_GQP_minus_GIP_deg, ...
    outDir, fontName, fsAxis, fsLabel, lwMain, clrMinus, clrPlus)
% Export a standalone copy of Figure 5(a) as a vector PDF.
%
% Output:
%   Figure5a.pdf
%
% No SVG is generated here.

    Cs = Cs_fF(:);
    sourceMode = string(sourceMode(:));
    fPSS = fPSS_GHz(:);
    fM = fKminusPhaseTarget_GHz(:);
    fP = fKplusPhaseTarget_GHz(:);
    phiG = phi_GQP_minus_GIP_deg(:);

    valid = isfinite(Cs);
    Cs = Cs(valid);
    sourceMode = sourceMode(valid);
    fPSS = fPSS(valid);
    fM = fM(valid);
    fP = fP(valid);
    phiG = phiG(valid);

    [Cs, ord] = sort(Cs);
    sourceMode = sourceMode(ord);
    fPSS = fPSS(ord);
    fM = fM(ord);
    fP = fP(ord);
    phiG = phiG(ord);

    isL = sourceMode == "L";
    isH = sourceMode == "H";

    xBoundary = 500;
    clrUn = [0.64 0.64 0.64];
    clrPhi = [0.0000 0.6900 0.7400];
    colorLbg = [244 249 255]/255;
    colorHbg = [1.0000 250/255 238/255];

    figA = figure('Color','w','Position',[120 120 760 540]);
    ax = axes(figA);
    hold(ax,'on');
    grid(ax,'on');
    box(ax,'on');
    setup_summary_axis(ax, fontName, fsAxis);

    idxLastL = find(isL, 1, 'last');
    idxFirstH = find(isH, 1, 'first');

    yAll = [fPSS; fM; fP];
    yAll = yAll(isfinite(yAll));
    if isempty(yAll)
        yMin = 9.0;
        yMax = 10.6;
    else
        ySpan = max(yAll)-min(yAll);
        if ySpan == 0, ySpan = 0.05; end
        yMin = floor((min(yAll)-0.10*ySpan)*10)/10;
        yMax = ceil((max(yAll)+0.10*ySpan)*10)/10;
    end

    %% Left y-axis: frequency
    yyaxis(ax,'left');

    hPSS = plot(ax, Cs, fPSS, 'k--', ...
        'LineWidth',1.4, 'DisplayName','PSS');

    hUn1 = plot(ax, Cs(isL), fP(isL), '-o', ...
        'Color',clrUn, 'LineWidth',1.6, ...
        'MarkerSize',5.8, 'MarkerFaceColor','w', ...
        'MarkerEdgeColor',clrUn, 'DisplayName','Unselected branch');

    hUn2 = plot(ax, Cs(isH), fM(isH), '-o', ...
        'Color',clrUn, 'LineWidth',1.6, ...
        'MarkerSize',5.8, 'MarkerFaceColor','w', ...
        'MarkerEdgeColor',clrUn, 'HandleVisibility','off');

    if ~isempty(idxLastL) && ~isempty(idxFirstH)
        plot(ax, [Cs(idxLastL) Cs(idxFirstH)], ...
            [fP(idxLastL) fP(idxFirstH)], '-', ...
            'Color',clrUn, 'LineWidth',1.6, 'HandleVisibility','off');
        plot(ax, [Cs(idxLastL) Cs(idxFirstH)], ...
            [fM(idxLastL) fM(idxFirstH)], '-', ...
            'Color',clrUn, 'LineWidth',1.6, 'HandleVisibility','off');
    end

    hL = plot(ax, Cs(isL), fM(isL), '-o', ...
        'Color',clrMinus, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', ...
        'DisplayName','Selected \omega_L');

    hH = plot(ax, Cs(isH), fP(isH), '-o', ...
        'Color',clrPlus, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', ...
        'DisplayName','Selected \omega_H');

    xline(ax, xBoundary, ':', ...
        'Color',[0.45 0.45 0.45], ...
        'LineWidth',1.0, 'HandleVisibility','off');

    ylabel(ax,'Frequency (GHz)', ...
        'FontName',fontName, 'FontSize',fsLabel);

    ylim(ax,[yMin yMax]);

    %% Right y-axis: quadrature phase
    yyaxis(ax,'right');

    hPhi = plot(ax, Cs, phiG, '-s', ...
        'Color',clrPhi, 'LineWidth',1.8, ...
        'MarkerSize',5.5, 'MarkerFaceColor','w', ...
        'DisplayName','\phi_{G,QP}-\phi_{G,IP}');

    ylim(ax,[-120 180]);
    yticks(ax,[-90 0 90]);
    ylabel(ax,'\phi_{G,QP}-\phi_{G,IP} (^\circ)', ...
        'Interpreter','tex', ...
        'FontName',fontName, 'FontSize',fsLabel);
    ax.YAxis(2).Color = clrPhi;

    %% Common x-axis and background
    yyaxis(ax,'left');

    xlabel(ax,'\itC\rm_S (fF)', ...
        'Interpreter','tex', ...
        'FontName',fontName, 'FontSize',fsLabel);

    xlim(ax,[min(Cs)-25 max(Cs)+25]);
    xticks(ax,150:100:750);

    % Add the mode-region background. This helper already sends the
    % background patches to the bottom of the axes stack, so no additional
    % Children re-ordering is required here. Avoiding manual ax.Children
    % assignment also prevents compatibility errors in some MATLAB releases.
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);

    legend(ax, [hL hH hUn1 hPSS hPhi], ...
        {'Selected \omega_L', 'Selected \omega_H', ...
         'Unselected branch', 'PSS', ...
         '\phi_{G,QP}-\phi_{G,IP}'}, ...
        'Location','best', ...
        'Interpreter','tex', ...
        'Box','on');

    % Export vector PDF only.
    pdfPath = fullfile(outDir,'[This_paper]Resolved_phase_shift_using_this_model.pdf');
    exportgraphics(figA, pdfPath, ...
        'ContentType','vector', ...
        'BackgroundColor','white');

    fprintf('Standalone Figure 5(a) PDF saved to:\n%s\n', pdfPath);
end


function plot_six_summary_panel_V20(DataSrc, Cs_fF, sourceMode, fPSS_GHz, ...
    fKminusPhaseTarget_GHz, fKplusPhaseTarget_GHz, phi_GQP_minus_GIP_deg, ...
    pss_mag_VS_over_VG, pss_mag_VS_over_VD, ...
    pss_Phi_SG_deg, pss_Phi_GD_deg, ...
    Qminus, Qplus, ...
    phaseTargetDeg, outDir, saveFig, fontName, fsAxis, fsLabel, fsTitle, ...
    lwMain, clrMinus, clrPlus)
    % V28: collect the six Cs-domain summary figures into one 2-by-3 panel.
    % Panel order:
    %   (a) phase-target frequencies + gate quadrature phase jump
    %   (b) publication-style phase summary
    %   (c) source-fraction ratios, PSS Sim. vs Zclean Cal.
    %   (d) |ZS| at fPSS
    %   (e) phase-slope effective Q
    %   (f) Rp extracted from V_D/I_DS with quadrature current excitation
    %
    % All axes and labels use Arial.

    valid = ~cellfun(@isempty, DataSrc);
    if ~any(valid)
        warning('No valid source-impedance data for six-summary panel.');
        return;
    end

    Cs = Cs_fF(valid);
    modeSel = string(sourceMode(valid));
    RR = DataSrc(valid);

    fPSS = fPSS_GHz(valid);
    fM = fKminusPhaseTarget_GHz(valid);
    fP = fKplusPhaseTarget_GHz(valid);
    phiG = phi_GQP_minus_GIP_deg(valid);

    pssVG = pss_mag_VS_over_VG(valid);
    pssVD = pss_mag_VS_over_VD(valid);
    pssSG = pss_Phi_SG_deg(valid);
    pssGD = pss_Phi_GD_deg(valid);

    Qm = Qminus(valid);
    Qp = Qplus(valid);

    % Extract Zclean source-fraction, RpDS, ZS, and calculated phases.
    ratioVD_L = nan(numel(RR),1); ratioVD_H = nan(numel(RR),1);
    ratioVG_L = nan(numel(RR),1); ratioVG_H = nan(numel(RR),1);
    RpDS_L = nan(numel(RR),1);   RpDS_H = nan(numel(RR),1);
    ZS_L_dB = nan(numel(RR),1);  ZS_H_dB = nan(numel(RR),1);
    calSG = nan(numel(RR),1);    calGD = nan(numel(RR),1);

    for ii = 1:numel(RR)
        r = RR{ii};

        ratioVD_L(ii) = r.ratio_VS_over_VD_L_atPSS;
        ratioVD_H(ii) = r.ratio_VS_over_VD_H_atPSS;
        ratioVG_L(ii) = r.ratio_VS_over_VG_L_atPSS;
        ratioVG_H(ii) = r.ratio_VS_over_VG_H_atPSS;

        % V30_Rp_VD_IDS:
        %   Use V_D/I_DS under the total quadrature current excitation.
        %   r.ZD_L/H = ZD_self + qL/H * ZD_cross, so the orthogonal
        %   IDS_Q = q*IDS_I contribution has already been included.
        RpDS_L(ii) = abs(real(r.ZD_L_atPSS));
        RpDS_H(ii) = abs(real(r.ZD_H_atPSS));

        zL = interp1(r.freq, r.ZS_L, r.fPSS_Hz, 'pchip', 'extrap');
        zH = interp1(r.freq, r.ZS_H, r.fPSS_Hz, 'pchip', 'extrap');
        ZS_L_dB(ii) = 20*log10(abs(zL));
        ZS_H_dB(ii) = 20*log10(abs(zH));

        if modeSel(ii) == "H"
            calSG(ii) = r.Phi_SG_H_atPSS;
            calGD(ii) = r.Phi_GD_H_atPSS;
        else
            calSG(ii) = r.Phi_SG_L_atPSS;
            calGD(ii) = r.Phi_GD_L_atPSS;
        end
    end

    % Sort everything by Cs.
    [Cs, ord] = sort(Cs);
    modeSel = modeSel(ord);
    fPSS = fPSS(ord); fM = fM(ord); fP = fP(ord); phiG = phiG(ord);
    pssVG = pssVG(ord); pssVD = pssVD(ord);
    pssSG = pssSG(ord); pssGD = pssGD(ord);
    Qm = Qm(ord); Qp = Qp(ord);
    ratioVD_L = ratioVD_L(ord); ratioVD_H = ratioVD_H(ord);
    ratioVG_L = ratioVG_L(ord); ratioVG_H = ratioVG_H(ord);
    RpDS_L = RpDS_L(ord); RpDS_H = RpDS_H(ord);
    ZS_L_dB = ZS_L_dB(ord); ZS_H_dB = ZS_H_dB(ord);
    calSG = calSG(ord); calGD = calGD(ord);

    isL = modeSel == "L";
    isH = modeSel == "H";
    xBoundary = 500;
    clrUn = [0.64 0.64 0.64];
    clrPhi = [0.0000 0.6900 0.7400];
    colorSimSG = [0.0000 0.6900 0.7400];
    colorSimGD = [0.0000 0.2700 0.5200];
    colorCalL  = [0.8500 0 0];
    colorCalH  = [0 0 0];
    colorLbg   = [244 249 255]/255;
    colorHbg   = [1.0000 250/255 238/255];

    fig = figure(5); clf(fig); set(fig,'Color','w','Position',[40 40 1680 920]);
    tl = tiledlayout(fig, 2, 3, 'TileSpacing','compact', 'Padding','compact');

    %% (c) source-fraction ratios
    ax = nexttile(tl,3); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    xline(ax, xBoundary, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.0, 'HandleVisibility','off');

    hUnA = plot(ax, Cs, ratioVD_L, '-o', 'Color',clrUn, 'LineWidth',1.4, 'MarkerSize',5.8, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'DisplayName','Zclean unselected');
    hUnA2 = plot(ax, Cs, ratioVD_H, '-o', 'Color',clrUn, 'LineWidth',1.4, 'MarkerSize',5.8, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hUnA3 = plot(ax, Cs, ratioVG_L, '--s', 'Color',clrUn, 'LineWidth',1.4, 'MarkerSize',5.5, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hUnA4 = plot(ax, Cs, ratioVG_H, '--s', 'Color',clrUn, 'LineWidth',1.4, 'MarkerSize',5.5, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');

    hPssL = plot(ax, Cs(isL), pssVD(isL), '-', 'Color',clrMinus, 'LineWidth',lwMain+0.7, 'DisplayName','|V_S|/|V_D| (Sim.)');
    hPssH = plot(ax, Cs(isH), pssVD(isH), '-', 'Color',clrPlus,  'LineWidth',lwMain+0.7, 'HandleVisibility','off');
    hPssL2 = plot(ax, Cs(isL), pssVG(isL), '--', 'Color',clrMinus, 'LineWidth',lwMain+0.7, 'HandleVisibility','off');
    hPssH2 = plot(ax, Cs(isH), pssVG(isH), '--', 'Color',clrPlus,  'LineWidth',lwMain+0.7, 'HandleVisibility','off');

    % V29: keep calculated source-fraction samples as discrete markers only,
    % with no connecting lines, so Sim. curves and Calc. points are separated.
    hCalL = plot(ax, Cs(isL), ratioVD_L(isL), 'o', 'LineStyle','none', ...
        'Color',clrMinus, 'LineWidth',1.1, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', 'DisplayName','|V_S|/|V_D| (Calc.)');
    hCalH = plot(ax, Cs(isH), ratioVD_H(isH), 'o', 'LineStyle','none', ...
        'Color',clrPlus, 'LineWidth',1.1, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', 'HandleVisibility','off');
    hCalL2 = plot(ax, Cs(isL), ratioVG_L(isL), 's', 'LineStyle','none', ...
        'Color',clrMinus, 'LineWidth',1.1, ...
        'MarkerSize',6.0, 'MarkerFaceColor','w', 'HandleVisibility','off');
    hCalH2 = plot(ax, Cs(isH), ratioVG_H(isH), 's', 'LineStyle','none', ...
        'Color',clrPlus, 'LineWidth',1.1, ...
        'MarkerSize',6.0, 'MarkerFaceColor','w', 'HandleVisibility','off');

    % xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'|V_S|/|V_D| or |V_S|/|V_G|','Interpreter','tex');
    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'Normalized voltage','Interpreter','tex');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750);
    yAll = [ratioVD_L; ratioVD_H; ratioVG_L; ratioVG_H; pssVD; pssVG]; ylim(ax,[0 max(yAll(isfinite(yAll)))*1.12]);
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    place_handles_above_background_v23(ax, [hUnA hUnA2 hUnA3 hUnA4]);
    bring_handles_to_front_v21(ax, [hPssL hPssH hPssL2 hPssH2 hCalL hCalH hCalL2 hCalH2]);
    % Restored legend for panel (c).
    legend(ax, [hPssL hPssL2 hCalL hCalL2 hUnA], ...
        {'|V_S|/|V_D| (Sim.)', '|V_S|/|V_G| (Sim.)', ...
         '|V_S|/|V_D| (Calc.)', '|V_S|/|V_G| (Calc.)', ...
         'Unselected branch'}, ...
        'Location','northwest', 'Interpreter','tex', 'Box','on');

    add_panel_label_v18(ax,'(c)',fontName,fsLabel);

    %% (a) phase-target frequency + phi jump
    ax = nexttile(tl,1); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    idxLastL = find(isL, 1, 'last');
    idxFirstH = find(isH, 1, 'first');
    xMinB = min(Cs)-25;
    xMaxB = max(Cs)+25;
    yAllB = [fPSS; fM; fP];
    yAllB = yAllB(isfinite(yAllB));
    if isempty(yAllB)
        yMinB = 9.0;
        yMaxB = 10.6;
    else
        ySpanB = max(yAllB)-min(yAllB);
        if ySpanB == 0, ySpanB = 0.05; end
        yMinB = floor((min(yAllB)-0.10*ySpanB)*10)/10;
        yMaxB = ceil((max(yAllB)+0.10*ySpanB)*10)/10;
    end
    yyaxis(ax,'left');
    hPSS = plot(ax, Cs, fPSS, 'k--', 'LineWidth',1.4, 'DisplayName','PSS f');
    hUnB = plot(ax, Cs(isL), fP(isL), '-o', 'Color',clrUn, 'LineWidth',1.6, 'MarkerSize',5.8, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'DisplayName','unselected');
    hUnB2 = plot(ax, Cs(isH), fM(isH), '-o', 'Color',clrUn, 'LineWidth',1.6, 'MarkerSize',5.8, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hConnP = plot(ax, [Cs(idxLastL) Cs(idxFirstH)], [fP(idxLastL) fP(idxFirstH)], '-', ...
        'Color',clrUn, 'LineWidth',1.6, 'HandleVisibility','off');
    hConnM = plot(ax, [Cs(idxLastL) Cs(idxFirstH)], [fM(idxLastL) fM(idxFirstH)], '-', ...
        'Color',clrUn, 'LineWidth',1.6, 'HandleVisibility','off');
    hL = plot(ax, Cs(isL), fM(isL), '-o', 'Color',clrMinus, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', 'DisplayName','Kminus \omega_L');
    hH = plot(ax, Cs(isH), fP(isH), '-o', 'Color',clrPlus, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',6.5, 'MarkerFaceColor','w', 'DisplayName','Kplus \omega_H');
    xline(ax, xBoundary, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.0, 'HandleVisibility','off');
    ylabel(ax,sprintf('Frequency (GHz)', phaseTargetDeg),'Interpreter','tex');
    yAll = [fPSS; fM; fP]; yAll = yAll(isfinite(yAll));
    if ~isempty(yAll)
        ylim(ax,[yMinB yMaxB]);
    end

    yyaxis(ax,'right');
    hPhi = plot(ax, Cs, phiG, '-s', 'Color',clrPhi, 'LineWidth',1.8, 'MarkerSize',5.5, ...
        'MarkerFaceColor','w', 'DisplayName','\phi_{G,QP}-\phi_{G,IP}');
    ylim(ax,[-120 180]); yticks(ax,[-90 0 90]);
    ylabel(ax,'\phi_{G,QP}-\phi_{G,IP} (^\circ)','Interpreter','tex');
    ax.YAxis(2).Color = clrPhi;

    yyaxis(ax,'left');
    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750);
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    place_handles_above_background_v23(ax, [hUnB hUnB2 hConnP hConnM]);
    % Restored legend for panel (a).
    legend(ax, [hL hH hUnB hPSS hPhi], ...
        {'Selected \omega_L', 'Selected \omega_H', ...
         'Unselected branch', 'PSS', ...
         '\phi_{G,QP}-\phi_{G,IP}'}, ...
        'Location','best', 'Interpreter','tex', 'Box','on');

    add_panel_label_v18(ax,'(a)',fontName,fsLabel);

    %% (f) Rp from ZDS
    ax = nexttile(tl,6); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    xline(ax, xBoundary, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.0, 'HandleVisibility','off');
    hUnC = plot(ax, Cs, RpDS_L, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'DisplayName','unselected');
    hUnC2 = plot(ax, Cs, RpDS_H, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hLC = plot(ax, Cs(isL), RpDS_L(isL), '-o', 'Color',clrMinus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected \omega_L');
    hHC = plot(ax, Cs(isH), RpDS_H(isH), '-o', 'Color',clrPlus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected \omega_H');
    yline(ax,0,'k:','HandleVisibility','off');
    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'R_p(\Omega)','Interpreter','tex');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750);
    yAll = [RpDS_L; RpDS_H]; yAll = yAll(isfinite(yAll));
    if ~isempty(yAll), ySpan = max(yAll)-min(yAll); if ySpan==0, ySpan=1; end; ylim(ax,[floor(min(yAll)-0.1*ySpan) ceil(max(yAll)+0.1*ySpan)]); end
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    place_handles_above_background_v23(ax, [hUnC hUnC2]);
    % Restored legend for panel (f).
    legend(ax, [hLC hHC hUnC], ...
        {'Selected \omega_L', 'Selected \omega_H', 'Unselected branch'}, ...
        'Location','best', 'Interpreter','tex', 'Box','on');

    add_panel_label_v18(ax,'(f)',fontName,fsLabel);

    %% (e) Q
    ax = nexttile(tl,5); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    xline(ax, xBoundary, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.0, 'HandleVisibility','off');
    hUnD = plot(ax, Cs, Qm, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'DisplayName','unselected');
    hUnD2 = plot(ax, Cs, Qp, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hLD = plot(ax, Cs(isL), Qm(isL), '-o', 'Color',clrMinus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected Kminus (\omega_L)');
    hHD = plot(ax, Cs(isH), Qp(isH), '-o', 'Color',clrPlus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected Kplus (\omega_H)');
    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'Open-loop \itQ\rm','Interpreter','tex');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750);
    yAll = [Qm; Qp]; yAll = yAll(isfinite(yAll));
    if ~isempty(yAll), ySpan = max(yAll)-min(yAll); if ySpan==0, ySpan=1; end; ylim(ax,[floor((min(yAll)-0.1*ySpan)*10)/10 ceil((max(yAll)+0.1*ySpan)*10)/10]); end
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    place_handles_above_background_v23(ax, [hUnD hUnD2]);
    % Restored legend for panel (e).
    legend(ax, [hLD hHD hUnD], ...
        {'Selected \omega_L', 'Selected \omega_H', 'Unselected branch'}, ...
        'Location','best', 'Interpreter','tex', 'Box','on');

    add_panel_label_v18(ax,'(e)',fontName,fsLabel);

    %% (d) |ZS|
    ax = nexttile(tl,4); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    xline(ax, xBoundary, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.0, 'HandleVisibility','off');
    hUnE = plot(ax, Cs, ZS_L_dB, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'DisplayName','unselected');
    hUnE2 = plot(ax, Cs, ZS_H_dB, '-o', 'Color',clrUn, 'LineWidth',1.7, 'MarkerSize',6, ...
        'MarkerFaceColor','w', 'MarkerEdgeColor',clrUn, 'HandleVisibility','off');
    hLE = plot(ax, Cs(isL), ZS_L_dB(isL), '-o', 'Color',clrMinus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected \omega_L');
    hHE = plot(ax, Cs(isH), ZS_H_dB(isH), '-o', 'Color',clrPlus, 'LineWidth',lwMain+0.6, ...
        'MarkerSize',6.8, 'MarkerFaceColor','w', 'DisplayName','selected \omega_H');
    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'|Z_S| at f_{PSS} (dB\Omega)','Interpreter','tex');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750);
    yAll = [ZS_L_dB; ZS_H_dB]; yAll = yAll(isfinite(yAll));
    if ~isempty(yAll), ySpan = max(yAll)-min(yAll); if ySpan==0, ySpan=1; end; ylim(ax,[floor(min(yAll)-0.1*ySpan) ceil(max(yAll)+0.1*ySpan)]); end
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    place_handles_above_background_v23(ax, [hUnE hUnE2]);
    % Restored legend for panel (d).
    legend(ax, [hLE hHE hUnE], ...
        {'Selected \omega_L', 'Selected \omega_H', 'Unselected branch'}, ...
        'Location','best', 'Interpreter','tex', 'Box','on');

    add_panel_label_v18(ax,'(d)',fontName,fsLabel);

    %% (b) phase summary
    ax = nexttile(tl,2); hold(ax,'on'); box(ax,'on'); grid(ax,'on'); setup_summary_axis(ax, fontName, fsAxis);
    yAll = [pssSG; pssGD; calSG; calGD]; yAll = yAll(isfinite(yAll));
    yMin = floor((min(yAll)-3)/5)*5; yMax = ceil((max(yAll)+3)/5)*5;
    if yMin > -30, yMin = -30; end
    if yMax < 10, yMax = 10; end
    xline(ax, xBoundary, 'k-.', 'LineWidth',1.0, 'HandleVisibility','off');
    yline(ax, 0, 'k:', 'LineWidth',1.0, 'HandleVisibility','off');

    hSgSim = plot(ax, Cs, pssSG, '-s', 'Color',colorSimSG, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',5.8, 'MarkerFaceColor','none', 'DisplayName','\phi_{SG} PSS');
    hGdSim = plot(ax, Cs, pssGD, '-o', 'Color',colorSimGD, 'LineWidth',lwMain+0.4, ...
        'MarkerSize',5.8, 'MarkerFaceColor','none', 'DisplayName','\phi_{GD} PSS');

    hSgCalH = plot(ax, Cs(isH), calSG(isH), '-p', 'Color',colorCalH, 'LineWidth',1.2, ...
        'MarkerSize',7.0, 'MarkerFaceColor',colorCalH, 'MarkerEdgeColor',colorCalH, ...
        'HandleVisibility','off');
    hGdCalH = plot(ax, Cs(isH), calGD(isH), '-x', 'Color',colorCalH, 'LineWidth',lwMain+0.2, ...
        'MarkerSize',6.8, 'HandleVisibility','off');
    hSgCalL = plot(ax, Cs(isL), calSG(isL), '-p', 'Color',colorCalL, 'LineWidth',1.2, ...
        'MarkerSize',7.0, 'MarkerFaceColor',colorCalL, 'MarkerEdgeColor',colorCalL, ...
        'DisplayName','\phi_{SG} Cal.');
    hGdCalL = plot(ax, Cs(isL), calGD(isL), '-x', 'Color',colorCalL, 'LineWidth',lwMain+0.2, ...
        'MarkerSize',6.8, 'DisplayName','\phi_{GD} Cal.');

    xlabel(ax,'\itC\rm_S (fF)','Interpreter','tex'); ylabel(ax,'Phase shift (^\circ)');
    % V37: Figure 2 per-panel title removed.
    xlim(ax,[min(Cs)-25 max(Cs)+25]); xticks(ax,150:100:750); ylim(ax,[yMin yMax]);
    add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg);
    bring_handles_to_front_v21(ax, [hSgCalL hGdCalL hSgCalH hGdCalH]);
    % Restored legend for panel (b).
    legend(ax, [hSgSim hGdSim hSgCalL hGdCalL], ...
        {'\phi_{SG} (PSS Sim.)', '\phi_{GD} (PSS Sim.)', ...
         '\phi_{SG} (Calc.)', '\phi_{GD} (Calc.)'}, ...
        'Location','best', 'Interpreter','tex', 'Box','on');

    set(ax, 'Layer','top', 'Box','on', 'XColor','k', 'YColor','k', 'LineWidth',1.0);
    add_panel_label_v18(ax,'(b)',fontName,fsLabel);

    % V37: Figure 2 top-level sgtitle removed.

    % V37: remove large mode-text annotations such as \omega_L mode / \omega_H mode,
    % without touching axis labels, legends, or (a)-(f) panel labels.
    remove_figure2_mode_text_v37(fig);

    if saveFig
        export_pdf_and_svg_from_pdf_v25(fig, outDir, 'KGS_Cs');
    end
end

function remove_figure2_mode_text_v37(fig)
    % V38 fix:
    %   V37 removed any text containing "\omega", which also accidentally
    %   removed panel (e)'s ylabel "Q_{\phi} from d\angleK/d\omega".
    %   Here we only remove free annotation text, and explicitly keep
    %   axis labels, titles, legends, and (a)-(f) panel labels.
    axList = findall(fig, 'Type', 'axes');
    for ia = 1:numel(axList)
        ax = axList(ia);
        txtList = findall(ax, 'Type', 'text');

        keepList = gobjects(0);
        if isprop(ax,'XLabel') && isvalid(ax.XLabel); keepList(end+1) = ax.XLabel; end %#ok<AGROW>
        if isprop(ax,'YLabel') && isvalid(ax.YLabel); keepList(end+1) = ax.YLabel; end %#ok<AGROW>
        if isprop(ax,'ZLabel') && isvalid(ax.ZLabel); keepList(end+1) = ax.ZLabel; end %#ok<AGROW>
        if isprop(ax,'Title')  && isvalid(ax.Title);  keepList(end+1) = ax.Title;  end %#ok<AGROW>

        for it = 1:numel(txtList)
            if any(txtList(it) == keepList)
                continue;
            end

            s = txtList(it).String;
            if iscell(s)
                sJoin = strjoin(string(s), ' ');
            else
                sJoin = string(s);
            end
            sTrim = strtrim(sJoin);

            % Keep subfigure labels.
            if any(strcmp(sTrim, ["(a)","(b)","(c)","(d)","(e)","(f)"]))
                continue;
            end

            % Delete only free mode annotations, not axis labels.
            if contains(sJoin, "\omega") || contains(sJoin, "omega") || ...
                    contains(sJoin, "ω") || contains(lower(sJoin), "mode")
                delete(txtList(it));
            end
        end
    end
end

function setup_summary_axis(ax, fontName, fsAxis)
    set(ax, 'FontName',fontName, 'FontSize',fsAxis, ...
        'LineWidth',1.0, 'Layer','top', 'Box','on', 'XColor','k');
    ax.GridAlpha = 0.18;
end

function export_pdf_and_svg_from_pdf_v25(fig, outDir, baseName)
    pdfPath = fullfile(outDir, [baseName '.pdf']);
    svgPath = fullfile(outDir, [baseName '.svg']);

    exportgraphics(fig, pdfPath, 'ContentType','vector');

    converter = 'C:\texlive\2026\bin\windows\pdftocairo.exe';
    if ~isfile(converter)
        converter = 'pdftocairo';
    end

    cmd = sprintf('"%s" -svg "%s" "%s"', converter, pdfPath, svgPath);
    [status, msg] = system(cmd);
    if status ~= 0
        error('PDF-to-SVG conversion failed for %s: %s', baseName, msg);
    end
end

function add_mode_background_v20(ax, xBoundary, colorLbg, colorHbg)
    xLim0 = xlim(ax);
    yLim0 = ylim(ax);
    yColors = get_axis_ycolors_v20(ax);

    wasHold = ishold(ax);
    hold(ax,'on');
    hL = patch(ax, [xLim0(1) xBoundary xBoundary xLim0(1)], ...
        [yLim0(1) yLim0(1) yLim0(2) yLim0(2)], colorLbg, ...
        'EdgeColor','none', 'FaceAlpha',0.78, 'HandleVisibility','off');
    hH = patch(ax, [xBoundary xLim0(2) xLim0(2) xBoundary], ...
        [yLim0(1) yLim0(1) yLim0(2) yLim0(2)], colorHbg, ...
        'EdgeColor','none', 'FaceAlpha',0.86, 'HandleVisibility','off');
    kids = ax.Children;
    isBg = (kids == hL) | (kids == hH);
    ax.Children = [kids(~isBg); hH; hL];
    xlim(ax, xLim0);
    ylim(ax, yLim0);
    set(ax, 'Layer','top', 'Box','on', 'XColor','k', 'LineWidth',1.0);
    set_axis_ycolors_v20(ax, yColors);
    if ~wasHold
        hold(ax,'off');
    end
end

function yColors = get_axis_ycolors_v20(ax)
    yColors = cell(1, numel(ax.YAxis));
    for ii = 1:numel(ax.YAxis)
        yColors{ii} = ax.YAxis(ii).Color;
    end
end

function set_axis_ycolors_v20(ax, yColors)
    for ii = 1:min(numel(ax.YAxis), numel(yColors))
        ax.YAxis(ii).Color = yColors{ii};
    end
end

function place_handles_above_background_v23(ax, hList)
    % Robust ordering helper. Force all graphics-handle lists to columns
    % to avoid dimension mismatches across MATLAB releases.

    hList = hList(:);
    hList = hList(isgraphics(hList));
    if isempty(hList)
        return;
    end

    kids = ax.Children;
    kids = kids(:);

    % Only keep handles that are direct children of this axes.
    keep = false(size(hList));
    for ii = 1:numel(hList)
        try
            keep(ii) = isequal(hList(ii).Parent, ax);
        catch
            keep(ii) = false;
        end
    end
    hList = hList(keep);

    moveMask = false(size(kids));
    bgMask = false(size(kids));

    for ii = 1:numel(kids)
        moveMask(ii) = any(kids(ii) == hList);
        try
            bgMask(ii) = strcmp(kids(ii).Type, 'patch') && ...
                strcmp(kids(ii).HandleVisibility, 'off');
        catch
            bgMask(ii) = false;
        end
    end

    ax.Children = [kids(~moveMask & ~bgMask); hList(:); kids(bgMask)];
end

function bring_handles_to_front_v21(ax, hList)
    % Robustly move selected graphics objects to the front.
    % Some MATLAB releases return ax.Children as a row vector while hList
    % is a column vector, which can cause a dimension-mismatch error when
    % concatenating them.  Force both to column vectors and only keep
    % objects that are direct children of this axes.

    if isempty(hList)
        return;
    end

    hList = hList(:);
    hList = hList(isgraphics(hList));
    if isempty(hList)
        return;
    end

    kids = ax.Children;
    kids = kids(:);

    % Keep only handles that actually belong to this axes.
    keep = false(size(hList));
    for ii = 1:numel(hList)
        try
            keep(ii) = isequal(hList(ii).Parent, ax);
        catch
            keep(ii) = false;
        end
    end
    hList = hList(keep);

    if isempty(hList)
        return;
    end

    moveMask = false(size(kids));
    for ii = 1:numel(hList)
        moveMask = moveMask | (kids == hList(ii));
    end

    % Avoid duplicate handles and preserve requested front-to-back order.
    hList = hList(:);
    remaining = kids(~moveMask);
    remaining = remaining(:);

    ax.Children = [hList; remaining];
end

function add_panel_label_v18(ax, labelStr, fontName, fsLabel)
    % V41 panel-label position for Figure 2:
    %   labelX = 0.00 aligns (a)-(f) with the left start of the x-axis.
    %       Increase it to move labels right; decrease slightly to move left.
    %   labelY = -0.10 controls vertical position.
    %       Increase it, e.g. -0.08, to move up; decrease to move down.
    labelX = 0.00;
    labelY = -0.10;

    text(ax, labelX, labelY, labelStr, ...
        'Units','normalized', ...
        'FontName',fontName, ...
        'FontSize',fsLabel+2, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','top', ...
        'Interpreter','none', ...
        'BackgroundColor','w', ...
        'Margin',1.0, ...
        'Clipping','off');
end

function R = calc_one_case(fileName, PEI, PEQ, Lobs, Rinj, correctionMode)
    Sobj = sparameters(char(fileName));

    freq = Sobj.Frequencies;
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;

    if numel(z0) ~= 1
        error('This script assumes scalar reference impedance z0.');
    end
    if size(S,1) ~= 9
        error('Imported file is not 9-port. Current Nport = %d.', size(S,1));
    end

    Nf = numel(freq);
    I9 = eye(9);

    KII = nan(Nf,1);
    KIQ = nan(Nf,1);
    KQI = nan(Nf,1);
    KQQ = nan(Nf,1);

    for n = 1:Nf
        Sn = S(:,:,n);
        Y9 = (1/z0) * (I9 - Sn) / (I9 + Sn);

        Ytotal6 = Y9(1:6,1:6);
        Ymos3 = Y9(7:9,7:9);

        switch correctionMode
            case 'noRemove'
                Yremove6 = zeros(6,6);
            case 'removeReal'
                Yremove6 = PEI.' * real(Ymos3) * PEI + PEQ.' * real(Ymos3) * PEQ;
            case 'removeFull'
                Yremove6 = PEI.' * Ymos3 * PEI + PEQ.' * Ymos3 * PEQ;
            otherwise
                error('Unknown correctionMode: %s', correctionMode);
        end

        Yclean6 = Ytotal6 - Yremove6;
        Zclean6 = inv(Yclean6);

        K = Lobs * Zclean6 * Rinj;

        KII(n) = K(1,1);
        KIQ(n) = K(1,2);
        KQI(n) = K(2,1);
        KQQ(n) = K(2,2);
    end

    R.freq = freq;
    R.KII = KII;
    R.KIQ = KIQ;
    R.KQI = KQI;
    R.KQQ = KQQ;
    R.Kplus  = KII + 1j*KIQ;
    R.Kminus = KII - 1j*KIQ;
end

function val = complex_interp(freq, x, f0)
    val = interp1(freq(:), x(:), f0, 'pchip', 'extrap');
end

function ph = unwrap_phase_for_display(x, plotMask, phaseConvention)
    ph = unwrap(angle(x(:))) * 180/pi;

    if nargin < 2 || isempty(plotMask)
        plotMask = true(size(ph));
    end

    phPlot = ph(plotMask);
    phPlot = phPlot(isfinite(phPlot));
    if isempty(phPlot)
        return;
    end

    switch phaseConvention
        case 'rawK'
            % Shift so the displayed range is visually near -180 deg.
            medPh = median(phPlot);
            ph = ph - 360 * round((medPh + 180) / 360);

            phPlot = ph(plotMask);
            phPlot = phPlot(isfinite(phPlot));
            if ~isempty(phPlot)
                if max(phPlot) > 30
                    ph = ph - 360;
                end
                phPlot = ph(plotMask);
                phPlot = phPlot(isfinite(phPlot));
                if ~isempty(phPlot) && min(phPlot) < -390
                    ph = ph + 360;
                end
            end

        case 'loopMinusK'
            % Shift so the displayed range is visually near 0 deg.
            medPh = median(phPlot);
            ph = ph - 360 * round(medPh / 360);
    end
end

function fTarget_GHz = phase_target_frequency(freq_Hz, phaseDeg, targetDeg, fmin_Hz, fmax_Hz, fRef_Hz)
    freq_Hz = freq_Hz(:);
    phaseDeg = phaseDeg(:);
    fTarget_GHz = NaN;

    mask = isfinite(freq_Hz) & isfinite(phaseDeg) & ...
        (freq_Hz >= fmin_Hz) & (freq_Hz <= fmax_Hz);
    if ~any(mask)
        return;
    end

    f = freq_Hz(mask);
    ph = phaseDeg(mask);
    d = ph - targetDeg;

    idxCross = find(d(1:end-1).*d(2:end) <= 0);
    fCross = [];
    for ii = idxCross(:).'
        if d(ii) == d(ii+1)
            fTmp = f(ii);
        else
            fTmp = f(ii) + (targetDeg - ph(ii)) * (f(ii+1)-f(ii)) / (ph(ii+1)-ph(ii));
        end
        fCross = [fCross; fTmp]; %#ok<AGROW>
    end

    if ~isempty(fCross)
        [~, k] = min(abs(fCross - fRef_Hz));
        fTarget_GHz = fCross(k)/1e9;
    else
        [~, k] = min(abs(d));
        fTarget_GHz = f(k)/1e9;
    end
end

function [Qphi, slopeDegPerGHz] = phase_slope_Q_at_freq(freq_Hz, phaseDeg, f0_Hz, halfBW_Hz)
    % Extract phase-slope effective Q using local linear fitting.
    % phaseDeg must be unwrapped.
    % Qphi = (f0/2)*abs(dphi_rad/df), where f and f0 use the same units.

    freq_Hz = freq_Hz(:);
    phaseDeg = phaseDeg(:);
    Qphi = NaN;
    slopeDegPerGHz = NaN;

    if isempty(freq_Hz) || isempty(phaseDeg) || isnan(f0_Hz)
        return;
    end

    fGHz = freq_Hz/1e9;
    f0_GHz = f0_Hz/1e9;

    mask = isfinite(fGHz) & isfinite(phaseDeg) & abs(freq_Hz - f0_Hz) <= halfBW_Hz;

    % If the requested window is too narrow for the file resolution, use
    % the nearest 7 points as a fallback.
    if nnz(mask) < 5
        [~, ord] = sort(abs(freq_Hz - f0_Hz), 'ascend');
        keepN = min(7, numel(ord));
        mask = false(size(freq_Hz));
        mask(ord(1:keepN)) = true;
        mask = mask & isfinite(fGHz) & isfinite(phaseDeg);
    end

    if nnz(mask) < 2
        return;
    end

    pfit = polyfit(fGHz(mask), phaseDeg(mask), 1);
    slopeDegPerGHz = pfit(1);
    Qphi = (f0_GHz/2) * (pi/180) * abs(slopeDegPerGHz);
end

function res = calc_source_impedance_one_file(s9p_file, fPSS_Hz, fmin_plot, fmax_plot, qL, qH)
    res = struct();
    res.valid = false;
    res.file = s9p_file;
    res.qL = qL;
    res.qH = qH;

    Sobj = sparameters(s9p_file);
    freq = Sobj.Frequencies;
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;
    if numel(z0) ~= 1
        error('This script assumes scalar z0.');
    end
    Nf = numel(freq);
    if size(S,1) ~= 9
        error('%s is not a 9-port file.', s9p_file);
    end

    % Convert S to Y
    I9 = eye(9);
    Y9 = zeros(9,9,Nf);
    for n = 1:Nf
        Sn = S(:,:,n);
        Y9(:,:,n) = (1/z0) * (I9 - Sn) / (I9 + Sn);
    end

    % Corrected physical mapping matrices from external 6-port voltages
    % to physical MOS D/G/S voltages.
    %
    % External voltage vector is [DI GI SI DQ GQ SQ]^T.
    % I-core physical MOS vector:
    %   [D_I; G_I; S_I] = [ +DI; -GI; +SQ ]
    %   This corresponds to I+ MOS (DIP, GIN, SQP)
    %   and I- MOS (DIN, GIP, SQN).
    %
    % Q-core physical MOS vector:
    %   [D_Q; G_Q; S_Q] = [ +DQ; -GQ; -SI ]
    %   This corresponds to Q+ MOS (DQP, GQN, SIN)
    %   and Q- MOS (DQN, GQP, SIP).
    %
    % These PE matrices embed the MOS-only 3-port real conductance into
    % the corrected external 6-port D/G/S connection when forming Yremove6.
    PEI = zeros(3,6);
    PEQ = zeros(3,6);
    PEI(1,1) = +1;  PEI(2,2) = -1;  PEI(3,6) = +1;
    PEQ(1,4) = +1;  PEQ(2,5) = -1;  PEQ(3,3) = -1;

    % IDS injection basis into external 6-port.
    % rI is I-core IDS: current enters DI and leaves I-core source +SQ.
    % rQ is Q-core IDS: current enters DQ and leaves Q-core source S_Q=-SI.
    % Leaving -SI is equivalent to entering +SI in the external basis.
    rI = zeros(6,1);  rI(1) = +1;  rI(6) = -1;  % IDS_I: DI -> SQ
    rQ = zeros(6,1);  rQ(4) = +1;  rQ(3) = +1;  % IDS_Q: DQ -> S_Q=-SI
    Rinj = [rI rQ];

    % Observers for I-core physical D/G/S.
    % They extract V_D,I=+DI, V_G,I=-GI, and V_S,I=+SQ.
    % Later:
    %   VGS_from = VG_from - VS_from  => ZGS = ZG - ZS
    %   VDS_from = VD_from - VS_from  => ZDS = ZD - ZS
    lDI = zeros(1,6); lDI(1) = +1;
    lGI = zeros(1,6); lGI(2) = -1;
    lSI = zeros(1,6); lSI(6) = +1;   % I-core source is SQ

    ZS_I_self = zeros(Nf,1);  ZS_I_cross = zeros(Nf,1);
    ZD_I_self = zeros(Nf,1);  ZD_I_cross = zeros(Nf,1);
    ZG_I_self = zeros(Nf,1);  ZG_I_cross = zeros(Nf,1);
    ZGS_I_self = zeros(Nf,1); ZGS_I_cross = zeros(Nf,1);
    ZDS_I_self = zeros(Nf,1); ZDS_I_cross = zeros(Nf,1);

    for n = 1:Nf
        Ytotal6 = Y9(1:6,1:6,n);
        Ymos3 = Y9(7:9,7:9,n);

        % Remove MOS-only real conductance, embedded with corrected D/G/S connection
        Yremove6 = PEI.' * real(Ymos3) * PEI + PEQ.' * real(Ymos3) * PEQ;
        Yclean6 = Ytotal6 - Yremove6;
        Zclean6 = inv(Yclean6);

        H = Zclean6 * Rinj;  % columns: response to IDS_I and IDS_Q, in external 6-port voltage basis

        % I-core physical D/G/S transfer transimpedances
        VD_from = lDI * H;
        VG_from = lGI * H;
        VS_from = lSI * H;
        VGS_from = VG_from - VS_from;
        VDS_from = VD_from - VS_from;

        ZD_I_self(n)  = VD_from(1);   ZD_I_cross(n)  = VD_from(2);
        ZG_I_self(n)  = VG_from(1);   ZG_I_cross(n)  = VG_from(2);
        ZS_I_self(n)  = VS_from(1);   ZS_I_cross(n)  = VS_from(2);
        ZGS_I_self(n) = VGS_from(1);  ZGS_I_cross(n) = VGS_from(2);
        ZDS_I_self(n) = VDS_from(1);  ZDS_I_cross(n) = VDS_from(2);
    end

    % Mode combination by superposition:
    %   IDS_Q = q * IDS_I
    %   Z_X,mode = Z_X,self + q * Z_X,cross
    % where X = D, G, S, GS, or DS.
    % qL=-j corresponds to omega_L; qH=+j corresponds to omega_H.
    modeCombine = @(self,cross,q) self + q.*cross;
    qList = [qL qH];
    nameList = {'L','H'};

    for mm = 1:2
        q = qList(mm);
        nm = nameList{mm};

        res.(sprintf('ZS_%s',nm))  = modeCombine(ZS_I_self,  ZS_I_cross,  q);
        res.(sprintf('ZD_%s',nm))  = modeCombine(ZD_I_self,  ZD_I_cross,  q);
        res.(sprintf('ZG_%s',nm))  = modeCombine(ZG_I_self,  ZG_I_cross,  q);
        res.(sprintf('ZGS_%s',nm)) = modeCombine(ZGS_I_self, ZGS_I_cross, q);
        res.(sprintf('ZDS_%s',nm)) = modeCombine(ZDS_I_self, ZDS_I_cross, q);

        res.(sprintf('ratio_VS_over_VD_%s',nm)) = abs(res.(sprintf('ZS_%s',nm))) ./ max(abs(res.(sprintf('ZD_%s',nm))), eps);
        res.(sprintf('ratio_VS_over_VG_%s',nm)) = abs(res.(sprintf('ZS_%s',nm))) ./ max(abs(res.(sprintf('ZG_%s',nm))), eps);
        res.(sprintf('ratio_VS_over_VGS_%s',nm)) = abs(res.(sprintf('ZS_%s',nm))) ./ max(abs(res.(sprintf('ZGS_%s',nm))), eps);
        res.(sprintf('ratio_VS_over_VDS_%s',nm)) = abs(res.(sprintf('ZS_%s',nm))) ./ max(abs(res.(sprintf('ZDS_%s',nm))), eps);

        % Unwrapped phase
        res.(sprintf('phase_ZS_%s',nm)) = unwrap_phase_deg_local(res.(sprintf('ZS_%s',nm)));
        res.(sprintf('phase_VGS_minus_VDS_%s',nm)) = unwrap_phase_deg_local(res.(sprintf('ZGS_%s',nm)) ./ res.(sprintf('ZDS_%s',nm)));
        % Phase error relative to 180 deg, same meaning as Cadence: phaseDeg(-VGS/VDS).
        res.(sprintf('phaseErr_VGS_VDS_%s',nm)) = wrap180_local(res.(sprintf('phase_VGS_minus_VDS_%s',nm)) - 180);

        % v26 paper/JSSC2023 same-frame drain-referenced phase shifts.
        % These are NOT MOS-physical phases.  The source terminal is first
        % rotated into the drain/gate reference frame by q, and the gate
        % polarity follows the paper convention VG_paper = -VG_MOS:
        %   Phi_GD = angle(-ZG/ZD)
        %   Phi_SD = angle(-q*ZS/ZD)
        %   Phi_SG = angle(-q*ZS/(-ZG))
        % The extra minus sign on the source branch aligns the Zclean source observer with the ADE/PSS paper-frame source reference.
        % This keeps Phi_SG = Phi_SD - Phi_GD under the same convention.
        res.(sprintf('Phi_GD_%s',nm)) = wrap180_local(angle((-res.(sprintf('ZG_%s',nm))) ./ res.(sprintf('ZD_%s',nm))) * 180/pi);
        res.(sprintf('Phi_SD_%s',nm)) = wrap180_local(angle((-q .* res.(sprintf('ZS_%s',nm))) ./ res.(sprintf('ZD_%s',nm))) * 180/pi);
        res.(sprintf('Phi_SG_%s',nm)) = wrap180_local(angle((-q .* res.(sprintf('ZS_%s',nm))) ./ (-res.(sprintf('ZG_%s',nm)))) * 180/pi);

        % v23 effective Rp extraction.
        % Rp_D  = Re{Z_D(q)}: real drain-node transimpedance, useful if the
        %         output/drain swing V_D is the reference quantity.
        % Rp_DS = Re{Z_D(q)-Z_S(q)}: real impedance seen by the physical MOS
        %         drain-source current. This is the recommended Rp-like metric
        %         for power balance because the current source delivers power
        %         into V_DS, not only into V_D.
        % Rp_GS = Re{Z_G(q)-Z_S(q)}: real feedback transimpedance. It is not
        %         a tank Rp, but is useful for loop-gain comparison.
        res.(sprintf('RpD_%s',nm))  = real(res.(sprintf('ZD_%s',nm)));
        res.(sprintf('RpDS_%s',nm)) = real(res.(sprintf('ZDS_%s',nm)));
        res.(sprintf('RpGS_%s',nm)) = real(res.(sprintf('ZGS_%s',nm)));
        res.(sprintf('XpD_%s',nm))  = imag(res.(sprintf('ZD_%s',nm)));
        res.(sprintf('XpDS_%s',nm)) = imag(res.(sprintf('ZDS_%s',nm)));
        res.(sprintf('XpGS_%s',nm)) = imag(res.(sprintf('ZGS_%s',nm)));

        % Cross/self and cross/total ratios
        res.(sprintf('eta_VS_cross_self_%s',nm)) = abs(q.*ZS_I_cross) ./ max(abs(ZS_I_self), eps);
        res.(sprintf('eta_VS_cross_total_%s',nm)) = abs(q.*ZS_I_cross) ./ max(abs(res.(sprintf('ZS_%s',nm))), eps);
    end

    % Store raw self/cross terms
    res.freq = freq(:);
    res.fGHz = freq(:)/1e9;
    res.fmin_plot = fmin_plot;
    res.fmax_plot = fmax_plot;
    res.plotMask = (freq(:) >= fmin_plot) & (freq(:) <= fmax_plot);
    res.fPSS_Hz = fPSS_Hz;
    res.fPSS_GHz = fPSS_Hz/1e9;
    res.ZS_I_self = ZS_I_self;
    res.ZS_I_cross = ZS_I_cross;
    res.ZD_I_self = ZD_I_self;
    res.ZD_I_cross = ZD_I_cross;
    res.ZG_I_self = ZG_I_self;
    res.ZG_I_cross = ZG_I_cross;

    % v13 phasor-composition diagnostics for
    % ZS_H = ZS_self + j*ZS_cross and ZS_L = ZS_self - j*ZS_cross.
    % delta = angle(ZS_self) - angle(ZS_cross).
    % |ZS_H|^2 - |ZS_L|^2 = 4*|ZS_self|*|ZS_cross|*sin(delta).
    res.delta_ZS_self_cross_deg = unwrap_phase_deg_local(ZS_I_self ./ ZS_I_cross);
    res.sin_delta_ZS_self_cross = sin(res.delta_ZS_self_cross_deg*pi/180);
    res.mode_diff_predictor = 4*abs(ZS_I_self).*abs(ZS_I_cross).*res.sin_delta_ZS_self_cross;

    res.valid = true;

    token = regexp(s9p_file, '(\d+)f', 'tokens', 'once');
    if isempty(token)
        res.Cs_fF = NaN;
    else
        res.Cs_fF = str2double(token{1});
    end

    % Interpolate at PSS if known
    if ~isnan(fPSS_Hz)
        fields = {'ZS_L','ZS_H','ZD_L','ZD_H','ZG_L','ZG_H','ZGS_L','ZGS_H','ZDS_L','ZDS_H', ...
                  'ratio_VS_over_VD_L','ratio_VS_over_VD_H','ratio_VS_over_VG_L','ratio_VS_over_VG_H', ...
                  'ratio_VS_over_VGS_L','ratio_VS_over_VGS_H','ratio_VS_over_VDS_L','ratio_VS_over_VDS_H', ...
                  'phase_ZS_L','phase_ZS_H', ...
                  'phase_VGS_minus_VDS_L','phase_VGS_minus_VDS_H', ...
                  'phaseErr_VGS_VDS_L','phaseErr_VGS_VDS_H', ...
                  'Phi_SG_L','Phi_SG_H','Phi_SD_L','Phi_SD_H','Phi_GD_L','Phi_GD_H', ...
                  'RpD_L','RpD_H','RpDS_L','RpDS_H','RpGS_L','RpGS_H', ...
                  'XpD_L','XpD_H','XpDS_L','XpDS_H','XpGS_L','XpGS_H', ...
                  'delta_ZS_self_cross_deg','sin_delta_ZS_self_cross','mode_diff_predictor', ...
                  'eta_VS_cross_self_L','eta_VS_cross_self_H', ...
                  'eta_VS_cross_total_L','eta_VS_cross_total_H'};
        for ii = 1:numel(fields)
            fn = fields{ii};
            res.([fn '_atPSS']) = interp1(freq, res.(fn), fPSS_Hz, 'pchip', 'extrap');
        end
        res.ZS_self_atPSS  = interp1(freq, ZS_I_self,  fPSS_Hz, 'pchip', 'extrap');
        res.ZS_cross_atPSS = interp1(freq, ZS_I_cross, fPSS_Hz, 'pchip', 'extrap');
        res.ZD_self_atPSS  = interp1(freq, ZD_I_self,  fPSS_Hz, 'pchip', 'extrap');
        res.ZD_cross_atPSS = interp1(freq, ZD_I_cross, fPSS_Hz, 'pchip', 'extrap');
        res.ZG_self_atPSS  = interp1(freq, ZG_I_self,  fPSS_Hz, 'pchip', 'extrap');
        res.ZG_cross_atPSS = interp1(freq, ZG_I_cross, fPSS_Hz, 'pchip', 'extrap');
    end
end

function y = wrap180_local(x)
    y = mod(x + 180, 360) - 180;
end

function ph = unwrap_phase_deg_local(x)
    ph = unwrap(angle(x)) * 180/pi;
    ph0_wrap = wrap180_local(angle(x(1)) * 180/pi);
    ph = ph + 360 * round((ph0_wrap - ph(1))/360);
end

function add_panel_label(ax, labelStr, fontName, fsLabel)
    % V32 paper-style Figure 1 subfigure label.
    % Labels are ordered column-wise:
    %   left column:   (a)(b)(c)
    %   middle column: (d)(e)(f)
    %   right column:  (g)(h)(i)
    %
    % Fine tuning:
    %   labelX = 0.00  -> aligned with the left start of the x-axis.
    %                     Increase it to move the label right; decrease it
    %                     slightly, e.g. -0.02, to move it left.
    %   labelY = -0.115 -> close to the x-label baseline.
    %                     Increase it, e.g. -0.09, to move the label upward.
    %                     Decrease it, e.g. -0.14, to move the label downward.
    labelX = 0.00;
    labelY = -0.125;

    text(ax, labelX, labelY, labelStr, ...
        'Units','normalized', ...
        'FontName',fontName, ...
        'FontSize',fsLabel+2, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','middle', ...
        'Interpreter','none', ...
        'BackgroundColor','w', ...
        'Margin',1.0, ...
        'Clipping','off');
end
