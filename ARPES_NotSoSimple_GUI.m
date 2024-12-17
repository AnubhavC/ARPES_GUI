function ARPES_NotSoSimple_GUI
%Preamble This GUI aims to help data analysis using the data acquired by
%the VG chamber. It is aimed to be compatible with those data files but it
%can also be other data files but presumably some of the coding structure
%has to change. It contains 3 separated add-ons to assist the data
%analysis, UPSSECO locates the SECO file to calculate the work function.
%However, it assumes that you typed the Fermi level to the GUI field (Type
%Fermi level) beforehand. Second, Ef_Analysis is an independent GUI
%analyzing the Fermi level data to evaluate the Analyzer's energy
%resolution. Lastly, Shirley BG assumes that you have already imported the
%data file using (Import Data). It helps


%A lot of useful colormaps were provided by Matlab users.
%First, ARPES_customcolrmap is developed by Víctor  Martínez-Cagigal.
%Second, perceptually uniform colormaps - viridis, inferno, magma are
%provided by Ander Biguri. For details, visit LabMonti ARPES Github page.

%% Global variables declaration
%==========================================================================
% >>>>>>>>>>>>>>>>>>>>>>> Global variable sections <<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
filemarker = '*_AR*';
bias = 0;
z = zeros(2,2);
z2 = zeros(2,2);
Ef = 22.04; %Fermi level value
theta = 0; %Initial angle from Gamma
dtheta = 1; %Angular increment
y = zeros(2,2);
ytemp = zeros(2,2);
BE = zeros(2,2); %Binding energy matrix, eV
KE = zeros(2,2); %Kinetic energy matrix, eV
KE0 = zeros(2,2); %no bias assumed KE
KE2 = zeros(2,2);
y2 = zeros(2,2);
BE2 = zeros(2,2);
kpar2 = zeros(2,2);
kpar = zeros(2,2); %Momentum parallel to surface
dataflag =0; %dataflag turns to 1 when imported
smoothingflag = 0;%0 is no smoothing,1: moving average, 2: Sgolay
sw = 3; %sw is a smoothing window
numint = 3; %number of interpolants between two points
shadingflag = 0;%0: basic shading(flat),1: faceted, 2: interpolated
shadingflag2 = 0;%0: basic shading(flat),1: faceted, 2: interpolated
brightness = 0;%value varies from 1 to -1
brightflag = 0;%0: default brightness control. 1: brightness control set by a user
smoothflag = 0;%0: no smooth applied, 1: smooth applied.
interpflag = 0;%0: no interpolation, 1: 1D interp, 2: 2D interp
interpon = 0; %0: no interpolation, 1: interpolation on.
axisflag = 0; %0: no axis, 1: axis on
xaxisflag = 0;%0: angle, 1: kpar
NLflag = 0; %0: linear color scheme, 1: non-linear color scheme
revflag1 = 0;
revflag2 = 0; %0: no color map revert, 1: color map revert
normalflag = 0; %normal flag is 0 when the processed data plot is displayed not-normalized.
mymap1 = jet(800);%mymap 1 defines the first axis plot's color map
mymap2 = jet(800);%mymap 2 defines the second axis plot's color map
paraflag = 0; %0: no parameter show up, 1: parameter show up
numfiles = 0; %number of spectra
L = 0;%length of one spectrum
wf = 0; %work function of interest determined by UPSSECO, if any.
cmin1 = 0;
cmax1 = 5000;
cmin2 = 0;
cmax2 = 5000;
Data = zeros(2,2); %global variable managing the imported data
specnum1 = 1; %specnum indicates the spectrum index for angle-by-angle navigation. 
specnum2 = 1;
C2=1E1; %C2 is a factor that scales the impact of y-direction derivatives
C1=C2.*10^(-1); %C1 is a factor scales the impact of x-direction derivative
C2_2 = 1E1;
C1_2 = C2_2.*10^(-1);
coefficient = 1.1;
scalingfactor = 8;
centerpoint = 1E2;
zq = 0; %zq is the number of the whole spectra after the interpolation.
Curvfinal2 = zeros(2,2);
xmin = 0;
BEmin = 0;
xmax = 0;
BEmax = 0;
customflag = 0;%0: no custom plot range, 1: custom plot range in BE and x
xyflag = 0;%xyflag is set to 1 when user checks the xylines box.
xline1 = 0;
xline2 = 0.5;
xline3 = 1;
yline1 = 0;
yline2 = -0.5;
yline3 = -1;
plotTitle1 = 'Raw ARPES';
plotTitle2 = 'Processed ARPES';

%% Figures declaration
%==========================================================================
% >>>>>>>>>>>>>>>>>>>> Figures declaration <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
f = figure('Visible','on','Position',[50,50,1300,720]);
f2 = figure('Visible','off','Position',[100,100,700,600]);% Compare curvature-intensity for ax1 data
f3 = figure('Visible','off','Position',[100,100,700,600]);% Compare curvature-intensity for ax2 data
f4 = figure('Visible','off','Position',[100,100,400,300]);%Non-linear color scheme box
f5 = figure('Visible','off','Position',[200,200,300,400]);%xyline settings box
f.Name = 'ARPES Main Analysis Panel';
f2.Name = 'Compare raw curvature-intensity';
f3.Name = 'Compare processed curvature-intensity';
f4.Name = 'Non-linear color scheme parameter box';
f5.Name = 'X and Y lines settings box';

% Set close request to hide windows instead of closing them
set(f,'CloseRequestFcn',@f_closereq);
set(f2,'CloseRequestFcn',@f2_closereq);
set(f3,'CloseRequestFcn',@f3_closereq);
set(f4,'CloseRequestFcn',@f4_closereq);
set(f5,'CloseRequestFcn',@f5_closereq);

%% Axes declaration
%==========================================================================
% >>>>>>>>>>>>>>>>>>>>>>> Axes declaration <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
ax1 = axes('Parent',f,'Units','Pixels','Position',[150,150,400,500]);
ax2 = axes('Parent',f,'Units','Pixels','Position',[800,150,400,500]);
ax3 = axes('Parent',f2,'Units','Pixels','Position',[100,100,450,450]);
ax4 = axes('Parent',f3,'Units','Pixels','Position',[100,100,450,450]);

%% GUI Layout section
%==========================================================================
% >>>>>>>>>>>>>>>>>>>>>>> GUI Layout section <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
instr_parameterset = uicontrol('Parent',f,'Style','text','String',...
    'Parameter set and Data Import Section','Position',[20,670,150,40],'FontSize',11);
%% Data import parameters
type_fermilevel = uicontrol('Parent',f,'Style','edit','String',...
    'value only','Position',[20,370,100,25],...
    'Callback',{@Eflevel_Callback});
instr_fermilevel = uicontrol('Parent',f,'Style','text','String',...
    'Type Fermi level','Position',[20,395,100,25]);
type_bias = uicontrol('Parent',f,'Style','edit','String',...
    'value only','Position',[20,430,100,25],...
    'Callback',{@bias_Callback});
instr_bias = uicontrol('Parent',f,'Style','text','String',...
    'Type Bias','Position',[20,455,100,25]);
type_theta = uicontrol('Parent',f,'Style','edit','String',...
    'Initial angle','Position',[20,550,100,25],...
    'Callback',{@theta_Callback});
help_theta = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[95,575,25,25],...
    'Callback',{@helptheta_Callback});
instr_theta = uicontrol('Parent',f,'Style','text','String',...
    'Type theta','Position',[20,575,75,25]);
type_dtheta = uicontrol('Parent',f,'Style','edit','String',...
    'type an integer','Position',[20,490,100,25],...
    'Callback',{@dtheta_Callback});
help_dtheta = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[95,515,25,25],...
    'Callback',{@helpdtheta_Callback});
instr_dtheta = uicontrol('Parent',f,'Style','text','String',...
    'Type d(theta)','Position',[20,515,75,25]);
type_filemarker = uicontrol('Parent',f,'Style','edit','String',...
    'File marker','Position',[20,605,100,25],...
    'Callback',{@filemarker_Callback});
help_filemarker = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[95,635,25,25],...
    'Callback',{@helpmarker_Callback});
instr_filemarker = uicontrol('Parent',f,'Style','text','String',...
    'Type Filemarker','Position',[20,635,75,25]);
%% Import and Load buttons
% Button to choose the raw data folder
dataFolder = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Import Data',...
    'Position',[20,320,100,25],...
    'Callback',{@Folder_Callback});
loadParameter = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Load Parameters',...
    'Position',[20,290,100,25],...
    'Callback',{@loadpara_Callback});
loadColormap = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Load Colormap',...
    'Position',[20,260,100,25],...
    'Callback',{@loadcolor_Callback});
save_para = uicontrol('Parent',f,'Style','Pushbutton','String',...
    'Save Parameters', 'Position',[20,230,100,25],'Callback',{@savepara_Callback});
%% Other data analysis options controls
instr_others = uicontrol('Parent',f,'Style','text','String',...
    'Other Data Analysis Options','Position',[20,155,100,50],'Fontsize',9);
go_UPSSECO = uicontrol('Parent',f,'Style','pushbutton','String',...
    'UPSSECO','Position',[20,140,100,25],'Callback',{@UPSSECO_Callback});
go_ShirleyBG = uicontrol('Parent',f,'Style','pushbutton','String',...
    'ShirleyBG','Position',[20,80,100,25],'Callback',{@ShirleyBG_Callback});
go_EfANA = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Ef Analysis','Position',[20,110,100,25],'Callback',{@EfANA_Callback});
%% Raw data plot controls
plot_Raw = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Plot Intensity Map','Position',[180,50,150,35],'Fontsize',10,'Callback',{@plotraw1_Callback});
plot_comparison = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Compare Curvature-Intensity','Position',[340,50,150,35],'Fontsize',8,'Callback',{@plotcompare1_Callback});
plot_2DCurvature = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Plot 2D Curvature','Position',[180,10,150,35],'Fontsize',10,'Callback',{@plot2dcurv1_Callback});
instr_2DParameters = uicontrol('Parent',f,'Style','text','String',...
    'Curvature Parameters','Position',[340,15,150,35],'Fontsize',8);
help_2DParameters = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[490,25,25,25],'Fontsize',8,'Callback',{@help2Dpara_Callback});
C1_2DCurvature = uicontrol('Parent',f,'Style','edit','String',...
    'C1','Position',[340,5,70,25],'Fontsize',8,'Callback',{@para1C1_Callback});
C2_2DCurvature = uicontrol('Parent',f,'Style','edit','String',...
    'C2','Position',[410,5,70,25],'Fontsize',8,'Callback',{@para1C2_Callback});
%% Contrast, color, name option controls for raw plot
instr_cmin = uicontrol('Parent',f,'Style','text','String',...
    'min. contrast', 'Position',[160,690,70,25]);
edit_cmin = uicontrol('Parent',f,'Style','edit','String',...
    '0','Position',[170,670,50,25],'Callback',{@ax1cmin_Callback});
instr_cmax = uicontrol('Parent',f,'Style','text','String',...
    'max. contrast', 'Position',[230,690,70,25]);
edit_cmax = uicontrol('Parent',f,'Style','edit','String',...
    '5000','Position',[230,670,50,25],'Callback',{@ax1cmax_Callback});
name1 = uicontrol('Parent',f,'Style','pushbutton','String',...
    'name plot', 'Position',[290,670,70,25],'Fontsize',8,'Callback',{@namePlot1_Callback});
instr_shading = uicontrol('Parent',f,'Style','text','String',...
    'shading', 'Position',[550,690,70,25]);
