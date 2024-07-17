function action = unique_usample(actInfo, numSamples)
    % Ensure unique samples are drawn
    numActions = length(actInfo); % actInfo의 길이를 구합니다
    samples = randperm(numActions, numSamples); % 고유한 값들을 뽑습니다
    action = zeros(1, 1, numSamples);
    action(1, 1, :) = samples;
end

