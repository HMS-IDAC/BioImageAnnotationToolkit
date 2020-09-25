%% 1. read and display (or go to [optional load] if you're resuming annotation from saved state)

load mri
V = double(squeeze(D))/255;

W = V;
AccM = false(size(W));
stackViewTool(W);

%% [optional save] save data to continue annotations later

disp('saving...')
data = {V,AccM,W};
save('data.mat','data');
disp('done saving')

%% [optional load] load data to continue annotations (then go to step 2)

disp('loading...')
load('data.mat');
V = data{1}; AccM = data{2}; W = data{3}; clear('data')
disp('done loading')

%% 2. annotate single sequence of contours (then go to step 3)

T = volumeAnnotationTool(W,1);

%% 3. interpolate contours
% then go to step 2; unless...
% ...you're done, in which case go to step 4
% ...you want to save variables to continue annotation later, in which use go to [optional save]

idcs = [];
for i = 1:size(V,3)
    if sum(sum(T.LabelMasks(:,:,i))) > 0
        idcs = [idcs i];
    end
end

M = zeros(size(V));
for i = 1:length(idcs)-1
    disp([i length(idcs)-1])
    I = imfill(T.LabelMasks(:,:,idcs(i)) > 0,'holes');
    J = imfill(T.LabelMasks(:,:,idcs(i+1)) > 0,'holes');
    M(:,:,idcs(i)) = I;
    M(:,:,idcs(i+1)) = J;
    for j = idcs(i)+1:idcs(i+1)-1
        a = (j-idcs(i))/(idcs(i+1)-idcs(i));
        K = bwInterpSingleObjectMasks(I,J,a);
        M(:,:,j) = K;
    end
end
M = M > 0;

AccM = AccM | M;

W = V;
W(AccM) = 0.75*W(AccM);
stackViewTool(W);

%% 4. save final annotations
% make sure the output file name is related to -- but not the same as -- the input file name

antPath = 'ant.tif';

Ant = 255*uint8(AccM);
disp('saving...')
imwrite(Ant(:,:,1), antPath, 'WriteMode', 'append', 'Compression','none');
for i = 2:size(V,3)
    imwrite(Ant(:,:,i), antPath, 'WriteMode', 'append', 'Compression','none');
end
disp('done saving')