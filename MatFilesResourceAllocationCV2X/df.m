function [timeManagement,stationManagement,sinrManagement,Nreassign,simValues,expManagement,Agents,Episodes,Critics,TargetCritics,Buffer] = BRreassignment3GPPautonomous(timeManagement,stationManagement,positionManagement,sinrManagement,simParams,phyParams,appParams,outParams,simValues,...
    expManagement,Agents,Episodes,EpisodesVector,Critics,TargetCritics,Buffer,Epsilons,obsInfo,actInfo,trainingMode,sharingReplay,criticOpts,outputValues)
% Sensing-based autonomous resource reselection algorithm (3GPP MODE 4)
% as from 3GPP TS 36.321 and TS 36.213
% Resources are allocated for a Resource Reselection Period (SPS)
% Sensing is performed in the last 1 second
% Map of the received power and selection of the best 20% transmission hypothesis
% Random selection of one of the M best candidates
% The selection is rescheduled after a random period, with random
% probability controlled by the input parameter 'probResKeep'

% Starting from version 5.6.1 also 5G-Mode2 is supported

% Number of TTIs per beacon period
NbeaconsT = appParams.NbeaconsT;
% Number of possible beacon resources in one TTI
NbeaconsF = appParams.NbeaconsF;
% Number of beacons per beacon period
Nbeacons = NbeaconsT*NbeaconsF;

% Calculate current T within the NbeaconsT
currentT = mod(timeManagement.elapsedTime_TTIs-1,NbeaconsT)+1; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIRST PART is checking the stations that need reselection

% LTE vehicles that are active
activeIDsCV2X = stationManagement.activeIDsCV2X;

% 1: check if a reselection is commanded by the PHY layer - i.e., in the case 
% the resource is not available in the interval T1-T2
% 2: check if (a) the reselection counter reaches one and (b) reselection is
% commanded depending on p_keep


%% 1 - check reallocation commanded due to non available resource
%% Focusing on all transmissions (including replicas)
subframeNextResource = ceil(stationManagement.BRid/appParams.NbeaconsF);
subframesToNextAlloc = zeros(length(stationManagement.BRid(:,1)),phyParams.cv2xNumberOfReplicasMax);
allConditionsMet = false(length(activeIDsCV2X),phyParams.cv2xNumberOfReplicasMax); 
resourceReEvaluationConditionMet = false(length(activeIDsCV2X),1);
B = zeros(length(activeIDsCV2X),1);
B_DENM = zeros(length(activeIDsCV2X),1);
B_DENM2 = zeros(length(activeIDsCV2X),1);
B_DENM3 = zeros(length(activeIDsCV2X),1);
C = zeros(length(activeIDsCV2X),1);
C_DENM = zeros(length(activeIDsCV2X),1);
C_DENM2 = zeros(length(activeIDsCV2X),1);
C_DENM3 = zeros(length(activeIDsCV2X),1);
D = zeros(length(activeIDsCV2X),1);
D2 = zeros(length(activeIDsCV2X),1);
Y = 0;
for j=1:phyParams.cv2xNumberOfReplicasMax    
    subframesToNextAlloc(:,j) = (subframeNextResource(:,j)>currentT).*(subframeNextResource(:,j)-currentT)+(subframeNextResource(:,j)<=currentT).*(subframeNextResource(:,j)+appParams.NbeaconsT-currentT);
    % A means this replica ('j') is allowed by 'cv2xNumberOfReplicas'
    A = stationManagement.cv2xNumberOfReplicas(activeIDsCV2X) >= j;
    for i = 1 : simValues.maxID
        if stationManagement.DENM_pck(i) == 1
            if j == 1
                % B means that there is a resource allocated
                B_DENM(i,1) = stationManagement.BRid(i,j)>0;
            elseif j == 2 && stationManagement.cv2xNumberOfReplicas(i) > 1
                B_DENM2(i,1) = stationManagement.BRid(i,j)>0;
            elseif j == 3 && stationManagement.cv2xNumberOfReplicas(i) > 2
                B_DENM3(i,1) = stationManagement.BRid(i,j)>0;
            end
        else
            B(i,1) = stationManagement.BRid(i,1)>0;
        end
    end
    for i = 1 : simValues.maxID
        if simParams.Priority_SPS == true
            if stationManagement.DENM_pck(i) == 1
                if j == 1
                    C_DENM(i,1) = (subframesToNextAlloc(i,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,j)>simParams.T2autonomousModeTTIs_min);
                elseif j == 2
                    C_DENM2(i,1) = (subframesToNextAlloc(i,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,j)>simParams.T2autonomousModeTTIs_min);
                end
            elseif stationManagement.DENM_pck(i) ~= 1
                % C means that the resource is ouside T1,T2
                C(i,1) = (subframesToNextAlloc(i,1) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,1)>simParams.T2autonomousModeTTIs);
            end
        elseif simParams.Priority_SPS == false
            if stationManagement.DENM_pck(i) == 1
                if j == 1
                    C_DENM(i,1) = (subframesToNextAlloc(i,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,j)>simParams.T2autonomousModeTTIs);
                elseif j == 2 && stationManagement.cv2xNumberOfReplicas(i) > 1
                    C_DENM2(i,1) = (subframesToNextAlloc(i,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,j)>simParams.T2autonomousModeTTIs);
                elseif j == 3 && stationManagement.cv2xNumberOfReplicas(i) > 2
                    C_DENM3(i,1) = (subframesToNextAlloc(i,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,j)>simParams.T2autonomousModeTTIs);
                end
            elseif stationManagement.DENM_pck(i) ~= 1
                % C means that the resource is ouside T1,T2
                C(i,1) = (subframesToNextAlloc(i,1) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(i,1)>simParams.T2autonomousModeTTIs);
            end
        end
    end
    % D means that resource of replica j comes after that of replica j-1 (not allowed and reselection commanded)
    if j>1
        for i = 1 : simValues.maxID
            if stationManagement.DENM_pck(i) == 1 && stationManagement.cv2xNumberOfReplicas(i) > 1
                D(i,1) = subframesToNextAlloc(i,j) < subframesToNextAlloc(i,j-1); % 다음 자원 할당 시간이 j번째 할당 시간보다 느린가?
            elseif stationManagement.DENM_pck(i) == 1 && stationManagement.cv2xNumberOfReplicas(i) > 2
                D2(i,1) = subframesToNextAlloc(i,j) < subframesToNextAlloc(i,j-1);
            end
        end
    else
        % E means that the user need to perform resource re-evaluation
        % debug for coexistence scenario
        E= subframesToNextAlloc(activeIDsCV2X,1)==3 & stationManagement.newDataIndicator(activeIDsCV2X) & stationManagement.pckBuffer(activeIDsCV2X) *(simParams.resourceReEvaluation);
        if find(B_DENM|B_DENM2)
            resourceReEvaluationConditionMet = A & (B|B_DENM|B_DENM2|B_DENM3) & E ;
        else
            resourceReEvaluationConditionMet = A & B & E ;
        end
        % if find(resourceReEvaluationConditionMet)
        %     disp(1)
        % end
    end

    % 결과 통합 행렬 초기화
    C_combined = zeros(length(activeIDsCV2X), 1);
    
    % C, C_DENM, C_DENM2의 값을 통합
    C_combined = C | C_DENM | C_DENM2 | C_DENM3;
    
    % 결과 통합 행렬 초기화
    B_combined = zeros(length(activeIDsCV2X), 1);

    % B, B_DENM, B_DENM2의 값을 통합
    B_combined = B | B_DENM | B_DENM2 | B_DENM3;

    allConditionsMet(:,j) = A & B_combined & (C_combined | D | D2);
