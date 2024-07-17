% Simplified scenario to use WilabV2Xsim
% Packet size and MCS are set accordingly to utilize the whole channel
% Each transmission uses all the subchannels available.
% NR-V2X is considered for these simulations

% WiLabV2Xsim('help')

close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

% Configuration file
%configFile = 'Highway3GPP.cfg';

B = 300;
T = 30;
cumulative_reward_vec = [];
episodeCumulativeRewardVector = [];
totalStepCt = 0;
sharingReplay = true;
trainingMode = true;

obsInfo = rlNumericSpec([1 1]);
obsInfo.Name = 'DENM States';
obsInfo.Description = 'RSRP';

drop = [-2, -1, 0];

actInfo = rlFiniteSetSpec(drop);
actInfo.Name = 'DENM action';

numObs = obsInfo.Dimension(1);
numAct = actInfo.Dimension(1);

criticNetwork = [
    featureInputLayer(obsInfo.Dimension(1),'Normalization','none','Name','state')
    fullyConnectedLayer(100,'Name','CriticStateFC1')
    reluLayer('Name','CriticRelu1')
    fullyConnectedLayer(100, 'Name','CriticStateFC2')
    reluLayer('Name','CriticRelu2')
    fullyConnectedLayer(length(actInfo.Elements),'Name','output')];

% criticNetwork = dlnetwork(criticNetwork);

criticOpts = rlRepresentationOptions('LearnRate',0.01,'GradientThreshold',1); %'UseDevice',device);


agentOpts = rlDQNAgentOptions(...
    'UseDoubleDQN',false, ...
    'TargetUpdateMethod',"periodic", ...
    'TargetUpdateFrequency',100, ... % 10000
    'ExperienceBufferLength',100000, ...
    'DiscountFactor',0.99, ...
    'MiniBatchSize',256, ...
    'ResetExperienceBufferBeforeTraining',false,...
    'SaveExperienceBufferWithAgent',true);
agentOpts.EpsilonGreedyExploration.EpsilonDecay = 0.1;

Buffer = rl.util.ExperienceBuffer(agentOpts.ExperienceBufferLength,{[numObs 1]},{[numAct 1]});
Buffer.DoValidate = false;
setSaveMemoryWithBuffer(Buffer,agentOpts.SaveExperienceBufferWithAgent);

numEpisodes = 2000;
%maxStepsPerEpisode = 250; % all vehicles? or per one vehicle?????
aveWindowSize = 100;
trainingTerminationValue = 210; % get 210 reward or larger than this, the episode is over.
%[trainingPlot,lineAvereward] = hBuildFigure;

h = animatedline('MaximumNumPoints',numEpisodes);



