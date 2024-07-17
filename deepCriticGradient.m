function criticGradient = deepCriticGradient(critic,observation,action,targetq,LossVariable)

% Compute: q = Q(s,a). Set the UseForward name-value
% pair to true to support cases where the critic has layers that define a
% forward pass different than prediction (e.g. batch normalization or
% dropout layers).
% observation = dlarray(observation);
observation = cellfun(@(x) dlarray(double(x)), observation, 'UniformOutput', false);
q = getValue(critic,observation,UseForward=true);
% Loss is the half mean-square error of 
% q = Q(observation,action) against target1
% 예측값 q의 크기 확인
qSize = size(q);
targetq = double(targetq);
% targetq의 크기 맞추기
targetq = repmat(targetq, [qSize(1), qSize(2) / numel(targetq)]);
targetq = dlarray(targetq);
criticLoss = mse(q,targetq,DataFormat="CB");
criticGradient = dlgradient(criticLoss,critic.Learnables);
% compute the gradient of the loss with respect to the critic parameters
% criticGradient = dlgradient(criticLoss,critic.Learnables);
end