end


% hasNewPacketThisTbeacon checks if any new packets were generated in this slot
hasNewPacketThisTbeacon = (timeManagement.timeLastPacket(activeIDsCV2X) > (timeManagement.timeNow-phyParams.TTI-1e-8));
% if hasNewPacketThisTbeacon(3) == 1;
%     disp(1)
% end

hasFirstResourceThisTbeacon = (subframeNextResource(activeIDsCV2X,1)==currentT);% 첫번째 전송
% hasSecondResourceThisTbeacon = (subframeNextResource(activeIDsCV2X,phyParams.cv2xNumberOfReplicasMax)==currentT);% 두번째 전송
% if stationManagement.cv2xNumberOfReplicas(hasSecondResourceThisTbeacon == 1) == 2
%     hasFirstTransmissionThisSlot= (hasFirstResourceThisTbeacon | hasSecondResourceThisTbeacon) & stationManagement.hasTransmissionThisSlot;
% else
%     hasFirstTransmissionThisSlot= (hasFirstResourceThisTbeacon) & stationManagement.hasTransmissionThisSlot;
% end
hasFirstTransmissionThisSlot= (hasFirstResourceThisTbeacon) & stationManagement.hasTransmissionThisSlot;
% The operand 'any' implies that if any replica is outside T1, T2, then a reallocation is performed
scheduledID_PHY = activeIDsCV2X(hasNewPacketThisTbeacon & any(allConditionsMet,2));
scheduledID_PHY(timeManagement.timeLastPacket(scheduledID_PHY)<0) = [];
% if find(scheduledID_PHY)
%     disp(1)
% end
% Following line for debug purposes - allows to remove PHY commanded reallocations
%scheduledID_PHY = [];

% When resource re-evaluation is active scheduledID_ReEval contains the IDs of vehicles performing the re-evaluation.
% The re-evaluation is performed at time t-T3 before the transmission in any UN-RESERVED resource. 
% The re-evaluation is performed before the first transmission.
% It also evaluates if any of the future retransmissions has been reserved by another user.
% Later possible collisions on the retransmissions are not checked.
%% TODO: re-evaluation is always performed 3 slots before transmission: it should be parametric -> define T3 in seconds then converted in slots
scheduledID_ReEval = activeIDsCV2X(resourceReEvaluationConditionMet);
scheduledID_ReEval(timeManagement.timeLastPacket(scheduledID_ReEval)<0) = []; % re-evaluation initially disabled



%% 2a - reselection counter to 1
% Evaluates which vehicles have the counter reaching one

