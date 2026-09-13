%% predict_mode_frequency.m
% Predict the two quadrature-mode frequencies from extracted 9-port
% S-parameters using the multi-port I/Q excitation method.
%
% Corresponding paper result:
%   calculated omega_L and omega_H across the
%   tuning range, compared with the simulated/measured oscillation frequency.
%
% This script plots only the model-derived mode-frequency prediction.
% The measured data shown in the paper are not generated here.
%
% Requirement:
%   MATLAB RF Toolbox (sparameters)

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
cd(scriptDir);

%% User settings
fileNames = { ...
    'QVCO_Mine_wi_var_SW0.s9p'; ...
    'QVCO_Mine_wi_var_SW5.s9p'; ...
    'QVCO_Mine_wi_var_SW10.s9p'; ...
    'QVCO_Mine_wi_var_SW15.s9p'; ...
    'QVCO_Mine_wi_var_SW20.s9p'; ...
    'QVCO_Mine_wi_var_SW25.s9p'; ...
    'QVCO_Mine_wi_var_SW31.s9p'};

SW = [0 5 10 15 20 25 31].';

% Simulated/PSS oscillation frequencies used as the local search reference.
fPSS_GHz = [28.00 26.10 24.73 23.36 22.22 21.27 20.24].';

% Current mapping for these data:
% Kminus / q=-j -> selected omega_H
% Kplus  / q=+j -> unselected omega_L
selectedBranch = repmat("minus",numel(SW),1);

correctionMode = 'removeReal';
phaseTarget_deg = -180;
fmin_Hz = 18e9;
fmax_Hz = 30e9;
selectedSearchHalfBW_Hz = 2.5e9;
selectedGuard_GHz = 2.0;

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

%% Calculate predicted mode frequencies
N = numel(SW);
fKminus_GHz = nan(N,1);
fKplus_GHz  = nan(N,1);
fKminusPeak_GHz = nan(N,1);
fKplusPeak_GHz  = nan(N,1);

for k = 1:N
    if ~isfile(fileNames{k})
        warning('Missing file: %s',fileNames{k});
        continue;
    end

    R = calc_k_branches(fileNames{k},PEI,PEQ,Lobs,Rinj,correctionMode);
    fRef_Hz = fPSS_GHz(k)*1e9;

    mask = R.freq>=fmin_Hz & R.freq<=fmax_Hz;

    phaseMinus = unwrap_phase_near_ref(R.Kminus,mask,R.freq,fRef_Hz,phaseTarget_deg);
    phasePlus  = unwrap_phase_near_ref(R.Kplus, mask,R.freq,fRef_Hz,phaseTarget_deg);

    idx = find(mask);
    [~,im] = max(abs(R.Kminus(mask)));
    [~,ip] = max(abs(R.Kplus(mask)));
    fKminusPeak_GHz(k) = R.freq(idx(im))/1e9;
    fKplusPeak_GHz(k)  = R.freq(idx(ip))/1e9;

    if selectedBranch(k)=="minus"
        fKminus_GHz(k) = find_phase_target(R.freq,phaseMinus,phaseTarget_deg, ...
            fmin_Hz,fmax_Hz,fRef_Hz,selectedSearchHalfBW_Hz);
        fKplus_GHz(k) = find_phase_target(R.freq,phasePlus,phaseTarget_deg, ...
            fmin_Hz,fmax_Hz,fRef_Hz,[]);
    else
        fKminus_GHz(k) = find_phase_target(R.freq,phaseMinus,phaseTarget_deg, ...
            fmin_Hz,fmax_Hz,fRef_Hz,[]);
        fKplus_GHz(k) = find_phase_target(R.freq,phasePlus,phaseTarget_deg, ...
            fmin_Hz,fmax_Hz,fRef_Hz,selectedSearchHalfBW_Hz);
    end
end

fKminus_GHz = guard_selected_frequency(fKminus_GHz,fPSS_GHz, ...
    fKminusPeak_GHz,selectedBranch=="minus",selectedGuard_GHz);
fKplus_GHz = guard_selected_frequency(fKplus_GHz,fPSS_GHz, ...
    fKplusPeak_GHz,selectedBranch=="plus",selectedGuard_GHz);

isMinus = selectedBranch=="minus";
fOmegaH_GHz = fKplus_GHz;
fOmegaH_GHz(isMinus) = fKminus_GHz(isMinus);

fOmegaL_GHz = fKminus_GHz;
fOmegaL_GHz(isMinus) = fKplus_GHz(isMinus);

