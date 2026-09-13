%% calc_zgs.m
% Mode-dependent Z_GS calculation from extracted 9-port S-parameters.
%
% Corresponding paper result:
%   simulated angle(Z_GS) versus frequency for
%   different C_S values and the two quadrature modes (omega_L, omega_H).
%
% Method:
%   1) Convert the extracted 9-port S-parameters to Y-parameters.
%   2) Remove Re{Y_MOS} using the same correction adopted in the paper.
%   3) Apply the two quadrature excitations q = -j and q = +j.
%   4) Calculate the mode-dependent Z_GS = V_GS / I_DS.
%
% Requirement:
%   MATLAB RF Toolbox (sparameters)
%
% Expected files:
%   QVCO_Mine_SW31_Cs_0f.s9p
%   QVCO_Mine_SW31_Cs_25f.s9p
%   ...
%   QVCO_Mine_SW31_Cs_300f.s9p

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
cd(scriptDir);

%% User settings
Cs_all_fF = (0:25:300).';
fileNames = arrayfun(@(c) sprintf('QVCO_Mine_SW31_Cs_%gf.s9p', c), ...
    Cs_all_fF, 'UniformOutput', false);

% Curves shown in the compact paper-style plot.
plotCs_fF = [0 75 150 225 300].';

% PSS frequencies used only to align the displayed phase branch.
fPSS_GHz = [ ...
    20.36; 20.32; 20.28; 20.24; 20.20; 20.16; 20.12; ...
    20.09; 20.05; 20.02; 20.00; 19.97; 19.99];

xMin_GHz = 10;
xMax_GHz = 30;
phaseTarget_deg = -180;
correctionMode = 'removeReal';

qMinus = -1j;
qPlus  = +1j;

%% Port mapping
% Six-port order: [DI, GI, SI, DQ, GQ, SQ]
p.DI = 1; p.GI = 2; p.SI = 3;
p.DQ = 4; p.GQ = 5; p.SQ = 6;

PEI = zeros(3,6);
PEI(1,p.DI) = +1;
PEI(2,p.GI) = -1;
PEI(3,p.SQ) = -1;

PEQ = zeros(3,6);
PEQ(1,p.DQ) = +1;
PEQ(2,p.GQ) = -1;
PEQ(3,p.SI) = +1;

% I/Q IDS excitation basis
Rinj = zeros(6,2);
Rinj(p.DI,1) = +1;
Rinj(p.SQ,1) = +1;
Rinj(p.DQ,2) = +1;
Rinj(p.SI,2) = -1;

% V_GS,I = -V_GI + V_SQ
lGI = zeros(1,6); lGI(p.GI) = -1;
lSI = zeros(1,6); lSI(p.SQ) = -1;
lGSI = lGI - lSI;

%% Calculate and plot
figure('Color','w','Position',[100 100 760 500]);
ax = axes;
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

plotIdx = find(ismember(Cs_all_fF, plotCs_fF));
curveColors = parula(max(numel(plotIdx),2));

for kk = 1:numel(plotIdx)
    ic = plotIdx(kk);
    fileName = fileNames{ic};

    if ~isfile(fileName)
        warning('Missing file: %s', fileName);
        continue;
    end

    D = calc_zgs_one_file(fileName, PEI, PEQ, Rinj, lGSI, ...
        correctionMode, qMinus, qPlus, ...
        fPSS_GHz(ic)*1e9, phaseTarget_deg);

    mask = D.freq/1e9 >= xMin_GHz & D.freq/1e9 <= xMax_GHz;

    % q=-j: selected physical mode omega_H for the current SW=31 design
    plot(ax, D.freq(mask)/1e9, D.phase_minus_deg(mask), '-', ...
        'LineWidth', 2.0, 'Color', curveColors(kk,:), ...
        'DisplayName', sprintf('C_S = %g fF, \\omega_H', Cs_all_fF(ic)));

    % q=+j: unselected physical mode omega_L
    plot(ax, D.freq(mask)/1e9, D.phase_plus_deg(mask), '--', ...
        'LineWidth', 1.6, 'Color', curveColors(kk,:), ...
        'HandleVisibility','off');
end

yline(ax,0,'-.','LineWidth',1.0,'HandleVisibility','off');

xlabel(ax,'Frequency (GHz)','FontName','Arial','FontSize',12);
ylabel(ax,'\angle Z_{GS} (deg)','Interpreter','tex', ...
    'FontName','Arial','FontSize',12);

xlim(ax,[xMin_GHz xMax_GHz]);
ylim(ax,[-300 50]);
set(ax,'FontName','Arial','FontSize',11,'LineWidth',1.0);

% Paper caption:
% Fig. 3 (Right): simulated angle(Z_GS), R_p, open-loop Q, and
% FoM@10MHz versus C_S of the two modes (omega_L and omega_H).
title(ax,'Mode-dependent \angle Z_{GS}', ...
    'Interpreter','tex','FontName','Arial','FontSize',12);

%% Local function
function D = calc_zgs_one_file(fileName, PEI, PEQ, Rinj, lGSI, ...
    correctionMode, qMinus, qPlus, fAlign_Hz, phaseTarget_deg)

    Sobj = sparameters(fileName);
    freq = Sobj.Frequencies(:);
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;

    if numel(z0) ~= 1
        error('A scalar reference impedance is required.');
    end
    if size(S,1) ~= 9
        error('%s is not a 9-port Touchstone file.', fileName);
    end

    I9 = eye(9);
    Nf = numel(freq);
    ZGS_self  = complex(zeros(Nf,1));
    ZGS_cross = complex(zeros(Nf,1));

    for n = 1:Nf
        Sn = S(:,:,n);
        Y9 = (1/z0) * (I9-Sn) / (I9+Sn);

        Ytotal6 = Y9(1:6,1:6);
        Ymos3   = Y9(7:9,7:9);
        Yclean6 = remove_mos_part(Ytotal6, Ymos3, PEI, PEQ, correctionMode);

        H = Yclean6 \ Rinj;
        ZGS_from = lGSI * H;

        ZGS_self(n)  = ZGS_from(1);
        ZGS_cross(n) = ZGS_from(2);
    end

    ZGS_minus = ZGS_self + qMinus.*ZGS_cross;
    ZGS_plus  = ZGS_self + qPlus .*ZGS_cross;

    phaseMinus = unwrap(angle(ZGS_minus))*180/pi;
    phasePlus  = unwrap(angle(ZGS_plus))*180/pi;

    ph0m = interp1(freq,phaseMinus,fAlign_Hz,'pchip','extrap');
    ph0p = interp1(freq,phasePlus, fAlign_Hz,'pchip','extrap');

    phaseMinus = phaseMinus + 360*round((phaseTarget_deg-ph0m)/360);
    phasePlus  = phasePlus  + 360*round((phaseTarget_deg-ph0p)/360);

    D.freq = freq;
    D.phase_minus_deg = phaseMinus;
    D.phase_plus_deg  = phasePlus;
end

function Yclean6 = remove_mos_part(Ytotal6, Ymos3, PEI, PEQ, mode)
    switch mode
        case 'noRemove'
            Yclean6 = Ytotal6;
        case 'removeReal'
            Yremove6 = PEI.'*real(Ymos3)*PEI + PEQ.'*real(Ymos3)*PEQ;
            Yclean6 = Ytotal6 - Yremove6;
        case 'removeFull'
            Yremove6 = PEI.'*Ymos3*PEI + PEQ.'*Ymos3*PEQ;
            Yclean6 = Ytotal6 - Yremove6;
        otherwise
            error('Unknown correctionMode: %s', mode);
    end
end