% Update resReselectionCounter
% Reduce the counter by one to all UEs that have the first packet TRANSMITTED in this slot
% if find(hasNewPacketThisTbeacon(1)==1)
%     if stationManagement.BRid(1) == 86
%         disp(1)
%     end
% end
stationManagement.resReselectionCounterCV2X(activeIDsCV2X) = stationManagement.resReselectionCounterCV2X(activeIDsCV2X)-hasFirstTransmissionThisSlot;

% reset newDataIndicator for user who transmitted the first initial transmission
stationManagement.newDataIndicator(activeIDsCV2X(hasFirstTransmissionThisSlot)) = 0;

%% 2b - p_keep check
% Vehicles that have reached RC=1 need to evaluate if they will perform the reselection. 
% In case they don't need to select a new resource, they update the RC before it reaches 0. 
% In case UEs need to perform reselection, the reselection is  done at the next packet arrival 
% and the last transmission before the resource change, doesn't reserve any resource 
% (simulating the event of a transmission with RRI=0)


% Detects the UEs transmitting in this slot whose RC has reached 1
keepCheck_MAC = activeIDsCV2X( hasFirstTransmissionThisSlot & (stationManagement.resReselectionCounterCV2X(activeIDsCV2X)==1));

updateCounter_MAC =[];
if simParams.probResKeep>0
    keepRand = rand(1,length(keepCheck_MAC));
    % Update the vehicles which don't perform reselection and update the RC
    updateCounter_MAC = keepCheck_MAC(keepRand < simParams.probResKeep);
end

if simParams.FDalgorithm==1
    % Increase the nSPS counter by one to all UEs that have a packet transmitted in this slot
    stationManagement.nSPS(activeIDsCV2X) = stationManagement.nSPS(activeIDsCV2X)+hasFirstTransmissionThisSlot;
    % Evaluates the individual Pkeep according to FD-alg1
    stationManagement.probResKeep(keepCheck_MAC)=1-stationManagement.FDcounter(keepCheck_MAC)./stationManagement.nSPS(keepCheck_MAC);
