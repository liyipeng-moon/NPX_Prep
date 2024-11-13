close all

addpath(genpath('C:\Users\admin\AppData\Roaming\MathWorks\MATLAB Add-Ons\Apps\NIMHMonkeyLogic22'))
addpath(genpath('C:\Users\admin\Desktop\PROCESS_Pipeline_241113'))

interested_path(1) = {'E:\241110'};
for path_now = 1
    close all
    Load_Data_function(interested_path{path_now});
    PostProcess_function_raw(interested_path{path_now});
    PostProcess_function(interested_path{path_now});
    PostProcess_function_LFP(interested_path{path_now});
end
