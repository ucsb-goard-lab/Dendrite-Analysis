function roi = extractROIAroundSkeleton(image_skeleton, meanImageEnh_2, localRegionSize, percentile)
    % EXTRACTROIAROUNDSKELETON Extracts a region of interest (ROI) around each point in the image_skeleton
    %   and combines them to obtain the final ROI based on the intensity information in meanImageEnh_2.
    %
    %   roi = extractROIAroundSkeleton(image_skeleton, meanImageEnh_2, localRegionSize, percentile)
    %
    %   Inputs:
    %       - image_skeleton: Binary image representing the skeleton of the dendrite.
    %       - meanImageEnh_2: Image from which to extract contours around the skeleton points.
    %       - localRegionSize: Size of the local region around each skeleton point.
    %       - percentile: Percentile of intensity values to use as the threshold in each local region.
    %
    %   Output:
    %       - roi: Binary image representing the final region of interest around the entire skeleton.

    % Step 1: Find the Coordinates of Points in image_skeleton
    [row, col] = find(image_skeleton);

    % Step 2 and 3: Extract Local Regions and Apply Threshold
    roi = false(size(meanImageEnh_2));
    for i = 1:length(row)
        % Extract local region around each point
        localRegion = meanImageEnh_2(row(i)-localRegionSize:row(i)+localRegionSize, col(i)-localRegionSize:col(i)+localRegionSize);

        % Compute the threshold as a percentile of intensity values within the local region
        intensityThreshold = prctile(localRegion(:), percentile);

        % Apply threshold to identify contours
        localROI = localRegion > intensityThreshold;

        % Place the local ROI back into the larger ROI
        roi(row(i)-localRegionSize:row(i)+localRegionSize, col(i)-localRegionSize:col(i)+localRegionSize) = roi(row(i)-localRegionSize:row(i)+localRegionSize, col(i)-localRegionSize:col(i)+localRegionSize) | localROI;
    end
end
