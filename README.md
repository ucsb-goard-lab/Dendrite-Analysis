# dendriteAnalysis

*Note: tdmsREAD is not supported on Silicon Mac

## Installation
1. Download `MATLAB`. This program was last running on `Matlab 2023a`. Older and newer versions of `MATLAB` may or may not be supported.
2. Download the required toolboxes which can be found in the next section below.
3. Clone the repository onto your machine using `git clone https://github.com/ucsb-goard-lab/dendriteAnalysis.git`
4. Navigate to the cloned respository within `MATLAB` and add the folder titled `dendriteAnalysisMaster` and all subfolders to your path.
5. Open `dendriteAnalysisMaster.m`.
6. Within `MATLAB` navigate to your data folder. It should be structured so there are folders inside labeled 'DendritesDAY*' where each of those folders contains 'TSeries*' folders with .tif files for analysis. Add your data folder and all subfolders to your path.
7. Run `dendriteAnalysisMaster.m`.

## Toolboxes required
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- Computer Vision Toolbox
- Data Acquisition Toolbox or Communications Toolbox

## Program Tasks Explained
The program as a whole completes 5 steps: 
1.  Determines which cells are place cells
2.  Extract main ROIs
3.  Extracts sub-ROIs and branch ROIs
4.  Extracts DFF
5.  Computes Co-Tuning

Here are the five steps in further detail:

### 1. Determining Place Cells
This section processes neurotar recordings stored in the 'suite2p/plane0/' directory. It calculates the number of frames, extracts hardware timestamps, and determines the last frame time. The script then uses an XML file to find a cutoff point, considering potential errors. In all it determines which cells in the neurotar recording are likely place cells. In this section the user is prompted to select which place cells they want to process and a heat map is produced.

Expected Output:   
```
Determining which cells are place cells...
Converting suite2p to data...
mean r_neuropil = 0.74791
Inferring spikes...
Calculating place cell responses...
Testing reliability of each cell...
Percentage of place cells = 16.3%
Done! Processed data saved to current directory.
```
_*mean r_neuropil and percentage of place cells will vary_

<img width="226" alt="Screenshot 2023-11-20 at 5 53 18 PM" src="https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/013887c1-967d-470c-852c-4339870a3ad4">

<img width="562" alt="Screenshot 2023-11-20 at 5 53 36 PM" src="https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/2731df14-5658-4973-b451-4d83b0f24a14">

### 2. Extracting Main ROIs
Task 2 is for extracting the main soma and dendrite Regions of Interest (ROIs) from selected place cells (selected_PCs). The extracted ROIs are then saved in the registered data file. The script loops through each selected cell, plotting cell masks on the average projection of the registered data. It prompts the user to manually select the soma first and then the overall ROI (soma + dendrite). The resulting ROIs are saved for further analysis. Ensure that as a user you only select two ROIs, first the soma and then the dendrite.

Expected Output: 
```
Extracting main ROIs...
Manually select soma first, then ROI
Define ROIs on template imaging session:
Found 3 cells.
File already has 2 cell masks.
Append (2), Overwrite (1), or Cancel (0)? 1
File saved
transferring ROIs...
Done.
```
_*'File already has 2 cell masks.' may or may not appear _ 
![Screenshot 2023-11-20 at 6 05 13 PM (2)](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/c6f817ef-9e77-4199-b609-19dd0334cc50)

If you run into the error:
```
Unrecognized method, property, or field 'Character' for class 'matlab.ui.eventdata.ActionData'.

Error in subroutine_interactiveROI/changeMode (line 114)
            switch evt.Character
 
114             switch evt.Character
```
Relaunch matlab and it will resolve.

## 3. Getting Sub ROIs and Branch ROIs
This task extracts ROIs from selected dendritic masks with interactive GUIs. It walks the user through creating a skeleton of each dendrite and extracing an ROI from the skeleton. The following output and GUIs appear in this task:

#### Selecting a Cell's ROI
Select a polygon covering the entire region closely outlining a dendrite where your first point is your last point. If you forget to include any branches you can include them in a following step.
![Screenshot 2023-11-20 at 6 09 34 PM (2)](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/85684a49-a270-43c2-a1d4-67a0f7764fbb)

### Generating an Inital Dendrite Skeleton
Move the slider on the right until you get a clean skeleton of the selected dendrite. You will have an opportunity in the next dialog to clean it up further by adding or removing any parts of the skeleton. I've selected a threshold here with gaps to demonstrate adding and removing parts of the skeleton in the following step.

![Screenshot 2023-11-20 at 6 13 09 PM](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/2d86a127-5287-412c-8c3b-8063bae5530f)

### Cleaning the Dendrite Skeleton
A prompt appears to add or remove pieces of the skeleton.

![Screenshot 2023-11-20 at 6 14 01 PM](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/271d8c17-dc42-4cd2-9a64-892a73ae153b)

