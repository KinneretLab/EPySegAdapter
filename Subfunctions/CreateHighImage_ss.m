
function HighIm = CreateHighImage_ss (mask, image, Sigma_gauss, heavyMask)
maskGray = rgb2gray(mask);

if nargin == 4
    maskGray(~heavyMask) = 0;
end

% se = strel('disk',2);
% nmask=imdilate(maskGray, se);
% HighIm = uint16(nmask);

Gimage3 = imgaussfilt(maskGray, Sigma_gauss);
Gimage3 = double(Gimage3);
Gimage3 = Gimage3/256;

Imd = double(image);
HighIm3 = Imd.*Gimage3;
HighIm = uint16(HighIm3);

end