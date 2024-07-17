function loss = criticLossFunction(qPrediction, lossData)
    % criticLossFunction computes the loss for critic training

    % Create the action indication matrix.
    batchSize = lossData.batchSize;
    Z = repmat(lossData.ActionInfo.Elements', 1, batchSize);
    actionIndicationMatrix = lossData.Action(:,:) == Z;

    qPrediction = qPrediction{1};
    qPrediction = qPrediction(actionIndicationMatrix);
    loss = mse(qPrediction, reshape(lossData.TargetQValues, size(qPrediction)), 'DataFormat', 'CB');
end