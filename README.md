# dendriteAnalysis

*Note: tdmsREAD is not supported on Silicon Mac

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
│
├───Task4_ExtractDFF 
|    |    extractDFF.m 
|    |    C_extractDFF.m (SubFunction of extractDFF)
│
└───Task5_ComputeCoTuning
     |    calculateCoTuning.m 
     |    HPC_Analysis_Pipeline_Dendrites.m (SubFunction of calculateCoTuning )
```