set_shading = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["Flat","Faceted","Interp"], 'Position',[550,670,70,25],'Callback',{@setax1shading_Callback});
instr_colormap1 = uicontrol('Parent',f,'Style','text','String',...
    'colormap', 'Position',[470,690,70,25]);
set_colormap1 = uicontrol('Parent',f,'Style','popupmenu','String',...    
    ["Choose one" "W2B" "hot" "Magma" "viridis" "RWB" "jet"],'Position',[470,670,70,25],...
    'Callback',{@colormap1flag_Callback});
check_revert_colormap1 = uicontrol('Parent',f,'Style','checkbox','String',...
    'Revert color', 'Position',[380,680,90,30],'Callback',{@revertcolormap1_Callback});
%---------------End of first column in GUI panel---------------------------
%% Data representation controls
instr_datrepset = uicontrol('Parent',f,'Style','text','String',...
    'Data Representation Conditions','Position',[650,670,150,40],'FontSize',11);
check_smoothing = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Smoothing','Position',[650,635,75,25],'Callback',{@smoothingflag_Callback});
help_smoothing = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[730,635,25,25],...
    'Callback',{@helpsmooth_Callback});
methods_smoothing = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["Moving Ave" "Sgolay"],'Position',[650,605,50,25],...
    'Callback',{@smoothmethods_Callback});
window_smoothing = uicontrol('Parent',f,'Style','edit','String',...
    'Window','Position',[705,605,50,25],...
    'Callback',{@smoothwindow_Callback});
check_shading = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Shading','Position',[650,575,75,25],'Callback',{@shadingflag_Callback});
help_shading = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[730,575,25,25],...
    'Callback',{@helpshading_Callback});
methods_shading = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["Flat" "Faceted" "Interp"],'Position',[650,545,50,25],...
    'Callback',{@shadingmethods_Callback});
check_brightness = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Brightness','Position',[650,515,75,25],'Callback',{@brightnessflag_Callback});
help_brightness = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[730,515,25,25],...
    'Callback',{@helpbrightness_Callback});
value_brightness = uicontrol('Parent',f,'Style','edit','String',...
    'within +/-1','Position',[650,485,75,25],...
    'Callback',{@brightnessvalue_Callback});
check_interpolation = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Interpolation','Position',[650,455,100,25],'Callback',{@interpolationflag_Callback});
help_interpolation = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[730,455,25,25],...
    'Callback',{@helpinterpolation_Callback});
value_interpolation = uicontrol('Parent',f,'Style','edit','String',...
    '# of interpolants','Position',[700,425,50,25],...
    'Callback',{@interpolationvalue_Callback});
methods_interpolation = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["deactivate" "1D_angle" "2D grid"],'Position',[650,425,45,25],...
    'Callback',{@interpolationmethods_Callback});
check_axisswitch = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Axes on/off','Position',[650,395,100,25],'Callback',{@axisswitch_Callback});
Instr_xaxis = uicontrol('Parent',f,'Style','Text','String',...
    '*Angle vs KPar*','Position',[650,365,100,25]);
methods_axis = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["Choose One" "Angle" "KPar"],'Position',[650,345,70,25],...
    'Callback',{@xaxisflag_Callback});
nonlinearcolorscheme = uicontrol('Parent',f,'Style','Checkbox','String',...
    'NL Color','Position',[650,315,75,25],'Callback',{@NLcolorschemeflag_Callback});
help_NLCS = uicontrol('Parent',f,'Style','Pushbutton','String',...
    '?','Position',[725,315,25,25],'Callback',{@helpNLCS_Callback});
open_NLCSbox = uicontrol('Parent',f,'Style','Pushbutton','String',...
    'Open Setup box','Enable','Off','Position',[650,285,100,25],'Callback',{@OpenNLCSbox_Callback});
Instr_colormap = uicontrol('Parent',f,'Style','Text','String',...
    '*Choose Colormap*','Position',[650,255,100,25]);
methods_colormap = uicontrol('Parent',f,'Style','popupmenu','String',...
    ["Choose one" "W2B" "hot" "Magma" "viridis" "RWB" "jet"],'Position',[650,235,70,25],...
    'Callback',{@colormap2flag_Callback});
check_normalization = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Normalize data?','Position',[650,210,100,25],'Callback',{@normalize2_Callback});
check_inverse_colormap = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Revert Color','Position',[650,180,100,25],'Callback',{@revertcolormap2_Callback});
check_parameterrecord = uicontrol('Parent',f,'Style','Checkbox','String',...
    'Show Para','Position',[650,155,100,25],'Callback',{@showparaflag_Callback});
help_parameterrecord = uicontrol('Parent',f,'Style','pushbutton','String',...
    '?','Position',[725,155,25,25],'Callback',{@helppararecord_Callback});
%% Contrast, color, name option controls for processed plot
instr_cminx2 = uicontrol('Parent',f,'Style','text','String',...
    'min. contrast', 'Position',[790,690,70,25]);
edit_cminx2 = uicontrol('Parent',f,'Style','edit','String',...
    '0','Position',[800,670,50,25],'Callback',{@ax2cmin_Callback});
instr_cmaxx2 = uicontrol('Parent',f,'Style','text','String',...
    'max. contrast', 'Position',[860,690,70,25]);
edit_cmaxx2 = uicontrol('Parent',f,'Style','edit','String',...
    '5000','Position',[860,670,50,25],'Callback',{@ax2cmax_Callback});
name2 = uicontrol('Parent',f,'Style','pushbutton','String',...
    'name plot', 'Position',[910,670,70,25],'Fontsize',8,'Callback',{@namePlot2_Callback});
check_customrange = uicontrol('Parent',f,'Style','checkbox','String',...
    'Custom Plot range','Position',[960,700,150,25],'Callback',{@set_customrange_Callback});
value_xmin = uicontrol('Parent',f,'Style','edit','String',...
    'xmin','Position',[1180,700,50,20],'Callback',{@edit_xmin_Callback});
value_xmax = uicontrol('Parent',f,'Style','edit','String',...
    'xmax','Position',[1230,700,50,20],'Callback',{@edit_xmax_Callback});
value_BEmin = uicontrol('Parent',f,'Style','edit','String',...
    'BEmin','Position',[1080,700,50,20],'Callback',{@edit_BEmin_Callback});
value_BEmax = uicontrol('Parent',f,'Style','edit','String',...
    'BEmax','Position',[1130,700,50,20],'Callback',{@edit_BEmax_Callback});
check_xandylines = uicontrol('Parent',f,'Style','checkbox','String',...
    'X and Y lines?','Position',[990,670,100,25],'Callback',{@set_xylines_Callback});
open_xylinesbox = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Open XY line Box','Position',[1080,670,150,25],'Enable','off','Callback',{@edit_xylines_Callback});
%% Processed data plot controls
plot_MDC = uicontrol('Parent',f,'Style','pushbutton','String',...
    'MDC','Position',[930,50,50,35],'Fontsize',10,'Callback',{@MDC_Callback});
plot_EDC = uicontrol('Parent',f,'Style','pushbutton','String',...
    'EDC','Position',[930,10,50,35],'Fontsize',10,'Callback',{@EDC_Callback});
plot2_Raw = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Intensity Map','Position',[830,50,100,35],'Fontsize',10,'Callback',{@plotrawax2_Callback});
plot2_comparison = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Compare Curvature-Intensity','Position',[990,50,150,35],'Fontsize',8,'Callback',{@plotcompareax2_Callback});
plot2_2DCurvature = uicontrol('Parent',f,'Style','pushbutton','String',...
    '2D Curvature','Position',[830,10,100,35],'Fontsize',10,'Callback',{@plot2dcurvax2_Callback});
instr2_2DParameters = uicontrol('Parent',f,'Style','text','String',...
    'Curvature Parameters','Position',[1000,15,150,35],'Fontsize',8);
ax2_C1_2DCurvature = uicontrol('Parent',f,'Style','edit','String',...
    'C1','Position',[1000,10,70,25],'Fontsize',8,'Callback',{@para2C1_Callback});
ax2_C2_2DCurvature = uicontrol('Parent',f,'Style','edit','String',...
    'C2','Position',[1070,10,70,25],'Fontsize',8,'Callback',{@para2C2_Callback});
save_intensity_map = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Save Intensity Set','Position',[1140,50,120,35],'Callback',{@saveintensity_Callback});
save_curvature_map = uicontrol('Parent',f,'Style','pushbutton','String',...
    'Save Curvature Set','Position',[1140,15,120,35],'Callback',{@savecurvature_Callback});
%-------------------------End of second column in GUI panel----------------
%% Curvature section controls for raw
%-------------------------Compare y vs Curvature for raw data section------
next_button = uicontrol('Parent',f2','Style','pushbutton','String',...
    '==>','Position',[625,400,50,30],'Callback',{@nextcompare_Callback});
previous_button = uicontrol('Parent',f2','Style','pushbutton','String',...
    '<==','Position',[575,400,50,30],'Callback',{@previouscompare_Callback});
instr_navi = uicontrol('Parent',f2','Style','text','String',...
    'Navigate spectra','Position',[575,430,100,30]);
display_specnum1 = uicontrol('Parent',f2','Style','text','String',...
    cat(2,'Current spectrum number is ',num2str(specnum1)),'Position',[575,530,100,70]);
jumpto_specnum1 = uicontrol('Parent',f2','Style','edit','String',...
    'Jump to?','Position',[575,370,100,30],'Callback',{@jumpto1_Callback});
jump_specnum1 = uicontrol('Parent',f2','Style','pushbutton','String',...
    'Jump!','Position',[575,340,100,30],'Callback',{@jump1_Callback});
%% Curvature section controls for processed
%-------------------------Compare y vs Curvature for processed data section------
next2_button = uicontrol('Parent',f3,'Style','pushbutton','String',...
    '==>','Position',[625,400,50,30],'Callback',{@next2compare_Callback});
previous2_button = uicontrol('Parent',f3,'Style','pushbutton','String',...
    '<==','Position',[575,400,50,30],'Callback',{@previous2compare_Callback});
instr2_navi = uicontrol('Parent',f3,'Style','text','String',...
    'Navigate spectra','Position',[575,430,100,30]);
display_specnum2 = uicontrol('Parent',f3,'Style','text','String',...
    cat(2,'Current spectrum number is ',num2str(specnum1)),'Position',[575,530,100,70]);
jumpto_specnum2 = uicontrol('Parent',f3,'Style','edit','String',...
    'Jump to?','Position',[575,370,100,30],'Callback',{@jumpto2_Callback});
jump_specnum2 = uicontrol('Parent',f3,'Style','pushbutton','String',...
    'Jump!','Position',[575,340,100,30],'Callback',{@jump2_Callback});
%% Status field
%-------------------------GUI Status Message field?------------------------
instr_status1 = uicontrol('Parent',f,'Style','text','String',...
    'GUI Status','Position',[650,120,100,25]);
display_status = uicontrol('Parent',f,'Style','text','String',...
    'GUI has started. Type th relevant parameters before you hit Import Data. Start from Fermi level and hit Tab key to navigate faster.','Position',[600,20,200,100]);
%% Non-linear color scheme box
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>> Non-linear color scheme box<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
inst_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    'Parameters will be immediately applied once you hit plot buttons again.','Position',[100,10,200,30]);
input1_NLCSbox = uicontrol('Parent',f4,'Style','edit','String',...
    'center point','Position',[50,70,70,30],'Callback',{@CP_NLCS_Callback});
input2_NLCSbox = uicontrol('Parent',f4,'Style','edit','String',...
    'scaling intensity','Position',[130,70,70,30],'Callback',{@SI_NLCS_Callback});
input3_NLCSbox = uicontrol('Parent',f4,'Style','edit','String',...
    'coefficient','Position',[210,70,70,30],'Callback',{@Coef_NLCS_Callback});