%     stationManagement.probResKeep(keepCheck_MAC(stationManagement.probResKeep(keepCheck_MAC)>0.8))=0.8; % modification: sets pk adaptive to max 0.8
    keepRand = rand(1,length(keepCheck_MAC));
    updateCounter_MAC =[];
    updateCounter_MAC = keepCheck_MAC(keepRand < stationManagement.probResKeep(keepCheck_MAC)');
end


% Sensed power by transmitting nodes in their BR
if phyParams.Ksi < Inf && phyParams.PDelta < Inf
    [stationManagement] = FDaidedReselection(currentT,stationManagement,simParams.FDalgorithm,phyParams,NbeaconsF,hasNewPacketThisTbeacon);
end

% Detects the UEs that need to perform reselection
% The reselection is triggered when RC=0 and the UE has a new packet generated
scheduledID_MAC = activeIDsCV2X( hasNewPacketThisTbeacon & (stationManagement.resReselectionCounterCV2X(activeIDsCV2X)<=0));



%% Calculate and Restart the reselection counter
% 1. For user with the counter reaching zero
% 2. For users with enforced reselection
% 3. For user that need to update the reselection counter instead of reselecting
needReselectionCounterRestart = [scheduledID_PHY;scheduledID_MAC;updateCounter_MAC]; % union removed to speed up coding, there might be repetitions but it's faster
needReselectionCounterRestart = unique(needReselectionCounterRestart);
% if find(scheduledID_PHY)
%     if scheduledID_MAC == scheduledID_PHY
%         needReselectionCounterRestart = [scheduledID_MAC;updateCounter_MAC];
%     end
% end
stationManagement.resReselectionCounterCV2X(needReselectionCounterRestart) = (~simParams.dynamicScheduling)*((simParams.minRandValueMode4-1) + randi((simParams.maxRandValueMode4-simParams.minRandValueMode4)+1,1,length(needReselectionCounterRestart)))'++simParams.dynamicScheduling;

if simParams.FDalgorithm==1 %adaptive pKeep
    % Reset the FD counter for vehicles who perform reselection
    stationManagement.FDcounter(needReselectionCounterRestart) = 0;
    stationManagement.nSPS(needReselectionCounterRestart) = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SECOND PART is performing the reselection
% Merge the scheduled IDs
scheduledID_PHY_MAC = unique(cat(2, [scheduledID_PHY;scheduledID_MAC]));
scheduledID = unique(cat(2, [scheduledID_PHY_MAC;scheduledID_ReEval])); % replace union for improved speed
Nscheduled = length(scheduledID);

% Reset number of successfully reassigned vehicles
Nreassign = 0;
for indexSensingV = 1:Nscheduled

    % Here saves the original BR
    BRidOriginal=stationManagement.BRid(scheduledID(indexSensingV),:);

    % Select the sensing matrix only for those vehicles that perform reallocation
    if simParams.averageSensingActive==true % 4G procedure
        % Calculate the average of the measured power over the sensing window
        sensingMatrixScheduled = sum(stationManagement.sensingMatrixCV2X(:,:,scheduledID(indexSensingV)),1)/size(stationManagement.sensingMatrixCV2X, 1);
        % "sensingMatrixScheduled" is a '1 x NbeaconIntervals' vector
    else %if simParams.mode5G==1 || simParams.averageSensingActive==false
        % Selects only the first row, which includes the slots relative to the last 'averageTbeacon'
        % In 5G the average process is removed and the senging is performed only on the basis of the decoded SCIs.
        sensingMatrixScheduled = stationManagement.sensingMatrixCV2X(1,:,scheduledID(indexSensingV));
    end

    % With intrafrequency coexistence, any coexistence method
    % (simParams.coexMethod==1,2,3,6) might forbid LTE using some TTI,
    % set non LTE TTI as inf
    if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON
        for block = 1:ceil(NbeaconsT/simParams.coex_superframeTTI)
            sensingMatrixScheduled(...
                (block-1)*simParams.coex_superframeTTI*NbeaconsF + ...
                ((sinrManagement.coex_NtotTTILTE(scheduledID(indexSensingV))*NbeaconsF+1):(simParams.coex_superframeTTI*NbeaconsF))...
                ) = inf;
        end            
    end


    % Check T1 and T2 and in case set the subframes that are not acceptable to inf
    % Since the currentT can be at any point of beacon resource matrix,
    % the calculations depend on where T1 and T2 are placed
    % Since version 6.2 it considers startingT which is the time at which
    % the packet is/was generated, as re-evaluation is possible
    timeStartingT = timeManagement.timeLastPacket(scheduledID(indexSensingV));
    startingT = mod(floor((timeStartingT)/phyParams.TTI),NbeaconsT)+1; 
    % IF Both T1 and T2 are within this beacon period
    if simParams.Priority_SPS == true
        if stationManagement.DENM_pck(scheduledID(indexSensingV)) == 1
            if (startingT+simParams.T2autonomousModeTTIs+1)<=NbeaconsT
                sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs_min)*NbeaconsF+1):Nbeacons]) = inf;
                % IF Both are beyond this beacon period
            elseif (startingT+simParams.T1autonomousModeTTIs-1)>NbeaconsT
                sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1-NbeaconsT)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs_min-NbeaconsT)*NbeaconsF+1):Nbeacons]) = inf;
                % IF T1 within, T2 beyond
            else
                sensingMatrixScheduled(((startingT+simParams.T2autonomousModeTTIs_min-NbeaconsT)*NbeaconsF+1):((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF)) = inf;
            end
        elseif stationManagement.DENM_pck(scheduledID(indexSensingV)) ~= 1
            if (startingT+simParams.T2autonomousModeTTIs+1)<=NbeaconsT
                sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs)*NbeaconsF+1):Nbeacons]) = inf;
                % IF Both are beyond this beacon period
            elseif (startingT+simParams.T1autonomousModeTTIs-1)>NbeaconsT
                sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1-NbeaconsT)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):Nbeacons]) = inf;
                % IF T1 within, T2 beyond
            else
                sensingMatrixScheduled(((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF)) = inf;
            end
        end
        
    elseif simParams.Priority_SPS == false
        if (startingT+simParams.T2autonomousModeTTIs+1)<=NbeaconsT
            sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs)*NbeaconsF+1):Nbeacons]) = inf;
            % IF Both are beyond this beacon period
        elseif (startingT+simParams.T1autonomousModeTTIs-1)>NbeaconsT
            sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1-NbeaconsT)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):Nbeacons]) = inf;
            % IF T1 within, T2 beyond
        else
            sensingMatrixScheduled(((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF)) = inf;
        end
    end
    % Conditions for re-evaluation
    % When re-evaluation is considered currentT and startingT can be different
    % T1 and T2 must be considered with respect to the time at which the re-evaluated packet WAS generated
    %% NB: These conditions might be compressed and included with the other
    if currentT>startingT % Both currentT and startingT within this beacon period
        sensingMatrixScheduled((startingT*NbeaconsF):(currentT*NbeaconsF)) = inf;
    elseif currentT<startingT % currentT is in the next beacon period
        sensingMatrixScheduled([1:(currentT*NbeaconsF),(startingT*NbeaconsF):Nbeacons]) = inf;
    end

    % The best 20% (parameter that can be changed) is selected inside the pool as in TS 36.213
    % The pool of available resources is obtained as those that are not set to infty

    % The pool of available resources is obtained as those that are not set
    % to infty -> resources discard due to HD and due to T1,T2 costraints
    % Then, the resource above threshold are discarded to build the selection set
    % The remaining resources must be at least X% of the nPossibleAllocations
    nPossibleAllocations = sum(isfinite(sensingMatrixScheduled));
    MBest = ceil(nPossibleAllocations * simParams.ratioSelectedAutonomousMode);     % minimum number of resources that must be in the selection set
    if MBest<=0
        if simParams.resourceReEvaluation == true
            continue    % when resource re-eval is active, if the re-eval is performed on a resource at the end of the T1-T2, there is no resource available -> maintains current transmission
        end
        error('Mbest must be a positive scalar (it is %d)',MBest);
    end

    % The knownUsedMatrix of the scheduled users is obtained
    knownUsedMatrixScheduled = stationManagement.knownUsedMatrixCV2X(:,scheduledID(indexSensingV))';

    % Create random permutation of the column indexes of sensingMatrix in
    % order to avoid the ascending order on the indexes of cells with the
    % same value (sort effect) -> minimize the probability of choosing the same resource
    rpMatrix = randperm(Nbeacons);

    % Build matrix made of random permutations of the column indexes
    % Permute sensing matrix
    sensingMatrixPerm = sensingMatrixScheduled(rpMatrix);
    knownUsedMatrixPerm = knownUsedMatrixScheduled(rpMatrix);
    % Remove resources from the selection set taking into account the threshold on RSRP
    % Please note that the sensed power is on a per MHz resource basis,
    % whereas simParams.powerThresholdAutonomous is on a resource element (15 kHz) basis
    % The remaining resources must be at least X% of the nPossibleAllocations
    % The cycle is stopped internally; a max of 100 is used to avoid infinite loops in case of bugs
    powerThreshold = simParams.powerThresholdAutonomous;    % threshold for excluding resources
    while powerThreshold < 100
        % If the number of acceptable BRs is lower than MBest,
        % powerThreshold is increased by 3 dB
        usableBRs = ((sensingMatrixPerm*0.015)<powerThreshold) | ((sensingMatrixPerm<inf) & (knownUsedMatrixPerm<1));
        if sum(usableBRs) < MBest
            powerThreshold = powerThreshold * 2;
        else
            break;
        end
    end
    
    % To mark unacceptable RB as occupied, their power is set to Inf
    sensingMatrixPerm = sensingMatrixPerm + (1-usableBRs) * max(phyParams.P_ERP_MHz_CV2X);
    
    % Sort sensingMatrix in ascending order
    [~, bestBRPerm] = sort(sensingMatrixPerm);

    % Reorder bestBRid matrix
    bestBR = rpMatrix(bestBRPerm);
    if stationManagement.DENM_pck(scheduledID(indexSensingV)) == 1
        stationManagement.PDR(scheduledID(indexSensingV)) = (stationManagement.PDR_suc(scheduledID(indexSensingV)) / (stationManagement.PDR_suc(scheduledID(indexSensingV)) + stationManagement.PDR_fai(scheduledID(indexSensingV)))) * 100;
%         [row,~] = find(sinrManagement.cumulativeSINR(:,scheduledID(indexSensingV)) ~= 0);
%         b = 0;
%         for i = 1 : length(row)
%             a = row(i);
%             b = b + (sinrManagement.cumulativeSINR(a,scheduledID(indexSensingV)) - stationManagement.sinrThreshold);
%         end
%         sinr = b / length(row);
%         sinr = sinr / 1000;

        stationManagement.PDR_num = stationManagement.PDR_num + 1;
        expManagement.reward(scheduledID(indexSensingV),1) = stationManagement.PDR(scheduledID(indexSensingV));
        stationManagement.PDR_suc(scheduledID(indexSensingV)) = 0;
        stationManagement.PDR_fai(scheduledID(indexSensingV)) = 0;
%         expManagement.reward(scheduledID(indexSensingV),1) = stationManagement.PDR(scheduledID(indexSensingV)) - abs(sinr);
%         totalPDR = (outputValues.NcorrectlyTxBeaconsCV2X(:,:,7) / outputValues.NtxBeaconsCV2X(:,:,7))*100;
%         camPDR = (outputValues.NcorrectlyTxBeaconsCV2X_CAM(:,:,7) / outputValues.NtxBeaconsCV2X_CAM(:,:,7))*100;
%         denmPDR = (outputValues.NcorrectlyTxBeaconsCV2X_DENM(:,:,7) / outputValues.NtxBeaconsCV2X_DENM(:,:,7))*100;
%         expManagement.reward(scheduledID(indexSensingV),1) = (0.6 * denmPDR) + (0.4 * camPDR);
        
        if expManagement.reward(scheduledID(indexSensingV),1) ~=0 & any(expManagement.obs(scheduledID(indexSensingV),:)~=0)
            expManagement.obs(scheduledID(indexSensingV),:) = 0;
        end
        
        obs = sensingMatrixPerm;

        if expManagement.reward(scheduledID(indexSensingV),1) ~= 0 & any(expManagement.previousObs(scheduledID(indexSensingV),:)~=0)
            next_obs = obs;

            expManagement.nextobs(scheduledID(indexSensingV),:) = next_obs;

            exp = {{expManagement.previousObs(scheduledID(indexSensingV),:)},expManagement.action(scheduledID(indexSensingV),:),expManagement.reward(scheduledID(indexSensingV),1),{expManagement.nextobs(scheduledID(indexSensingV),:)},expManagement.isdone(scheduledID(indexSensingV),1)};
            expManagement.exp(scheduledID(indexSensingV),:) = exp(1,:);


            if any(expManagement.previousObs(scheduledID(indexSensingV),:)>= 0)
                expManagement.savingExp(scheduledID(indexSensingV),:) = exp(1,:);

                if sharingReplay
                    %rewardBuffer(outputValues.stepCt,Nscheduled) = expManagement.reward(Nscheduled,1);
                    %append(Agents(Nscheduled).agent.ExperienceBuffer,{exp});
                    append(Buffer,{exp});

                end
            end

            Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.CumulativeReward = Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.CumulativeReward + (expManagement.reward(scheduledID(indexSensingV),1));
            Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.StepsTaken = Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.StepsTaken + 1;

            if trainingMode

                %     if Agents(1,ix).agent.ExperienceBuffer.Length < Agents(1,ix).agent.AgentOptions.MiniBatchSize
                %         batchSize = min(Agents(1,ix).agent.ExperienceBuffer.Length,maxStepsPerEpisode);
                %     else
                %         batchSize = min(Agents(1,ix).agent.AgentOptions.MiniBatchSize,maxStepsPerEpisode);
                %     end
                BufferLength = Buffer.Length;  %Agents(Nscheduled).agent.ExperienceBuffer.Length ;

                if  BufferLength > 256
                    if BufferLength < 256
                        batchSize = BufferLength;
                    else
                        batchSize = 256;
                    end

                    %     observationBatch = observationBuffer(:,:,1:batchSize);
                    %     actionBatch = actionBuffer(:,:,1:batchSize);
                    %     rewardBatch = rewardBuffer(:,1:batchSize);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%zzzzzzzzz
                    miniBatch = createSampledExperienceMiniBatch(Buffer,...
                        batchSize,...
                        Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.DiscountFactor,Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.NumStepsToLookAhead);

                    %Compute the discounted future reward.
                    %                             discountedReturn = zeros(1,batchSize);
                    %                             for t = 1:batchSize
                    %                                 G = 0;
                    %                                 for k = t:batchSize
                    %                                     G = G + discountFactor ^ (k-t) * miniBatch{3}(k);
                    %                                 end
                    %                                 discountedReturn(t) = G;
                    %                             end
                    %
                    %5. Organize data to pass to the loss function.
                    if Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.UseDoubleDQN
                        % DoubleDQN: r + DiscountFactor*Q[s',a' = argmax(qNetwork(s'))]
                        TargetCriticLocal = Critics(1,scheduledID(indexSensingV)).critic;

                    else
                        % DQN:       r + DiscountFactor*Qtarget[s',a' = argmax(targetNetwork(s'))]
                        TargetCriticLocal = TargetCritics(1,scheduledID(indexSensingV)).critic;

                        %     LossVariable.TargetCritic = updateTarget(1,critic,LossVariable.TargetCritic,...
                        %     agent.AgentOptions.TargetSmoothFactor,...
                        %     agent.AgentOptions.TargetUpdateFrequency);
                        %        LossVariable.TargetCritic = updateTargetRepresentations(LossVariable.TargetCritic);

                    end

                    % unpack experience

                    Reward          = miniBatch{3};
                    NextObservation = miniBatch{4};
                    DoneIdx         = miniBatch{5} == 1;
                    Discount        = Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.DiscountFactor ^ ...
                        Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.NumStepsToLookAhead;


                    TargetQValues = getMaxQValue(TargetCriticLocal, NextObservation);
                    TargetQValues(~DoneIdx) = Reward(~DoneIdx) + ...
                        Discount.*TargetQValues(~DoneIdx);

                    % for terminal step, use the immediate reward (no more next state)
                    TargetQValues(DoneIdx) = Reward(DoneIdx);

                    % build loss variable struct
                    LossVariable.obs           = miniBatch{1};
                    LossVariable.Action        = miniBatch{2};
                    LossVariable.ActionInfo    = Critics(1,scheduledID(indexSensingV)).critic.ActionInfo;
                    LossVariable.QType         = getQType(TargetCriticLocal); % multioutput
                    LossVariable.UseDevice     = TargetCriticLocal.Options.UseDevice; % CPU
                    LossVariable.TargetQValues = TargetQValues; % 256 batch maxQ values
                    % 6. Compute the gradient of the loss with respect to the policy
                    % parameters.
                    %     CriticGradient = gradient(Critics(1,ix).critic,'loss-parameters',...
                    %         [miniBatch{1},miniBatch{2}], LossVariable);
                    if strcmpi(getQType(Critics(1,scheduledID(indexSensingV)).critic),'singleOutput')
                        CriticGradient = gradient(Critics(1,scheduledID(indexSensingV)).critic,'loss-parameters',...
                            [miniBatch{1},LossVariable.Action], LossVariable);
                    else
                        CriticGradient = gradient(Critics(1,scheduledID(indexSensingV)).critic,'loss-parameters',...
                                miniBatch{1}, LossVariable);
%                         AccelCriticGradFcn = dlaccelerate(@deepCriticGradient);
%                         criticGradient = dlfeval(AccelCriticGradFcn,...
%                             Critics(1, scheduledID(indexSensingV)).critic,LossVariable.obs,LossVariable.Action,LossVariable.TargetQValues);
                    end
                    % 7. Update the actor network using the computed gradients.
                    Critics(1,scheduledID(indexSensingV)).critic= optimize(Critics(1,scheduledID(indexSensingV)).critic,CriticGradient);
%                     [Critics(1, scheduledID(indexSensingV)).critic,criticOpts] = update(criticOpts,Critics(1, scheduledID(indexSensingV)).critic,criticGradient);
                    %     TargetCritic = updateTarget(episode,critic,LossVariable.TargetCritic,...
                    %       agent.AgentOptions.TargetSmoothFactor,...
                    %       agent.AgentOptions.TargetUpdateFrequency);


                    if mod( sum(EpisodesVector(1,scheduledID(indexSensingV)).StepsTaken ) + Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.StepsTaken,Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.TargetUpdateFrequency) == 0
                        TargetCritics(1,scheduledID(indexSensingV)).critic = syncParameters(TargetCritics(1,scheduledID(indexSensingV)).critic,Critics(1,scheduledID(indexSensingV)).critic,Agents(1,scheduledID(indexSensingV)).agent.AgentOptions.TargetSmoothFactor);
                        %          expManagement.numtarget(ix, 1) = expManagement.numtarget(ix, 1) + 1;
                    end
                end

            end

        end
     
        [MaxQ,MaxActionIndex] = getMaxQValue(Critics(1,scheduledID(indexSensingV)).critic,{obs});
        if Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.StepsTaken < 1
            Episodes(1,scheduledID(indexSensingV)).EpisodeInfo.Q0 = MaxQ;
        end
        if obs >= 0
%             if (rand < Epsilons(1,scheduledID(indexSensingV))) && trainingMode
%                 action = usample(actInfo,3);
%                 action = action{1};
%             else
%                 if trainingMode
%                     action = getElementValue(actInfo,MaxActionIndex);
%                     %action = getActionWithExploration(Agents(Nscheduled).agent,{obs}); % exploration and exploitation
% 
%                 else % test
%                     action = getAction(Agents(scheduledID(indexSensingV)).agent,{obs});
% 
%                 end
%             end
            if (rand < Epsilons(1, scheduledID(indexSensingV))) && trainingMode
                while true
                    action = usample(actInfo, 1);
                    action = action{1};
                    if length(unique(action)) == 1
                        break;
                    end
                end
            else
                if trainingMode
                    action = getElementValue(actInfo, MaxActionIndex);
                else % test
                    action = getAction(Agents(scheduledID(indexSensingV)).agent, {obs});
                end
            end

            %%%%%%%%%%REWARD%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            expManagement.obs(scheduledID(indexSensingV),:) = obs;
            expManagement.previousObs(scheduledID(indexSensingV),:) = obs;
            expManagement.action(scheduledID(indexSensingV),1) = {action};
        end

        if obs >= 0
            act = expManagement.action(scheduledID(indexSensingV),:);
            % 셀 배열의 값을 추출하여 벡터로 변환
            values = cell2mat(act);
            
            % 값을 오름차순으로 정렬
            act = sort(values);
            stationManagement.BRid(scheduledID(indexSensingV),1) = act(1,1);
%             stationManagement.BRid(scheduledID(indexSensingV),2) = act(1,2);
%             stationManagement.BRid(scheduledID(indexSensingV),3) = act(1,3);
        end
    end
    % L2 is removed in mode2
    % 5G mode2 admits all resources that are not HD or reserved with an
    % RSRP level above threshold, or outside T1-T2. LTE takes the best X%
    if simParams.L2active==false
        MBest=sum(usableBRs);
    end
    
    % Keep the best M canditates
    bestBR = bestBR(1:MBest);

    % Reassign, selecting a random BR among the bestBR
    BRindex = randi(MBest);
    BR = bestBR(BRindex);
%     printDebugReallocation(timeManagement.timeNow,scheduledID(indexSensingV),positionManagement.XvehicleReal(stationManagement.activeIDs==scheduledID(indexSensingV)),'reall',BR,outParams);
    
    % if reEvaluation is active and only one resource need to be reselected, restores the other resource(s)
    % if more than 2 retransmission get developed -> this must be changed
    if simParams.resourceReEvaluation == true
        if sum((scheduledID_ReEval==scheduledID(indexSensingV))==1)
            BRtoChange=~ismember(BRidOriginal,bestBR);
            if sum(BRtoChange)==0
                continue   % exit as both resources are still available
            elseif BRtoChange(1,1)==0
                BR=BRidOriginal(1,1);   % maintains first resource
            elseif BRtoChange(1,2)==0
                BR=BRidOriginal(1,2);   % maintains second resource
            end
        end
    end
    if stationManagement.DENM_pck(scheduledID(indexSensingV)) ~= 1
        % Assign the new selected resource
        stationManagement.BRid(scheduledID(indexSensingV),1)=BR;
        % stationManagement.BRid(scheduledID(indexSensingV),1)=BR;
        Nreassign = Nreassign + 1;
    end

    %% From v 5.4.16
    % Executes HARQ allocation if enabled
    for y = 1 : Nscheduled
%         if stationManagement.cv2xNumberOfReplicas(scheduledID(y)) > 1
%             if phyParams.cv2xNumberOfReplicasMax>1
%                 % Check on max number of retransmissions supported
%                 if phyParams.cv2xNumberOfReplicasMax>3
%                     error('HARQ with more than 1 retransmission not implemented');
%                 end
% 
%                 if simParams.FDalgorithm==5 || simParams.FDalgorithm==6
%                     continue
%                 end
%                 % INPUT:
%                 % currentT is the current subframe in resource grid
%                 % bestBR is the set of best resources passed to MAC
%                 % BR is the resource selected for the first transmission
%                 % THEN: add Nbeacons to all resources before current
% 
%                 bestSubframe = ceil(bestBR/NbeaconsF);
%                 bestSubframe(bestSubframe<=currentT) = bestSubframe(bestSubframe<=currentT) + NbeaconsT;
%                 % identify subframe of BR
%                 subframe_BR = ceil(BR/NbeaconsF);
%                 subframe_BR(subframe_BR<=currentT) = subframe_BR + NbeaconsT;
%                 % remove resources in subframe_x
%                 bestBR(bestSubframe==subframe_BR) = -1;
% 
%                 % remove resources before Now+T1
%                 bestBR(bestSubframe<currentT+simParams.T1autonomousModeTTIs) = -1;
% 
%                 if simParams.mode5G == constants.MODE_LTE
%                     % remove resources before x-15
%                     bestBR(bestSubframe<subframe_BR-15) = -1;
%                 else%if simParams.mode5G==constants.MODE_5G
%                     % remove resources before x-31
%                     bestBR(bestSubframe<subframe_BR-31) = -1;
%                 end
% 
%                 % remove resources after Now+T2
%                 if simParams.Priority_SPS == true
%                     bestBR(bestSubframe>currentT+simParams.T2autonomousModeTTIs_min) = -1;
%                 else
%                     bestBR(bestSubframe>currentT+simParams.T2autonomousModeTTIs) = -1;
%                 end
% 
%                 if simParams.mode5G==constants.MODE_LTE
%                     % remove resources after x+15
%                     bestBR(bestSubframe>subframe_BR+15) = -1;
%                 else% if simParams.mode5G==constants.MODE_5G
%                     % remove resources after x+31
%                     bestBR(bestSubframe>subframe_BR+31) = -1;
%                 end
% 
% 
%                 bestBR(bestBR==-1) = [];
% 
%                 if length(bestBR)>1
%                     % Reassign, selecting a random BR among the remaining bestBR
%                     BRindex2 = randi(length(bestBR));
%                     BR2 = bestBR(BRindex2);
%                     % In case, BR and BR2 might need to be switched
%                     subframe_BR2 = ceil(BR2/NbeaconsF);
%                     subframe_BR2(subframe_BR2<=currentT) = subframe_BR2 + NbeaconsT;
%                     if subframe_BR2 < subframe_BR
%                         stationManagement.BRid(scheduledID(indexSensingV),1) = BR2;
%                         BR2 = BR;
%                         subframe_BR2 = subframe_BR;
%                     end
%                 else
%                     BR2 = -1;
%                 end
%                 stationManagement.BRid(scheduledID(indexSensingV),2) = BR2;
% 
%             end
%         end
%         if stationManagement.cv2xNumberOfReplicas(scheduledID(y)) > 2
%             if length(bestBR)>1
%                 % Reassign, selecting a random BR among the remaining bestBR
%                 BRindex3 = randi(length(bestBR));
%                 BR3 = bestBR(BRindex3);
%                 % In case, BR and BR2 might need to be switched
%                 subframe_BR3 = ceil(BR3/NbeaconsF);
%                 subframe_BR3(subframe_BR3<=currentT) = subframe_BR3 + NbeaconsT;
%                 if subframe_BR3 < subframe_BR2
%                     stationManagement.BRid(scheduledID(indexSensingV),2) = BR3;
%                     BR3 = BR2;
%                     subframe_BR3 = subframe_BR2;
%                 end
%             else
%                 BR3 = -1;
%             end
%             stationManagement.BRid(scheduledID(indexSensingV),3) = BR3;
%         end
    end
    
%% Release 16 3GPP resource re-evaluation
% The vehicles who selected new resources need to set the flag NEW DATA INDICATOR
% Vehicles who performed the re-evaluation do not need to set it, as it is
% already at 1, and it will be decremented after the first transmission
stationManagement.newDataIndicator(activeIDsCV2X(scheduledID_PHY_MAC)) = 1;
% the vehicles who DID NOT transmit in an allocated resource need to set the flag NEW DATA INDICATOR
if simParams.reEvalAfterEmptyResource==true
    % the product between hasFirstResourceThisTbeacon and ~stationManagement.hasTransmissionThisSlot returns one only as a
    % consequence to an allocated resource without a packet to transmit
    stationManagement.newDataIndicator(activeIDsCV2X(hasFirstResourceThisTbeacon & (~stationManagement.hasTransmissionThisSlot))) = 1;
end
% FD function call
if simParams.FDalgorithm==4
    [stationManagement,Nreassign] = FDsingleRetransmissionReselection(timeManagement,stationManagement,positionManagement,simParams,phyParams,outParams,Nreassign,hasNewPacketThisTbeacon,scheduledID,appParams);
end
% FD function call
if simParams.FDalgorithm~= 0 && (simParams.FDalgorithm==5 || simParams.FDalgorithm==6 || simParams.FDalgorithm==7 || simParams.FDalgorithm==8)  % ismember(simParams.FDalgorithm,[5,6,7,8]) replaced for speed
    [stationManagement] = FDtriggeredRetransmission(timeManagement,stationManagement,simParams,phyParams,outParams,appParams);
end
end