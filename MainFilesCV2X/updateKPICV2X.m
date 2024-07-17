function [stationManagement,sinrManagement,outputValues,simValues,expManagement] = updateKPICV2X(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE,neighborsID_LTE,timeManagement,stationManagement,positionManagement,sinrManagement,outputValues,outParams,simParams,appParams,phyParams,simValues,...
    expManagement)

% Update the counter for transmissions and retransmissions
outputValues.cv2xTransmissionsIncHarq = outputValues.cv2xTransmissionsIncHarq + length(activeIDsTXLTE);
outputValues.cv2xTransmissionsFirst = outputValues.cv2xTransmissionsFirst + sum(stationManagement.pckTxOccurring(activeIDsTXLTE)==1);

% Error detection (up to RawMax)
% Each line corresponds to an error [TX, RX, BR, distance] within RawMax
%errorMatrixRawMax = findErrors_TEMP(activeIDsTXLTE,indexInActiveIDsOnlyLTE,neighborsID_LTE,sinrManagement,stationManagement,positionManagement,phyParams);
% From v 5.4.14
[fateRxListRawMax,fateRxListRawMax_DENM,fateRxListRawMax_CAM,stationManagement,sinrManagement,expManagement] = elaborateFateRxCV2X(timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,neighborsID_LTE,sinrManagement,stationManagement,positionManagement,appParams,phyParams,expManagement);
[a,~] = size(fateRxListRawMax_DENM);
for i = 1 : a
    if fateRxListRawMax_DENM(i,5) == 1
        k = fateRxListRawMax_DENM(i);
        stationManagement.PDR_suc(k) = stationManagement.PDR_suc(k) + 1;
    else
        k = fateRxListRawMax_DENM(i);
        stationManagement.PDR_fai(k) = stationManagement.PDR_fai(k) + 1;
    end
end

