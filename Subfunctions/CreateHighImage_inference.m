
function HighIm = CreateHighImage_inference (mask, image, Sigma_gauss, heavyMask)
maskGray = rgb2gray(mask);

if nargin == 4
    maskGray(~heavyMask) = 0;
end

Gimage3 = imgaussfilt(maskGray, Sigma_gauss);
Gimage3 = double(Gimage3);
Gimage3 = Gimage3/max(max(Gimage3))*(2^16-1); % Normalize to uint16 format

HighIm = uint16(Gimage3);

end