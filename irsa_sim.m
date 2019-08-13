function [loadNorm,throughputNorm,packetLossRatio_per_degree] = irsa_sim(sourceNumber,randomAccessFrameLength,packetReadyProb,degree,simulationTime,maxIter)
%A generalized IRSA Simulator

validateattributes(sourceNumber,{'numeric'},{'scalar','integer','positive','>' 2},mfilename,'sourceNumber',1)
validateattributes(randomAccessFrameLength,{'numeric'},{'scalar','integer','positive','>' 2},mfilename,'randomAccessFrameLength',2)
validateattributes(packetReadyProb,{'numeric'},{'scalar','real','>=', 0,'<=',1},mfilename,'packetReadyProb',3)
if exist('maxIter','var') % complete SIC
    validateattributes(maxIter,{'numeric'},{'integer','positive'},mfilename,'maximum SIC iterations',6)
end
if length(degree)>randomAccessFrameLength
    error('ERROR! The maximum degree cannot be greater than Random Access Frame Length.')
end
if any(degree<zeros(1,length(degree))) || (sum(degree,2)>1)
    error('ERROR! The degree distribution is not a probability distribution.')
end

ackdPacketCount = 0;
pcktTransmissionAttempts = 0;
pcktCollisionCount = 0;
sourceStatus = zeros(1,sourceNumber);
% legit source statuses are always non-negative integers and equal to:
% 0: source has no packet ready to be transmitted (is idle)
% 1: source has a packet ready to be transmitted, either because new data must be sent or a previously collided packet has waited the backoff time
% 2: source is backlogged due to previous packets collision
pcktGenerationTimestamp = zeros(1,sourceNumber);
currentRAF = 0;

if ~exist('maxIter','var')
    warning('Performing complete interference cancellation.')
end
pcktTransmissionAttempts_per_degree = zeros(1,length(degree));
ackdPacketCount_per_degree = zeros(1,length(degree));

while currentRAF < simulationTime
    randomAccessFrame = zeros(sourceNumber,randomAccessFrameLength); % later on referred to as RAF
    twinsOverhead = cell(sourceNumber,randomAccessFrameLength);
    currentRAF = currentRAF + 1;

    USER_name=cell(length(degree),1);

    for eachSource1 = 1:sourceNumber % create the RAF
        if sourceStatus(1,eachSource1) == 0 && rand(1) <= packetReadyProb % new packet
            sourceStatus(1,eachSource1) = 1;
            pcktGenerationTimestamp(1,eachSource1) = currentRAF;
            pcktRepetitionExp = rand(1);
            sum_degree=0;
            for i=1:length(degree)
                if (sum_degree < pcktRepetitionExp) && (pcktRepetitionExp <= sum_degree+degree(i))
                    % generate i replicas
                    [pcktTwins,rafRow] = generateTwins(randomAccessFrameLength,i);
                    randomAccessFrame(eachSource1,pcktTwins) = 1;
                    twinsOverhead(eachSource1,:) = rafRow;
                    USER_name{i,1}=[USER_name{i,1} eachSource1];
                end
                sum_degree= sum_degree + degree(i);
            end
        end
    end

    if ~exist('maxIter','var')
        [~,sicCol,sicRow] = sic(randomAccessFrame,twinsOverhead); % do the Successive Interference Cancellation
    elseif exist('maxIter','var')
        [~,sicCol,sicRow] = sic(randomAccessFrame,twinsOverhead,maxIter); % do the Successive Interference Cancellation
    end

    pcktTransmissionAttempts = pcktTransmissionAttempts + sum(sourceStatus == 1); % "the normalized MAC load G does not take into account the replicas" Casini et al., 2007, pag.1411; "The performance parameter is throughput (measured in useful packets received per slot) vs. load (measured in useful packets transmitted per slot" Casini et al., 2007, pag.1415
    ackdPacketCount = ackdPacketCount + numel(sicCol);
    for i=1:size(USER_name,1)
        pcktTransmissionAttempts_per_degree(i)= pcktTransmissionAttempts_per_degree(i) + numel(USER_name{i,1});
        ackdPacketCount_per_degree(i) = ackdPacketCount_per_degree(i) + numel(intersect(USER_name{i,1},sicRow));
    end

    sourcesReady = find(sourceStatus);
    sourcesCollided = setdiff(sourcesReady,sicRow);
    % if numel(sourcesCollided) > 0
    %     pcktCollisionCount = pcktCollisionCount + numel(sourcesCollided);
    %     sourceStatus(sourcesCollided) = 2;
    % end

    sourceStatus = sourceStatus - 1; % update sources statuses
    sourceStatus(sourceStatus < 0) = 0; % idle sources stay idle (see permitted statuses above)
end

loadNorm = pcktTransmissionAttempts / (simulationTime * randomAccessFrameLength);
throughputNorm = ackdPacketCount / (simulationTime * randomAccessFrameLength);

packetLossRatio_per_degree=zeros(1,length(degree));
for i=1:length(degree)
    if pcktTransmissionAttempts_per_degree(i) ~= 0
        packetLossRatio_per_degree(i) = 1 - ackdPacketCount_per_degree(i) / pcktTransmissionAttempts_per_degree(i);
    elseif pcktTransmissionAttempts_per_degree(i) == 0 && ackdPacketCount_per_degree(i) == 0
        packetLossRatio_per_degree(i) = 0;
    end
end
end