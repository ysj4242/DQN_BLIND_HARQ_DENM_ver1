function [trainingPlot,lineLossTrain1,ax] = hBuildFigureModelTest()

    % Copyright 2021 The MathWorks, Inc.

    plotRatio = 16/9;
    trainingPlot = figure(...
        'Visible','off',...
        'HandleVisibility','off', ...
        'NumberTitle','off',...
        'Name','Cart Pole Custom Training (Models)');
    trainingPlot.Position(3) = plotRatio * trainingPlot.Position(4);
    
    ax = gca(trainingPlot);
    
    lineLossTrain1 = animatedline(ax, 'Color',[0.85 0.325 0.098]);
    ylim(ax, [0 inf])
    xlabel(ax, "Episode")
    ylabel(ax, "Error")
    title(ax,'Model Prediction Error')
end