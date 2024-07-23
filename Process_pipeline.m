close all
cd 'E:\'
addpath(genpath('C:\Users\admin\AppData\Roaming\MathWorks\MATLAB Add-Ons\Apps\NIMHMonkeyLogic22'))
addpath(genpath("util\"))

interested_path = {'....'};

nas_location = 'Z:\Monkey_ephys\...';
nas_location_raster = 'Z:\Monkey_ephys\...';

for path_now = 1:length(interested_path)
    Load_Data_function(interested_path{path_now});
    PostProcess_function_raw(interested_path{path_now}, nas_location_raster);
    PostProcess_function(interested_path{path_now}, nas_location);
end