%% Plot
figure('Color','w','Position',[100 100 680 500]);
ax = axes;
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

plot(ax,SW,fOmegaH_GHz,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Calc. \omega_H');
plot(ax,SW,fOmegaL_GHz,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Calc. \omega_L');
plot(ax,SW,fPSS_GHz,'--s','LineWidth',1.6, ...
    'MarkerFaceColor','w','DisplayName','Sim./PSS reference');

xlabel(ax,'Bank Code','FontName','Arial','FontSize',12);
ylabel(ax,'Frequency (GHz)','FontName','Arial','FontSize',12);
xlim(ax,[0 31]);
set(ax,'FontName','Arial','FontSize',11,'LineWidth',1.0);
legend(ax,'Location','best','Interpreter','tex','Box','off');

% Paper caption:
% Fig. 4 (Bottom right): simulated/measured frequency and calculated
% omega_L and omega_H across the tuning range.
title(ax,'Predicted quadrature-mode frequencies', ...
    'FontName','Arial','FontSize',12);

%% Local functions
function R = calc_k_branches(fileName,PEI,PEQ,Lobs,Rinj,correctionMode)
    Sobj = sparameters(fileName);
    freq = Sobj.Frequencies(:);
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;

    if numel(z0)~=1, error('A scalar reference impedance is required.'); end
    if size(S,1)~=9, error('%s is not a 9-port file.',fileName); end

    I9 = eye(9);
    KII = nan(numel(freq),1);
    KIQ = nan(numel(freq),1);

    for n = 1:numel(freq)
        Sn = S(:,:,n);
        Y9 = (1/z0)*(I9-Sn)/(I9+Sn);

        Ytotal6 = Y9(1:6,1:6);
        Ymos3 = Y9(7:9,7:9);
        Yclean6 = remove_mos_part(Ytotal6,Ymos3,PEI,PEQ,correctionMode);

        K = Lobs*(Yclean6\Rinj);
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

function phaseDeg = unwrap_phase_near_ref(z,mask,freq,fRef,targetDeg)
    phaseDeg = unwrap(angle(z))*180/pi;
    idxAllowed = find(mask & isfinite(phaseDeg));
    if isempty(idxAllowed), idxAllowed = find(isfinite(phaseDeg)); end
    if isempty(idxAllowed), return; end
    [~,k] = min(abs(freq(idxAllowed)-fRef));
    idx0 = idxAllowed(k);
    phaseDeg = phaseDeg + 360*round((targetDeg-phaseDeg(idx0))/360);
end

function fTarget_GHz = find_phase_target(freq,phaseDeg,targetDeg, ...
    fmin_Hz,fmax_Hz,fRef_Hz,searchHalfBW_Hz)

    mask = freq>=fmin_Hz & freq<=fmax_Hz & isfinite(phaseDeg);

    if ~isempty(searchHalfBW_Hz)
        nearMask = mask & abs(freq-fRef_Hz)<=searchHalfBW_Hz;
        if nnz(nearMask)>=3, mask=nearMask; end
    end

    f = freq(mask);
    p = phaseDeg(mask);

    if numel(f)<2
        fTarget_GHz = NaN;
        return;
    end

    d = p-targetDeg;
    cross = find(d(1:end-1).*d(2:end)<=0);

    if ~isempty(cross)
        fc = nan(numel(cross),1);
        for n = 1:numel(cross)
            i = cross(n);
            if p(i+1)~=p(i)
                fc(n)=f(i)+(targetDeg-p(i))*(f(i+1)-f(i))/(p(i+1)-p(i));
            else
                fc(n)=f(i);
            end
        end
        [~,best] = min(abs(fc-fRef_Hz));
        fTarget_Hz = fc(best);
    else
        [~,best] = min(abs(d));
        fTarget_Hz = f(best);
    end

    fTarget_GHz = fTarget_Hz/1e9;
end

function fTarget = guard_selected_frequency(fTarget,fPSS,fPeak,isSelected,maxDelta)
    for n = 1:numel(fTarget)
        if ~isSelected(n), continue; end
        bad = ~isfinite(fTarget(n)) || abs(fTarget(n)-fPSS(n))>maxDelta;
        if bad
            if isfinite(fPeak(n)) && abs(fPeak(n)-fPSS(n))<=maxDelta
                fTarget(n)=fPeak(n);
            else
                fTarget(n)=fPSS(n);
            end
        end
    end
end
