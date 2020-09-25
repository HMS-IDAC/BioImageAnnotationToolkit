%% read, load annotation tool

load mri
V = double(squeeze(D))/255;
V = V/max(V(:));

nClasses = 2;
T = volumeAnnotationTool(V, nClasses, 1-V);
% the third parameter is an optional 2nd channel, accessible by
% pressing the space key when using the annotation tool

%%

% annotate; close tool
% annotations are accessible at T.LabelMasks

%% display annotations

classIndex = 1;

V2 = V;
M = squeeze(T.LabelMasks(:,:,:,classIndex) > 0); 
V2(M) = 0.5*V2(M);
stackViewTool([V2, M]);