%% read, load annotation tool

load mri
V = double(squeeze(D))/255;
V = V/max(V(:));

nClasses = 2;
maxRadius = 20;
T = sphereAnnotationTool(V , maxRadius, nClasses, 1-V);
% the third parameter is an optional 2nd channel, accessible by
% pressing the space key when using the annotation tool

%%

% annotate; close tool
% annotations are accessible at T.Spheres
% see cell below for interpretation

%% prepare to display annotations

[X,Y,Z] = meshgrid(1:size(V,1),1:size(V,2),1:size(V,3));

W = zeros(size(V));
for i = 1:size(T.Spheres,1)
    % sphereID = T.Spheres(i,1);
    classIndex = T.Spheres(i,2);
    centerRow = T.Spheres(i,3);
    centerCol = T.Spheres(i,4);
    centerPln = T.Spheres(i,5);
    radius = T.Spheres(i,6);
    
    D = sqrt((X-centerRow).^2+(Y-centerCol).^2+(Z-centerPln).^2);
    M = D > radius-1 & D < radius+1;
    W(M) = classIndex;
end

%% display annotations

classIndex = 2;

V2 = V;
M = W == classIndex; 
V2(M) = 0.5*V2(M);
stackViewTool([V2, M]);