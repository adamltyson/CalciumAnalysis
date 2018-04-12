# CalciumAnalysis
 Adam Tyson | 21/03/2017 | adam.tyson@icr.ac.uk

To segment 2D timelapse of cellular calcium fluoresence and extract timecourses. N.B. needs a recent version of MATLAB and the Image Processing Toolbox. Should work on Windows/OSX/Linux.

Instructions:
 
 1 - Export 2D timelapse as multipage tiff (default if <4GB in Slidebook). All images can be saved into the same directory.
 
 2- Unzip CalciumAnalysis-master and place in the MATLAB path (e.g. C:\Users\User\Documents\MATLAB). 
 
 3- Open CalciumAnalysis\calciumBatch and run (F5 or the green "Run" arrow under the "EDITOR" tab). Alternatively, type "calciumBatch" into the Command Window and press ENTER
 
 4- Choose a directory that contains the images.
 
 5- Choose various options
 
      Testing - to speed up processing, just work with 10% of the data
      
      Plot results - display the segmentation, and the final plot. Useful for testing on a single dataset, cumbersome for many.
      
      Save results as csv - all the results (i.e. one value per timepoint per image) will be exported as a .csv for plotting and        statistics.
      
      Save segmentation - export the segmentation mask as a .tif file to for troubleshooting or later analysis.
    
6- Confirm or change options (the defaults can be changed under "function vars=getVars" in calciumBatch.m

        Segmentation threshold -  increase to be more stringent on what is a cell (and vice versa)
        
        Smoothing width - how much to smooth before thresholding (proportional to cell size
        
        Maximum hole size - how big a "hole" inside a cell should be filled
        
        Largest false cell to remove - how big can bright spots outside the main mass of cells be and still be ignored by the analysis
        
        Frames to use as basline - First N number of frames are averaged to use as a baseline (all results saved are relative to this baseline).
 
The script will then loop through all the images in the chosen folder, analysing time series and writing results. The segmentation images and the .csv files will be saved in the same directory with a time stamp (e.g. 201832115252) to distinguish different analyses.

Once the first time series has been analysed, the progress bar will give an estimate of the remaining time.
