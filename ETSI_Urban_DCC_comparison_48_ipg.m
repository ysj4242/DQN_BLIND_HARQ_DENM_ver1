close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 300
% A = load('2rep_800_np_d1_0.8.mat');   %black
% B = load('2rep_800_np_d1_0.65.mat');     %black
% C = load('2rep_800_np_d1_1.mat');   %black
% D = load('2rep_800_np_nd.mat');     %red
% E = load('2rep_400_np_d1_1.mat');   %red
% F = load('2rep_400_np_nd.mat');     %red
% G = load('2rep_200_np_pd1.mat');     %green
% H = load('2rep_200_np_d1_1.mat');     %green
% I = load('2rep_200_np_nd.mat');     %green
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 300
A = load('2rep_800_np_d1_0.65.mat');    %black
B = load('2rep_800_np_nd.mat');         %black
C = load('2rep_400_np_d1_0.3.mat');     %red
D = load('2rep_400_np_nd.mat');         %red
E = load('2rep_200_np_d1_0.3.mat');     %blue
F = load('2rep_200_np_nd.mat');         %blue
G = load('2rep_200_np_pd1.mat');        %green
H = load('2rep_200_np_d1_1.mat');       %green
I = load('2rep_200_np_nd.mat');         %green

% r = length(A.phyParams.Raw);
r = 5;

A_1=A.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
A_2=reshape(A_1,10001,r);
B_1=B.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
B_2=reshape(B_1,10001,r);
C_1=C.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
C_2=reshape(C_1,10001,r);
D_1=D.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
D_2=reshape(D_1,10001,r);
E_1=E.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
E_2=reshape(E_1,10001,r);
F_1=F.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
F_2=reshape(F_1,10001,r);
G_1=F.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
G_2=reshape(G_1,10001,r);
H_1=F.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
H_2=reshape(H_1,10001,r);
I_1=F.outputValues.updateDelayCounterCV2X(:,:,:,[1,3,5,6,7]);
I_2=reshape(I_1,10001,r);


% B = load('control_524_V2I_I2V_Corrent.mat');
% B_1=B.outputValues.updateDelayCounterCV2X;
% B_2=reshape(B_1,10001,10);
% 
% C = load('control_524_V2I_I2V_delt.mat');
% C_1=C.outputValues.updateDelayCounterCV2X;
% C_2=reshape(C_1,10001,10);

x=length(A_2(:,1));

s = r;

A_sum=zeros(1,s);
A_num=zeros(1,s);
B_sum=zeros(1,s);
B_num=zeros(1,s);
C_sum=zeros(1,s);
C_num=zeros(1,s);
D_sum=zeros(1,s);
D_num=zeros(1,s);
E_sum=zeros(1,s);
E_num=zeros(1,s);
F_sum=zeros(1,s);
F_num=zeros(1,s);
G_sum=zeros(1,s);
G_num=zeros(1,s);
H_sum=zeros(1,s);
H_num=zeros(1,s);
I_sum=zeros(1,s);
I_num=zeros(1,s);
% C_num=zeros(1,10);
A_mean = 0;
B_mean = 0;
C_mean = 0;

for i=2:x
    A_sum=A_sum+((0.001*i).*A_2(i,:));
    A_num=A_num+A_2(i,:);
    B_sum=B_sum+((0.001*i).*B_2(i,:));
    B_num=B_num+B_2(i,:);
    C_sum=C_sum+((0.001*i).*C_2(i,:));
    C_num=C_num+C_2(i,:);
    D_sum=D_sum+((0.001*i).*D_2(i,:));
    D_num=D_num+D_2(i,:);
    E_sum=E_sum+((0.001*i).*E_2(i,:));
    E_num=E_num+E_2(i,:);
    F_sum=F_sum+((0.001*i).*F_2(i,:));
    F_num=F_num+F_2(i,:);
    G_sum=G_sum+((0.001*i).*G_2(i,:));
    G_num=G_num+G_2(i,:);
    H_sum=H_sum+((0.001*i).*H_2(i,:));
    H_num=H_num+H_2(i,:);
    I_sum=I_sum+((0.001*i).*I_2(i,:));
    I_num=I_num+I_2(i,:);
end

A_meanIPG=A_sum./A_num;
B_meanIPG=B_sum./B_num;
C_meanIPG=C_sum./C_num;
D_meanIPG=D_sum./D_num;
E_meanIPG=E_sum./E_num;
F_meanIPG=F_sum./F_num;
G_meanIPG=G_sum./G_num;
H_meanIPG=H_sum./H_num;
I_meanIPG=I_sum./I_num;