inst2_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    'center point: change this value by a order of magnitude','Position',[50,250,350,20]);
inst3_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    ' example: 0.1->1->10->100->1000 to see an effective change','Position',[50,220,300,20]);
inst4_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    'Scaling intensity: Stretches the color palette at a certain color range.','Position',[50,190,350,20]);
 inst5_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    'Coefficient: Smaller the number, faster the color saturates','Position',[50,160,350,20]);
 inst6_NLCSbox = uicontrol('Parent',f4,'Style','text','String',...
    'Relative scale between Scaling intensity and Coefficient matters','Position',[50,130,350,20]); 
%% X and Y Lines Box
%==========================================================================%
%>>>>>>>>>>>>>>>>>>>> X and Y lines Box Sections <<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================%
check_xline1 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use xline 1','Position',[20,370,100,25]);
check_xline2 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use xline 2','Position',[20,340,100,25]);
check_xline3 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use xline 3','Position',[20,310,100,25]);
check_yline1 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use yline 1','Position',[20,270,100,25]);
check_yline2 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use yline 2','Position',[20,240,100,25]);
check_yline3 = uicontrol('Parent',f5,'Style','checkbox','String',...
    'use yline 3','Position',[20,210,100,25]);
field_xline1 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,370,100,25],'Callback',{@xline1_value_Callback});
field_xline2 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,340,100,25],'Callback',{@xline2_value_Callback});
field_xline3 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,310,100,25],'Callback',{@xline3_value_Callback});
field_yline1 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,270,100,25],'Callback',{@yline1_value_Callback});
field_yline2 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,240,100,25],'Callback',{@yline2_value_Callback});
field_yline3 = uicontrol('Parent',f5,'Style','edit','String',...
    'type number here','Position',[150,210,100,25],'Callback',{@yline3_value_Callback});
instruction_xyline = uicontrol('Parent',f5,'Style','text','String',...
    'You can check up to 3 lines per axis. xline is angle/k-space and yline is BE space. This will affect both of the axes in the main GUI panel.',...
    'Position',[20,100,250,100]);

%% Callback functions
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>> Call back sections <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
%% Shirley BG subtraction
%-------------------------Shirley BG subtraction---------------------------
    function ShirleyBG_Callback(~,~)
        msgbox('locate where the ARPES_BG_Subtraction_Tool_notsimpleGUI is at. It assumes that the data for BG subtraction is already imported via Import Data button.');
        [name,location] = uigetfile();
        fileID = fopen(cat(2,location,name));
        ARPES_BG_Subtraction_Tool_notsimpleGUI(KE,y,location,Ef);
    end
%% Fermi level analyzer
    function EfANA_Callback(~,~)
        ARPES_Ef_analyzer;
        msgbox('Fermi level analyzer is a separate package to find the Fermi level using a peak fitting approach. Refer to the MATLAB script preamble by opening Ef_analyzer file.');
    end
%% Import raw data
    function Folder_Callback(~,~)
                dataflag =1;
                location = uigetdir();
                if location == 0
                    msgbox('You decided not to choose a folder.');
                else
                    filenames={};
                    plotfile=dir(fullfile(location,filemarker));%Identify the image file location    
                    numfiles=length(plotfile);%calculate the number of spectra
                    filenames={plotfile,plotfile.name};%construct an array of file names
                    filenames(:,1) = []; %removing unnecessary data
                    Data=[]; %Make an empty array. Notice that zeros is not allowed as Data=[Data,importdata(filenames{1,i})]; will concatenate after the zero array.
                    for i=1:numfiles      %populate the empty array with the imported data
                      Data=[Data,importdata(fullfile(location,filenames{1,i}))];%Due to a particular mechanism that this concatenating method, preallocation is not possible.
                    end
                    % ------------Importing binding energy data
                    KE = zeros(length(Data(:,1)),numfiles);
                    for i=1:numfiles
                        KE(:,i)=Data(:,2*i-1);
                        KE = round(KE,2);%This is used in order to trim the BE matrix such that the BE is read like 300.32eV not 300.2199999eV
                    end
            %         KE = PE-BE;
                    L = length(KE(:,1));
                    %-------------Separate the intensity data into arrays of one data type
                    y=zeros(length(Data(:,1)),numfiles); %This array initially contains intensity data

                    for i=1:numfiles
                        y(:,i)=Data(:,2*i);
                    end
                    if KE(1,1)>KE(L,1)
                        y = flip(y);
                        KE = flip(KE);
                    end

                    display_status.String = 'The raw data set is imported.';
                end
    end
    function loadcolor_Callback(~,~)
        [targetfile,directory] = uigetfile();
        colorpalette = importdata(cat(2,directory,'/',targetfile));
        mymap2 = colorpalette;
        display_status.String = 'Colormap imported. Notice that it is best to import the colormap right before you hit Plot button on the second axis.';
    end
    function loadpara_Callback(~,~)
        [targetfile,directory] = uigetfile();
        paravector = importdata(cat(2,directory,'/',targetfile));     
        
        smoothingflag = cell2mat(table2array(paravector(1,2)));
        sw = cell2mat(table2array(paravector(2,2)));
        brightflag = cell2mat(table2array(paravector(3,2)));
        brightness = cell2mat(table2array(paravector(4,2)));
        interpflag = cell2mat(table2array(paravector(5,2)));
        numint = cell2mat(table2array(paravector(6,2)));
        cmin2 = cell2mat(table2array(paravector(7,2)));
        cmax2 = cell2mat(table2array(paravector(8,2)));
        NLflag = cell2mat(table2array(paravector(9,2)));
        coefficient = cell2mat(table2array(paravector(10,2)));
        scalingfactor = cell2mat(table2array(paravector(11,2)));
        centerpoint = cell2mat(table2array(paravector(12,2)));
        C2_2 = cell2mat(table2array(paravector(13,2)));
        C1_2 = cell2mat(table2array(paravector(14,2)));
        dtheta = cell2mat(table2array(paravector(15,2)));
        theta = cell2mat(table2array(paravector(16,2)));
        bias = cell2mat(table2array(paravector(17,2)));
        Ef = cell2mat(table2array(paravector(18,2)));
        filemarker = char(table2array(paravector(19,2)));
        cmin1 = cell2mat(table2array(paravector(20,2)));
        cmax1 = cell2mat(table2array(paravector(21,2)));
        customflag = cell2mat(table2array(paravector(22,2)));
        xmin = cell2mat(table2array(paravector(23,2)));
        xmax = cell2mat(table2array(paravector(24,2)));
        BEmin = cell2mat(table2array(paravector(25,2)));
        BEmax = cell2mat(table2array(paravector(26,2)));
        if smoothingflag > 0
            check_smoothing.Value =1;
            window_smoothing.String = num2str(sw);
        end
        if smoothingflag ==1
           methods_smoothing.Value = 1;
            
        elseif smoothingflag ==2
            methods_smoothing.Value = 2;
        end
        if brightflag ==1
            check_brightness.Value =1;
            value_brightness.String = num2str(brightness);
        end
        if interpflag ==1
            check_interpolation.Value = 1;
            methods_interpolation.Value =1;
            value_interpolation.String = num2str(numint);
            
        elseif interpflag ==2
            check_interpolation.Value = 1;
            methods_interpolation.Value = 2;
            value_interpolation.String = num2str(numint);
        end
        edit_cminx2.String = num2str(cmin2);
        edit_cmaxx2.String = num2str(cmax2);
        if NLflag ==1
            nonlinearcolorscheme.Value = 1;
        end
        type_filemarker.String = filemarker;
        input3_NLCSbox.String = num2str(coefficient);
        input2_NLCSbox.String = num2str(scalingfactor);
        input1_NLCSbox.String = num2str(centerpoint);
        ax2_C1_2DCurvature.String = num2str(C1_2);
        ax2_C2_2DCurvature.String = num2str(C2_2);
        type_theta.String = num2str(theta);
        type_dtheta.String = num2str(dtheta);
        type_fermilevel.String = num2str(Ef);
        type_bias.String = num2str(bias);
        edit_cmin.String = num2str(cmin1);
        edit_cmax.String = num2str(cmax1);
        if customflag ==1
            check_customrange.Value = 1;
        end
        value_xmin.String = num2str(xmin);
        value_xmax.String = num2str(xmax);
        value_BEmin.String = num2str(BEmin);
        value_BEmax.String = num2str(BEmax);
        display_status.String = 'Parameter set imported. Any changes are reflected on the data representation conditions. Notice that the colormap and revert color palette information is not addressed yet brightness value is imported. It is recommended to turn off the brightness and import colormap to restore 100%.';
        
    end
%% Smoothing
    function smoothmethods_Callback(source,handles)
            % Determine the selected data set.
            str = source.String;
            val = source.Value;
                % Set current data to the selected data set.
            switch str{val}
            case 'Moving Ave' % User selects a smoothing method
                smoothingflag =1;
                
            case 'Sgolay'
                smoothingflag =2;
            end
    end
    function smoothwindow_Callback(~,~)
        sw = str2double(window_smoothing.String);
        display_status.String = cat(2,'smoothing window set to ',window_smoothing.String);
    end
    function helpsmooth_Callback(~,~)
        msgbox('smoothing option smooths data spectrum per spectrum. Sgolay is useful when data point fluctuation is violently strong. Moving average averages a data point by referencing nearby data points. Larger the smoothing window, more aggressive smoothing result will be. This can result in evil artifacts, even merging two separate peaks in a single peak! ');
    end
%% Contrast and colors callbacks
    function ax1cmax_Callback(~,~)
        cmax1 = str2double(edit_cmax.String);
        display_status.String = 'maximum contrast value for axis 1 adjusted. Hit one of the plot buttons to visualize.';
    end
    function ax1cmin_Callback(~,~)
        cmin1 = str2double(edit_cmin.String);
        display_status.String = 'minimum contrast value for axis 1 adjusted. Hit one of the plot buttons to visualize.';
    end
    function ax2cmax_Callback(~,~)
        cmax2 = str2double(edit_cmaxx2.String);
        
        display_status.String = 'maximum contrast value for axis 2 adjusted. Hit one of the plot buttons to visualize.';
    end
    function ax2cmin_Callback(~,~)
        cmin2 = str2double(edit_cminx2.String);
        display_status.String = 'minimum contrast value for axis 2 adjusted. Hit one of the plot buttons to visualize.';
    end

    function setax1shading_Callback(source,~)
        str = source.String;
        val = source.Value;      
        switch str{val}
            case 'Flat'
                shadingflag = 0;
            case 'Faceted'
                shadingflag = 1;
            case 'Interp'
                shadingflag = 2;
        end
        
    end
    function revertcolormap1_Callback(~,~)
        if check_revert_colormap1.Value ==1
            revflag1 = 1;
            display_status.String = 'Color map will be reverted.';
        else 
            revflag1 =0;
            display_status.String = 'Color map will be displayed in normal order.';
        end
        
    end
    function colormap1flag_Callback(source,~)
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'W2B'
                mymap1 = ARPES_white2blue(800);
                display_status.String = 'Color map is set to White2Blue';
            case 'hot'
                mymap1 = hot(800);
                display_status.String = 'Color map is set to hot';
            case 'Magma'
                mymap1 = ARPES_magma(800);
                display_status.String = 'Color map is set to Magma (Perceptually uniform colormap)';
            case 'viridis'
                mymap1 = ARPES_viridis(800);
                display_status.String = 'Color map is set to viridis (Perceptually uniform colormap)';
            case 'RWB'
                mymap1 = ARPES_customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
                display_status.String = 'Color map is set to Red-White-Blue.';
            case 'jet'
                mymap1 = jet(800);
                display_status.String = 'Color map is set to jet';
        end
        
    end