% Error detection (within each value of Raw)
for iPhyRaw=1:length(phyParams.Raw)
    
    % From v 5.4.14
    %errorMatrix = errorMatrixRawMax(errorMatrixRawMax(:,4)<phyParams.Raw(iPhyRaw),:);
    correctRxList = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax(:,5)==1,:);
    errorRxList = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax(:,5)==0,:);
    correctRxList_DENM = fateRxListRawMax_DENM(fateRxListRawMax_DENM(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax_DENM(:,5)==1,:);
    errorRxList_DENM = fateRxListRawMax_DENM(fateRxListRawMax_DENM(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax_DENM(:,5)==0,:);
    correctRxList_CAM = fateRxListRawMax_CAM(fateRxListRawMax_CAM(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax_CAM(:,5)==1,:);
    errorRxList_CAM = fateRxListRawMax_CAM(fateRxListRawMax_CAM(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax_CAM(:,5)==0,:);
    % for iPhycbr = 1:length(phyParams.cbr)
    %     if iPhycbr == 1
    %         correctRxList1 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList1 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 2
    %         correctRxList2 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList2 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 3
    %         correctRxList3 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList3 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 4
    %         correctRxList4 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList4 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 5
    %         correctRxList5 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList5 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 6
    %         correctRxList6 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList6 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 7
    %         correctRxList7 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList7 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 8
    %         correctRxList8 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList8 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     elseif iPhycbr == 9
    %         correctRxList9 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==1,:);
    %         errorRxList9 = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw)& round(fateRxListRawMax(:,6),1)==phyParams.cbr(iPhycbr) & fateRxListRawMax(:,5)==0,:);
    %     end
    % end
    % Call function to create awarenessMatrix
    % [#Correctly transmitted beacons, #Errors, #Neighbors]
    %awarenessMatrix = counterTX(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),errorMatrix);
    %awarenessMatrix = counterTX(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList);

    % Number of errors
    for iChannel = 1:phyParams.nChannels
        for pckType = 1:appParams.nPckTypes
            %Nerrors = length(errorMatrix( (stationManagement.pckType(errorMatrix(:,1))==pckType & stationManagement.vehicleChannel(errorMatrix(:,1))==iChannel),1));
            %Nerrors = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),2));
            Nerrors = length(errorRxList( (stationManagement.pckType(errorRxList(:,1))==pckType & stationManagement.vehicleChannel(errorRxList(:,1))==iChannel),1));
            Nerrors_DENM = length(errorRxList_DENM( (stationManagement.pckType(errorRxList_DENM(:,1))==pckType & stationManagement.vehicleChannel(errorRxList_DENM(:,1))==iChannel),1));
            Nerrors_CAM = length(errorRxList_CAM( (stationManagement.pckType(errorRxList_CAM(:,1))==pckType & stationManagement.vehicleChannel(errorRxList_CAM(:,1))==iChannel),1));

            % Nerrors1 = length(errorRxList1( (stationManagement.pckType(errorRxList1(:,1))==pckType & stationManagement.vehicleChannel(errorRxList1(:,1))==iChannel),1));
            % Nerrors2 = length(errorRxList2( (stationManagement.pckType(errorRxList2(:,1))==pckType & stationManagement.vehicleChannel(errorRxList2(:,1))==iChannel),1));
            % Nerrors3 = length(errorRxList3( (stationManagement.pckType(errorRxList3(:,1))==pckType & stationManagement.vehicleChannel(errorRxList3(:,1))==iChannel),1));
            % Nerrors4 = length(errorRxList4( (stationManagement.pckType(errorRxList4(:,1))==pckType & stationManagement.vehicleChannel(errorRxList4(:,1))==iChannel),1));
            % Nerrors5 = length(errorRxList5( (stationManagement.pckType(errorRxList5(:,1))==pckType & stationManagement.vehicleChannel(errorRxList5(:,1))==iChannel),1));
            % Nerrors6 = length(errorRxList6( (stationManagement.pckType(errorRxList6(:,1))==pckType & stationManagement.vehicleChannel(errorRxList6(:,1))==iChannel),1));
            % Nerrors7 = length(errorRxList7( (stationManagement.pckType(errorRxList7(:,1))==pckType & stationManagement.vehicleChannel(errorRxList7(:,1))==iChannel),1));
            % Nerrors8 = length(errorRxList8( (stationManagement.pckType(errorRxList8(:,1))==pckType & stationManagement.vehicleChannel(errorRxList8(:,1))==iChannel),1));
            % Nerrors9 = length(errorRxList9( (stationManagement.pckType(errorRxList9(:,1))==pckType & stationManagement.vehicleChannel(errorRxList9(:,1))==iChannel),1));

            outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) + Nerrors;

            % outputValues.NerrorsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X1(iChannel,pckType,iPhyRaw) + Nerrors1;
            % outputValues.NerrorsCV2X2(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X2(iChannel,pckType,iPhyRaw) + Nerrors2;
            % outputValues.NerrorsCV2X3(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X3(iChannel,pckType,iPhyRaw) + Nerrors3;
            % outputValues.NerrorsCV2X4(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X4(iChannel,pckType,iPhyRaw) + Nerrors4;
            % outputValues.NerrorsCV2X5(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X5(iChannel,pckType,iPhyRaw) + Nerrors5;
            % outputValues.NerrorsCV2X6(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X6(iChannel,pckType,iPhyRaw) + Nerrors6;
            % outputValues.NerrorsCV2X7(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X7(iChannel,pckType,iPhyRaw) + Nerrors7;
            % outputValues.NerrorsCV2X8(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X8(iChannel,pckType,iPhyRaw) + Nerrors8;
            % outputValues.NerrorsCV2X9(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X9(iChannel,pckType,iPhyRaw) + Nerrors9;

            outputValues.NerrorsCV2X_DENM(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X_DENM(iChannel,pckType,iPhyRaw) + Nerrors_DENM;
            outputValues.NerrorsCV2X_CAM(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X_CAM(iChannel,pckType,iPhyRaw) + Nerrors_CAM;
            outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) = outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) + Nerrors;
        %end
    %end
    
    % Number of correctly transmitted beacons
    %for iChannel = 1:phyParams.nChannels
        %for pckType = 1:appParams.nPckTypes
            %NcorrectlyTxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),1));
            NcorrectlyTxBeacons = length(correctRxList( (stationManagement.pckType(correctRxList(:,1))==pckType & stationManagement.vehicleChannel(correctRxList(:,1))==iChannel),1));

            % NcorrectlyTxBeacons1 = length(correctRxList1( (stationManagement.pckType(correctRxList1(:,1))==pckType & stationManagement.vehicleChannel(correctRxList1(:,1))==iChannel),1));
            % NcorrectlyTxBeacons2 = length(correctRxList2( (stationManagement.pckType(correctRxList2(:,1))==pckType & stationManagement.vehicleChannel(correctRxList2(:,1))==iChannel),1));
            % NcorrectlyTxBeacons3 = length(correctRxList3( (stationManagement.pckType(correctRxList3(:,1))==pckType & stationManagement.vehicleChannel(correctRxList3(:,1))==iChannel),1));
            % NcorrectlyTxBeacons4 = length(correctRxList4( (stationManagement.pckType(correctRxList4(:,1))==pckType & stationManagement.vehicleChannel(correctRxList4(:,1))==iChannel),1));
            % NcorrectlyTxBeacons5 = length(correctRxList5( (stationManagement.pckType(correctRxList5(:,1))==pckType & stationManagement.vehicleChannel(correctRxList5(:,1))==iChannel),1));
            % NcorrectlyTxBeacons6 = length(correctRxList6( (stationManagement.pckType(correctRxList6(:,1))==pckType & stationManagement.vehicleChannel(correctRxList6(:,1))==iChannel),1));
            % NcorrectlyTxBeacons7 = length(correctRxList7( (stationManagement.pckType(correctRxList7(:,1))==pckType & stationManagement.vehicleChannel(correctRxList7(:,1))==iChannel),1));
            % NcorrectlyTxBeacons8 = length(correctRxList8( (stationManagement.pckType(correctRxList8(:,1))==pckType & stationManagement.vehicleChannel(correctRxList8(:,1))==iChannel),1));
            % NcorrectlyTxBeacons9 = length(correctRxList9( (stationManagement.pckType(correctRxList9(:,1))==pckType & stationManagement.vehicleChannel(correctRxList9(:,1))==iChannel),1));

            NcorrectlyTxBeacons_DENM = length(correctRxList_DENM( (stationManagement.pckType(correctRxList_DENM(:,1))==pckType & stationManagement.vehicleChannel(correctRxList_DENM(:,1))==iChannel),1));
            NcorrectlyTxBeacons_CAM = length(correctRxList_CAM( (stationManagement.pckType(correctRxList_CAM(:,1))==pckType & stationManagement.vehicleChannel(correctRxList_CAM(:,1))==iChannel),1));
            outputValues.NcorrectlyTxBeaconsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;

            % outputValues.NcorrectlyTxBeaconsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X1(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons1;
            % outputValues.NcorrectlyTxBeaconsCV2X2(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X2(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons2;
            % outputValues.NcorrectlyTxBeaconsCV2X3(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X3(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons3;
            % outputValues.NcorrectlyTxBeaconsCV2X4(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X4(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons4;
            % outputValues.NcorrectlyTxBeaconsCV2X5(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X5(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons5;
            % outputValues.NcorrectlyTxBeaconsCV2X6(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X6(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons6;
            % outputValues.NcorrectlyTxBeaconsCV2X7(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X7(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons7;
            % outputValues.NcorrectlyTxBeaconsCV2X8(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X8(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons8;
            % outputValues.NcorrectlyTxBeaconsCV2X9(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X9(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons9;

            outputValues.NcorrectlyTxBeaconsCV2X_DENM(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X_DENM(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons_DENM;
            outputValues.NcorrectlyTxBeaconsCV2X_CAM(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X_CAM(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons_CAM;
            outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;
    %    end
    %end
    
    % Number of transmitted beacons
    %for iChannel = 1:phyParams.nChannels
        %for pckType = 1:appParams.nPckTypes
            %NtxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),3));
            NtxBeacons = Nerrors + NcorrectlyTxBeacons;

            % NtxBeacons1 = Nerrors1 + NcorrectlyTxBeacons1;
            % NtxBeacons2 = Nerrors2 + NcorrectlyTxBeacons2;
            % NtxBeacons3 = Nerrors3 + NcorrectlyTxBeacons3;
            % NtxBeacons4 = Nerrors4 + NcorrectlyTxBeacons4;
            % NtxBeacons5 = Nerrors5 + NcorrectlyTxBeacons5;
            % NtxBeacons6 = Nerrors6 + NcorrectlyTxBeacons6;
            % NtxBeacons7 = Nerrors7 + NcorrectlyTxBeacons7;
            % NtxBeacons8 = Nerrors8 + NcorrectlyTxBeacons8;
            % NtxBeacons9 = Nerrors9 + NcorrectlyTxBeacons9;

            NtxBeacons_DENM = Nerrors_DENM + NcorrectlyTxBeacons_DENM;
            NtxBeacons_CAM = Nerrors_CAM + NcorrectlyTxBeacons_CAM;
            outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) + NtxBeacons;

            % outputValues.NtxBeaconsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X1(iChannel,pckType,iPhyRaw) + NtxBeacons1;
            % outputValues.NtxBeaconsCV2X2(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X2(iChannel,pckType,iPhyRaw) + NtxBeacons2;
            % outputValues.NtxBeaconsCV2X3(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X3(iChannel,pckType,iPhyRaw) + NtxBeacons3;
            % outputValues.NtxBeaconsCV2X4(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X4(iChannel,pckType,iPhyRaw) + NtxBeacons4;
            % outputValues.NtxBeaconsCV2X5(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X5(iChannel,pckType,iPhyRaw) + NtxBeacons5;
            % outputValues.NtxBeaconsCV2X6(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X6(iChannel,pckType,iPhyRaw) + NtxBeacons6;
            % outputValues.NtxBeaconsCV2X7(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X7(iChannel,pckType,iPhyRaw) + NtxBeacons7;
            % outputValues.NtxBeaconsCV2X8(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X8(iChannel,pckType,iPhyRaw) + NtxBeacons8;
            % outputValues.NtxBeaconsCV2X9(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X9(iChannel,pckType,iPhyRaw) + NtxBeacons9;

            outputValues.NtxBeaconsCV2X_DENM(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X_DENM(iChannel,pckType,iPhyRaw) + NtxBeacons_DENM;
            outputValues.NtxBeaconsCV2X_CAM(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X_CAM(iChannel,pckType,iPhyRaw) + NtxBeacons_CAM;
            outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) + NtxBeacons;
        end
    end
    
    % Compute update delay (if enabled)
    if outParams.printUpdateDelay
        %[simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X] = countUpdateDelay(stationManagement,iPhyRaw,activeIDsTXLTE,indexInActiveIDsOnlyLTE,stationManagement.BRid,appParams.NbeaconsF,awarenessID_LTE(:,:,iPhyRaw),errorMatrix,timeManagement.timeNow,simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X,outParams.delayResolution,outParams.enableUpdateDelayHD);
        [simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X] = countUpdateDelay(stationManagement,iPhyRaw,activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList,correctRxList_DENM,correctRxList_CAM,timeManagement.timeNow,simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X,outParams.delayResolution,simValues);
    end

    % Compute data age (if enabled)
    if outParams.printDataAge
        %[simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X] = countDataAge(stationManagement,iPhyRaw,timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,stationManagement.BRid,appParams.NbeaconsF,awarenessID_LTE(:,:,iPhyRaw),errorMatrix,timeManagement.timeNow,simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X,outParams.delayResolution,appParams);
        [simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X] = countDataAge(stationManagement,iPhyRaw,timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList,timeManagement.timeNow,simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X,outParams.delayResolution,simValues);
    end

    % Compute packet delay (if enabled)
    if outParams.printPacketDelay
        outputValues.packetDelayCounterCV2X = countPacketDelay(stationManagement,iPhyRaw,activeIDsTXLTE,timeManagement.timeNow,timeManagement.timeGeneratedPacketInTxLTE,correctRxList,outputValues.packetDelayCounterCV2X,outParams.delayResolution);
    end

    % Compute power control allocation (if enabled)
    if outParams.printPowerControl
        error('Output not updated in v5');
        %   % Convert linear PtxERP values to Ptx in dBm
        %	Ptx_dBm = 10*log10((phyParams.PtxERP_RB*appParams.RBsBeacon)/(2*phyParams.Gt))+30;
        %	outputValues.powerControlCounter = countPowerControl(IDvehicleTX,Ptx_dBm,outputValues.powerControlCounter,outParams.powerResolution);
    end

    % Update matrices needed for PRRmap creation in urban scenarios (if enabled)
    if simParams.typeOfScenario==constants.SCENARIO_TRACE && outParams.printPRRmap
        simValues = counterMap(iPhyRaw,simValues,stationManagement.activeIDsCV2X,indexInActiveIDsOnlyLTE,activeIDsTXLTE,awarenessID_LTE(:,:,iPhyRaw),errorMatrix);
    end

end
% a=0;
% for iPhyRaw = 1:length(phyParams.cbr)
%     % From v 5.4.14
%     %errorMatrix = errorMatrixRawMax(errorMatrixRawMax(:,4)<phyParams.Raw(iPhyRaw),:);
%     correctRxList1(:,:,iPhyRaw) = fateRxListRawMax((a<fateRxListRawMax(:,6)&fateRxListRawMax(:,6)<phyParams.cbr(iPhyRaw)) & fateRxListRawMax(:,5)==1,:);
%     errorRxList1(:,:,iPhyRaw) = fateRxListRawMax((a<fateRxListRawMax(:,6)&fateRxListRawMax(:,6)<phyParams.cbr(iPhyRaw)) & fateRxListRawMax(:,5)==0,:);
%     a = a + 0.1;
%     % Number of errors
%     for iChannel = 1:phyParams.nChannels
%         for pckType = 1:appParams.nPckTypes
%             %Nerrors = length(errorMatrix( (stationManagement.pckType(errorMatrix(:,1))==pckType & stationManagement.vehicleChannel(errorMatrix(:,1))==iChannel),1));
%             %Nerrors = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),2));
%             Nerrors1 = length(errorRxList1( (stationManagement.pckType(errorRxList1(:,1))==pckType & stationManagement.vehicleChannel(errorRxList1(:,1))==iChannel),1));
%             outputValues.NerrorsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X1(iChannel,pckType,iPhyRaw) + Nerrors1;
%         %end
%     %end
% 
%     % Number of correctly transmitted beacons
%     %for iChannel = 1:phyParams.nChannels
%         %for pckType = 1:appParams.nPckTypes
%             %NcorrectlyTxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),1));
%             NcorrectlyTxBeacons1 = length(correctRxList1( (stationManagement.pckType(correctRxList1(:,1))==pckType & stationManagement.vehicleChannel(correctRxList1(:,1))==iChannel),1));
%             outputValues.NcorrectlyTxBeaconsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X1(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons1;
%     %    end
%     %end
% 
%     % Number of transmitted beacons
%     %for iChannel = 1:phyParams.nChannels
%         %for pckType = 1:appParams.nPckTypes
%             %NtxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),3));
%             NtxBeacons1 = Nerrors1 + NcorrectlyTxBeacons1;
%             outputValues.NtxBeaconsCV2X1(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X1(iChannel,pckType,iPhyRaw) + NtxBeacons1;
%         end
%     end
% end
% Count distance details for distances up to the maximum awareness range (if enabled)
if outParams.printPacketReceptionRatio
    %outputValues.distanceDetailsCounterCV2X = countDistanceDetails(indexInActiveIDsOnlyLTE,activeIDsTXLTE,neighborsID_LTE,stationManagement.neighborsDistanceLTE,errorMatrixRawMax,outputValues.distanceDetailsCounterCV2X,stationManagement,outParams,appParams,phyParams);
    outputValues.distanceDetailsCounterCV2X = countDistanceDetails(fateRxListRawMax(fateRxListRawMax(:,5)==1,:),fateRxListRawMax(fateRxListRawMax(:,5)==0,:),outputValues.distanceDetailsCounterCV2X,stationManagement,outParams,appParams,phyParams);
end