% ETSI_LDM_300 = (C_meanIPG - B_meanIPG);
% LDM_NO_300 = (C_meanIPG - A_meanIPG);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 500
% E=load('NO_DCC_NR_500.mat');
% E_1=E.outputValues.updateDelayCounterCV2X;
% E_2=reshape(E_1,10001,10);
% 
% F=load('ETSI_DCC_NR_500.mat');
% F_1=F.outputValues.updateDelayCounterCV2X;
% F_2=reshape(F_1,10001,10);
% 
% G=load('LDM_DCC_NR_500.mat');
% G_1=G.outputValues.updateDelayCounterCV2X;
% G_2=reshape(G_1,10001,10);
% 
% x=length(E_2(:,1));
% 
% E_sum=zeros(1,10);
% E_num=zeros(1,10);
% F_sum=zeros(1,10);
% F_num=zeros(1,10);
% G_sum=zeros(1,10);
% G_num=zeros(1,10);
% 
% 
% for i=2:x
%     E_sum=E_sum+((0.001*i).*E_2(i,:));
%     E_num=E_num+E_2(i,:);
%     F_sum=F_sum+((0.001*i).*F_2(i,:));
%     F_num=F_num+F_2(i,:);
%     G_sum=G_sum+((0.001*i).*G_2(i,:));
%     G_num=G_num+G_2(i,:);
% end
% 
% distance=[20 40 60 80 100 120 140 160 180 200];
% E_meanIPG=E_sum./E_num;
% F_meanIPG=F_sum./F_num;
% G_meanIPG=G_sum./G_num;
% 
% ETSI_LDM_500 = (G_meanIPG - F_meanIPG);
% LDM_NO_500 = (G_meanIPG - E_meanIPG);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% distance=[50 75 100 125 150 200 300];
distance=[50 100 150 200 300];



% figure
% semilogy(distance,A_meanIPG,'Color','black','LineStyle','-','Marker','o','LineWidth',1.5);
% hold on
% semilogy(distance,B_meanIPG,'Color','black','LineStyle',':','Marker','diamond','LineWidth',1.5);
% hold on
% semilogy(distance,C_meanIPG,'Color','black','LineStyle','--','Marker','*','LineWidth',1.5);
% hold on
% semilogy(distance,D_meanIPG,'Color','r','LineStyle','-','Marker','o','LineWidth',1.5);
% hold on
% semilogy(distance,E_meanIPG,'Color','r','LineStyle',':','Marker','diamond','LineWidth',1.5);
% hold on
% semilogy(distance,F_meanIPG,'Color','r','LineStyle','--','Marker','*','LineWidth',1.5);
% hold on
% semilogy(distance,G_meanIPG,'Color','g','LineStyle','-','Marker','o','LineWidth',1.5);
% hold on
% semilogy(distance,H_meanIPG,'Color','g','LineStyle',':','Marker','diamond','LineWidth',1.5);
% hold on
% semilogy(distance,I_meanIPG,'Color','g','LineStyle','--','Marker','*','LineWidth',1.5);

figure
semilogy(distance,A_meanIPG,'Color','black','LineStyle','-','Marker','o','LineWidth',1.5);
hold on
semilogy(distance,B_meanIPG,'Color','black','LineStyle','--','Marker','o','LineWidth',1.5);
hold on
semilogy(distance,C_meanIPG,'Color','r','LineStyle','-','Marker','o','LineWidth',1.5);
hold on
semilogy(distance,D_meanIPG,'Color','r','LineStyle','--','Marker','o','LineWidth',1.5);
hold on
semilogy(distance,E_meanIPG,'Color','b','LineStyle','-','Marker','o','LineWidth',1.5);
hold on
semilogy(distance,F_meanIPG,'Color','b','LineStyle','--','Marker','o','LineWidth',1.5);

% semilogy(distance,G_meanIPG,'Color','r','LineStyle','-','Marker','square','LineWidth',1.5);
grid on
lgd=legend('adaptive DENM, ρ=800','general DENM, ρ=800', 'adaptive DENM, ρ=400','general DENM, ρ=400','adaptive DENM, ρ=200', 'general DENM, ρ=200','Orientation','horizontal');
lgd.NumColumns = 2;
xlabel('Tx-Rx distance (m)','FontSize',13,'Color','k');
ylabel('Average IPG (s)','FontSize',13,'Color','k');
title('IPG');
axis([50 300 0 0.35])
set(gca,'FontSize',12)
A = A_meanIPG - B_meanIPG;
B = C_meanIPG - D_meanIPG;
C = E_meanIPG - F_meanIPG;
for a = 1 : r
    A_mean = A_mean + A(1, a);
    B_mean = B_mean + B(1, a);
    C_mean = C_mean + C(1, a);
end
fprintf("평균 IPG : %f\n",A);
fprintf("평균 IPG : %f\n",B);
fprintf("평균 IPG : %f\n",C);