%% Shading/Brightness Callbacks
    function shadingmethods_Callback(source,~)
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'Flat'
                shadingflag2 = 0;
                display_status.String = 'Shading is set to flat';
            case 'Faceted'
                shadingflag2 = 1;
                display_status.String = 'Shading is set to faceted';
            case 'Interp'
                shadingflag2 = 2;
                display_status.String = 'Shading is set to interpolated';
        end
    end
    function brightnessvalue_Callback(~,~)
        if abs(str2double(value_brightness.String))<=1
            brightness = str2double(value_brightness.String);
            display_status.String = cat(2,'Brightness value set to ',value_brightness.String);
        else 
            msgbox('Brightness value needs to be within +/- 1','Error');
        end
    end
    function helpshading_Callback(~,~)
        msgbox('Shading is one part of the plot representation. Flat might show the true-to-data plot. Interp will interpolate the data to make it looking smooth. Be mindful of possible artifacts.');
    end
    function helpbrightness_Callback(~,~)
        msgbox('Brightness can adjust an overall tone. This is equivalent to shifting the color bar. Value must be contained within +/-1. Notice that brightness control is cumulative effect. You will see a gradual tone change as you hit plot buttons over and over.');
    end
    function helpinterpolation_Callback(~,~)
        msgbox('Interpolation can fill virtual data between the adjascent data points. This can result in artifacts to some extent yet it may be useful to make 2D curvature looking smoother. 1D angle interpolates the data points along the angle which may not be reflected in k-space as angle->kspace is a non-linear transformation. 2D grid uses a 2D grid thus there is a high possibility that 2D grid may appear differently.');
    end
    function helpNLCS_Callback(~,~)
        msgbox('Non-linear color scheme uses an exponential function to modify color variation rate in the color map. By properly setting the values, it may have a largest color variation at intensity value range that you are interested in.');
    end
    function helppararecord_Callback(~,~)
        msgbox('Once Show parameter is checked, the resulting plot will also display all the relevant parameters used for data processing. As you save the plot, it will save the parameter set too. Thereby you will be able to keep track of parameter variation for data analysis.');
    end
    function smoothingflag_Callback(~,~)
        if check_smoothing.Value ==1
            smoothflag = 1;
            display_status.String = 'Smoothing activated.';
        else
            smoothflag = 0;
            display_status.String = 'Smoothing deactivated.';
        end
    end
    function shadingflag_Callback(~,~)
        if check_shading.Value ==1
            shadingflag = 1;
            display_status.String = 'shading activated.';
        else
            shadingflag = 0;
            display_status.String = 'shading deactivated. The default setting will be applied.';
        end
    end
    function brightnessflag_Callback(~,~)
        if check_brightness.Value ==1
            brightflag =1;
            display_status.String = 'Brightness will be adjusted by the value set.';
        else
            brightflag = 0;
            display_status.String = 'Brightness is set to default.';
        end
    end
%% Figure titles
    function namePlot1_Callback(~,~)
        plotTitle1 = inputdlg('Enter plot title');
    end
    function namePlot2_Callback(~,~)
        plotTitle2 = inputdlg('Enter plot title');
    end
%% Parameter Set and Data Import Callbacks
    function helpmarker_Callback(~,~)
        msgbox('Filemarker indicates a specific set of common letters that every spectrum you want to import shares. For example, if all the files contain _AR_ in the file name, _AR_ should be the filemarker to facilitate importing process.','Help_Filemarker');
    end
    function helptheta_Callback(~,~)
        msgbox('Theta means how many degrees the gamma point angle is away from the first file to be imported. For example, if the first file starts from 6 degrees away from gamma and it has 1 degree increment, -7 is applied to every file number index such that 1-7 = -6 7-7=0 such that the 7th file, which is gamma, becomes 0 degrees.','Help_Theta');
    end
    function helpdtheta_Callback(~,~)
        msgbox('dTheta means what is the angle increment within the data set. For example, if the experiment increased the polar angle by 2 degrees per scan, dTheta is 2. If it was 1 degree per scan, dTheta is 1.','Help_dTheta');
    end
    function filemarker_Callback(~,~)
        filemarker = cat(2,'*',type_filemarker.String,'*');
        display_status.String = cat(2,'Filemarker is set to ',filemarker);
    end
    function theta_Callback(~,~)
        theta = str2double(type_theta.String);
        display_status.String = cat(2,'Gamma point is set as ',type_theta.String,' degrees away from the first data file. Make sure that a minus sign is correctly assigned.');
    end
    function dtheta_Callback(~,~)
        dtheta = str2double(type_dtheta.String);
        display_status.String = cat(2,'Angle increment is set to ',type_dtheta.String);
    end
    function bias_Callback(~,~)
        bias = str2double(type_bias.String);
        display_status.String = cat(2,'Bias value is set to ',type_bias.String,'. Make sure that if a minus sign is correctly assigned, if any.');
    end
    function Eflevel_Callback(~,~)
        Ef = str2double(type_fermilevel.String);
        display_status.String = cat(2,'Fermi level is set to ',type_fermilevel.String);
    end
%% UPS SECO Callback
    function UPSSECO_Callback(~,~)
        [targetfile,directory] = uigetfile();
        SECOdata = importdata(cat(2,directory,'/',targetfile));
        wf = ARPES_UPSSECO(SECOdata,Ef);
        display_status.String = cat(2,'Workfunction is determined by UPSSECO. The value is ',num2str(wf),'. However, make sure that you have typed the Fermi level correctly. UPSSECO imports the Fermi level from the GUI set up.');
    end