for episodesCt = 1:numEpisodes
    % Simulator parameters and initial settings
    % [simParams,appParams,phyParams,outParams] = initiateParameters({'default','Technology','NR-V2X','TypeOfScenario','ETSI-URBAN', ...
    %     'beaconSizeBytes',B,'simulationTime',T,'rho',50,'Nblocks',4,'MCS_NR',7, ...
    %     'vMean',70,'vStDev',3,'Raw',[25 50 75 100 125 150],'printUpdateDelay', true, 'folderPERcurves','PERcurves', 'folderPERcurvesNLOS', 'G5-UrbanNLOS', 'seed', 1});

    % [simParams,appParams,phyParams,outParams] = initiateParameters({'default','Technology','NR-V2X','TypeOfScenario','ETSI-URBAN', ...
    %     'beaconSizeBytes',B,'simulationTime',T,'rho',10,'Nblocks',4,'MCS_NR',7, ...
    %     'vMean',70,'vStDev',3,'Raw',[25 50 75 100 125 150],'printUpdateDelay', true, 'seed', 1});

    [simParams,appParams,phyParams,outParams] = initiateParameters({'default','Technology','NR-V2X','TypeOfScenario','PPP', ...
        'beaconSizeBytes',B,'simulationTime',T,'rho',200,'roadLength',2000,'NLanes',3,'MCS_NR',7, ...
        'vMean',70,'vStDev',3,'roadWidth',3.5,'Raw',[50 75 100 125 150 200 300],'printUpdateDelay', true, 'dynamicScheduling', false, 'TsensingPeriod', 1, ...
        'cv2xNumberOfReplicasMax', 3, 'DENM_prob', 0.3, 'dcc_active', false, 'sizeSubchannel',25, 'BwMHz',10, 'SCS_NR',15, ...
        'Priority_SPS',false, 'T2autonomousMode_min',5,'resourceReEvaluation',true,'cv2xCbrFactor',1, 'Priority_DCC', 1});
    % Update PHY structure with the ranges
    [phyParams] = deriveRanges(phyParams,simParams);

    % Simulator output inizialization
    outputValues = struct('computationTime',-1,...
        'blockingRateCV2X',-1*ones(1,length(phyParams.Raw)),'blockingRate11p',-1*ones(1,length(phyParams.Raw)),'blockingRateTOT',-1*ones(1,length(phyParams.Raw)),...
        'errorRateCV2X',-1*ones(1,length(phyParams.Raw)),'errorRate11p',-1*ones(1,length(phyParams.Raw)),'errorRateTOT',-1*ones(1,length(phyParams.Raw)),...
        'packetReceptionRatioCV2X',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatio11p',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioTOT',-1*ones(1,length(phyParams.Raw)),...
        'NvehiclesLTE',0,'Nvehicles11p',0,'NvehiclesTOT',0,...
        'NneighborsCV2X',zeros(1,length(phyParams.Raw)),'Nneighbors11p',zeros(1,length(phyParams.Raw)),'NneighborsTOT',zeros(1,length(phyParams.Raw)),...
        'StDevNeighboursCV2X',zeros(1,length(phyParams.Raw)),'StDevNeighbours11p',zeros(1,length(phyParams.Raw)),'StDevNeighboursTOT',zeros(1,length(phyParams.Raw)),...
        'NreassignCV2X',0,...%%%%%
        'NblockedCV2X',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'Nblocked11p',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NblockedTOT',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),...
        'NtxBeaconsCV2X',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeacons11p',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsTOT',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),...
        'NerrorsCV2X',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'Nerrors11p',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsTOT',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),...
        'NcorrectlyTxBeaconsCV2X',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeacons11p',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsTOT',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),...
        'cv2xTransmissionsIncHarq',0,'cv2xTransmissionsFirst',0, ...
        'packetReceptionRatioCV2X_DENM',-1*ones(1,length(phyParams.Raw)),'NtxBeaconsCV2X_DENM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X_DENM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'NcorrectlyTxBeaconsCV2X_DENM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'NerrorsCV2X1',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X2',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X3',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X4',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X5',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X6',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X7',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X8',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X9',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'NtxBeaconsCV2X1',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X2',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X3',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X4',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X5',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X6',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X7',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X8',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsCV2X9',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'NcorrectlyTxBeaconsCV2X1',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X2',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X3',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X4',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X5',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X6',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X7',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X8',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsCV2X9',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'packetReceptionRatioCV2X1',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X2',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X3',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X4',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X5',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X6',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X7',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X8',-1*ones(1,length(phyParams.Raw)),'packetReceptionRatioCV2X9',-1*ones(1,length(phyParams.Raw)), ...
        'mean_CBR',0 ,...
        'packetReceptionRatioCV2X_CAM',-1*ones(1,length(phyParams.Raw)),'NtxBeaconsCV2X_CAM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)),'NerrorsCV2X_CAM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)), ...
        'NcorrectlyTxBeaconsCV2X_CAM',zeros(phyParams.nChannels,appParams.nPckTypes,length(phyParams.Raw)));
    %     'NblockedCV2X',zeros(appParams.nPckTypes,length(phyParams.Raw)),'Nblocked11p',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NblockedTOT',zeros(appParams.nPckTypes,length(phyParams.Raw)),...
    %     'NtxBeaconsCV2X',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NtxBeacons11p',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NtxBeaconsTOT',zeros(appParams.nPckTypes,length(phyParams.Raw)),...
    %     'NerrorsCV2X',zeros(appParams.nPckTypes,length(phyParams.Raw)),'Nerrors11p',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NerrorsTOT',zeros(appParams.nPckTypes,length(phyParams.Raw)),...
    %     'NcorrectlyTxBeaconsCV2X',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeacons11p',zeros(appParams.nPckTypes,length(phyParams.Raw)),'NcorrectlyTxBeaconsTOT',zeros(appParams.nPckTypes,length(phyParams.Raw)));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Scenario Description

    % Load scenario from Trace File or generate initial positions of vehicles
    [simParams,simValues,positionManagement,appParams] = initVehiclePositions(simParams,appParams);

    % Load obstacles scenario from Obstacles Map File (if selected)
    if simParams.typeOfScenario==constants.SCENARIO_TRACE && simParams.fileObstaclesMap % Only with traffic traces
        [simParams,positionManagement] = loadObstaclesMapFile(simParams,positionManagement);
    else
        [positionManagement.XminMap,positionManagement.YmaxMap,positionManagement.StepMap,positionManagement.GridMap] = deal(-1);
    end

    % Initialization of matrices correctlyReceivedMap and neighborsMap (for PRRmap)
    if simParams.typeOfScenario==constants.SCENARIO_TRACE && outParams.printPRRmap % Only traffic traces
        simValues.correctlyReceivedMap11p = zeros(size(positionManagement.GridMap));
        simValues.neighborsMap11p = zeros(size(positionManagement.GridMap));
        simValues.correctlyReceivedMapCV2X = zeros(size(positionManagement.GridMap));
        simValues.neighborsMapCV2X = zeros(size(positionManagement.GridMap));
    end

    if outParams.printUpdateDelay
        % Initialize matrix containing update time of the received beacons
        simValues.updateTimeMatrix11p = -1*ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));
        simValues.updateTimeMatrixCV2X = -1*ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));

        % Initialize array with the counters of update delay events
        % (max 10 s + delayResolution -> delays larger than 10 s are
        % registered in the last element of the array)
        NupdateDelayEvents = round(10/outParams.delayResolution)+1;
        %     outputValues.updateDelayCounter11p = zeros(appParams.nPckTypes,NupdateDelayEvents,length(phyParams.Raw));
        %     outputValues.updateDelayCounterCV2X = zeros(appParams.nPckTypes,NupdateDelayEvents,length(phyParams.Raw));
        outputValues.updateDelayCounter11p = zeros(phyParams.nChannels,appParams.nPckTypes,NupdateDelayEvents,length(phyParams.Raw));
        outputValues.updateDelayCounterCV2X = zeros(phyParams.nChannels,appParams.nPckTypes,NupdateDelayEvents,length(phyParams.Raw));

        if outParams.printWirelessBlindSpotProb
            % Initialize matrix containing the counters needed for computation
            % of wireless blind spot probability
            % last dimension has size 3: [Time interval - # delay events larger or equal than time interval - #
            % delay events shorter than time interval]
            %        outputValues.wirelessBlindSpotCounter = zeros(length(delayValues),4);
            NupdateWBSevents = ceil(outParams.delayWBSmax/outParams.delayWBSresolution);

            outputValues.wirelessBlindSpotCounterCV2X = zeros(NupdateWBSevents,length(phyParams.Raw),3);
            outputValues.wirelessBlindSpotCounterCV2X(:,:,1) = repmat((outParams.delayWBSresolution*(1:NupdateWBSevents))',1,length(phyParams.Raw));
            outputValues.wirelessBlindSpotCounter11p = zeros(NupdateWBSevents,length(phyParams.Raw),3);
            outputValues.wirelessBlindSpotCounter11p(:,:,1) = repmat((outParams.delayWBSresolution*(1:NupdateWBSevents))',1,length(phyParams.Raw));
        end
    end

    if outParams.printDataAge
        % Initialize matrix containing update time of the received beacons
        simValues.dataAgeTimestampMatrix11p = -1*ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));
        simValues.dataAgeTimestampMatrixCV2X = -1*ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));

        % Initialize array with the counters of update delay events
        % (max 10 s + delayResolution -> delays larger than 10 s are
        % registered in the last element of the array)
        NdataAgeEvents = round(10/outParams.delayResolution)+1;
        %     outputValues.dataAgeCounter11p = zeros(appParams.nPckTypes,NdataAgeEvents,length(phyParams.Raw));
        %     outputValues.dataAgeCounterCV2X = zeros(appParams.nPckTypes,NdataAgeEvents,length(phyParams.Raw));
        outputValues.dataAgeCounter11p = zeros(phyParams.nChannels,appParams.nPckTypes,NdataAgeEvents,length(phyParams.Raw));
        outputValues.dataAgeCounterCV2X = zeros(phyParams.nChannels,appParams.nPckTypes,NdataAgeEvents,length(phyParams.Raw));
    end

    if outParams.printPacketDelay
        % Initialize array with the counters of packet delay events
        % (max Tbeacon/delayResolution -> delays larger than Tbeacon are
        % registered in the last element of the array)
        NpacketDelayEvents = round((2*appParams.allocationPeriod)/outParams.delayResolution);
        %     outputValues.packetDelayCounter11p = zeros(appParams.nPckTypes,NpacketDelayEvents,length(phyParams.Raw));
        %     outputValues.packetDelayCounterCV2X = zeros(appParams.nPckTypes,NpacketDelayEvents,length(phyParams.Raw));
        outputValues.packetDelayCounter11p = zeros(phyParams.nChannels,appParams.nPckTypes,NpacketDelayEvents,length(phyParams.Raw));
        outputValues.packetDelayCounterCV2X = zeros(phyParams.nChannels,appParams.nPckTypes,NpacketDelayEvents,length(phyParams.Raw));
    end

    if outParams.printPacketReceptionRatio
        % If simulating variable beacon size (currently 802.11p only)
        if simParams.technology~=constants.TECH_ONLY_CV2X % not only C-V2X
            if simParams.technology==constants.TECH_ONLY_11P && appParams.variableBeaconSize
                % Initialize 9 columns in distanceDetailsCounter (for smaller beacons)
                % The matrix becomes:
                % [distance, #Correctly decoded beacons (big), #Errors (big), #Blocked neighbors (big), #Neighbors (big),
                % #Correctly decoded beacons (small), #Errors (small), #Blocked neighbors (small), #Neighbors (small)]
                %            outputValues.distanceDetailsCounter11p = zeros(appParams.nPckTypes,floor(phyParams.RawMax11p/outParams.prrResolution),9);
                outputValues.distanceDetailsCounter11p = zeros(phyParams.nChannels,appParams.nPckTypes,floor(phyParams.RawMax11p/outParams.prrResolution),9);
            else
                %            outputValues.distanceDetailsCounter11p = zeros(appParams.nPckTypes,floor(phyParams.RawMax11p/outParams.prrResolution),5);
                outputValues.distanceDetailsCounter11p = zeros(phyParams.nChannels,appParams.nPckTypes,floor(phyParams.RawMax11p/outParams.prrResolution),5);
            end
            for iChannel = 1:phyParams.nChannels
                for pckType=1:appParams.nPckTypes
                    outputValues.distanceDetailsCounter11p(iChannel,pckType,:,1) = (outParams.prrResolution:outParams.prrResolution:floor(phyParams.RawMax11p))';
                end
            end
        end

        if simParams.technology~=constants.TECH_ONLY_11P % not only 11p
            % Initialize array with the counters of Rx details vs. distance (up to RawMax)
            % [distance, #Correctly decoded beacons, #Errors, #Blocked neighbors, #Neighbors (computed in printDistanceDetailsCounter)]

            %        outputValues.distanceDetailsCounterCV2X = zeros(appParams.nPckTypes,floor(phyParams.RawMaxCV2X/outParams.prrResolution),5);
            outputValues.distanceDetailsCounterCV2X = zeros(phyParams.nChannels,appParams.nPckTypes,floor(phyParams.RawMaxCV2X/outParams.prrResolution),5);
            for iChannel = 1:phyParams.nChannels
                for pckType=1:appParams.nPckTypes
                    %            outputValues.distanceDetailsCounterCV2X(pckType,:,1) = (outParams.prrResolution:outParams.prrResolution:floor(phyParams.RawMaxCV2X))';
                    outputValues.distanceDetailsCounterCV2X(iChannel,pckType,:,1) = (outParams.prrResolution:outParams.prrResolution:floor(phyParams.RawMaxCV2X))';
                end
            end
        end
    end

    if outParams.printPowerControl
        %
        error('Power control output not updated in v5');
        % NOTE: needs check regarding the new power per MHz parameter
        %     % Initialize array with the counters of power control events
        %     % (max Ptx/powerResolution + 10dBm margin -> TX power higher than
        %     % PtxMax + 10 dBm are registered in the last element of the array)
        %     % (min -100 dBm -> TX power lower than -100dBm are registered in the
        %     % first element of the array)
        %     NpowerControlEvents = round(101/outParams.powerResolution) + round(phyParams.P_ERP_MHz_dBm/outParams.powerResolution);
        %     outputValues.powerControlCounter = zeros(NpowerControlEvents,1);
    end

    if outParams.printHiddenNodeProb
        % TODO - not updated
        error('not supported in v5');
        % Initialize arrays for hidden node probability
        %outputValues.hiddenNodeSumProb = zeros(floor(phyParams.RawMax)+1,1);
        %outputValues.hiddenNodeProbEvents = zeros(floor(phyParams.RawMax)+1,1);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Start Simulation
    %% Initialization
    [appParams,simParams,phyParams,outParams,simValues,outputValues,...
        sinrManagement,timeManagement,positionManagement,stationManagement,expManagement] = mainInit(appParams,simParams,phyParams,outParams,simValues,outputValues,positionManagement);

    if episodesCt == 1 
        Critics = struct;
        Agents = struct; %load("0419_trainedAgents.mat");
        %Agents = Agents.Agents
        Epsilons = zeros(1,simValues.maxID);
        EpisodesVector = struct;
        
        for t = 1:simValues.maxID
            Critics(1,t).critic = rlQValueRepresentation(criticNetwork,obsInfo,actInfo,'Observation',{'state'},'Action',{'output'},criticOpts);
            % DQN 에이전트 생성
            Agents(1,t).agent = rlDQNAgent(Critics(1,t).critic, agentOpts);
            % %Actors(1,t).actor = rlDeterministicActorRepresentation(actorNetwork,obsInfo,actInfo,'Observation',{'state'},'Action',{'ActorScaling'},actorOpts);
            % Agents(1,t).agent = rlDQNAgent(Critics(1,t).critic,agentOpts);
            % criticgradFcn = dlaccelerate(@deepCriticGradient);
            Critics(1,t).critic = setLoss(Critics(1,t).critic,'rl.loss.dq');
            epsilon = Agents(1,t).agent.AgentOptions.EpsilonGreedyExploration.Epsilon;
            Epsilons(1,t) = epsilon;
            EpisodesVector(1,t).Reward = [];
            EpisodesVector(1,t).StepsTaken = [];
            EpisodesVector(1,t).Q0 = [];
        end
        TargetCritics = Critics;
    end
    Episodes = struct;
    for k = 1:simValues.maxID
        Episodes(1,k).EpisodeInfo.CumulativeReward = 0;
        Episodes(1,k).EpisodeInfo.StepsTaken = 0;
        Episodes(1,k).EpisodeInfo.Q0 = 0;
        
    end
    % The variable 'timeNextPrint' is used only for printing purposes
    timeNextPrint = 0;

    % The variable minNextSuperframe is used in the case of coexistence
    minNextSuperframe = min(timeManagement.coex_timeNextSuperframe);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Simulation Cycle
    % The simulation ends when the time exceeds the duration of the simulation
    % (not really used, since a break inside the cycle will stop the simulation
    % earlier)

    % Start stopwatch
    tic
    fprintf('Episode number = %.0f\n',episodesCt);
    fprintf('Simulation ID: %d\nMessage: %s\n',outParams.simID, outParams.message);
    fprintf('Simulation Time: ');
    reverseStr = '';

    while timeManagement.timeNow < simParams.simulationTime

        % The instant and node of the next event is obtained
        % indexEvent is the index of the vector IDvehicle
        % idEvent is the ID of the vehicle of the current event
        [timeEvent, indexEvent] = min(timeManagement.timeNextEvent(stationManagement.activeIDs));
        %timeEvent는 200x1배열의  가장 작은값...
        %indexEvent는 위의 값이 몇행에 있는지
        idEvent = stationManagement.activeIDs(indexEvent); % 가장 작은 값인 indexEvent를 차량 번호 배열인 ...
        % activeIDs에 넣어줌으로써 idEvent는 다음 이벤트가 발생할 차량의 번호

        % If the next C-V2X event is earlier than timeEvent, set the time to the
        % C-V2X event
        if timeEvent >= timeManagement.timeNextCV2X - 1e-9 %10^-9
            timeEvent = timeManagement.timeNextCV2X;
            %fprintf('LTE subframe %.6f\n',timeEvent);
        end

        % If the next superframe event (coexistence, method A) is earlier than timeEvent, set the time to the
        % this event
        if timeEvent >= minNextSuperframe  - 1e-9
            timeEvent = minNextSuperframe;
        end

        % If timeEvent is later than the next CBR update, set the time
        % to the CBR update
        if timeEvent >= (timeManagement.timeNextCBRupdate - 1e-9)
            timeEvent = timeManagement.timeNextCBRupdate;
            %fprintf('CBR update%.6f\n',timeEvent);
        end

        % If timeEvent is later than the next position update, set the time
        % to the position update
        % With LTE, it must necessarily be done after the end of a subframe and
        % before the next one
        if timeEvent >= (timeManagement.timeNextPosUpdate-1e-9) && ...
                (isempty(stationManagement.activeIDsCV2X) || (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==true))
            timeEvent = timeManagement.timeNextPosUpdate;
        end

        % to avoid vechile go out of scenario right before CV2X Tx ending or CBR update
        % special case: timeManagement.timeNextPosUpdate == timeManagement.timeNextCV2X
        if (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false) ||...
                timeManagement.timeNextPosUpdate == timeManagement.timeNextCBRupdate
            delayPosUpdate = true;
        else
            delayPosUpdate = false;
        end

        % if the CV2X ending transmission time equals to the timeNextCBRupdate,
        % end the transmission first
        if timeManagement.timeNextCBRupdate == timeManagement.timeNextCV2X &&...
                (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false)
            delayCBRupdate = true;
        else
            delayCBRupdate = false;
        end

        % if the CV2X ending transmission time equals to the minNextSuperframe,
        % end the transmission first
        if minNextSuperframe == timeManagement.timeNextCV2X &&...
                (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false)
            delay_minNextSuperframe = true;
        else
            delay_minNextSuperframe = false;
        end
        if timeEvent < timeManagement.timeNow
            % error log
            fid_error = fopen(fullfile(outParams.outputFolder,...
                sprintf("error_log_%d.txt",outParams.simID)), "at");
            fprintf(fid_error, sprintf("Time goes back! Stop and check!\nSeed=%d, timeNow=%f, timeEvent=%f\n",...
                simParams.seed, timeManagement.timeNow, timeEvent));
            fclose(fid_error);
        end
        % update timenow, timenow do not go back, deal with float-point-related
        % cases.
        % fixme: need to check
        timeManagement.timeNow = max(timeEvent, timeManagement.timeNow);

        % If the time instant exceeds or is equal to the duration of the
        % simulation, the simulation is ended
        if round(timeManagement.timeNow, 10) >= round(simParams.simulationTime, 10)
            break;
        end

        %%
        % Print time to video
        while timeManagement.timeNow > timeNextPrint  - 1e-9
            reverseStr = printUpdateToVideo(timeManagement.timeNow,simParams.simulationTime,reverseStr);
            timeNextPrint = timeNextPrint + simParams.positionTimeResolution;
        end

        %% Action
        % The action at timeManagement.timeNow depends on the selected event
        % POSITION UPDATE: positions of vehicles are updated
        if timeEvent == timeManagement.timeNextPosUpdate && ~delayPosUpdate
            % DEBUG EVENTS
            % printDebugEvents(timeEvent,'position update',-1);

            if isfield(timeManagement,'ttiCV2Xstarts') && timeManagement.ttiCV2Xstarts==false
                % During a position update, some vehicles can enter or exit the
                % scenario; this is not managed if it happens during one
                % subframe
                error('A position update is occurring during the subframe; not allowed by implementation.');
            end

            [appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement] = ...
                mainPositionUpdate(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement);

            % DEBUG IMAGE
            % printDebugImage('position update',timeManagement,stationManagement,positionManagement,simParams,simValues);

            % Set value of next position update
            timeManagement.timeNextPosUpdate = round(timeManagement.timeNextPosUpdate + simParams.positionTimeResolution, 10);
            positionManagement.NposUpdates = positionManagement.NposUpdates+1;

        elseif timeEvent == timeManagement.timeNextCBRupdate && ~delayCBRupdate
            % Part dealing with the channel busy ratio calculation
            % Done for every station in the system, if the option is active
            %
            thisSubInterval = mod(ceil((timeEvent-1e-9)/(simParams.cbrSensingInterval/simParams.cbrSensingIntervalDesynchN))-1,simParams.cbrSensingIntervalDesynchN)+1;
            %
            % ITS-G5
            % CBR and DCC (if active)
            if ~isempty(stationManagement.activeIDs11p)
                vehiclesToConsider = stationManagement.activeIDs11p(stationManagement.cbr_subinterval(stationManagement.activeIDs11p)==thisSubInterval);
                [timeManagement,stationManagement,stationManagement.cbr11pValues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9))] = ...
                    cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams,outParams);
                %             %% =========
                %             % Plot figs of related paper, could be commented in other case.
                %             % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
                %             % Only for IEEE 802.11p, highway scenario.
                %             % log number of replicas
                %             stationManagement.ITSReplicasLog(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9)) = stationManagement.ITSNumberOfReplicas(vehiclesToConsider);
                %             stationManagement.positionLog(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9)) = positionManagement.XvehicleReal(vehiclesToConsider);
                %             %% =========
            end
            % In case of Mitigation method with dynamic slots, also in LTE nodes
            if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC && simParams.coex_cbrTotVariant==2
                vehiclesToConsider = stationManagement.activeIDsCV2X(stationManagement.cbr_subinterval(stationManagement.activeIDsCV2X)==thisSubInterval);
                [timeManagement,stationManagement,sinrManagement.cbrLTE_coex11ponly(vehiclesToConsider)] = ...
                    cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams,outParams);
            end

            % LTE-V2X
            % CBR and DCC (if active)
            if ~isempty(stationManagement.activeIDsCV2X)
                vehiclesToConsider = stationManagement.activeIDsCV2X(stationManagement.cbr_subinterval(stationManagement.activeIDsCV2X)==thisSubInterval);
                [timeManagement,stationManagement,sinrManagement,stationManagement.cbrCV2Xvalues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval)),stationManagement.coex_cbrLteOnlyValues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval))] = ...
                    cbrUpdateCV2X(timeManagement,vehiclesToConsider,stationManagement,positionManagement,sinrManagement,appParams,simParams,phyParams,outParams,outputValues);
            end

            timeManagement.timeNextCBRupdate = round(timeManagement.timeNextCBRupdate + (simParams.cbrSensingInterval/simParams.cbrSensingIntervalDesynchN), 10);

        elseif timeEvent == minNextSuperframe && ~delay_minNextSuperframe
            % only possible in coexistence with mitigation methods
            if simParams.technology~=constants.TECH_COEX_STD_INTERF || simParams.coexMethod==constants.COEX_METHOD_NON
                error('Superframe is only possible with coexistence, Methods A, B, C, F');
            end

            % coexistence Methods, superframe boundary
            [timeManagement,stationManagement,sinrManagement,outputValues] = ...
                superframeManagement(timeManagement,stationManagement,simParams,sinrManagement,phyParams,outParams,simValues,outputValues);

            minNextSuperframe=min(timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs));

            % CASE C-V2X
        elseif abs(timeEvent-timeManagement.timeNextCV2X)<1e-8    % timeEvent == timeManagement.timeNextCV2X 0이거나 음수이면?

            if timeManagement.ttiCV2Xstarts
                % DEBUG EVENTS
                %printDebugEvents(timeEvent,'LTE subframe starts',-1);
                %fprintf('Starts\n');

                if timeManagement.timeNow>0
                    [phyParams,simValues,outputValues,sinrManagement,stationManagement,timeManagement,expManagement,Agents,Episodes,Critics,TargetCritics,Buffer] = ...
                        mainCV2XttiEnds(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement,...
                        expManagement,Agents,Episodes,EpisodesVector,Critics,TargetCritics,Buffer,Epsilons,obsInfo,actInfo,trainingMode,sharingReplay,criticOpts);
                end

                [sinrManagement,stationManagement,timeManagement,outputValues] = ...
                    mainCV2XttiStarts(appParams,phyParams,timeManagement,sinrManagement,stationManagement,simParams,simValues,outParams,outputValues);

                % DEBUG TX-RX
                % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
                %     printDebugTxRx(timeManagement.timeNow,'LTE subframe starts',stationManagement,sinrManagement);
                % end

                % DEBUG TX
                % printDebugTx(timeManagement.timeNow,true,-1,stationManagement,positionManagement,sinrManagement,outParams,phyParams);

                timeManagement.ttiCV2Xstarts = false;
                timeManagement.timeNextCV2X = round(timeManagement.timeNextCV2X + (phyParams.TTI - phyParams.TsfGap), 10);

                % DEBUG IMAGE
                % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
                %     printDebugImage('LTE subframe starts',timeManagement,stationManagement,positionManagement,simParams,simValues);
                % end
            else
                % DEBUG EVENTS
                % printDebugEvents(timeEvent,'LTE subframe ends',-1);
                % fprintf('Stops\n');

                [phyParams,simValues,outputValues,sinrManagement,stationManagement,timeManagement,expManagement] = ...
                    mainCV2XtransmissionEnds(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement,...
                    expManagement);

                % DEBUG TX-RX
                % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
                %     printDebugTxRx(timeManagement.timeNow,'LTE subframe ends',stationManagement,sinrManagement);
                % end

                timeManagement.ttiCV2Xstarts = true;
                timeManagement.timeNextCV2X = round(timeManagement.timeNextCV2X + phyParams.TsfGap, 10);

                % DEBUG IMAGE
                % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
                %     printDebugImage('LTE subframe ends',timeManagement,stationManagement,positionManagement,simParams,simValues);
                % end
            end

            % CASE A: new packet is generated
        elseif abs(timeEvent-timeManagement.timeNextPacket(idEvent))<1e-8   % timeEvent == timeManagement.timeNextPacket(idEvent)

            % printDebugReallocation(timeEvent,idEvent,positionManagement.XvehicleReal(indexEvent),'gen',-1,outParams);

            if stationManagement.vehicleState(idEvent)==constants.V_STATE_LTE_TXRX % is LTE
                % DEBUG EVENTS
                %printDebugEvents(timeEvent,'New packet, LTE',idEvent);

                stationManagement.pckBuffer(idEvent) = stationManagement.pckBuffer(idEvent)+1;
                stationManagement.BRid(idEvent,2:phyParams.cv2xNumberOfReplicasMax) = -1;
                %             %% From version 6.2, the following corrects a bug
                %             %The buffer may include a packet that is being transmitted
                %             %If the buffer already includes a packet, this needs to be
                %             %checked at the end of this subframe
                %             %If this is not the case, the pckNextAttempt must be reset
                if stationManagement.pckBuffer(idEvent)<=1
                    stationManagement.pckNextAttempt(idEvent) = 1;
                    stationManagement.cv2xNumberOfReplicas(idEvent) = 1;
                    stationManagement.DENM_pck(idEvent) = 0;
                end

                % DEBUG IMAGE
                %printDebugImage('New packet LTE',timeManagement,stationManagement,positionManagement,simParams,simValues);
            else % is not LTE
                % DEBUG EVENTS
                %printDebugEvents(timeEvent,'New packet, 11p',idEvent);

                % In the case of 11p, some processing is necessary
                [timeManagement,stationManagement,sinrManagement,outputValues] = ...
                    newPacketIn11p(idEvent,indexEvent,outParams,simParams,positionManagement,...
                    phyParams,timeManagement,stationManagement,sinrManagement,outputValues,appParams);

                % DEBUG TX-RX
                % printDebugTxRx(timeManagement.timeNow,idEvent,'11p packet generated',stationManagement,sinrManagement,outParams);
                % printDebugBackoff11p(timeManagement.timeNow,'11p backoff started',idEvent,stationManagement,outParams)

                % DEBUG IMAGE
                %printDebugImage('New packet 11p',timeManagement,stationManagement,positionManagement,simParams,simValues);
            end
            % printDebugGeneration(timeManagement,idEvent,positionManagement,outParams);

            % from version 5.6.2 the 3GPP aperiodic generation is also supported. The generation interval is now composed of a
            % deterministic part and a random part. The random component is active only when enabled.
            generationInterval = timeManagement.generationIntervalDeterministicPart(idEvent) + exprnd(appParams.generationIntervalAverageRandomPart);
            if generationInterval >= timeManagement.dcc_minInterval(idEvent)
                timeManagement.timeNextPacket(idEvent) = round(timeManagement.timeNow + generationInterval, 10); % 선택된 timeEvent에 0.1 더함
            else
                timeManagement.timeNextPacket(idEvent) = round(timeManagement.timeNow + timeManagement.dcc_minInterval(idEvent), 10);
                if ismember(idEvent, stationManagement.activeIDs11p)
                    stationManagement.dcc11pTriggered(stationManagement.vehicleChannel(idEvent)) = true;
                elseif ismember(idEvent, stationManagement.activeIDsCV2X)
                    stationManagement.dccLteTriggered(stationManagement.vehicleChannel(idEvent)) = true;
                end
            end
            stationManagement.prob(idEvent) = rand;
            stationManagement.pckBuffer_prob(idEvent) = stationManagement.prob(idEvent);
            if stationManagement.pckBuffer_prob(idEvent) < simParams.DENM_prob
                stationManagement.DENM_pck(idEvent) = 1;
                stationManagement.cv2xNumberOfReplicas(idEvent) = phyParams.cv2xNumberOfReplicasMax;
                stationManagement.resReselectionCounterCV2X(idEvent) = 0;
            end
            timeManagement.timeLastPacket(idEvent) = timeManagement.timeNow-timeManagement.addedToGenerationTime(idEvent);

            if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_A && simParams.coexA_improvements>0
                timeManagement = coexistenceImprovements(timeManagement,idEvent,stationManagement,simParams,phyParams);
            end

            % CASE B+C: either a backoff or a transmission concludes
        else % txrxevent-11p
            % A backoff ends
            if stationManagement.vehicleState(idEvent)==constants.V_STATE_11P_BACKOFF % END backoff
                % DEBUG EVENTS
                %printDebugEvents(timeEvent,'backoff concluded, tx start',idEvent);

                [timeManagement,stationManagement,sinrManagement,outputValues] = ...
                    endOfBackoff11p(idEvent,indexEvent,simParams,simValues,phyParams,timeManagement,stationManagement,sinrManagement,appParams,outParams,outputValues);

                % DEBUG TX-RX
                % printDebugTxRx(timeManagement.timeNow,idEvent,'11p Tx started',stationManagement,sinrManagement,outParams);
                % printDebugBackoff11p(timeManagement.timeNow,'11p tx started',idEvent,stationManagement,outParams)

                % DEBUG TX
                % printDebugTx(timeManagement.timeNow,true,idEvent,stationManagement,positionManagement,sinrManagement,outParams,phyParams);

                % DEBUG IMAGE
                %printDebugImage('11p TX starts',timeManagement,stationManagement,positionManagement,simParams,simValues);

                % A transmission ends
            elseif stationManagement.vehicleState(idEvent)==constants.V_STATE_11P_TX % END tx
                % DEBUG EVENTS
                %printDebugEvents(timeEvent,'Tx concluded',idEvent);

                [simValues,outputValues,timeManagement,stationManagement,sinrManagement] = ...
                    endOfTransmission11p(idEvent,indexEvent,positionManagement,phyParams,outParams,simParams,simValues,outputValues,timeManagement,stationManagement,sinrManagement,appParams);

                % DEBUG IMAGE
                %printDebugImage('11p TX ends',timeManagement,stationManagement,positionManagement,simParams,simValues);

                % DEBUG TX-RX
                % printDebugTxRx(timeManagement.timeNow,idEvent,'11p Tx ended',stationManagement,sinrManagement,outParams);
                % printDebugBackoff11p(timeManagement.timeNow,'11p tx ended',idEvent,stationManagement,outParams)

            else
                fprintf('idEvent=%d, state=%d\n',idEvent,stationManagement.vehicleState(idEvent));
                error('Ends unknown event...')
            end
        end

        % The next event is selected as the minimum of all values in 'timeNextPacket'
        % and 'timeNextTxRx'
        timeManagement.timeNextEvent = min(timeManagement.timeNextPacket,timeManagement.timeNextTxRx11p);
        if min(timeManagement.timeNextEvent(stationManagement.activeIDs)) < timeManagement.timeNow-1e-8 % error check
            format long
            fprintf('next=%f, now=%f\n',min(timeManagement.timeNextEvent(stationManagement.activeIDs)),timeManagement.timeNow);
            error('An event is schedule in the past...');
        end

    end

    % Print end of simulation
    msg = sprintf('%.1f / %.1fs',simParams.simulationTime,simParams.simulationTime);
    fprintf([reverseStr, msg]);

    % Number of position updates
    simValues.snapshots = positionManagement.NposUpdates;

    % Stop stopwatch
    outputValues.computationTime = toc;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% KPIs Computation (Output)
    fprintf('\nElaborating the outputs...\n');

    % First of all convert from cumulative to groups
    for pckType = 1:appParams.nPckTypes
        for iPhyRaw=length(phyParams.Raw):-1:2
            for idChannel = 1:phyParams.nChannels
                %            outputValues.NblockedCV2X(pckType,iPhyRaw) = outputValues.NblockedCV2X(pckType,iPhyRaw)-outputValues.NblockedCV2X(pckType,iPhyRaw-1);
                %             outputValues.NcorrectlyTxBeaconsCV2X(pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X(pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X(pckType,iPhyRaw-1);
                %             outputValues.NerrorsCV2X(pckType,iPhyRaw) = outputValues.NerrorsCV2X(pckType,iPhyRaw)-outputValues.NerrorsCV2X(pckType,iPhyRaw-1);
                %             outputValues.NtxBeaconsCV2X(pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X(pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X(pckType,iPhyRaw-1);
                %             outputValues.Nblocked11p(pckType,iPhyRaw) = outputValues.Nblocked11p(pckType,iPhyRaw)-outputValues.Nblocked11p(pckType,iPhyRaw-1);
                %             outputValues.NcorrectlyTxBeacons11p(pckType,iPhyRaw) = outputValues.NcorrectlyTxBeacons11p(pckType,iPhyRaw)-outputValues.NcorrectlyTxBeacons11p(pckType,iPhyRaw-1);
                %             outputValues.Nerrors11p(pckType,iPhyRaw) = outputValues.Nerrors11p(pckType,iPhyRaw)-outputValues.Nerrors11p(pckType,iPhyRaw-1);
                %             outputValues.NtxBeacons11p(pckType,iPhyRaw) = outputValues.NtxBeacons11p(pckType,iPhyRaw)-outputValues.NtxBeacons11p(pckType,iPhyRaw-1);
                %             outputValues.NblockedTOT(pckType,iPhyRaw) = outputValues.NblockedTOT(pckType,iPhyRaw)-outputValues.NblockedTOT(pckType,iPhyRaw-1);
                %             outputValues.NcorrectlyTxBeaconsTOT(pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsTOT(pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsTOT(pckType,iPhyRaw-1);
                %             outputValues.NerrorsTOT(pckType,iPhyRaw) = outputValues.NerrorsTOT(pckType,iPhyRaw)-outputValues.NerrorsTOT(pckType,iPhyRaw-1);
                %             outputValues.NtxBeaconsTOT(pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(pckType,iPhyRaw)-outputValues.NtxBeaconsTOT(pckType,iPhyRaw-1);
                outputValues.NblockedCV2X(idChannel,pckType,iPhyRaw) = outputValues.NblockedCV2X(idChannel,pckType,iPhyRaw)-outputValues.NblockedCV2X(idChannel,pckType,iPhyRaw-1);
                outputValues.NcorrectlyTxBeaconsCV2X(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X(idChannel,pckType,iPhyRaw-1);
                outputValues.NcorrectlyTxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw-1);
                outputValues.NcorrectlyTxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw-1);

                % outputValues.NcorrectlyTxBeaconsCV2X1(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X1(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X1(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X2(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X2(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X2(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X3(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X3(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X3(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X4(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X4(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X4(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X5(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X5(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X5(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X6(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X6(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X6(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X7(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X7(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X7(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X8(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X8(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X8(idChannel,pckType,iPhyRaw-1);
                % outputValues.NcorrectlyTxBeaconsCV2X9(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X9(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsCV2X9(idChannel,pckType,iPhyRaw-1);

                outputValues.NerrorsCV2X(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X(idChannel,pckType,iPhyRaw-1);
                outputValues.NerrorsCV2X_DENM(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X_DENM(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X_DENM(idChannel,pckType,iPhyRaw-1);
                outputValues.NerrorsCV2X_CAM(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X_CAM(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X_CAM(idChannel,pckType,iPhyRaw-1);

                % outputValues.NerrorsCV2X1(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X1(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X1(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X2(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X2(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X2(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X3(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X3(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X3(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X4(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X4(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X4(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X5(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X5(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X5(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X6(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X6(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X6(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X7(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X7(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X7(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X8(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X8(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X8(idChannel,pckType,iPhyRaw-1);
                % outputValues.NerrorsCV2X9(idChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X9(idChannel,pckType,iPhyRaw)-outputValues.NerrorsCV2X9(idChannel,pckType,iPhyRaw-1);

                outputValues.NtxBeaconsCV2X(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X(idChannel,pckType,iPhyRaw-1);
                outputValues.NtxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X_DENM(idChannel,pckType,iPhyRaw-1);
                outputValues.NtxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X_CAM(idChannel,pckType,iPhyRaw-1);

                % outputValues.NtxBeaconsCV2X1(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X1(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X1(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X2(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X2(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X2(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X3(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X3(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X3(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X4(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X4(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X4(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X5(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X5(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X5(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X6(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X6(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X6(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X7(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X7(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X7(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X8(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X8(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X8(idChannel,pckType,iPhyRaw-1);
                % outputValues.NtxBeaconsCV2X9(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X9(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsCV2X9(idChannel,pckType,iPhyRaw-1);

                outputValues.Nblocked11p(idChannel,pckType,iPhyRaw) = outputValues.Nblocked11p(idChannel,pckType,iPhyRaw)-outputValues.Nblocked11p(idChannel,pckType,iPhyRaw-1);
                outputValues.NcorrectlyTxBeacons11p(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeacons11p(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeacons11p(idChannel,pckType,iPhyRaw-1);
                outputValues.Nerrors11p(idChannel,pckType,iPhyRaw) = outputValues.Nerrors11p(idChannel,pckType,iPhyRaw)-outputValues.Nerrors11p(idChannel,pckType,iPhyRaw-1);
                outputValues.NtxBeacons11p(idChannel,pckType,iPhyRaw) = outputValues.NtxBeacons11p(idChannel,pckType,iPhyRaw)-outputValues.NtxBeacons11p(idChannel,pckType,iPhyRaw-1);
                outputValues.NblockedTOT(idChannel,pckType,iPhyRaw) = outputValues.NblockedTOT(idChannel,pckType,iPhyRaw)-outputValues.NblockedTOT(idChannel,pckType,iPhyRaw-1);
                outputValues.NcorrectlyTxBeaconsTOT(idChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsTOT(idChannel,pckType,iPhyRaw)-outputValues.NcorrectlyTxBeaconsTOT(idChannel,pckType,iPhyRaw-1);
                outputValues.NerrorsTOT(idChannel,pckType,iPhyRaw) = outputValues.NerrorsTOT(idChannel,pckType,iPhyRaw)-outputValues.NerrorsTOT(idChannel,pckType,iPhyRaw-1);
                outputValues.NtxBeaconsTOT(idChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(idChannel,pckType,iPhyRaw)-outputValues.NtxBeaconsTOT(idChannel,pckType,iPhyRaw-1);
            end
        end
    end
    % Temporary
    % OUTPUT FOR MCO
    % if simParams.mco_nVehInterf>0 && outParams.mco_printInterfStatistic
    %     mco_printOutput(stationManagement,simParams,outParams,outputValues);
    % end

    % Average Blocking Rate
    % outputValues.blockingRateCV2X = sum(outputValues.NblockedCV2X,1) ./ (sum(outputValues.NcorrectlyTxBeaconsCV2X+outputValues.NerrorsCV2X+outputValues.NblockedCV2X,1));
    % outputValues.blockingRate11p = sum(outputValues.Nblocked11p,1) ./ (sum(outputValues.NcorrectlyTxBeacons11p+outputValues.Nerrors11p+outputValues.Nblocked11p,1));
    % outputValues.blockingRateTOT = sum(outputValues.NblockedTOT,1) ./ (sum(outputValues.NcorrectlyTxBeaconsTOT+outputValues.NerrorsTOT+outputValues.NblockedTOT,1));
    outputValues.blockingRateCV2X = sum(sum(outputValues.NblockedCV2X,1),1) ./ (sum(sum(outputValues.NcorrectlyTxBeaconsCV2X+outputValues.NerrorsCV2X+outputValues.NblockedCV2X,1),1));
    outputValues.blockingRate11p = sum(sum(outputValues.Nblocked11p,1),1) ./ (sum(sum(outputValues.NcorrectlyTxBeacons11p+outputValues.Nerrors11p+outputValues.Nblocked11p,1),1));
    outputValues.blockingRateTOT = sum(sum(outputValues.NblockedTOT,1),1) ./ (sum(sum(outputValues.NcorrectlyTxBeaconsTOT+outputValues.NerrorsTOT+outputValues.NblockedTOT,1),1));

    % Average Error Rate
    % outputValues.errorRateCV2X = sum(outputValues.NerrorsCV2X,1) ./ sum(outputValues.NtxBeaconsCV2X,1);
    % outputValues.errorRate11p = sum(outputValues.Nerrors11p,1) ./ sum(outputValues.NtxBeacons11p,1);
    % outputValues.errorRateTOT = sum(outputValues.NerrorsTOT,1) ./ sum(outputValues.NtxBeaconsTOT,1);
    outputValues.errorRateCV2X = sum(sum(outputValues.NerrorsCV2X,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X,1),1);
    outputValues.errorRateCV2X_DENM = sum(sum(outputValues.NerrorsCV2X_DENM,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X_DENM,1),1);
    outputValues.errorRateCV2X_CAM = sum(sum(outputValues.NerrorsCV2X_CAM,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X_CAM,1),1);

    % outputValues.errorRateCV2X1 = sum(sum(outputValues.NerrorsCV2X1,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X1,1),1);
    % outputValues.errorRateCV2X2 = sum(sum(outputValues.NerrorsCV2X2,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X2,1),1);
    % outputValues.errorRateCV2X3 = sum(sum(outputValues.NerrorsCV2X3,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X3,1),1);
    % outputValues.errorRateCV2X4 = sum(sum(outputValues.NerrorsCV2X4,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X4,1),1);
    % outputValues.errorRateCV2X5 = sum(sum(outputValues.NerrorsCV2X5,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X5,1),1);
    % outputValues.errorRateCV2X6 = sum(sum(outputValues.NerrorsCV2X6,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X6,1),1);
    % outputValues.errorRateCV2X7 = sum(sum(outputValues.NerrorsCV2X7,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X7,1),1);
    % outputValues.errorRateCV2X8 = sum(sum(outputValues.NerrorsCV2X8,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X8,1),1);
    % outputValues.errorRateCV2X9 = sum(sum(outputValues.NerrorsCV2X9,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X9,1),1);


    outputValues.errorRate11p = sum(sum(outputValues.Nerrors11p,1),1) ./ sum(sum(outputValues.NtxBeacons11p,1),1);
    outputValues.errorRateTOT = sum(sum(outputValues.NerrorsTOT,1),1) ./ sum(sum(outputValues.NtxBeaconsTOT,1),1);

    % Average Packet Reception Ratio
    % outputValues.packetReceptionRatioCV2X = sum(outputValues.NcorrectlyTxBeaconsCV2X,1) ./ sum(outputValues.NtxBeaconsCV2X,1);
    % outputValues.packetReceptionRatio11p = sum(outputValues.NcorrectlyTxBeacons11p,1) ./ sum(outputValues.NtxBeacons11p,1);
    % outputValues.packetReceptionRatioTOT = sum(outputValues.NcorrectlyTxBeaconsTOT,1) ./ sum(outputValues.NtxBeaconsTOT,1);
    outputValues.packetReceptionRatioCV2X = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X,1),1);
    outputValues.packetReceptionRatioCV2X_DENM = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X_DENM,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X_DENM,1),1);
    outputValues.packetReceptionRatioCV2X_CAM = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X_CAM,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X_CAM,1),1);

    % outputValues.packetReceptionRatioCV2X1 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X1,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X1,1),1);
    % outputValues.packetReceptionRatioCV2X2 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X2,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X2,1),1);
    % outputValues.packetReceptionRatioCV2X3 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X3,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X3,1),1);
    % outputValues.packetReceptionRatioCV2X4 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X4,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X4,1),1);
    % outputValues.packetReceptionRatioCV2X5 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X5,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X5,1),1);
    % outputValues.packetReceptionRatioCV2X6 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X6,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X6,1),1);
    % outputValues.packetReceptionRatioCV2X7 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X7,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X7,1),1);
    % outputValues.packetReceptionRatioCV2X8 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X8,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X8,1),1);
    % outputValues.packetReceptionRatioCV2X9 = sum(sum(outputValues.NcorrectlyTxBeaconsCV2X9,1),1) ./ sum(sum(outputValues.NtxBeaconsCV2X9,1),1);

    outputValues.packetReceptionRatio11p = sum(sum(outputValues.NcorrectlyTxBeacons11p,1),1) ./ sum(sum(outputValues.NtxBeacons11p,1),1);
    outputValues.packetReceptionRatioTOT = sum(sum(outputValues.NcorrectlyTxBeaconsTOT,1),1) ./ sum(sum(outputValues.NtxBeaconsTOT,1),1);

    % Average number of neighbors per vehicle
    outputValues.NneighborsCV2X = outputValues.NneighborsCV2X ./ outputValues.NvehiclesLTE;
    outputValues.Nneighbors11p = outputValues.Nneighbors11p ./ outputValues.Nvehicles11p;
    outputValues.NneighborsTOT = outputValues.NneighborsTOT ./ outputValues.NvehiclesTOT;
    outputValues.StDevNeighboursCV2X = outputValues.StDevNeighboursCV2X / simValues.snapshots;
    outputValues.StDevNeighbours11p = outputValues.StDevNeighbours11p / simValues.snapshots;
    outputValues.StDevNeighboursTOT = outputValues.StDevNeighboursTOT / simValues.snapshots;

    % Average number of vehicles in the scenario
    outputValues.AvgNvehiclesCV2X = outputValues.NvehiclesLTE / simValues.snapshots;
    outputValues.AvgNvehicles11p = outputValues.Nvehicles11p / simValues.snapshots;
    outputValues.AvgNvehiclesTOT = outputValues.NvehiclesTOT / simValues.snapshots;

    % 평균 CBR 구하기
    [row, col] = size(sinrManagement.cbrCV2X);
    cbr_size = row * col;
    sum_cbr = sum(sinrManagement.cbrCV2X,"all");
    outputValues.mean_CBR = sum_cbr / cbr_size;
    % Average number of successful BR reassignment per vehicle per second
    if outputValues.AvgNvehiclesCV2X>0
        outputValues.NreassignCV2X = (outputValues.NreassignCV2X ./ outputValues.AvgNvehiclesCV2X) / simParams.simulationTime;
    else
        outputValues.NreassignCV2X = 0;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Print To Files

    % %% =========
    % % Plot figs of related paper, could be commented in other case.
    % % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
    % % Only for IEEE 802.11p, highway scenario.
    % fname = fullfile(outParams.outputFolder, sprintf('_log_replications_%d_%s',outParams.simID, simParams.Technology));
    % ITSReplicasLog = stationManagement.ITSReplicasLog;
    % positionLog = stationManagement.positionLog;
    % save(fname, "ITSReplicasLog", "positionLog");
    % %% =========
    % Print to file of the CBR statistics
    if simParams.cbrActive == true
        if outParams.printCBR
            if sum(stationManagement.vehicleState ~= constants.V_STATE_LTE_TXRX)>0
                printCBRToFileITSG5(stationManagement,simParams,outParams,phyParams);
            end
            if sum(stationManagement.vehicleState == constants.V_STATE_LTE_TXRX)>0
                printCBRToFileCV2X(stationManagement,simParams,outParams,phyParams);
            end
        end
    end

    % Print update delay to file (if enabled)
    if outParams.printUpdateDelay || outParams.printDataAge || outParams.printPacketDelay
        printDelay(stationManagement,outputValues,appParams,outParams,phyParams,simParams);
    end

    % Print details for distances up to the maximum awareness range (if enabled)
    if outParams.printPacketReceptionRatio
        if sum(stationManagement.vehicleState == constants.V_STATE_LTE_TXRX)>0
            printPacketReceptionRatio(simParams.stringCV2X,outputValues.distanceDetailsCounterCV2X,outParams,appParams,simParams,phyParams);
        end
        if sum(stationManagement.vehicleState ~= constants.V_STATE_LTE_TXRX)>0
            %if simParams.technology~=1 % 11p or coexistence, not LTE
            printPacketReceptionRatio('11p',outputValues.distanceDetailsCounter11p,outParams,appParams,simParams,phyParams);
        end
    end

    % Print PRRmap to file (if enabled)
    if simParams.typeOfScenario==constants.SCENARIO_TRACE && outParams.printPRRmap && simParams.fileObstaclesMap
        printPRRmapToFile(simValues,simParams,outParams,positionManagement);
    end

    % Print power control allocation to file (if enabled)
    if outParams.printPowerControl
        printPowerControl(outputValues,outParams);
    end

    % Print hidden node probability to file (if enabled)
    if outParams.printHiddenNodeProb
        printHiddenNodeProb(outputValues,outParams);
    end

    % Print to XLS file
    outputToFiles(stationManagement,simParams,appParams,phyParams,sinrManagement,outParams,outputValues);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Print To Video
    fprintf('\nAverage number of vehicles in the scenario = %.0f\n',outputValues.AvgNvehiclesTOT);
    if outputValues.AvgNvehiclesCV2X>0 && outputValues.AvgNvehicles11p>0
        fprintf('Average %.0f C-V2X, ',outputValues.AvgNvehiclesCV2X);
        fprintf('average %.0f IEEE 802.11p\n',outputValues.AvgNvehicles11p);
    end
    for iPhyRaw=1:length(phyParams.Raw) % 1 부터 인식 범위(m)까지
        if iPhyRaw==1
            fprintf('*** In the range 0-%d:\n',phyParams.Raw(iPhyRaw));
        else
            fprintf('*** In the range %d-%d:\n',phyParams.Raw(iPhyRaw-1),phyParams.Raw(iPhyRaw));
        end
        if outputValues.AvgNvehiclesCV2X>0 && outputValues.AvgNvehicles11p>0
            fprintf('LTE: average neigbors %.2f +- %.2f, ',outputValues.NneighborsCV2X(iPhyRaw),outputValues.StDevNeighboursCV2X(iPhyRaw));
            fprintf('Blocking = %.5f\tError = %.5f\tCorrect = %.5f\n',outputValues.blockingRateCV2X(iPhyRaw),outputValues.errorRateCV2X(iPhyRaw),outputValues.packetReceptionRatioCV2X(iPhyRaw));
            fprintf('11p: average neighbors %.2f +- %.2f, ',outputValues.Nneighbors11p(iPhyRaw),outputValues.StDevNeighbours11p(iPhyRaw));
            fprintf('Blocking = %.5f\tError = %.5f\tCorrect = %.5f\n',outputValues.blockingRate11p(iPhyRaw),outputValues.errorRate11p(iPhyRaw),outputValues.packetReceptionRatio11p(iPhyRaw));
        else
            fprintf('Average neighbors %.2f +- %.2f\n',outputValues.NneighborsTOT(iPhyRaw),outputValues.StDevNeighboursTOT(iPhyRaw));
            fprintf('Blocking = %.5f\tError = %.5f\tCorrect = %.5f\n',outputValues.blockingRateTOT(iPhyRaw),outputValues.errorRateTOT(iPhyRaw),outputValues.packetReceptionRatioTOT(iPhyRaw));
        end
    end

    fclose('all');

    stoptime=toc;
    % fprintf("**transmission rate = %.2fms\n**transmitted power = %.2fdBm",appParams.averageTbeacon*1000,phyParams.Ptx_dBm);
    fprintf("\nsimulation time : %.0fmin %.0fsec \n",floor(stoptime/60),floor(stoptime-(floor(stoptime/60)*60)));

    cumulative_reward = 0;

    % Episodes : 1 episode EpisodesVector: every episode
    for i = 1:simValues.maxID
        if Buffer.Length > Agents(1,i).agent.AgentOptions.MiniBatchSize
            Epsilons(1,i) = max(Epsilons(1,i) * (1-Agents(1,i).agent.AgentOptions.EpsilonGreedyExploration.EpsilonDecay), Agents(1,i).agent.AgentOptions.EpsilonGreedyExploration.EpsilonMin);
        end
        EpisodeCumulativeReward = Episodes(1,i).EpisodeInfo.CumulativeReward;
        EpisodeStepsTaken = Episodes(1,i).EpisodeInfo.StepsTaken;
        EpisodeQ0 = double(Episodes(1,i).EpisodeInfo.Q0);
        
        EpisodesVector(1,i).Reward = cat(2,...
            EpisodesVector(1,i).Reward, EpisodeCumulativeReward);
        EpisodesVector(1,i).StepsTaken = cat(2,...
            EpisodesVector(1,i).StepsTaken, EpisodeStepsTaken);
        EpisodesVector(1,i).Q0 = cat(2,...
            EpisodesVector(1,i).Q0, EpisodeQ0);
        
        cumulative_reward = (cumulative_reward + Episodes(1,i).EpisodeInfo.CumulativeReward);   
        
    end
    cumulative_reward = cumulative_reward/simValues.maxID;
    
    cumulative_reward_vec = cat(2,...
        cumulative_reward_vec,cumulative_reward);
    
    addpoints(h,episodesCt,cumulative_reward);
    drawnow

   
    Ct = 0;
    candidate = [];
    result = 0;
    if episodesCt >=20
        for i = 1: 20
            candidate = cat(2,...
                candidate,cumulative_reward_vec(end - Ct));
            Ct = Ct + 1;
        end
        result = max(candidate);
        if result == cumulative_reward
            epi = num2str(episodesCt);
            save(strcat(epi,'.mat'),'Critics');
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%