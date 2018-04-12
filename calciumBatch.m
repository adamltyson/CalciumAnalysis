function calciumBatch
%% Adam Tyson | 20/03/2018 | adam.tyson@icr.ac.uk
% Loads all tifs in a folder
% Segments a "cell" ROI at each time point
% Extracts mean fluorescence over time, and scales to baseline
% plots & saves

vars=getVars;
tic
cd(vars.Folder) 
files=dir('*.tif'); % all tif's in this folder
numImages=length(files);

progressbar('Analysing images') % Init prog bar
count=0;

for file=files' % go through all images
    count=count+1; 
    image=loadFile(file.name, vars.test);
    Results{2,count+1}=file.name; % save the filename for results .csv
    
    
    [maskedImage, thresholded]=threshMask(image, vars); % threshold and mask
    totalFluoTrace_norm=extractTrace(maskedImage, vars); % extract fluroescence trace

    for i=1:length(totalFluoTrace_norm) % save to one cell array
        Results{i+2,count+1}=totalFluoTrace_norm(i);
    end
    
    plotResults(image, thresholded, totalFluoTrace_norm, vars.plot)
    saveSegmentation(file.name, thresholded, vars)
    
    % progress bar
    frac1 =count/numImages;
    progressbar(frac1)
end
saveResults(Results, vars)
disp(['Time elapsed: ' num2str(toc) ' seconds'])

end

%% internal functions
function vars=getVars
    vars.Folder = uigetdir('', 'Choose directory containing images');
    
    vars.test= questdlg('Testing (only keep 10% of data)?', ...
	'Testing', ...
	'Yes', 'No', 'No'); 

    vars.plot = questdlg('Plot results?', ...
	'Plotting', ...
	'Yes', 'No', 'No'); 

    vars.saveTrace = questdlg('Save results as .csv?', ...
	'Exporting', ...
	'Yes', 'No', 'Yes');

    vars.saveSegmentation= questdlg('Save segmentation as.tif?', ...
	'Saving segmentation', ...
	'Yes', 'No', 'No');
    
    prompt = {'Segmentation threshold (a.u.):','Smoothing width (pixels):', 'Maximum hole size to fill (pixels):',...
        'Largest false cell to remove (pixels):', 'Frames to use as baseline:'};
    dlg_title = 'Analysis variables';
    num_lines = 1;
    defaultans = {'0.8', '10', '1000', '100', '10'};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    vars.threshScale=str2double(answer{1});%change sensitivity of threshold
    vars.smoothKernel=str2double(answer{2});% smoothing kernel
    vars.holeSize=str2double(answer{3});% largest hole to fill
    vars.noiseRemoval=str2double(answer{4}); % smallest obj to remove outside cells
    vars.baselineEnd=str2double(answer{5});% how many frames to use as baseline?
    
    vars.stamp=num2str(fix(clock)); % date and time 
    vars.stamp(vars.stamp==' ') = '';%remove spaces
end

function image=loadFile(filename, test)
    % load data, if test keep every 10th to speed up, if not, remove 1st 10%
    disp(['Processing: ' filename])
    info = imfinfo(filename);
    numZ = numel(info);
    
    image=uint16(zeros(info(1).Height, info(1).Width, numZ)); %initalise

    for k = 1:numZ
        image(:,:,k) = imread(filename, k, 'Info', info); % load data frame by frame  
    end
    
    if strcmp(test, 'Yes')        
        image=image(:,:,1:10:size(image,3)); % pick every 10th image
    else
        firstIm=round(0.1*size(image,3));
        image=image(:,:,firstIm:size(image,3)); % only keep final 90%
    end
end

function [maskedImage, thresholded]=threshMask(image, vars)
    smoothed=imgaussfilt(image,vars.smoothKernel); % smooth
    
    thresholded=zeros(size(image)); %initialise thresholded image
    
    for t=1:size(image,3)
        tempIm=smoothed(:,:,t); % assign smoothed image to temp
        levelOtsu = vars.threshScale*multithresh(tempIm); % calculate threshold (fudge)
        tempIm(tempIm<levelOtsu)=0; 
        tempIm(tempIm>0)=1;
        tempIm=~(bwareaopen(~tempIm, vars.holeSize)); % fill holes
        tempIm=bwareaopen(tempIm,vars.noiseRemoval); % remove small objects
        thresholded(:,:,t)=tempIm;
    end

    maskedImage=double(image).*thresholded; % apply mask to the raw image
end

function totalFluoTrace_norm=extractTrace(maskedImage, vars)
totalFluoTrace=zeros(1,size(maskedImage, 3)); %initialise
    for i=1:size(maskedImage,3) % for each image 
        totalFluoTrace(i)=mean(nonzeros(maskedImage(:,:,i))); % get the non-zero mean (i.e. those inside the mask)
    end

    if strcmp(vars.test, 'No')  
        baseline=mean(totalFluoTrace(1:vars.baselineEnd));
    else
        baseline=1;
    end
    
    totalFluoTrace_norm=totalFluoTrace./baseline; %normalise
end

function plotResults(image, thresholded, trace, plotYes)
    if strcmp(plotYes, 'Yes')        
        figure; imshowpair(image(:,:,1),thresholded(:,:,1),'montage') % show an overlay of the segmentation for the first image
        title('Segmentation of t=1')

        figure;
        plot(trace); % plot mean fluorescence
        title('Total cellular fluorescence (normalised)')
        xlabel('Time')
        ylabel('Mean fluorescence (normalised)')
    end
end

function saveResults(Results, vars)
    Results{1,2}='Filename';
    Results{2,1}='Timepoint';

    for i=1:size(Results,1)-2
        Results{i+2,1}=i;
    end
    
    if strcmp(vars.saveTrace, 'Yes')
        traces_table=cell2table(Results);
        writetable(traces_table, ['Mean_timecourses_' vars.stamp '.csv'])
    end
end

function saveSegmentation(filename, thresholded, vars)
    if strcmp(vars.saveSegmentation, 'Yes')
        for frame=1:size(thresholded,3)
            outfile=['segmentation_' vars.stamp '_' filename];
            imwrite(thresholded(:,:,frame),outfile, 'tif', 'WriteMode', 'append', 'compression', 'none');
        end 
    end
end