Pressing `Add Objects` will allow you to draw a polygon around any part of the dendrite you want included in the dendrite's sekeleton. 

![add1](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/47c5d369-2615-46b5-8ca0-01229cd652d8)

You can press `Add Object` and draw a polgyon as many times as you need.

![add2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/5a53897b-332a-4ef7-94aa-94bdce55ff36)


Selecting `Remove Object` will bring up the same ROI selection dialogue, but this time the region selected will be removed from the image skeleton.

![removeSelect](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/1d10935b-5a93-4e56-9ef4-4dee2e07d26c)
![remove1](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/f592c867-469e-4818-b164-01d55ffaea9f)

Finally, we can add again the missing region.

![add3](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/577b002a-07e1-49e5-a832-b0d192b8408c)

If any part of the skeleton will not appear even after selecting the region through the `Add Object` method, the next dialog will allow you to add it into the skeleton.

When finished adding and removing parts of the image skeleton, select `Neither`.
![Screenshot 2023-11-20 at 6 21 43 PM 2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/9b1c64ca-0b9f-4338-a068-67457c6bceb2)

### If the Dendrite Skeleton is Disconnected, a GUI will appear to allow you to connect the image skeleton
![Screenshot 2023-11-20 at 6 23 02 PM 2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/15134e55-7065-4189-8272-35de66fd69c8)

Select one point with a single left click
![connectPoint](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/20075b6d-1ffc-4271-bb33-c5f5b59eddb5)

and then the other
![Screenshot 2023-11-20 at 6 25 18 PM 2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/b18da261-de1f-47bf-9276-08680fed7bbe)

A yellow line between the dots will appear for a second and the dendrite skeleton will now be connected.
![Screenshot 2023-11-20 at 6 26 20 PM 2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/3ea58126-b294-4518-8392-4d40003ba5b7)

If there are more disconnected areas within the dendrite skeleton, a prompt will appear allowing the user to make more connections if needed.

![Screenshot 2023-11-20 at 6 27 13 PM](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/3804c2fc-dbc3-4835-aeac-ec33bd9dba34)


### If there are branch points, those can be selected through the following dialogue
Here is an example with a branch included in the skeleton:

![Screenshot 2023-11-20 at 6 33 53 PM](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/99a8d179-cfa4-43c9-b625-afa1870b0fd4)

Opt for choosing the base of the branch when selecting, as this point marks the split of the dendrite into the fewest pieces. By doing so, you avoid dealing with three separate objects that result from removing the intersection point of the branch and the main dendrite. Instead, you can simplify the process to work with just two objects—separating the branch from the main dendrite—by selecting the base of the branch.

<img width="932" alt="Screenshot 2023-11-20 at 6 34 45 PM" src="https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/a065c035-8fa3-487f-baf8-a26577d0a4ef">

### Extracing the ROI Around the Dendrite Skeleton
An interactive GUI will appear with 5 sliders to allow the user to adjust the ROI around each dendrite skeleton. Adjust the value of each slider to best fit the selected dendrite.

![Screenshot 2023-11-20 at 6 29 48 PM](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/840b6291-82a5-4f57-b51f-a72bed97bd90)

If in the previous steps the branch was included in the dendrite's skeleton and selected in the branch dialogue, then a second ROI GUI will appear for the branch:

![Screenshot 2023-11-20 at 6 42 55 PM 2](https://github.com/ucsb-goard-lab/dendriteAnalysis/assets/65988599/89ceefec-b282-4ff3-877e-f7e9233554cd)

Expected Output:
```
Getting sub-ROIs and branch ROIs...
Saving Skeleton...
Found 2 pieces of the dendrite
Saving ROI...
Saving ROI...
```

## 4. Extracting DFF
The script extractDFF.m employs the Goard Method to extract Delta F/F (DFF) signals from various Regions of Interest (ROIs) in a registered multipage TIF. It processes soma, dendrite, branch, and sub-ROI data using the C_ExtractDFF function. The script then restructures and filters the branch and sub-ROI data to eliminate small branches and empty cells. Finally, it constructs and saves data files (branch_ROIs.mat and subROIs.mat) containing the relevant information, such as cell masks, average projections, and file details. The DFF extraction is performed separately for branch and sub-ROI data, and the processed results are saved in the respective files.

## 5. Computing Co-Tuning
The script calculateCoTuning.m computes co-tuning metrics based on the O'Hare... Losonczy method (Science, 2022). It processes registered data for cell bodies, dendritic branches, and sub-ROIs. The tuning curves for each ROI across all laps are generated, and Pearson's correlation coefficients are calculated between various ROIs. The resulting correlation values are then organized and saved in separate data files (*_cellData_*, *_branchData_*, and *_subData_*). 


## Project File Structure
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
