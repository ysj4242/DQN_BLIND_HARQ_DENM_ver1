function [mean_pdr,mean_pdr_CAM,mean_pdr_DENM] = PDRCalculation(outputValues)

% 200m 까지의 평균 PDR 구하기

% 변수 초기화
Asum_Ntxbeacon = 0;
Asum_Ncorrectlybeacon = 0;
Asum_Ntxbeacon_CAM = 0;
Asum_Ncorrectlybeacon_CAM = 0;
Asum_Ntxbeacon_DENM = 0;
Asum_Ncorrectlybeacon_DENM = 0;
Bsum_Ntxbeacon = 0;
Bsum_Ncorrectlybeacon = 0;
Bsum_Ntxbeacon_CAM = 0;
Bsum_Ncorrectlybeacon_CAM = 0;
Bsum_Ntxbeacon_DENM = 0;
Bsum_Ncorrectlybeacon_DENM = 0;
A_CAM = 0;
B_CAM = 0;
A_DENM = 0;
B_DENM = 0;

A = load('2rep_400_np_d1_0.65.mat');        %black
B = load('2rep_400_np_nd.mat');        %
% load('2rep_400_pp_nd.mat');         %red
% load('2rep_400_np_nd.mat');         %
% load('2rep_200_p5_nd.mat');         %blue
% load('2rep_200_np_nd.mat');         %

i = 7;

%TOTAL
% for a = 1 : i
%     Asum_Ntxbeacon = Asum_Ntxbeacon + A.outputValues.NtxBeaconsCV2X(:,:,a);
%     Asum_Ncorrectlybeacon = Asum_Ncorrectlybeacon + A.outputValues.NcorrectlyTxBeaconsCV2X(:,:,a);
%     Bsum_Ntxbeacon = Bsum_Ntxbeacon + B.outputValues.NtxBeaconsCV2X(:,:,a);
%     Bsum_Ncorrectlybeacon = Bsum_Ncorrectlybeacon + B.outputValues.NcorrectlyTxBeaconsCV2X(:,:,a);
% 
% 
%     %CAM
% 
%     Asum_Ntxbeacon_CAM = Asum_Ntxbeacon_CAM + A.outputValues.NtxBeaconsCV2X_CAM(:,:,a);
%     Asum_Ncorrectlybeacon_CAM = Asum_Ncorrectlybeacon_CAM + A.outputValues.NcorrectlyTxBeaconsCV2X_CAM(:,:,a);
%     Bsum_Ntxbeacon_CAM = Bsum_Ntxbeacon_CAM + B.outputValues.NtxBeaconsCV2X_CAM(:,:,a);
%     Bsum_Ncorrectlybeacon_CAM = Bsum_Ncorrectlybeacon_CAM + B.outputValues.NcorrectlyTxBeaconsCV2X_CAM(:,:,a);
% 
% 
%     %DENM
% 
%     Asum_Ntxbeacon_DENM  = Asum_Ntxbeacon_DENM + A.outputValues.NtxBeaconsCV2X_DENM(:,:,a);
%     Asum_Ncorrectlybeacon_DENM = Asum_Ncorrectlybeacon_DENM + A.outputValues.NcorrectlyTxBeaconsCV2X_DENM(:,:,a);
%     Bsum_Ntxbeacon_DENM = Bsum_Ntxbeacon_DENM + B.outputValues.NtxBeaconsCV2X_DENM(:,:,a);
%     Bsum_Ncorrectlybeacon_DENM = Bsum_Ncorrectlybeacon_DENM + B.outputValues.NcorrectlyTxBeaconsCV2X_DENM(:,:,a);
% end
for a = 1 : i
    A_CAM = A_CAM + A.outputValues.packetReceptionRatioCV2X_CAM(:,:,a);
    A_DENM = A_DENM + A.outputValues.packetReceptionRatioCV2X_DENM(:,:,a);
    B_CAM = B_CAM + B.outputValues.packetReceptionRatioCV2X_CAM(:,:,a);
    B_DENM = B_DENM + B.outputValues.packetReceptionRatioCV2X_DENM(:,:,a);
end
A_CAM = A_CAM  / i;
B_CAM = B_CAM  / i;
A_DENM = A_DENM / i;
B_DENM = B_DENM / i;


% A.mean_pdr = A.sum_Ncorrectlybeacon / A.sum_Ntxbeacon;
% A.mean_pdr_CAM = A.sum_Ncorrectlybeacon_CAM / A.sum_Ntxbeacon_CAM;
% A.mean_pdr_DENM = A.sum_Ncorrectlybeacon_DENM / A.sum_Ntxbeacon_DENM;
% 
% B.mean_pdr = B.sum_Ncorrectlybeacon / B.sum_Ntxbeacon;
% B.mean_pdr_CAM = B.sum_Ncorrectlybeacon_CAM / B.sum_Ntxbeacon_CAM;
% B.mean_pdr_DENM = B.sum_Ncorrectlybeacon_DENM / B.sum_Ntxbeacon_DENM;
% 
% comparison_pdr = (A.mean_pdr - B.mean_pdr)/((A.mean_pdr+B.mean_pdr)/2);
% comparison_CAM_pdr = (A_CAM - B_CAM)/((A_CAM+B_CAM)/2);
% comparison_DENM_pdr = (A_DENM - B_DENM)/((A_DENM+B_DENM)/2);

percentage_increase_CAM = ((A_CAM - B_CAM) / B_CAM) * 100;
percentage_increase_DENM = ((A_DENM - B_DENM) / B_DENM) * 100;

% fprintf("TOTAL 평균 PDR : %f\n",A.mean_pdr);
fprintf("CAM 평균 PDR : %f\n",A_CAM);
fprintf("DENM 평균 PDR : %f\n\n",A_DENM);

% fprintf("TOTAL 평균 PDR : %f\n",B.mean_pdr);
fprintf("CAM 평균 PDR : %f\n",B_CAM);
fprintf("DENM 평균 PDR : %f\n\n",B_DENM);

% fprintf("TOTAL PDR 차이 : %f\n",round(comparison_pdr,3));
fprintf("CAM PDR 차이 : %f\n",round(percentage_increase_CAM,2));
fprintf("DENM PDR 차이 : %f\n",round(percentage_increase_DENM,2));
end

