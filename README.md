# dendriteAnalysis

*Note: tdmsREAD is not supported on Silicon Mac

## Installation
1. Download `MATLAB`. This program was last running on `Matlab 2023a`. Older and newer versions of `MATLAB` may or may not be supported
2. Download the required toolboxes which can be found in the next section below.
3. Clone the repository onto your machine using `git clone https://github.com/ucsb-goard-lab/dendriteAnalysis.git`
4. Open your data folder. It should be structured so there are folders inside labeled 'DendritesDAY*' where each of those folders contains 'TSeries*' folders with .tif files for analysis.
5. Open and run `dendriteAnalysisMaster.m`

## Toolboxes required
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- Computer Vision Toolbox
- Data Acquisition Toolbox or Communications Toolbox

## File Structure
```
dendriteAnalysisMaster
│   dendriteAnalysisMaster.m
│
├───Task1_DeterminePlaceCells
│   │   getExtractorInptDendrites.m
│   │   suite2p2data.m
│   │   HPC_Analysis_Pipeline_SingleEnv.m
│   │
│   ├───Classes
│   │       NewNeurotarExtractor.m
│   │
│   ├───SubFunctions_suite2p2data
│   │       spikeInference.m
│   │       deconvolveCa.m
│   │       DeConcatenateEnvironments_v2.m
|   |       subroutine_test_r_HPC
|   |       subroutine_find_corr_HPC
|   |       GetSn
|   |       estimate_time_constant
|   |       foopsi_oasisAR1
|   |       oasisAR1
│   │
│   └───SubFunctions_HPC_Analysis_Pipeline_SingleEnv
│           Spike_Max.m
│           Normalizer.m
│           Moving_v3.m
│           Active_Cells.m
│           DFF_transients.m
│           OneD_Track_Anaysis_v2.m
│           PC_reliability_checker_WTR_v2.m
│           SpatialInfoComputer.m
│           Speed_Cells.m
│           plotAllLapByLap_SingleEnv.m
│           plotHeatMaps.m
│           plotOneD_SingleEnv.m
│           plotSuite2pCellMasks.m
│           Save_Data.m
│           colormapMaker
│           getLaps.m (SubFunction of OneD_Track_Anaysis_v2)
│           Spatial_Information_v2.m (SubFunction of PC_reliability_checker_WTR_v2 and SpatialInfoComputer)
│
├───Task2_ExtractMainROIs
|   |    extractMainROIs.m 
|   |
|   └───SubFunctions_extractMainROIs 
|        |    B_DefineROI.m 
|        |    subroutine_interactiveROI.m (SubFunction of B_DefineROI)
|        |    subroutine_transferROI.m (SubFunction of B_DefineROI)
|        |    subroutine_normalize.m (SubFunction of subroutine_interactiveROI)
|        |    replotImage (defined in subroutine_manualAnchorPoints, SubFunction of subroutine_interactiveROI)
│
├───Task3_GetSubROIsAndBranchROIs 
|    |    getZoom.m 
|    |    getSubROIs.m 
|    |
|    └───SubFunctions_getSubROIs 
|         |    binarizeMeanGausProjection_NSWEdit.m
|         |    getBranchPoints_NSWEdit.m
|         |    pgonCorners.m
|         |    connectBranchPoints.m
|         |    extractROIAroundSkeleton.m
|         |    interactiveROIAdjustment.m
|         |    interactiveSkeleton.m
|         |    selectBaseBranches.m
|         |    separateSkeletonIntoBranches.m
|         |    skeletonizeBinarizedBranch.m
|         |    skeletonizeMeanGausProjection.m
|         |    smoothROI.m
|         |    userGetBranchPoints.m
│
├───Task4_ExtractDFF 
|    |    extractDFF.m
|    └─── SubFunctions of extractDFF
|         |    C_extractDFF.m ()
|         |    subroutine_find_corr.m
|         |    subroutine_progressbar.m
|         |    subroutine_test_r.m
│
├───Task5_ComputeCoTuning
│    |    calculateCoTuning.m
|    └─── SubFunctions of 
|         |    HPC_Analysis_Pipeline_Dendrites.m
|         |    OneD_Track_Analysis_v2.m
|         |    DFF_transients.m
|
└─── natsortfiles
```
