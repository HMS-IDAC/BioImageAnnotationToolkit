function K = bwInterpSingleObjectMasks(I,J,a)
% K = bwInterpSingleObjectMasks(I,J,a)
% computes intermediate object in morphing from I to J
% I,J: binary images with single, 'filled' object, in each
% a: value from 0 to 1 indicating position between I (a = 0) and J (a = 1)
% K: intermediate object mask
%
% example:
% 
% [X,Y] = meshgrid(1:400,1:400);
% 
% I = sqrt((X-200).^2+(Y-200).^2) < 75;
% J = sqrt(0.5*(X-220).^2+(Y-250).^2) < 100;
% 
% for a = 0:0.05:1
%     K = bwInterpSingleObjectMasks(I,J,a);
%     M = zeros(size(I));
%     M(bwmorph(I,'remove')) = 0.5;
%     M(bwmorph(J,'remove')) = 0.5;
%     M(bwmorph(K,'remove')) = 1;
%     imshow(M)
%     pause(0.1)
% end

I0 = bwmorph(I,'remove');
J0 = bwmorph(J,'remove');

[rI,cI] = find(I0);
[rJ,cJ] = find(J0);

[idx,d] = knnsearch([rI cI],[rJ cJ]);
[~,im] = min(d);

rImin = rI(idx(im));
cImin = cI(idx(im));
rJmin = rJ(im);
cJmin = cJ(im);

% imshowpair(I0,J0), hold on
% plot(cImin,rImin,'o')
% plot(cJmin,rJmin,'*'), hold off


maxP = Inf;
tI = bwtraceboundary(I,[rImin cImin],'W',8,maxP,'counterclockwise');
tJ = bwtraceboundary(J,[rJmin cJmin],'W',8,maxP,'counterclockwise');

% subplot(1,2,1)
% imshow(I0), hold on
% plot(tI(:,2),tI(:,1),'.'), hold off
% subplot(1,2,2)
% imshow(J0), hold on
% plot(tJ(:,2),tJ(:,1),'.'), hold off

nI = size(tI,1);
nJ = size(tJ,1);

if nI > nJ
    tJ2 = zeros(size(tI));
    for i = 1:nI
        tJ2(i,:) = tJ(ceil(i/nI*nJ),:);
    end
    tJ = tJ2;
else
    tI2 = zeros(size(tJ));
    for j = 1:nJ
        tI2(j,:) = tI(ceil(j/nJ*nI),:);
    end
    tI = tI2;
end

tM = round((1-a)*tI+a*tJ);
itM = sub2ind(size(I),tM(:,1),tM(:,2));

K0 = false(size(I0));
K0(itM) = true;
K0 = bwmorph(K0,'dilate',1);
K = imfill(K0,'holes');
K = bwmorph(K,'erode',1);

% imshowlt(I,K,J)

end