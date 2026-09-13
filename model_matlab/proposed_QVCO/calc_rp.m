%% calc_rp.m
% Mode-dependent effective parallel resistance R_p versus C_S.
%
% Corresponding paper result:
%   simulated R_p versus C_S for the selected
%   omega_H mode and the unselected omega_L mode.
%
% Definition:
%   Z_D,- = Z_D,self + (-j) Z_D,cross
%   Z_D,+ = Z_D,self + (+j) Z_D,cross
%   R_p,- = |Re{Z_D,-(f_PSS)}|
%   R_p,+ = |Re{Z_D,+(f_PSS)}|
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
qMinus = -1j;
qPlus  = +1j;

% Current SW=31 assignment:
% q=-j -> selected omega_H
% q=+j -> unselected omega_L
selectedBranch = 'minus';

%% Port mapping
p.DI = 1; p.GI = 2; p.SI = 3;
p.DQ = 4; p.GQ = 5; p.SQ = 6;

PEI = zeros(3,6);
PEI(1,p.DI)=+1; PEI(2,p.GI)=-1; PEI(3,p.SQ)=-1;

PEQ = zeros(3,6);
PEQ(1,p.DQ)=+1; PEQ(2,p.GQ)=-1; PEQ(3,p.SI)=+1;

Rinj = zeros(6,2);
Rinj(p.DI,1)=+1; Rinj(p.SQ,1)=+1;
Rinj(p.DQ,2)=+1; Rinj(p.SI,2)=-1;

lDI = zeros(1,6);
lDI(p.DI)=+1;

%% Calculate
N = numel(Cs_fF);
Rp_minus = nan(N,1);
Rp_plus  = nan(N,1);

for k = 1:N
    if ~isfile(fileNames{k})
        warning('Missing file: %s',fileNames{k});
        continue;
    end

    [Rp_minus(k),Rp_plus(k)] = calc_rp_one_file( ...
        fileNames{k}, fPSS_GHz(k)*1e9, ...
        qMinus,qPlus,PEI,PEQ,Rinj,lDI,correctionMode);
end

if strcmpi(selectedBranch,'minus')
    Rp_selected   = Rp_minus;
    Rp_unselected = Rp_plus;
else
    Rp_selected   = Rp_plus;
    Rp_unselected = Rp_minus;
end

%% Plot
figure('Color','w','Position',[100 100 650 470]);
ax = axes;
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

plot(ax,Cs_fF,Rp_selected,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Selected mode \omega_H');
plot(ax,Cs_fF,Rp_unselected,'-o','LineWidth',2.0, ...
    'MarkerFaceColor','w','DisplayName','Unselected mode \omega_L');

xlabel(ax,'C_S (fF)','Interpreter','tex','FontName','Arial','FontSize',12);
ylabel(ax,'R_p (\Omega)','Interpreter','tex','FontName','Arial','FontSize',12);
xlim(ax,[0 300]);
set(ax,'FontName','Arial','FontSize',11,'LineWidth',1.0);
legend(ax,'Location','best','Interpreter','tex','Box','off');

% Paper caption:
% Fig. 3 (Right): simulated angle(Z_GS), R_p, open-loop Q, and
% FoM@10MHz versus C_S of the two modes (omega_L and omega_H).
title(ax,'Mode-dependent R_p','Interpreter','tex', ...
    'FontName','Arial','FontSize',12);

%% Local functions
function [Rp_minus,Rp_plus] = calc_rp_one_file( ...
    fileName,fPSS_Hz,qMinus,qPlus,PEI,PEQ,Rinj,lDI,correctionMode)

    Sobj = sparameters(fileName);
    freq = Sobj.Frequencies(:);
    S = Sobj.Parameters;
    z0 = Sobj.Impedance;

    if numel(z0) ~= 1, error('A scalar reference impedance is required.'); end
    if size(S,1) ~= 9, error('%s is not a 9-port file.',fileName); end

    I9 = eye(9);
    Nf = numel(freq);
    ZD_self  = complex(zeros(Nf,1));
    ZD_cross = complex(zeros(Nf,1));

    for n = 1:Nf
        Sn = S(:,:,n);
        Y9 = (1/z0)*(I9-Sn)/(I9+Sn);

        Ytotal6 = Y9(1:6,1:6);
        Ymos3 = Y9(7:9,7:9);
        Yclean6 = remove_mos_part(Ytotal6,Ymos3,PEI,PEQ,correctionMode);

        H = Yclean6 \ Rinj;
        VD_from = lDI*H;
        ZD_self(n)  = VD_from(1);
        ZD_cross(n) = VD_from(2);
    end

    ZD_minus = ZD_self + qMinus.*ZD_cross;
    ZD_plus  = ZD_self + qPlus .*ZD_cross;

    Zm = interp_complex(freq,ZD_minus,fPSS_Hz);
    Zp = interp_complex(freq,ZD_plus, fPSS_Hz);

    Rp_minus = abs(real(Zm));
    Rp_plus  = abs(real(Zp));
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

function val = interp_complex(freq,x,f0)
    val = interp1(freq,real(x),f0,'pchip','extrap') + ...
          1j*interp1(freq,imag(x),f0,'pchip','extrap');
end
