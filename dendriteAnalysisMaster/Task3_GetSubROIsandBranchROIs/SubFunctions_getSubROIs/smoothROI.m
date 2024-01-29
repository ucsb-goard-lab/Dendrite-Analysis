function smoothedROI = smoothROI(roi, smoothingSigma, holeFillRadius, minObjectArea)
    % SMOOTHROI Smoothes the ROI by applying Gaussian blur and morphological operations.
    %
    %   smoothedROI = smoothROI(roi, smoothingSigma, holeFillRadius, minObjectArea)
    %
    %   Inputs:
    %       - roi: Binary image representing the ROI.
    %       - smoothingSigma: Standard deviation of the Gaussian blur.
    %       - holeFillRadius: Radius for morphological hole-filling operation (disk-shaped structuring element).
    %       - minObjectArea: Minimum area of connected objects to keep in the final ROI.
    %
    %   Output:
    %       - smoothedROI: Binary image representing the smoothed and processed ROI.

    % Smooth the ROI using Gaussian blur
    if smoothingSigma ~= 0
        smoothedROI = imgaussfilt(double(roi), smoothingSigma) > 0.5;
    else
        smoothedROI = roi;
    end

    % Fill holes in the smoothed ROI using morphological operation
    if holeFillRadius ~= 0
        seHoleFill = strel('disk', holeFillRadius);
        smoothedROI = imclose(smoothedROI, seHoleFill);
        % smoothedROI = imfill(smoothedROI, 'holes');
    end


    % Remove small objects from the smoothed ROI
    smoothedROI = bwareaopen(smoothedROI, minObjectArea);
end