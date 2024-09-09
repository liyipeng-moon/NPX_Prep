close all
cd 'E:\'
addpath(genpath('C:\Users\admin\AppData\Roaming\MathWorks\MATLAB Add-Ons\Apps\NIMHMonkeyLogic22'))
addpath(genpath("util\"))
% 

interested_path={'F:\240906\'};

nas_location = 'Z:\Monkey_ephys\NPX_Processed';
nas_location_raster = 'Z:\Monkey_ephys\NPXRaster_Pool';
LocalData = 'D:\CookedData';
for path_now = 1:length(interested_path) 
    Load_Data_function(interested_path{path_now});
    PostProcess_function_raw(interested_path{path_now}, nas_location_raster);
    PostProcess_function(interested_path{path_now}, nas_location);
    PostProcess_function_LFP(interested_path{path_now}, nas_location);
    fileName = dir(fullfile(interested_path{path_now},"processed",'GoodUnit_2*'));
    Destination_file = fullfile(LocalData, fileName.name(10:end-4));
    mkdir(Destination_file)
    copyfile(fullfile(interested_path{path_now},"processed"), Destination_file)
    close all
end

