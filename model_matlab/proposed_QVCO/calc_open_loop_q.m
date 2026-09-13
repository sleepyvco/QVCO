%% calc_open_loop_q.m
% Mode-dependent open-loop Q versus C_S.
%
% Corresponding paper result:
%   simulated open-loop Q versus C_S for
%   the selected omega_H and unselected omega_L modes.
%
% Definition:
%   Q = (f_PSS/2) * |d(phi_K)/df|
% where phi_K is in radians and its slope is evaluated locally around
% the corresponding PSS oscillation frequency.
%
% Requirement:
%   MATLAB RF Toolbox (sparameters)

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
cd(scriptDir);

%% User settings
Cs_fF = (0:25:300).';
fileNames = arrayfun(@(x) sprintf('QVCO_Mine_SW31_Cs_%gf.s9p',x), ...
    Cs_fF,'UniformOutput',false);

fPSS_GHz = [ ...
    20.36; 20.32; 20.28; 20.24; 20.20; 20.16; 20.12; ...
    20.09; 20.05; 20.02; 20.00; 19.97; 19.99];

correctionMode = 'removeReal';
phaseSlopeFitHalfBW_Hz = 100e6;
selectedBranch = 'minus';

%% Port mapping
p.DI=1; p.GI=2; p.SI=3;
p.DQ=4; p.GQ=5; p.SQ=6;

PEI = zeros(3,6);
PEI(1,p.DI)=+1; PEI(2,p.GI)=-1; PEI(3,p.SQ)=-1;

PEQ = zeros(3,6);
PEQ(1,p.DQ)=+1; PEQ(2,p.GQ)=-1; PEQ(3,p.SI)=+1;

Lobs = zeros(2,6);
Lobs(1,p.GI)=-1; Lobs(1,p.SQ)=+1;
Lobs(2,p.GQ)=-1; Lobs(2,p.SI)=-1;

Rinj = zeros(6,2);
Rinj(p.DI,1)=+1; Rinj(p.SQ,1)=+1;
Rinj(p.DQ,2)=+1; Rinj(p.SI,2)=-1;

%% Calculate
N = numel(Cs_fF);
Qminus = nan(N,1);
Qplus  = nan(N,1);

for k = 1:N
    if ~isfile(fileNames{k})
        warning('Missing file: %s',fileNames{k});
        continue;
    end

    R = calc_k_branches(fileNames{k},PEI,PEQ,Lobs,Rinj,correctionMode);

    phaseMinus = unwrap_phase_near_freq(R.Kminus,R.freq,fPSS_GHz(k)*1e9,-180);
    phasePlus  = unwrap_phase_near_freq(R.Kplus, R.freq,fPSS_GHz(k)*1e9,-180);

    Qminus(k) = phase_slope_q(R.freq,phaseMinus,fPSS_GHz(k)*1e9,phaseSlopeFitHalfBW_Hz);
    Qplus(k)  = phase_slope_q(R.freq,phasePlus, fPSS_GHz(k)*1e9,phaseSlopeFitHalfBW_Hz);
end

if strcmpi(selectedBranch,'minus')
    Qselected   = Qminus;
    Qunselected = Qplus;
else
    Qselected   = Qplus;
    Qunselected = Qminus;
end

%% Plot
figure('Color','w','Position',[100 100 650 470]);
ax = axes;
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

plot(ax,Cs_fF,Qselected,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Selected mode \omega_H');
plot(ax,Cs_fF,Qunselected,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Unselected mode \omega_L');

xlabel(ax,'C_S (fF)','Interpreter','tex','FontName','Arial','FontSize',12);
ylabel(ax,'Open-loop Q','FontName','Arial','FontSize',12);
xlim(ax,[0 300]);
set(ax,'FontName','Arial','FontSize',11,'LineWidth',1.0);
legend(ax,'Location','best','Interpreter','tex','Box','off');

% Paper caption:
% Fig. 3 (Right): simulated angle(Z_GS), R_p, open-loop Q, and
% FoM@10MHz versus C_S of the two modes (omega_L and omega_H).
title(ax,'Mode-dependent open-loop Q', ...
    'FontName','Arial','FontSize',12);

%% Local functions
function R = calc_k_branches(fileName,PEI,PEQ,Lobs,Rinj,correctionMode)
    Sobj = sparameters(fileName);
    freq = Sobj.Frequencies(:);
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;

    if numel(z0) ~= 1, error('A scalar reference impedance is required.'); end
    if size(S,1) ~= 9, error('%s is not a 9-port file.',fileName); end

    [freq,ord] = sort(freq);
    S = S(:,:,ord);

    I9 = eye(9);
    KII = nan(numel(freq),1);
    KIQ = nan(numel(freq),1);

    for n = 1:numel(freq)
        Sn = S(:,:,n);
        Y9 = (1/z0)*(I9-Sn)/(I9+Sn);

        Ytotal6 = Y9(1:6,1:6);
        Ymos3 = Y9(7:9,7:9);
        Yclean6 = remove_mos_part(Ytotal6,Ymos3,PEI,PEQ,correctionMode);

        H = Yclean6 \ Rinj;
        K = Lobs*H;

        KII(n) = K(1,1);
        KIQ(n) = K(1,2);
    end

    R.freq = freq;
    R.Kplus  = KII + 1j*KIQ;
    R.Kminus = KII - 1j*KIQ;
end

function Yclean6 = remove_mos_part(Ytotal6,Ymos3,PEI,PEQ,mode)
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
            error('Unknown correctionMode: %s',mode);
    end
end

function phaseDeg = unwrap_phase_near_freq(K,freq,f0,targetDeg)
    phaseDeg = unwrap(angle(K))*180/pi;
    valid = isfinite(phaseDeg);
    idx = find(valid);
    if isempty(idx), return; end
    [~,m] = min(abs(freq(idx)-f0));
    idx0 = idx(m);
    phaseDeg = phaseDeg + 360*round((targetDeg-phaseDeg(idx0))/360);
end

function Q = phase_slope_q(freq,phaseDeg,f0,halfBW)
    valid = isfinite(freq) & isfinite(phaseDeg);
    idx = find(valid & abs(freq-f0)<=halfBW);

    if numel(idx)<3
        vidx = find(valid);
        [~,ord] = sort(abs(freq(vidx)-f0));
        idx = vidx(ord(1:min(5,numel(ord))));
    end

    if numel(idx)<2
        Q = NaN;
        return;
    end

    fGHz = freq(idx)/1e9;
    pDeg = phaseDeg(idx);
    pp = polyfit(fGHz,pDeg,1);

    slope_rad_per_GHz = pp(1)*pi/180;
    Q = (f0/1e9/2)*abs(slope_rad_per_GHz);
end
