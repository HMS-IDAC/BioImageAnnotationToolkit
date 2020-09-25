%% read, load annotation tool

I = im2double(imread('rice.png'));
I = I/max(I(:));

nClasses = 2;
T = imageAnnotationTool(I, nClasses, 1-I);
% the third parameter is an optional 2nd channel, accessible by
% pressing the space key when using the annotation tool

%%

% annotate; close tool
% annotations are accessible at T.LabelMasks

%% display annotations

subplot(1,nClasses+1,1)
imshow(I)
for i = 1:nClasses
    subplot(1,nClasses+1,1+i)
    imshow(T.LabelMasks(:,:,i))
end