%% Raw Plot Callbacks
    function plotraw1_Callback(~,~)
        BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
        kpar=zeros(L,numfiles);
        KE0=KE+bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
        for m=1:numfiles
            kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
        end              
        axes(ax1);
        if revflag1 ==0
            colormap (mymap1);
        elseif revflag1 ==1
            colormap (flipud(mymap1));
        end
        if xaxisflag ==1
            if customflag ==0
                h= surf(kpar,BE,y);
                axis([ min(min(kpar)) max(max(kpar)) min(BE(:,1)) max(BE(:,1)) min(min(y(:,:))) max(max(y(:,:)))+max(max(y(:,:)))*0.1])
            xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            else
                h= surf(kpar,BE,y);
                axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(y(:,:))) max(max(y(:,:)))+max(max(y(:,:)))*0.1])
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            end
        else
            if customflag ==0
                h= surf(z,BE,y);
                axis([ min(min(z)) max(max(z)) min(BE(:,1)) max(BE(:,1)) min(min(y(:,:))) max(max(y(:,:)))+max(max(y(:,:)))*0.1])
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            else
                h= surf(z,BE,y);
                axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(y(:,:))) max(max(y(:,:)))+max(max(y(:,:)))*0.1])
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            end 
        end        
        axis on
        if shadingflag == 0
            shading flat;
        elseif shadingflag == 1
            shading faceted;
            set(h,'LineWidth',1)
            set(h,'EdgeAlpha',0.05)
        elseif shadingflag == 2
            shading interp;
        end
        caxis ([cmin1,cmax1])
        view(0,89.9)
        colorbar('westoutside')
        ylabel('Binding Energy (eV)','FontSize',16)
        zlabel('Intensity','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title(plotTitle1);
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        hold off
        display_status.String = 'Raw data plot complete';
    end
%% Curvature Plot Callbacks
    function plot2dcurv1_Callback(~,~)
        %Initial vectors set up
            BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
            kpar=zeros(L,numfiles);
            KE0=KE+bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
            for m=1:numfiles
                kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y);

        for i=1:numfiles   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:numfiles   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end

        %---------------    Curvature section    -------------
        t1=(1+C1.*((gkpar).^2)).*C2.*(g2BE);
        t2=2.*C1.*C2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2.*((gBE).^2)).*C1.*(g2kpar);
        t4=(1+C1.*((gkpar).^2)+C2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:numfiles
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal=Newcurv2D.*(y); % to optimize the quality, you might have to tune the number dividing the y
        %Plotting section
        axes(ax1);
        if revflag1 ==0
            colormap (mymap1);
        elseif revflag1 ==1
            colormap (flipud(mymap1));
        end
        
        if xaxisflag ==1
            if customflag ==0
                h = surf(kpar,BE,Curvfinal);
                axis([ min(min(kpar)) max(max(kpar)) min(BE(:,1)) max(BE(:,1)) min(min(Curvfinal(:,:))) max(max(Curvfinal(:,:)))+max(max(Curvfinal(:,:)))*0.1])
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            else
                h = surf(kpar,BE,Curvfinal);
                axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(Curvfinal(:,:))) max(max(Curvfinal(:,:)))+max(max(Curvfinal(:,:)))*0.1])
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            end
        else
            if customflag ==0
                h = surf(z,BE,Curvfinal);
                axis([ min(min(z)) max(max(z)) min(BE(:,1)) max(BE(:,1)) min(min(Curvfinal(:,:))) max(max(Curvfinal(:,:)))+max(max(Curvfinal(:,:)))*0.1])
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            else
                h = surf(z,BE,Curvfinal);
                axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(Curvfinal(:,:))) max(max(Curvfinal(:,:)))+max(max(Curvfinal(:,:)))*0.1])
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
            end 
        end        
        axis on
        if shadingflag == 0
            shading flat;
        elseif shadingflag == 1
            shading faceted;
            set(h,'LineWidth',3)
            set(h,'EdgeAlpha',0.05)
        elseif shadingflag == 2
            shading interp;
        end
        caxis ([cmin1,cmax1])
        view(0,89.9)
        colorbar('westoutside')
        ylabel('Binding Energy (eV)','FontSize',16)
        zlabel('Curvature','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title (plotTitle1);
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        hold off        
        display_status.String = '2D Curvature plot complete';
    end
%% Curvature Parameters Callbacks
    function help2Dpara_Callback(~,~)
        msgbox('C1 and C2 are the parameters determining the curvature characteristics. C1 impacts the x-direction derivative and C2 impacts the y-direction derivative. If C1 is too small it becomes y-based 1D curvature effectively. It is recommended to set C1 and C2 equivalent to numerical step sizes of the data. For example, if energy step size was 0.01eV and kpar step size is roughly 0.002 then best to have C2 and C1 proportionally different.','help_C1 and C2');
    end
    function para1C1_Callback(~,~)
        C1 = str2double(C1_2DCurvature.String);
        display_status.String = cat(2,'C1 is set to ',C1_2DCurvature.String);
    end
    function para1C2_Callback(~,~)
        C2 = str2double(C2_2DCurvature.String);
        display_status.String = cat(2,'C2 is set to ',C2_2DCurvature.String);
    end
    function plotcompare1_Callback(~,~)
                %Initial vectors set up
            BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
            kpar=zeros(L,numfiles);
            KE0=KE-bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
            for m=1:numfiles
                kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y);

        for i=1:numfiles   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:numfiles   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1.*((gkpar).^2)).*C2.*(g2BE);
        t2=2.*C1.*C2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2.*((gBE).^2)).*C1.*(g2kpar);
        t4=(1+C1.*((gkpar).^2)+C2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:numfiles
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal=Newcurv2D.*(y); % to optimize the quality, you might have to tune the number dividing the y
        set(f2,'Visible','on')
        axes(ax3)
        plot(BE(:,1),y(:,1),BE(:,1),Curvfinal(:,1));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
    end

    function nextcompare_Callback(~,~)
        if specnum1 == numfiles
            specnum1 = numfiles;
        elseif specnum1 < numfiles
            specnum1 = specnum1+1;
        end
                        %Initial vectors set up
            BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
            kpar=zeros(L,numfiles);
            KE0=KE-bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
            for m=1:numfiles
                kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y);

        for i=1:numfiles   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:numfiles   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1.*((gkpar).^2)).*C2.*(g2BE);
        t2=2.*C1.*C2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2.*((gBE).^2)).*C1.*(g2kpar);
        t4=(1+C1.*((gkpar).^2)+C2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:numfiles
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal=Newcurv2D.*(y); % to optimize the quality, you might have to tune the number dividing the y
        set(f2,'Visible','on')
        axes(ax3)
        plot(BE(:,specnum1),y(:,specnum1),BE(:,specnum1),Curvfinal(:,specnum1));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum1.String = cat(2,'Current spectrum number is ',num2str(specnum1));
    end

    function previouscompare_Callback(~,~)
        if specnum1 == 1
            specnum1 = 1;
        elseif specnum1 > 1
            specnum1 = specnum1-1;
        end
                        %Initial vectors set up
            BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
            kpar=zeros(L,numfiles);
            KE0=KE-bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
            for m=1:numfiles
                kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y);

        for i=1:numfiles   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:numfiles   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1.*((gkpar).^2)).*C2.*(g2BE);
        t2=2.*C1.*C2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2.*((gBE).^2)).*C1.*(g2kpar);
        t4=(1+C1.*((gkpar).^2)+C2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:numfiles
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal=Newcurv2D.*(y); % to optimize the quality, you might have to tune the number dividing the y
        set(f2,'Visible','on')
        axes(ax3)
        plot(BE(:,specnum1),y(:,specnum1),BE(:,specnum1),Curvfinal(:,specnum1));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum1.String = cat(2,'Current spectrum number is ',num2str(specnum1));
    end

    function jumpto1_Callback(~,~)
        if str2double(jumpto_specnum1.String) <= numfiles && str2double(jumpto_specnum1.String) >= 1
            specnum1 = str2double(jumpto_specnum1.String);
        else
            msgbox(cat(2,'Error in Jump To number. Check if it is defined within 1 - ',num2str(numfiles)),'Error');
        end
        display_specnum1.String = cat(2,'The spectrum number will be set to ',num2str(specnum1));
    end
    function jump1_Callback(~,~)
                                %Initial vectors set up
            BE=KE-Ef;  %converting KE to BE
                    
        %Angle matrixx`
        z=zeros(L,numfiles);    % z-vector to represent the angle of photoemission
        for m=0:numfiles-1
            z(:,m+1)=theta+(m*dtheta);
        end
            kpar=zeros(L,numfiles);
            KE0=KE-bias;       %KE0 is the kinetic energy matrix excluding bias which is necessary for kpar calculations
            for m=1:numfiles
                kpar(:,m)=sqrt(2*(9.109*10^-31)*KE0(:,m)*(1.602*10^-19)).*sin(z(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y);

        for i=1:numfiles   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:numfiles   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1.*((gkpar).^2)).*C2.*(g2BE);
        t2=2.*C1.*C2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2.*((gBE).^2)).*C1.*(g2kpar);
        t4=(1+C1.*((gkpar).^2)+C2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:numfiles
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal=Newcurv2D.*(y); % to optimize the quality, you might have to tune the number dividing the y
        set(f2,'Visible','on')
        axes(ax3)
        plot(BE(:,specnum1),y(:,specnum1),BE(:,specnum1),Curvfinal(:,specnum1));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum1.String = cat(2,'Current spectrum number is ',num2str(specnum1));
        
    end
%% Interpolation Callbacks
    function interpolationflag_Callback(~,~)
        if check_interpolation.Value ==1
            interpon =1;
            
            display_status.String = 'Interpolation will be applied. Default setting is Nint = 3 and 1D along angle axis. If you want to set up a specific parameter set, you should.';
        else
            interpon =0;
            interpflag =0;
            methods_interpolation.Value = 1;
            display_status.String = 'Interpolation deactivated.';
        end
    end
    function interpolationmethods_Callback(source,~)
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'deactivate'
                interpflag =0;
                interpon =0;
                check_interpolation.Value =0;
                display_status.String = 'Interpolation deactivated.';
            case '1D_angle'
                interpflag =1;
                display_status.String = 'Interpolation method is set to 1D along angle.';
            case '2D grid'
                interpflag =2;
                display_status.String = 'Interpolation method is set to 2D Gridded interpolation.';
        end
    end
    function interpolationvalue_Callback(~,~)
        numint = str2double(value_interpolation.String);
        display_status.String = cat(2,'The number of interpolant between every two data point is ',value_interpolation.String);
    end
%% Axes Callbacks
    function axisswitch_Callback(~,~)
        if check_axisswitch.Value ==1
            axisflag =1;
            display_status.String = 'Axis will be plotted. Default is set to angle. If you want to plot it with Kpar, you need to define so.';
        else
            axisflag =0;
            display_status.String = 'Axis will not be plotted.';
        end
    end
    function xaxisflag_Callback(source,~)
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'KPar'
                xaxisflag = 1;
                display_status.String ='x axis is set to KPar now.';
            case 'Angle'
                xaxisflag = 0;
                display_status.String = 'x axis is set to angle now.';
        end
    end
%% Show Parameters
    function showparaflag_Callback(~,~)
        if check_parameterrecord.Value ==1
            paraflag = 1;
            display_status.String = 'Parameters will show up inside the plot.';
        else
            paraflag = 0;
            display_status.String = 'Parameters will not show up in the plot.';
        end
    end
%% Colormap Callbacks
    function colormap2flag_Callback(source,~)
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'W2B'
                mymap2 = ARPES_white2blue(800);
                display_status.String = 'Color map is set to White2Blue';
            case 'hot'
                mymap2 = hot(800);
                display_status.String = 'Color map is set to hot';
            case 'Magma'
                mymap2 = ARPES_magma(800);
                display_status.String = 'Color map is set to Magma (Perceptually uniform colormap)';
            case 'viridis'
                mymap2 = ARPES_viridis(800);
                display_status.String = 'Color map is set to viridis (Perceptually uniform colormap)';
            case 'RWB'
                mymap2 = ARPES_customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
                display_status.String = 'Color map is set to Red-White-Blue';
            case 'jet'
                mymap2 = jet(800);
                display_status.String = 'Color map is set to jet';
        end
        
    end
%% Non-linear Colors Callbacks
    function NLcolorschemeflag_Callback(~,~)
        if nonlinearcolorscheme.Value ==1
            NLflag =1;
            display_status.String = 'Non-linear color scheme activated. Click Open Setup box to set the detailed color scheme parameters.';
            open_NLCSbox.Enable = 'on';
        else
            NLflag = 0;
            display_status.String = 'Non-linear color scheme deactivated.';
            open_NLCSbox.Enable = 'off';
        end
    end
    function para2C1_Callback(~,~)
        C1_2 = str2double(ax2_C1_2DCurvature.String);
        display_status.String = cat(2,'C1 on axis 2 is set to ',ax2_C1_2DCurvature.String);
    end
    function para2C2_Callback(~,~)
        C2_2 = str2double(ax2_C2_2DCurvature.String);
        display_status.String = cat(2,'C2 on axis 2 is set to ',ax2_C2_2DCurvature.String);
    end
    function revertcolormap2_Callback(~,~)
        if check_inverse_colormap.Value ==1
            revflag2 = 1;
            display_status.String = 'Color map is in opposite order now.';
        else 
            revflag2 = 0;
            display_status.String = 'Color map is in normal order now.';
        end
    end
%========================Non-linear color scheme box=======================
    function OpenNLCSbox_Callback(~,~)
        set(f4,'Visible','on');
    end
    function Coef_NLCS_Callback(~,~)
        coefficient = str2double(input3_NLCSbox.String);
        display_status.String = cat(2,'coefficient value set to ',input3_NLCSbox.String);
    end
    function SI_NLCS_Callback(~,~)
        scalingfactor = str2double(input2_NLCSbox.String);
        display_status.String = cat(2,'scaling intensity set to ',input2_NLCSbox.String);
    end
    function CP_NLCS_Callback(~,~)
        centerpoint = str2double(input1_NLCSbox.String);
        display_status.String = cat(2,'centerpoint set to ',input1_NLCSbox.String);
    end
%% Normalization Callbacks
    function normalize2_Callback(~,~)
        if check_normalization.Value ==1
            display_status.String = 'The processed raw data will be normalized.';
            normalflag =1;
        else
            display_status.String = 'The processed raw data will not be normalized.';
            normalflag =0;
        end
    end
%% Processed Plot Callbacks
    function MDC_Callback(~,~)
         if smoothflag ==1 && smoothingflag == 1
            ytemp = smoothdata(y,1,'movmean',sw);
        elseif smoothflag ==1 && smoothingflag == 2
            ytemp = smoothdata(y,1,'Sgolay',sw);
        elseif smoothflag ==0
            ytemp = y;
        end
        axes (ax2)       
        if interpflag ==1 && interpon ==1
            %Interpolated angle matrix
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            V(:,:)=z(:,:);
             zq= length(xq);
             z2 = zeros(L,zq);
            for i= 1:L
                z2(i,:)=interp1(z(i,:),V(i,:),xq);
            end
           BE2 = zeros(L,zq);
            for i=1:zq       %Beint for interpolated data
                BE2(:,i)=BE(:,1);
            end
            KE2 = zeros(L,zq);
            for i=1:zq
                KE2(:,i)=KE0(:,1);
            end
            kpar2 = zeros(L,zq);
            for m=1:zq
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KE2(:,m)*(1.602*10^-19)).*sin(z2(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            y2 = zeros(L,zq);
            for i=1:L %this creates yintp for the first time, meaning this is the intensity data that we're going to use.
                
                 y2(i,:) = interp1(z(i,:),ytemp(i,:),z2(i,:),'linear');
            end
        elseif interpflag ==2 && interpon == 1
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            zq = length(xq);
            yintp2D = griddedInterpolant(KE0,z,y,'linear');
            intvl_KE = abs((KE0(2,1)-KE0(1,1))/numint);
            intvl_z = abs((z(1,2)-z(1,1))/numint);
            [KEint_2D,z_2D]= ndgrid(min(min(KE0)):intvl_KE:max(max(KE0)),min(min(z)):intvl_z:max(max(z)));

            q_2D = length(KEint_2D(:,1));
            zq_2D = length(xq);
            kpar2=zeros(q_2D,zq_2D);
            for m=1:zq_2D
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KEint_2D(:,m)*(1.602*10^-19)).*sin(z_2D(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            z2 = z_2D;
            KE2 = KEint_2D;
            y2 = yintp2D(KEint_2D,z_2D);
            BE2=KEint_2D-Ef-bias;
        elseif interpflag ==0
            BE2 = BE;
            KE2 = KE;
            kpar2 = kpar;
            y2 = ytemp;
            z2 = z;
            zq = numfiles;
        end
        if normalflag ==1
            for i=1:length(y2(1,:))
                y2(:,i) = y2(:,i)./max(y2(:,i));
            end
        end  
            if xaxisflag ==0
                
                h2 = waterfall(z2,BE2,y2);
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(z2)) max(max(z2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(cmin2) max(cmax2*1.1)])
                end

            elseif xaxisflag ==1
                
                h2=waterfall(kpar2,BE2,y2);
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(kpar2)) max(max(kpar2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(cmin2) max(cmax2*1.1)])
                end
            end
            if revflag2 ==1 && NLflag ==0 && brightflag ==0
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==1 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==0
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2, newMap)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, newMap)                
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2,flipud(newMap))
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, flipud(newMap))                         
            end
            view(0,89.9)
            colorbar('westoutside')            
            if shadingflag2 == 0
                shading flat
            elseif shadingflag2 ==1
                shading faceted
                set(h2,'EdgeAlpha',0.05)
                set(h2,'LineWidth',3)
            elseif shadingflag2 ==2
                shading interp
            end
            caxis ([cmin2,cmax2])

            
        ylabel('Binding Energy (eV)','FontSize',16)
        
        zlabel('Intensity','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title(plotTitle2);
        if axisflag == 1
            axis on
        else
            axis off
        end
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        if paraflag ==1
            P1 = {'Smoothing method';'Smoothing window';'Brightness on/off';'Brightness';'Interpolation method';'Number of interp';'cmin2';'cmax2';'Non-linear color scheme';'Coefficient';'Scaling factor';'Center Point';'C2';'C1';'dtheta';'theta';'bias';'Ef';'Filemarker';'cmin1';'cmax1';'customflag';'xmin';'xmax';'BEmin';'BEmax'};
            P2 = {smoothingflag;sw;brightflag;brightness;interpflag;numint;cmin2;cmax2;NLflag;coefficient;scalingfactor;centerpoint;C2_2;C1_2;dtheta;theta;bias;Ef;filemarker;cmin1;cmax1;customflag;xmin;xmax;BEmin;BEmax};
            P3 = {'0: no smooth 1: move average 2: Sgolay';'default: 3';'0: no brightness 1: brightness';'default: 0';'0: no interpolation, 1: 1D interpolation, 2: Gridded interpolation';'Default: 3';'Default: 0';'Default: 5000';'0: normal colormap, 1: non-linear color map';'Default: 1.1';'Default: 8';'Default: 100';'Default: 10';'Default:1';'Default: 1';'Default: 0';'Default: 0';'Default:22.04';'Default:_AR_';'Rawdata cmin default 0';'Rawdata cmax default 5000';'Default: 0 for non-customized plot range';'default: 0';'default: 0';'default: 0';'default:0'};
            column = {'Variable','User set','Instruction'};

            fig = uifigure('Name','Parameters Table');
            fig.Position = [100 100 800 600];
            uit = uitable(fig,'Data',table(P1,P2,P3,'VariableNames',column),'Position',[10 10 750 550]);
        end
        hold off        
        display_status.String = 'Postprocessing MDC plot complete';        
    end
    function EDC_Callback(~,~)
        if smoothflag ==1 && smoothingflag == 1
            ytemp = smoothdata(y,1,'movmean',sw);
        elseif smoothflag ==1 && smoothingflag == 2
            ytemp = smoothdata(y,1,'Sgolay',sw);
        elseif smoothflag ==0
            ytemp = y;
        end
        axes (ax2)        
        if interpflag ==1 && interpon ==1
            %Interpolated angle matrix
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            V(:,:)=z(:,:);
             zq= length(xq);
             z2 = zeros(L,zq);
            for i= 1:L
                z2(i,:)=interp1(z(i,:),V(i,:),xq);
            end
           BE2 = zeros(L,zq);
            for i=1:zq       %Beint for interpolated data
                BE2(:,i)=BE(:,1);
            end
            KE2 = zeros(L,zq);
            for i=1:zq
                KE2(:,i)=KE0(:,1);
            end
            kpar2 = zeros(L,zq);
            for m=1:zq
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KE2(:,m)*(1.602*10^-19)).*sin(z2(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            y2 = zeros(L,zq);
            for i=1:L %this creates yintp for the first time, meaning this is the intensity data that we're going to use.
                
                 y2(i,:) = interp1(z(i,:),ytemp(i,:),z2(i,:),'linear');
            end
        elseif interpflag ==2 && interpon == 1
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            zq = length(xq);
            yintp2D = griddedInterpolant(KE0,z,y,'linear');
            intvl_KE = abs((KE0(2,1)-KE0(1,1))/numint);
            intvl_z = abs((z(1,2)-z(1,1))/numint);
            [KEint_2D,z_2D]= ndgrid(min(min(KE0)):intvl_KE:max(max(KE0)),min(min(z)):intvl_z:max(max(z)));

            q_2D = length(KEint_2D(:,1));
            zq_2D = length(xq);
            kpar2=zeros(q_2D,zq_2D);
            for m=1:zq_2D
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KEint_2D(:,m)*(1.602*10^-19)).*sin(z_2D(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            z2 = z_2D;
            KE2 = KEint_2D;
            y2 = yintp2D(KEint_2D,z_2D);
            BE2=KEint_2D-Ef-bias;
        elseif interpflag ==0
            BE2 = BE;
            KE2 = KE;
            kpar2 = kpar;
            y2 = ytemp;
            z2 = z;
            zq = numfiles;
        end
        if normalflag ==1
            for i=1:length(y2(1,:))
                y2(:,i) = y2(:,i)./max(y2(:,i));
            end
        end  
            if xaxisflag ==0
                
                h2 = waterfall(z2.',BE2.',y2.');
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(z2)) max(max(z2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(cmin2) max(cmax2*1.1)])
                end

            elseif xaxisflag ==1
                
                h2=waterfall(kpar2.',BE2.',y2.');
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(kpar2)) max(max(kpar2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(cmin2) max(cmax2*1.1)])
                end
            end
            if revflag2 ==1 && NLflag ==0 && brightflag ==0
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==1 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==0
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2, newMap)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, newMap)                
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2,flipud(newMap))
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, flipud(newMap))                         
            end
            view(0,89.9)
            colorbar('westoutside')            
            if shadingflag2 == 0
                shading flat
            elseif shadingflag2 ==1
                shading faceted
                set(h2,'EdgeAlpha',0.05)
                set(h2,'LineWidth',3)
            elseif shadingflag2 ==2
                shading interp
            end
            caxis ([cmin2,cmax2])

            
        ylabel('Binding Energy (eV)','FontSize',16)
        
        zlabel('Intensity','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title(plotTitle2);
        if axisflag == 1
            axis on
        else
            axis off
        end
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        if paraflag ==1
            P1 = {'Smoothing method';'Smoothing window';'Brightness on/off';'Brightness';'Interpolation method';'Number of interp';'cmin2';'cmax2';'Non-linear color scheme';'Coefficient';'Scaling factor';'Center Point';'C2';'C1';'dtheta';'theta';'bias';'Ef';'Filemarker';'cmin1';'cmax1';'customflag';'xmin';'xmax';'BEmin';'BEmax'};
            P2 = {smoothingflag;sw;brightflag;brightness;interpflag;numint;cmin2;cmax2;NLflag;coefficient;scalingfactor;centerpoint;C2_2;C1_2;dtheta;theta;bias;Ef;filemarker;cmin1;cmax1;customflag;xmin;xmax;BEmin;BEmax};
            P3 = {'0: no smooth 1: move average 2: Sgolay';'default: 3';'0: no brightness 1: brightness';'default: 0';'0: no interpolation, 1: 1D interpolation, 2: Gridded interpolation';'Default: 3';'Default: 0';'Default: 5000';'0: normal colormap, 1: non-linear color map';'Default: 1.1';'Default: 8';'Default: 100';'Default: 10';'Default:1';'Default: 1';'Default: 0';'Default: 0';'Default:22.04';'Default:_AR_';'Rawdata cmin default 0';'Rawdata cmax default 5000';'Default: 0 for non-customized plot range';'default: 0';'default: 0';'default: 0';'default:0'};
            column = {'Variable','User set','Instruction'};

            fig = uifigure('Name','Parameters Table');
            fig.Position = [100 100 800 600];
            uit = uitable(fig,'Data',table(P1,P2,P3,'VariableNames',column),'Position',[10 10 750 550]);
        end
        hold off        
        display_status.String = 'Postprocessing EDC plot complete';
    end


    function plotrawax2_Callback(~,~)
        if smoothflag ==1 && smoothingflag == 1
            ytemp = smoothdata(y,1,'movmean',sw);
        elseif smoothflag ==1 && smoothingflag == 2
            ytemp = smoothdata(y,1,'Sgolay',sw);
        elseif smoothflag ==0
            ytemp = y;
        end
        axes (ax2)

        if interpflag ==1 && interpon ==1
            %Interpolated angle matrix
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            V(:,:)=z(:,:);
             zq= length(xq);
             z2 = zeros(L,zq);
            for i= 1:L
                z2(i,:)=interp1(z(i,:),V(i,:),xq);
            end
           BE2 = zeros(L,zq);
            for i=1:zq       %Beint for interpolated data
                BE2(:,i)=BE(:,1);
            end
            KE2 = zeros(L,zq);
            for i=1:zq
                KE2(:,i)=KE0(:,1);
            end
            kpar2 = zeros(L,zq);
            for m=1:zq
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KE2(:,m)*(1.602*10^-19)).*sin(z2(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            y2 = zeros(L,zq);
            for i=1:L %this creates yintp for the first time, meaning this is the intensity data that we're going to use.
                
                 y2(i,:) = interp1(z(i,:),ytemp(i,:),z2(i,:),'linear');
            end
        elseif interpflag ==2 && interpon == 1
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            zq = length(xq);
            yintp2D = griddedInterpolant(KE0,z,y,'linear');
            intvl_KE = abs((KE0(2,1)-KE0(1,1))/numint);
            intvl_z = abs((z(1,2)-z(1,1))/numint);
            [KEint_2D,z_2D]= ndgrid(min(min(KE0)):intvl_KE:max(max(KE0)),min(min(z)):intvl_z:max(max(z)));

            q_2D = length(KEint_2D(:,1));
            zq_2D = length(xq);
            kpar2=zeros(q_2D,zq_2D);
            for m=1:zq_2D
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KEint_2D(:,m)*(1.602*10^-19)).*sin(z_2D(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            z2 = z_2D;
            KE2 = KEint_2D;
            y2 = yintp2D(KEint_2D,z_2D);
            BE2=KEint_2D-Ef-bias;
        elseif interpflag ==0
            BE2 = BE;
            KE2 = KE;
            kpar2 = kpar;
            y2 = ytemp;
            z2 = z;
            zq = numfiles;
        end
        if normalflag ==1
            for i=1:length(y2(1,:))
                y2(:,i) = y2(:,i)./max(y2(:,i));
            end
        end
            if xaxisflag ==0
                h2 = surf(z2,BE2,y2);
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(z2)) max(max(z2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                end

            elseif xaxisflag ==1
                h2=surf(kpar2,BE2,y2);
                xlabel('K_|_|(Å^-^1)','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(kpar2)) max(max(kpar2)) min(BE2(:,1)) max(BE2(:,1)) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(y2(:,:))) max(max(y2(:,:)))+max(max(y2(:,:)))*0.1])
                end
            end
            if revflag2 ==1 && NLflag ==0 && brightflag ==0
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==1 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==0
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2, newMap)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, newMap)                
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==0
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2,flipud(newMap))
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==1
                 dataMax = max(y2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, flipud(newMap))                         
            end
            view(0,89.9)
            colorbar('westoutside')            
            if shadingflag2 == 0
                shading flat
            elseif shadingflag2 ==1
                shading faceted
                set(h2,'EdgeAlpha',0.05)
                set(h2,'LineWidth',3)
            elseif shadingflag2 ==2
                shading interp
            end
            caxis ([cmin2,cmax2])

            
        ylabel('Binding Energy (eV)','FontSize',16)
        
        zlabel('Intensity','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title(plotTitle2);
        if axisflag == 1
            axis on
        else
            axis off
        end
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        if paraflag ==1
            P1 = {'Smoothing method';'Smoothing window';'Brightness on/off';'Brightness';'Interpolation method';'Number of interp';'cmin2';'cmax2';'Non-linear color scheme';'Coefficient';'Scaling factor';'Center Point';'C2';'C1';'dtheta';'theta';'bias';'Ef';'Filemarker';'cmin1';'cmax1';'customflag';'xmin';'xmax';'BEmin';'BEmax'};
            P2 = {smoothingflag;sw;brightflag;brightness;interpflag;numint;cmin2;cmax2;NLflag;coefficient;scalingfactor;centerpoint;C2_2;C1_2;dtheta;theta;bias;Ef;filemarker;cmin1;cmax1;customflag;xmin;xmax;BEmin;BEmax};
            P3 = {'0: no smooth 1: move average 2: Sgolay';'default: 3';'0: no brightness 1: brightness';'default: 0';'0: no interpolation, 1: 1D interpolation, 2: Gridded interpolation';'Default: 3';'Default: 0';'Default: 5000';'0: normal colormap, 1: non-linear color map';'Default: 1.1';'Default: 8';'Default: 100';'Default: 10';'Default:1';'Default: 1';'Default: 0';'Default: 0';'Default:22.04';'Default:_AR_';'Rawdata cmin default 0';'Rawdata cmax default 5000';'Default: 0 for non-customized plot range';'default: 0';'default: 0';'default: 0';'default:0'};
            column = {'Variable','User set','Instruction'};

            fig = uifigure('Name','Parameters Table');
            fig.Position = [100 100 800 600];
            uit = uitable(fig,'Data',table(P1,P2,P3,'VariableNames',column),'Position',[10 10 750 550]);
        end
        hold off        
        display_status.String = 'Postprocessing Raw Intensity complete';
    end
%% Processed Curvature Plot Callbacks
    function plot2dcurvax2_Callback(~,~)
        %Initial parameter set up for Curvature calculation.
        if smoothflag ==1 && smoothingflag == 1
            ytemp = smoothdata(y,1,'movmean',sw);
        elseif smoothflag ==1 && smoothingflag == 2
            ytemp = smoothdata(y,1,'Sgolay',sw);
        elseif smoothflag ==0
            ytemp = y;
        end
        axes (ax2)

        if interpflag ==1 && interpon ==1
            %Interpolated angle matrix
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            V(:,:)=z(:,:);
             zq= length(xq);
             z2 = zeros(L,zq);
            for i= 1:L
                z2(i,:)=interp1(z(i,:),V(i,:),xq);
            end
           BE2 = zeros(L,zq);
            for i=1:zq       %Beint for interpolated data
                BE2(:,i)=BE(:,1);
            end
            KE2 = zeros(L,zq);
            for i=1:zq
                KE2(:,i)=KE0(:,1);
            end
            kpar2 = zeros(L,zq);
            for m=1:zq
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KE2(:,m)*(1.602*10^-19)).*sin(z2(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            y2 = zeros(L,zq);
            for i=1:L %this creates yintp for the first time, meaning this is the intensity data that we're going to use.
                
                 y2(i,:) = interp1(z(i,:),ytemp(i,:),z2(i,:),'linear');
            end
        elseif interpflag ==2 && interpon ==1
            xq= theta:(dtheta/numint):(theta+((numfiles-1)*dtheta));
            zq = length(xq);
            yintp2D = griddedInterpolant(KE0,z,y,'linear');
            intvl_KE = abs((KE0(2,1)-KE0(1,1))/numint);
            intvl_z = abs((z(1,2)-z(1,1))/numint);
            [KEint_2D,z_2D]= ndgrid(min(min(KE0)):intvl_KE:max(max(KE0)),min(min(z)):intvl_z:max(max(z)));

            q_2D = length(KEint_2D(:,1));
            zq_2D = length(xq);
            kpar2=zeros(q_2D,zq_2D);
            for m=1:zq_2D
                kpar2(:,m)=sqrt(2*(9.109*10^-31)*KEint_2D(:,m)*(1.602*10^-19)).*sin(z_2D(:,m)*pi/180)/((6.626*10^-34)/(2*pi))*(10^-10);
            end
            z2 = z_2D;
            KE2 = KEint_2D;
            y2 = yintp2D(KEint_2D,z_2D);
            BE2=KEint_2D-Ef-bias;

        elseif interpflag ==0 && interpon ==0
            BE2 = BE;
            KE2 = KE;
            kpar2 = kpar;
            y2 = ytemp;
            z2 = z;
            zq = numfiles;
        end
        %calculating curvature out of the predefined parameters.
                %2D Curvature related preamble
        [gkpar,gBE]=gradient(y2);

        for i=1:zq   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:zq   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1_2.*((gkpar).^2)).*C2_2.*(g2BE);
        t2=2.*C1_2.*C2_2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2_2.*((gBE).^2)).*C1_2.*(g2kpar);
        t4=(1+C1_2.*((gkpar).^2)+C2_2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:zq
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal2=Newcurv2D.*(y2); % to optimize the quality, you might have to tune the number dividing the y
        
        %Plot section
            if xaxisflag ==0
                h2 = surf(z2,BE2,Curvfinal2);
                xlabel('Angle','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(z2)) max(max(z2)) min(BE2(:,1)) max(BE2(:,1)) min(min(Curvfinal2(:,:))) max(max(Curvfinal2(:,:)))+max(max(Curvfinal2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(Curvfinal2(:,:))) max(max(Curvfinal2(:,:)))+max(max(Curvfinal2(:,:)))*0.1])
                end
            elseif xaxisflag ==1
                h2=surf(kpar2,BE2,Curvfinal2);
                xlabel('KPar','FontSize',16,'Units','Normalized','Position',[0.5 -0.06])
                if customflag ==0
                    axis([ min(min(kpar2)) max(max(kpar2)) min(BE2(:,1)) max(BE2(:,1)) min(min(Curvfinal2(:,:))) max(max(Curvfinal2(:,:)))+max(max(Curvfinal2(:,:)))*0.1])
                else
                    axis([ min(xmin) max(xmax) min(BEmin) max(BEmax) min(min(Curvfinal2(:,:))) max(max(Curvfinal2(:,:)))+max(max(Curvfinal2(:,:)))*0.1])
                end                
            end
            if revflag2 ==1 && NLflag ==0 && brightflag ==0
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==1 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,flipud(mymap2))
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==0
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==0 && brightflag ==1
                mymap2 = brighten(mymap2,brightness);
                colormap (ax2,mymap2)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==0
                 dataMax = max(Curvfinal2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2, newMap)
            elseif revflag2 ==0 && NLflag ==1 && brightflag ==1
                 dataMax = max(Curvfinal2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, newMap)                
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==0
                 dataMax = max(Curvfinal2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                colormap (ax2,flipud(newMap))
            elseif revflag2 ==1 && NLflag ==1 && brightflag ==1
                 dataMax = max(Curvfinal2,[],'all');
                 dataMin = 0;
                 cMap = mymap2; %choose a color scheme
                 cs = 1:length(cMap); 
                 cs = cs - (centerpoint-dataMin)*length(cs)/(dataMax-dataMin);
                 cs = scalingfactor * cs/max(abs(cs));
                 cs = sign(cs).* exp(abs(cs))*coefficient;
                 newMap = interp1(cs, cMap, 1:400);
                newMap = brighten(ax2,newMap);
                colormap (ax2, flipud(newMap))                         
            end
            view(0,89.9)
            colorbar('westoutside')            
            if shadingflag2 == 0
                shading flat
            elseif shadingflag2 ==1
                shading faceted
                set(h2,'EdgeAlpha',0.05)
                set(h2,'LineWidth',3)
            elseif shadingflag2 ==2
                shading interp
            end
            caxis ([cmin2,cmax2])

            
        ylabel('Binding Energy (eV)','FontSize',16)
        
        zlabel('Curvature','FontSize',16,'Units','Normalized','Position',[0 0 0])
        title(plotTitle2);
        if axisflag == 1
            axis on
        else
            axis off
        end
        hold on
        if check_xline1.Value ==1 && xyflag==1
            xline(xline1,'b');
        end
        if check_xline2.Value ==1 && xyflag==1
            xline(xline2,'b');
        end        
        if check_xline3.Value ==1 && xyflag==1
            xline(xline3,'b');
        end     
        if check_yline1.Value ==1 && xyflag==1
            yline(yline1,'r');
        end        
        if check_yline2.Value ==1 && xyflag==1
            yline(yline2,'r');
        end             
        if check_yline3.Value ==1 && xyflag==1
            yline(yline3,'r');
        end                
        if paraflag ==1
            P1 = {'Smoothing method';'Smoothing window';'Brightness on/off';'Brightness';'Interpolation method';'Number of interp';'cmin2';'cmax2';'Non-linear color scheme';'Coefficient';'Scaling factor';'Center Point';'C2';'C1';'dtheta';'theta';'bias';'Ef';'Filemarker';'cmin1';'cmax1';'customflag';'xmin';'xmax';'BEmin';'BEmax'};
            P2 = {smoothingflag;sw;brightflag;brightness;interpflag;numint;cmin2;cmax2;NLflag;coefficient;scalingfactor;centerpoint;C2_2;C1_2;dtheta;theta;bias;Ef;filemarker;cmin1;cmax1;customflag;xmin;xmax;BEmin;BEmax};
            P3 = {'0: no smooth 1: move average 2: Sgolay';'default: 3';'0: no brightness 1: brightness';'default: 0';'0: no interpolation, 1: 1D interpolation, 2: Gridded interpolation';'Default: 3';'Default: 0';'Default: 5000';'0: normal colormap, 1: non-linear color map';'Default: 1.1';'Default: 8';'Default: 100';'Default: 10';'Default:1';'Default: 1';'Default: 0';'Default: 0';'Default:22.04';'Default:_AR_';'Rawdata cmin default 0';'Rawdata cmax default 5000';'Default: 0 for non-customized plot range';'default: 0';'default: 0';'default: 0';'default:0'};
            column = {'Variable','User set','Instruction'};

            fig = uifigure('Name','Parameters Table');
            fig.Position = [100 100 800 600];
            uit = uitable(fig,'Data',table(P1,P2,P3,'VariableNames',column),'Position',[10 10 750 550]);
        end
        hold off        
        display_status.String = 'Postprocessing 2D Curvature complete';
    end
%% Compare Curvature-Intensity Processed Callbacks       
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>> Compare Curvature-Intensity For Processed Data<<<
%==========================================================================
    function plotcompareax2_Callback(~,~)
                %2D Curvature related preamble
        [gkpar,gBE]=gradient(y2);

        for i=1:zq   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:zq   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1_2.*((gkpar).^2)).*C2_2.*(g2BE);
        t2=2.*C1_2.*C2_2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2_2.*((gBE).^2)).*C1_2.*(g2kpar);
        t4=(1+C1_2.*((gkpar).^2)+C2_2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:zq
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal2=Newcurv2D.*(y2); % to optimize the quality, you might have to tune the number dividing the y

        
        set(f3,'Visible','on')
        axes (ax4)
        plot(BE2(:,1),y2(:,1),BE2(:,1),Curvfinal2(:,1));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');

    end
    function next2compare_Callback(~,~)
        if specnum2 == zq
            specnum2 = zq;
        elseif specnum2 < zq
            specnum2 = specnum2+1;
        end

        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y2);

        for i=1:zq   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:zq   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1_2.*((gkpar).^2)).*C2_2.*(g2BE);
        t2=2.*C1_2.*C2_2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2_2.*((gBE).^2)).*C1_2.*(g2kpar);
        t4=(1+C1_2.*((gkpar).^2)+C2_2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:zq
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal2=Newcurv2D.*(y2); % to optimize the quality, you might have to tune the number dividing the y
        set(f3,'Visible','on')
        axes(ax4)
        plot(BE2(:,specnum2),y2(:,specnum2),BE2(:,specnum2),Curvfinal2(:,specnum2));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum2.String = cat(2,'Current spectrum number is ',num2str(specnum2));
    end
    function previous2compare_Callback(~,~)
        if specnum2 == 1
            specnum2 = 1;
        elseif specnum2 > 1
            specnum2 = specnum2-1;
        end

        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y2);

        for i=1:zq   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:zq   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1_2.*((gkpar).^2)).*C2_2.*(g2BE);
        t2=2.*C1_2.*C2_2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2_2.*((gBE).^2)).*C1_2.*(g2kpar);
        t4=(1+C1_2.*((gkpar).^2)+C2_2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:zq
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal2=Newcurv2D.*(y2); % to optimize the quality, you might have to tune the number dividing the y
        set(f3,'Visible','on')
        axes(ax4)
        plot(BE2(:,specnum2),y2(:,specnum2),BE2(:,specnum2),Curvfinal2(:,specnum2));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum2.String = cat(2,'Current spectrum number is ',num2str(specnum2));
    end
    function jumpto2_Callback(~,~)
        if str2double(jumpto_specnum2.String) <= zq && str2double(jumpto_specnum2.String) >= 1
            specnum2 = str2double(jumpto_specnum2.String);
        else
            msgbox(cat(2,'Error in Jump To number. Check if it is defined within 1 - ',num2str(zq)),'Error');
        end
        display_specnum2.String = cat(2,'The spectrum number will be set to ',num2str(specnum2));
    end
    function jump2_Callback(~,~)
        %2D Curvature related preamble
        [gkpar,gBE]=gradient(y2);

        for i=1:zq   %smoothing each spectrum
                gBE(:,i) = smoothdata(gBE(:,i),'sgolay'); 
        end
        for i=1:length(gkpar(:,1))   %smoothing Between angles
                gkpar(i,:) = smoothdata(gkpar(i,:),'sgolay'); 
        end   
        [g2mix,g2BE]=gradient(gBE);
        for i=1:zq   %smoothing each spectrum
                g2BE(:,i) = smoothdata(g2BE(:,i),'sgolay'); 
        end
        for i=1:length(g2mix(:,1))   %smoothing Between angles
                g2mix(i,:) = smoothdata(g2mix(i,:),'sgolay'); 
        end
        g2kpar=gradient(gkpar);
        for i=1:length(g2kpar(1,:))   %smoothing each spectrum
                g2kpar(i,:) = smoothdata(g2kpar(i,:),'sgolay'); 
        end


        %---------------    Curvature section    -------------
        t1=(1+C1_2.*((gkpar).^2)).*C2_2.*(g2BE);
        t2=2.*C1_2.*C2_2.*(gkpar).*(gBE).*(g2mix);
        t3=(1+C2_2.*((gBE).^2)).*C1_2.*(g2kpar);
        t4=(1+C1_2.*((gkpar).^2)+C2_2.*((gBE).^2)).^(3/2);
        Curv2D=(t1-t2+t3)./t4;
        Newcurv2D = Curv2D;
        s = length(g2kpar);

        for Q =1:s %Only the negative curvature is meaningful. Thus we eliminate all the positive numbers
            for R=1:zq
                if (Curv2D(Q,R)>0)
                    Newcurv2D(Q,R)=0;
                end
            end
        end
        Newcurv2D = abs(Newcurv2D); %And make it positive for figure representation
        Curvfinal2=Newcurv2D.*(y2); % to optimize the quality, you might have to tune the number dividing the y
        set(f3,'Visible','on')
        axes(ax4)
        plot(BE2(:,specnum2),y2(:,specnum2),BE2(:,specnum2),Curvfinal2(:,specnum2));
        axis on
        legend ('Raw y','2D Curvature');
        xlabel('BE (ev)');
        ylabel('values');
        display_specnum2.String = cat(2,'Current spectrum number is ',num2str(specnum2));
        
    end
%% Custom Plot Range
    function set_customrange_Callback(~,~)
        if check_customrange.Value ==1
            display_status.String = 'Custom range in effect. This will affect both of the plots in this panel.';
            customflag = 1;
        else
            display_status.String = 'Plots will be displayed in tight ranges';
            customflag =0;
        end
    end
    function edit_xmin_Callback(~,~)
        xmin = str2double(value_xmin.String);
        display_status.String = cat(2,'xmin is set to ',value_xmin.String);
    end
    function edit_xmax_Callback(~,~)
        xmax = str2double(value_xmax.String);
        display_status.String = cat(2,'xmax is set to ',value_xmax.String);
    end
    function edit_BEmin_Callback(~,~)
        BEmin = str2double(value_BEmin.String);
        display_status.String = cat(2,'BEmin is set to ',value_BEmin.String);
    end
    function edit_BEmax_Callback(~,~)
        BEmax = str2double(value_BEmax.String);
        display_status.String = cat(2,'BEmax is set to ',value_BEmax.String);
    end
%% Save Functions
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>> Save Functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
    function saveintensity_Callback(~,~)
        selection = questdlg('Locate the folder where you want to save',...
            'Hit Okay to proceed',...
            'Okay','No','Okay');
        switch selection
            case 'Okay'
                location = uigetdir();
                cd = location;
                cube = zeros(length(z2(:,1)),length(z2(1,:)),4);
                cube(:,:,1) = z2;
                cube(:,:,2) = kpar2;
                cube(:,:,3) = BE2;
                cube(:,:,4) = y2;
                c = fix(clock);
                filename = cat(2,cd,'\intensity matrix set_',num2str(c(1,1)),'_',num2str(c(1,2)),'_',num2str(c(1,3)),'_',num2str(c(1,4)),'_',num2str(c(1,5)));
                save(filename,'cube');
                display_status.String = 'Data cube saved to the directory you assigned. The filename contains the time of action to differentiate the file name automatically.';
            case 'No'
                return
        end
    end
    function savecurvature_Callback(~,~)
        selection = questdlg('Locate the folder where you want to save',...
            'Hit Okay to proceed',...
            'Okay','No','Okay');
        switch selection
            case 'Okay'        
                location = uigetdir();
                cd = location;
                cube = zeros(length(z2(:,1)),length(z2(1,:)),4);
                cube(:,:,1) = z2;
                cube(:,:,2) = kpar2;
                cube(:,:,3) = BE2;
                cube(:,:,4) = Curvfinal2;
                c = fix(clock);
                filename = cat(2,cd,'\curvature matrix set_',num2str(c(1,1)),'_',num2str(c(1,2)),'_',num2str(c(1,3)),'_',num2str(c(1,4)),'_',num2str(c(1,5)));
                save(filename,'cube');
                display_status.String = 'Data cube saved to the directory you assigned. The filename contains the time of action to differentiate the file name automatically.';
            case 'No'
                return
        end
    end
    function savepara_Callback(~,~)
        selection = questdlg('Locate the folder where you want to save',...
            'Hit Okay to proceed',...
            'Okay','No','Okay');
        switch selection
            case 'Okay'        
                location = uigetdir();
                cd = location;      
                    P1 = {'Smoothing method';'Smoothing window';'Brightness on/off';'Brightness';'Interpolation method';'Number of interp';'cmin2';'cmax2';'Non-linear color scheme';'Coefficient';'Scaling factor';'Center Point';'C2';'C1';'dtheta';'theta';'bias';'Ef';'Filemarker';'cmin1';'cmax1';'customflag';'xmin';'xmax';'BEmin';'BEmax'};
                    P2 = {smoothingflag;sw;brightflag;brightness;interpflag;numint;cmin2;cmax2;NLflag;coefficient;scalingfactor;centerpoint;C2_2;C1_2;dtheta;theta;bias;Ef;filemarker;cmin1;cmax1;customflag;xmin;xmax;BEmin;BEmax};
                    P3 = {'0: no smooth 1: move average 2: Sgolay';'default: 3';'0: no brightness 1: brightness';'default: 0';'0: no interpolation, 1: 1D interpolation, 2: Gridded interpolation';'Default: 3';'Default: 0';'Default: 5000';'0: normal colormap, 1: non-linear color map';'Default: 1.1';'Default: 8';'Default: 100';'Default: 10';'Default:1';'Default: 1';'Default: 0';'Default: 0';'Default:22.04';'Default:_AR_';'Rawdata cmin default 0';'Rawdata cmax default 5000';'Default: 0 for non-customized plot range';'default: 0';'default: 0';'default: 0';'default:0'};
                    column = {'Variable','User set','Instruction'};
                    paratable = table(P1,P2,P3,'VariableNames',column);
                    colorpalette = colormap(ax2,mymap2);
                c = fix(clock);
                filename1 = cat(2,cd,'\parameters set_',num2str(c(1,1)),'_',num2str(c(1,2)),'_',num2str(c(1,3)),'_',num2str(c(1,4)),'_',num2str(c(1,5)));
                filename2 = cat(2,cd,'\colormap vector_',num2str(c(1,1)),'_',num2str(c(1,2)),'_',num2str(c(1,3)),'_',num2str(c(1,4)),'_',num2str(c(1,5)));
                save(filename1,'paratable');
                save(filename2,'colorpalette','-ascii','-tabs');
                display_status.String = 'Both parameter vectors and color palette are saved in the located directory. File name contains the time of action to avoid overwriting.';
            case 'No'
                return
        end
    end
%% X and Y Lines Callbacks
    function set_xylines_Callback(~,~)
        if check_xandylines.Value ==0
            display_status.String = 'X and Y lines will not be displayed.';
            xyflag = 0;
            open_xylinesbox.Enable = 'off';
        elseif check_xandylines.Value ==1
            display_status.String = 'X and Y lines will be displayed. Use the box to outline at which data line you want to draw the lines.';
            xyflag =1;
            open_xylinesbox.Enable = 'on';
        end
    end
    function edit_xylines_Callback(~,~)
        set(f5,'Visible','on');
    end
    function xline1_value_Callback(~,~)
        xline1 = str2double(field_xline1.String);
        display_status.String = cat(2,'X line 1 is set to ',field_xline1.String);
    end
    function xline2_value_Callback(~,~)
        xline2 = str2double(field_xline2.String);
        display_status.String = cat(2,'X line 2 is set to ',field_xline2.String);
    end
    function xline3_value_Callback(~,~)
        xline3 = str2double(field_xline3.String);
        display_status.String = cat(2,'X line 3 is set to ',field_xline3.String);
    end
    function yline1_value_Callback(~,~)
        yline1 = str2double(field_yline1.String);
        display_status.String = cat(2,'Y line 1 is set to ',field_yline1.String);
    end
    function yline2_value_Callback(~,~)
        yline2 = str2double(field_yline2.String);
        display_status.String = cat(2,'Y line 2 is set to ',field_yline2.String);
    end
    function yline3_value_Callback(~,~)
        yline3 = str2double(field_yline3.String);
        display_status.String = cat(2,'Y line 3 is set to ',field_yline3.String);
    end
%% Close Requests
%==========================================================================
% >>>>>>>>>>>>>>>>>>>>>>> Back back sections <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
    function f_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Exit the GUI application?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'
                delete(f3)
                delete(f2)
                delete(f4)
                delete(f5)
                delete(f)
            case 'No'
                return 
        end
    end
    function f2_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'
                set(f2,'Visible','off');
            case 'No'
                return 
        end
    end
    function f3_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'

                set(f3,'Visible','off');
            case 'No'
                return 
        end
    end
    function f4_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'

                set(f4,'Visible','off');
            case 'No'
                return 
        end
    end
    function f5_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'

                set(f5,'Visible','off');
            case 'No'
                return 
        end
    end
end
