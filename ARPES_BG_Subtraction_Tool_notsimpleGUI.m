function ARPES_BG_Subtraction_Tool_notsimpleGUI(KE,y,location,Ef)


% This tool aims to subtract UPS spectra using Shirley method. It isn't
% wise to use Shirley method to valence level spectra but it can still be
% useful mostly in highlighting pick positions for 2D Curvature map. 
%As of August 2021, This tool can automatically redefine the KE vector regardless of the
%original data files (It doesn't matter if the original data was taken from
%high KE to low KE or low KE to high KE). Now it can detect the data source and arrange the data
%volume such that clipping and BG estimate become more universal.
%Also save all function now supports dividing every spectrum as a separate
%file. Notice that it starts with 11 to avoid the number-based file
%ordering issue. The problem happens when the file starts from 1 then the 2-9 labeled files come
%after 11-19 labeled files. Also it tried to avoid the degenerate local
%minimum problem of the LMEA and LMSA variables. If things keep screwing
%up, I recommend reading the codes related to LMEA and LMSA. tempLMEA and
%tempLMSA are meant to be fixing the issue. 
%This GUI is largely based on RESPES_BG_Subtraction_Tool.

%==========================================================================
% >>>>>>>>>>>>>>>>>>>> Figures and Axes declaration <<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
    fShirley = figure('Visible','off','Position',[50,50,1000,720]);
    ax = axes('Parent',fShirley,'Units','Pixels','Position',[550,300,400,300]);
    frf = figure('Visible','off','Position',[100,100,750,600]);
    axfrf = axes('Parent',frf,'Units','Pixels','Position',[100,200,400,300]);
    fShirley.Name = 'UPS Background Subtraction Tool: Main Panel';
    frf.Name = 'UPS Background Subtraction Tool: Review and Finalize';
    
    
    % Set close request to hide windows instead of closing them
    set(fShirley,'CloseRequestFcn',@f_closereq);
    set(frf,'CloseRequestFcn',@frf_closereq);
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>Global Variables<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    % Make the main UI visible.
    fShirley.Visible = 'on';
   EFermi = Ef; %Ef value will be imported from the NotSoSimpleGUI.
   FDflag = 0; %FDflag will become 1 when the user checks the Fermi Dirac Preset part.
   T = 290; %Effective temperature in kelvin. It must be larger than the room temperature because the instrumental broadening increases effective temperature as well.
   nFD = zeros(2,2); %nFD is the Fermi-Dirac distribution based on the preset parameters defined by users.
   Data = zeros(2,2);
   KE = KE;
   scalefactor = 1;
   FDscalefactor = 1;
   offsetfactor = 0;
   y = y;
   specnum = 'Unknown';
   totalspecnum = 'Unknown';    
   sgolaywindow = 5;
   sy = zeros(2,2);
   Anchor1=0;
   Anchor2=0;
   NumIter=10;
   AR = 10;
   BG =zeros(2,2);
   SaveTag = {};
   SaveAllTag = {};
   onefile = zeros(2,2);
   allfile = zeros(2,2);
   ClipBEMin = 0;
   ClipBEMax = 0;
   %s = 0;
   modeflag = 1; %1 is default, processing kinetic energy data.
   dataflag =0; %0 is default, if the data are imported it will turn into 1.
   L =0; %length of the column vector
   yBG = zeros(2,2);
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>GUI Layout<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
        % 1. Buttons
%     folder = uicontrol('Parent',f,'Style','pushbutton','String',...
%         'Data Folder',...
%         'Position',[50,660,100,25],...
%         'Callback',{@Folder_Callback});
    instructions = uicontrol('Parent',fShirley,'Style','text','String',...
        'Use the following tool to carry on Background subtraction. You need to define the anchors to evaluate the background. Start anchor tends to be beyond the Fermi level and End Anchor tends to be a spectral puddle where a saddle point is observed after the peak. Go to Review and Finalize to finalize. Use Save all to save the result. Then import the data back in the ARPES GUI.',...
        'Position',[100,500,300,200]);
    FermiDiraczone = uicontrol('Parent',fShirley,'Style','text','String',...
        '====================================',...
        'Position',[50,500,400,25]);
    Checkbox_FDpreset = uicontrol('Parent',fShirley,'Style','Checkbox','String',...
        'Use Fermi Dirac distribution?','Position',[50,475,300,25],'Callback',{@FDpreset_Callback});
    idea_FDpreset = uicontrol('Parent',fShirley,'Style','Pushbutton','String',...
        '!','Position',[355,475,25,25],'Callback',{@idea_FD_Callback});
    Help_FDpreset = uicontrol('Parent',fShirley,'Style','Pushbutton','String',...
        '?','Position',[385,475,25,25],'Callback',{@Help_FD_Callback}); 
    Help_TEffective = uicontrol('Parent',fShirley,'Style','Pushbutton','String',...
        '?','Position',[265,420,25,25],'Callback',{@Help_TEff_Callback});    
    Text_FDpreset = uicontrol('Parent',fShirley,'Style','text','String',...
        'FD distribution could be useful when you deal with metals.','Position',[50,450,400,25]);
    Text_temperature = uicontrol('Parent',fShirley,'Style','text','String',...
        'Effective Temperature','Position',[50,420,100,25]);
    Field_temperature = uicontrol('Parent',fShirley,'Style','edit','String',...
        'In Kevin','Position',[160,420,100,25],'Callback',{@FDtemperature_Callback});
    Text_FermiLevel = uicontrol('Parent',fShirley,'Style','text','String',...
        cat(2,'Registered Fermi level is ',num2str(EFermi),' eV'),'Position',[50,375,200,25]);
    previous = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        '<==',...
        'Position',[550,200,50,25],...
        'Callback',{@Previous_Callback});    
    next = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        '==>',...
        'Position',[600,200,50,25],...
        'Callback',{@Next_Callback});     
    jumpto = uicontrol('Parent',fShirley,'Style','edit','String',...
        'where to?',...
        'Position',[770,200,80,25]);
    jumpit = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        'Jump!',...
        'Position',[850,200,100,25],'Callback',{@Jump_Callback});    
%     smoothbutton = uicontrol('Parent',f,'Style','pushbutton','String',...
%         'Run Smoothing',...
%         'Position',[150,570,100,25],'Callback',{@Smoothdata_Callback});     
%     smoothwindowtext = uicontrol('Parent',f,'Style','edit','String',...
%         'Window size',...
%         'Position',[50,570,100,25]);             
    Shirleytext1 = uicontrol('Parent',fShirley,'Style','text','String',...
        '====================================',...
        'Position',[50,325,400,25]); 
    Shirleytext2 = uicontrol('Parent',fShirley,'Style','text','String',...
        'Shirley Background subtraction section. Type in all the associated values.',...
        'Position',[50,300,400,25]); 
    SBSAtext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Start Anchor (eV)',...
        'Position',[50,250,100,25]);                 
    SBEAtext = uicontrol('Parent',fShirley,'Style','text','String',...
        'End Anchor (eV)',...
        'Position',[150,250,100,25]);   
    SBARtext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Anchor Range (Points)',...
        'Position',[250,250,100,25]);       
    SBNItext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Number of iterations',...
        'Position',[350,250,100,25]);    
    previewBG = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        'Preview BG',...
        'Position',[350,190,100,25],'Callback',{@PreviewBG_Callback});        
    SSBG = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        'Subtract&Save each spectrum',...
        'Position',[50,130,200,50],'Callback',{@SubandSave_Callback});          
    RFBG = uicontrol('Parent',fShirley,'Style','pushbutton','String',...
        'Review and Finalize',...
        'Position',[50,80,200,50],'Callback',{@ReviewandFinalize_Callback});         
    scalingfactor = uicontrol('Parent',fShirley,'Style','edit','String',...
        'Shirley  Scale factor','Position',[50,190,100,25],'Callback',{@scalefactor_Callback});
    FDscalefactor_Field = uicontrol('Parent',fShirley,'Style','edit','String',...
        'FD Scale factor','Position',[250,190,100,25],'Callback',{@FDscalefactor_Callback});
    offsetfactor_field = uicontrol('Parent',fShirley,'Style','edit','String',...
        'Y Offset','Position',[150,190,100,25],'Callback',{@offsetfactor_Callback});    
    % 2. Pushbutton Instructions
%     foldertext = uicontrol('Parent',f,'Style','text','String',...
%         '1. Choose the folder where the data is located',...
%         'Position',[10,690,300,25]);
%     cliptext = uicontrol('Parent',f,'Style','text','String',...
%         '2. Clip the data if needed',...
%         'Position',[250,650,200,25]);
%     clipKEmintext = uicontrol('Parent',f,'Style','text','String',...
%         'KEmin',...
%         'Position',[310,630,50,25]);
%     clipKEmaxtext = uicontrol('Parent',f,'Style','text','String',...
%         'KEmax',...
%         'Position',[360,630,50,25]);    
%     clipKEminbutton = uicontrol('Parent',f,'Style','edit','String',...
%         '(eV)',...
%         'Position',[310,605,50,25],'Callback',{@ClipMin_Callback});
%     clipKEmaxbutton = uicontrol('Parent',f,'Style','edit','String',...
%         '(eV)',...
%         'Position',[360,605,50,25],'Callback',{@ClipMax_Callback});  
%     clipbutton = uicontrol('Parent',f,'Style','pushbutton','String',...
%         'Clip em !',...
%         'Position',[410,605,70,25],'Callback',{@Clip_Callback});  
    navitext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Use the buttons to navigate the data',...
        'Position',[550,225,200,25],'Callback',{@Jump_Callback});   
    navitext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Jump To',...
        'Position',[750,225,100,25]);      
%     smoothtext = uicontrol('Parent',f,'Style','text','String',...
%         '3. Smoothing Options',...
%         'Position',[10,600,200,25]);
    SBSAedit = uicontrol('Parent',fShirley,'Style','edit','String',...
        'type the number',...
        'Position',[50,220,100,25]);                 
    SBEAedit = uicontrol('Parent',fShirley,'Style','edit','String',...
        'type the number',...
        'Position',[150,220,100,25]);   
    SBARedit = uicontrol('Parent',fShirley,'Style','edit','String',...
        '12',...
        'Position',[250,220,100,25]);       
    SBNIedit = uicontrol('Parent',fShirley,'Style','edit','String',...
        '10',...
        'Position',[350,220,100,25]);   
%     ARinstructiontext = uicontrol('Parent',fShirley,'Style','text','String',...
%         'Anchor Range MUST BE an odd number',...
%         'Position',[150,390,350,25]);    
    SSinstructiontext = uicontrol('Parent',fShirley,'Style','text','String',...
        'Each spectrum will be registered in a separate matrix. Go to Review to finalize.',...
        'Position',[10,275,500,25]);        
    rfprevious = uicontrol('Parent',frf,'Style','pushbutton','String',...
        '<==',...
        'Position',[100,520,50,25],...
        'Callback',{@rfPrevious_Callback});    
    rfnext = uicontrol('Parent',frf,'Style','pushbutton','String',...
        '==>',...
        'Position',[150,520,50,25],...
        'Callback',{@rfNext_Callback});     
    rfjumpto = uicontrol('Parent',frf,'Style','edit','String',...
        'where to?',...
        'Position',[200,520,80,25]);
    rfjumpit = uicontrol('Parent',frf,'Style','pushbutton','String',...
        'Jump!',...
        'Position',[280,520,100,25],'Callback',{@rfJump_Callback});     
    %3. Status field
    statusfield = uicontrol('Parent',fShirley,'Style','text','String',...
        'Current Status: GUI Initiated. Click the Data Folder button to import the data. All the data name MUST BE as seen at the bottom instruction.',...
        'Position',[450,650,500,50]);
    spectrumfield1 = uicontrol('Parent',fShirley,'Style','text','String',...
        'Current Spectrum',...
        'Position',[550,630,100,25]);
    spectrumfield2 = uicontrol('Parent',fShirley,'Style','text','String',...
        specnum,...
        'Position',[650,630,50,25]);    
    spectrumfield3 = uicontrol('Parent',fShirley,'Style','text','String',...
        'Out of',...
        'Position',[700,630,50,25]);        
     spectrumfield4 = uicontrol('Parent',fShirley,'Style','text','String',...
        totalspecnum,...
        'Position',[750,630,50,25]);           
        
%     instructionfield = uicontrol('Parent',f,'Style','text','String',...
%         'Data file name must contain Data. e.g., Data_01',...
%         'Position',[10,10,700,25]);        
%     instructiontext = uicontrol('Parent',f,'Style','text','String',...
%         'Sgolay smoothing will be applied to all data. Suggested window size: 5 ',...
%         'Position',[50,530,350,25]);        
    instructionfield2 = uicontrol('Parent',fShirley,'Style','text','String',...
        'Kinetic energy can be read down to 2 digit to the right of decimal point. (e.g., 33.32 eV not 33.3199eV)',...
        'Position',[10,35,700,25]);            
    
    %===========Review and finalize window instructions
    frfspectrumfield1 = uicontrol('Parent',frf,'Style','text','String',...
        'Current Spectrum',...
        'Position',[50,550,100,25]);
    frfspectrumfield2 = uicontrol('Parent',frf,'Style','text','String',...
        specnum,...
        'Position',[150,550,50,25]);    
    frfspectrumfield3 = uicontrol('Parent',frf,'Style','text','String',...
        'Out of',...
        'Position',[200,550,50,25]);        
     frfspectrumfield4 = uicontrol('Parent',frf,'Style','text','String',...
        totalspecnum,...
        'Position',[250,550,50,25]);   
    
     frfsave = uicontrol('Parent',frf,'Style','edit','String',...
        'Put name here',...
        'Position',[50,75,200,25],'Callback',{@SaveName_Callback});       
     frfsaveall = uicontrol('Parent',frf,'Style','edit','String',...
        'Put name here',...
        'Position',[250,75,200,25],'Callback',{@SaveAllName_Callback});    
     frfsaveinstruction = uicontrol('Parent',frf,'Style','text','String',...
        'Save current',...
        'Position',[50,100,100,25]);       
     frfsaveallinstruction = uicontrol('Parent',frf,'Style','text','String',...
        'Save all',...
        'Position',[250,100,100,25]);    
     frfsavebutton = uicontrol('Parent',frf,'Style','pushbutton','String',...
        'Save current',...
        'Position',[50,50,200,25],'Callback',{@SaveOne_Callback});       
     frfsaveallbutton = uicontrol('Parent',frf,'Style','pushbutton','String',...
        'Save all',...
        'Position',[250,50,200,25],'Callback',{@SaveAll_Callback}); 
     frfinstructions = uicontrol('Parent',frf,'Style','text','String',...
        'Navigate the spectrum to save each. Hit Save All to save all in separate vectors. Then import those files again in the ARPES Main Analysis Panel.',...
        'Position',[50,25,500,25]);    
     frfoffset1 = uicontrol('Parent',frf,'Style','text','String',...
        'Add or subtract offset in y per spectrum',...
        'Position',[525,400,200,25]);     
     frfoffset2 = uicontrol('Parent',frf,'Style','edit','String',...
        'How much?',...
        'Position',[550,380,150,25]);        
     frfoffset3 = uicontrol('Parent',frf,'Style','pushbutton','String',...
        'Apply',...
        'Position',[550,350,50,25],'Callback',{@Offset_Callback});   
     frfoffset4 = uicontrol('Parent',frf,'Style','text','String',...
        'Positive input increases the y value',...
        'Position',[525,300,200,25]);              
%==========================================================================
%>>>>>>>>>>>>>>>>>>>>>>>>>>>Call Back Functions<<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
%Callback without a function, which initiates when the GUI begins.
        numfiles = length(KE(1,:));
        L = length(KE(:,1));
        %-------------Separate the intensity data into arrays of one data type

%         if KE(1,1)>KE(L,1)
%             y = flip(y);
%             KE = flip(KE);
%         end
            axes(ax)
            plot(KE(:,1),y(:,1));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');

            specnum = 1;
            totalspecnum = numfiles;
        spectrumfield2.String = specnum;
        spectrumfield4.String = totalspecnum;
        statusfield.String = 'Data imported. Use the direction buttons or type the spectrum number to navigate. Smooth the spectra first.'; 
        sy = y;
        BG = zeros(length(y(:,1)),length(y(1,:)));
        

        
        %Callbacks begin
    function FDscalefactor_Callback(~,~)
       FDscalefactor = str2double(FDscalefactor_Field.String);
       statusfield.String = cat(2,'Fermi-Dirac function scale will be adjusted by a factor ',FDscalefactor_Field.String);
       
    end
    function FDpreset_Callback(~,~)
        if Checkbox_FDpreset.Value ==1
            statusfield.String = 'Fermi-Dirac distribution will be accounted in your BG estimateand subtraction.';
            FDflag = 1;
        else
            statusfield.String = 'Fermi-Dirac distribution is inactive in your BG estimate and subtraction';
            FDflag =0;
        end
    end
    function idea_FD_Callback(~,~)
        msgbox('The way how it includes Fermi Dirac distribution is as following. Even though Shirley Background takes the nature of FD distribution, it is deemed that it does not account the presence of it. Where the data has very low counts - especially when you do high resolution study, the contribution of FD near Fermi level is not negligible. Thus this method could be useful when you have ARPES data of metallic sample yet counts were low.' ,'Basic Idea');
    end
    function Help_FD_Callback(~,~)
        msgbox('Find the effective temperature best describing the FD curve near Fermi level. Then set up Anchors and other associated parameters. Start from scale factor of 1 and Offset of 0. You will keep previewing the estimate BG and change Scale factor and Offset iteratively. Optimal Offset is where your estimated BG touches the FD curve of the data. Optimal Scale factor is where the estimated background End Anchor touches the spectral intensity at the End Anchor.','Pro Tips');
    end
    function Help_TEff_Callback(~,~)
        msgbox('FD curve not only depends on the sample temperature but also the instrumental broadening. To the VG chamber resolution, C3 slit requires minimum 350 Kelvin in the data field.','Good guess value of Effective Temperature');
    end
    function FDtemperature_Callback(~,~)
        T = str2double(Field_temperature.String);
        statusfield.String = cat(2,'Sample temperature set to ',Field_temperature.String,' K.');
        kB = 8.167e-5;
        nFD = 1./(1+exp((KE(:,1)-EFermi)./(kB*T)));
    end
    function scalefactor_Callback(~,~)
        scalefactor = str2double(scalingfactor.String);
        statusfield.String = cat(2,'Scale Factor is set to ',scalingfactor.String);
    end
    function offsetfactor_Callback(~,~)
        offsetfactor = str2double(offsetfactor_field.String);
        statusfield.String = cat(2,'Y offset is set to ',offsetfactor_field.String);
    end
    function Previous_Callback(~,~)

        if specnum>1 && modeflag==1
            axes(ax)
            plot(KE(:,specnum-1),y(:,specnum-1));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            specnum = specnum-1;
            spectrumfield2.String = specnum;
        end

    end
    function Next_Callback(~,~)
                if specnum<totalspecnum && modeflag ==1
                    axes(ax)
                    plot(KE(:,specnum+1),y(:,specnum+1));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                    specnum = specnum+1;
                    spectrumfield2.String = specnum;

                end
    end
    function Jump_Callback(~,~)
        if 0<str2double(jumpto.String) && str2double(jumpto.String)<totalspecnum+1
                    axes(ax)
                    plot(KE(:,str2double(jumpto.String)),y(:,str2double(jumpto.String)));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                    specnum = str2double(jumpto.String);
                    spectrumfield2.String = specnum;

        elseif str2double(jumpto.String)>totalspecnum
            statusfield.String = 'Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.';
        elseif str2double(jumpto.String)<1
            statusfield.String = 'Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.';    
        end
    end



    function PreviewBG_Callback(~,~)
        Anchor1 = str2double(SBSAedit.String);
        Anchor2 = str2double(SBEAedit.String);
        NumIter = str2double(SBNIedit.String);
        AR = str2double(SBARedit.String);
%============startanchor==========        


        startanchor = find(Anchor1==KE(:,specnum));
        %         SAD = zeros(2*AR+1,1);
            if startanchor<length(KE(:,1))-(AR-1)
                SAD(:,1) = y(startanchor-AR:startanchor+AR,specnum);%Find the data near the anchor that the user chose. (Start Anchor Data)
                tempLMSA = find(SAD(:,1)==min(SAD(:,1)));
                if size(tempLMSA,1)>1
                    if max(diff(tempLMSA,1))<4
                        LMSA(:,specnum) = tempLMSA(1,1);
                    elseif max(diff(tempLMSA,1))>=4
                        msgbox('There were at least 2 data points matching with the energy you set which are too far away from each other. Try choosing another energy value to avoid this.');
                    end
                elseif size(tempLMSA,1)==1
                    LMSA(:,specnum) = tempLMSA;
                elseif size(tempLMSA,1)==0
                    msgbox('The algorithm failed to find the data point you typed in the Start energy. Try another number.');
                end
                %LMSA(:,specnum) = find(SAD(:,1)==min(SAD(:,1)));%Indexing the true minimum position near the SAD. tempLMSA is a temporary local minimum start anchor.
                ILMSA(1,specnum) = LMSA(1,specnum)-((length(SAD)/2)+0.5); %translation operation. SAD/2+0.5 is the reference point that the start anchor located. Thus the new ILMSA finds the relative coordinate change from the anchor that the user chose.
                ASA(1,specnum) = startanchor-ILMSA(1,specnum); %This is automatically adjusted anchor for the fitting at every single pixel. Automatic Start Anchor.
            else     
                for m=0:AR-1
                    if startanchor == length(KE(:,1))-m
                        correction = m;
                        SAD(:,1) = y(startanchor-AR:startanchor+correction,specnum);%If the number of data before the startanchor is less than Range, this algorithm fixes the range of the EAD
                    end
                end
                tempLMSA = find(SAD(:,1)==min(SAD(:,1)));%Indexing the true minimum position near the SAD
                if size(tempLMSA,1)>1
                    if max(diff(tempLMSA,1))<4
                        LMSA(:,specnum) = tempLMSA(1,1);
                    elseif max(diff(tempLMSA,1))>=4
                        msgbox('There were at least 2 data points matching with the energy you set which are too far away from each other. Try choosing another energy value to avoid this.');
                    end
                elseif size(tempLMSA,1)==1
                    LMSA(:,specnum) = tempLMSA;
                elseif size(tempLMSA,1)==0
                    msgbox('The algorithm failed to find the data point you typed in the Start energy. Try another number.');
                end
                ILMSA(1,specnum) = LMSA(1,specnum)-(AR+1); %translation operation. AR/2+1 is the reference point that the start anchor located. Thus the new ILMSA finds the relative coordinate change from the anchor that the user chose.
                ASA(1,specnum) = startanchor+ILMSA(1,specnum); %This is automatically adjusted anchor for the fitting at every single pixel. Automatic Start Anchor.
            end

                

%==============endanchor============


        endanchor = find(Anchor2==KE(:,specnum)); %Find the end anchor index
        if endanchor>AR && AR<length(y(:,specnum))/2
            EAD(:,1) = y(endanchor-AR:endanchor+AR,specnum);%Find the data near the anchor that the user chose. (End Anchor Data)           
            %LMEA(1,specnum) = find(EAD(:,1)==min(EAD(:,1)));%Indexing the true minimum position near the EAD    
            tempLMEA = find(EAD(:,1)==min(EAD(:,1)));
            if size(tempLMEA,1)>1
                if max(diff(tempLMEA,1))<4
                    LMEA(1,specnum) = tempLMEA(1,1);
                elseif max(diff(tempLMEA,1))>=4
                    msgbox('There were at least 2 data points matching with the energy you set which are too far away from each other. Try choosing another energy value to avoid this.');
                end
            elseif size(tempLMEA,1)==1
                LMEA(1,specnum) = tempLMEA;
            elseif size(tempLMEA,1)==0
                msgbox('The algorithm failed to find the data point you typed in the End energy. Try another number.');
            end
            
            ILMEA(1,specnum) = LMEA(1,specnum)-((length(EAD)/2)+0.5); %translation operation. (AR+1) is the reference point that the start anchor located. Thus the new ILMEA finds the relative coordinate change from the anchor that the user chose. 

        else
            for m=1:AR
                if endanchor == m
                    correction2 = m-1; % The number of data counted near the data boundary
                    EAD(:,1) = y(endanchor-correction2:endanchor+AR,specnum);%If the number of data behind the endanchor is more than AR, this algorithm fixes the range of the EAD
                end
            end
            %LMEA(1,specnum) = find(EAD(:,1)==min(EAD(:,1)));%Indexing the true minimum position near the EAD     
            tempLMEA = find(EAD(:,1)==min(EAD(:,1)));
            if size(tempLMEA,1)>1
                if max(diff(tempLMEA,1))<4
                    LMEA(1,specnum) = tempLMEA(1,1);
                elseif max(diff(tempLMEA,1))>=4
                    msgbox('There were at least 2 data points matching with the energy you set which are too far away from each other. Try choosing another energy value to avoid this.');
                end
            elseif size(tempLMEA,1)==1
                LMEA(1,specnum) = tempLMEA;
            elseif size(tempLMEA,1)==0
                msgbox('The algorithm failed to find the data point you typed in the End energy. Try another number.');
            end
            ILMEA(1,specnum) = LMEA(1,specnum)-(correction2+1); %translation operation. (AR+1) is the reference point that the start anchor located. Thus the new ILMEA finds the relative coordinate change from the anchor that the user chose. 
        end
            AEA(1,specnum) = endanchor+ILMEA(1,specnum);
        
      
%============Shirley Loop Initiation=========
    Iy = zeros(length(y(:,1)),2);%integrate->this is the first shirley background function

        fy = flip(y);
        
        for n=1:NumIter %looping the Shirley iteration
            Iy(:,2)=cumtrapz(fy(:,specnum)-Iy(:,1)-fy(1,specnum));
            s=(fy(length(KE(:,specnum))-AEA(1,specnum),specnum)-fy(length(KE(:,specnum))-(ASA(1,specnum)-1),specnum))/(Iy(length(KE(:,specnum))-AEA(1,specnum),2));
            Iy(:,2)=s.*Iy(:,2);
            Iy(:,1)=Iy(:,2); %Fire and forget for compact cumulative iterations. 
        end    

            BG(:,specnum) = flip(Iy(:,1))+min(y(:,specnum));
            BG(:,specnum) = scalefactor.*BG(:,specnum);
            [M,I] = min(abs(KE(:,1)-EFermi));
            
        if FDflag ==1
            BG(:,specnum) = BG(:,specnum)+y(I,specnum).*nFD*FDscalefactor;
        end
            BG(:,specnum) = BG(:,specnum)+offsetfactor;
            axes(ax)
            if FDflag ==1
                plot(KE(:,specnum),y(:,specnum),KE(:,specnum),BG(:,specnum),KE(:,specnum),FDscalefactor.*nFD.*y(I,specnum));
            else
                plot(KE(:,specnum),y(:,specnum),KE(:,specnum),BG(:,specnum))
            end
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');  
            hold on
            plot(KE(ASA(1,specnum),specnum),BG(ASA(1,specnum),specnum),'o','MarkerFaceColor','r');
            plot(KE(AEA(1,specnum),specnum),BG(AEA(1,specnum),specnum),'o','MarkerFaceColor','b');
            hold off     
            if FDflag ==1
                legend('Data','BG','Fermi Dirac','Automated Start Anchor','Automated End Anchor','Location','best')
            else
                legend('Data','BG','Automated Start Anchor','Automated End Anchor','Location','best')
            end

            if FDflag ==1
                statusfield.String = 'Background estimation finished. Change the effective temperature and scale factor such that the estimate background at End Anchor is identical to intensity at the End Anchor.';
            else
                statusfield.String = 'Background estimation finished. The figure now shows both the spectrum and the BG.';
            end
    end
    function SubandSave_Callback(~,~)
        sy(:,specnum) = y(:,specnum)-BG(:,specnum);
    statusfield.String = {'Background subtraction for' specnum 'th data finished and saved. Mark off on you note to check if the whole BG subtraction is done.'};
    end

    function ReviewandFinalize_Callback(~,~)
        frf.Visible = 'on';
        if modeflag ==0
            axes(axfrf)
            plot(KE(:,specnum),sy(:,specnum));
            axis on
            xlabel ('BE(eV)');
            ylabel ('Intensity');    
        elseif modeflag ==1
            axes(axfrf)
            plot(KE(:,specnum),sy(:,specnum));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');   
        end
            frfspectrumfield2.String = specnum;
            frfspectrumfield4.String = totalspecnum;
    end
    function rfPrevious_Callback(~,~)
        if specnum>1 && modeflag ==0
            axes(ax)
            plot(KE(:,specnum-1),y(:,specnum-1));
            axis on
            xlabel ('BE(eV)');
            ylabel ('Intensity');
            axes(axfrf)
            plot(KE(:,specnum-1),sy(:,specnum-1));
            axis on
            xlabel ('BE(eV)');
            ylabel ('Intensity');
        elseif specnum>1 && modeflag ==1
            axes(ax)
            plot(KE(:,specnum-1),y(:,specnum-1));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            axes(axfrf)
            plot(KE(:,specnum-1),sy(:,specnum-1));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');
        end
            specnum = specnum-1;
            spectrumfield2.String = specnum;
            frfspectrumfield2.String = specnum;
            %spectrumfield6.String = PE(1,specnum);
    end
    function rfNext_Callback(~,~)
                if specnum<totalspecnum && modeflag ==0
                    axes(ax)
                    plot(KE(:,specnum+1),y(:,specnum+1));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');
                    axes(axfrf)
                    plot(KE(:,specnum+1),sy(:,specnum+1));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');
                elseif specnum<totalspecnum && modeflag ==1
                    axes(ax)
                    plot(KE(:,specnum+1),y(:,specnum+1));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                    axes(axfrf)
                    plot(KE(:,specnum+1),sy(:,specnum+1));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                end
                    specnum = specnum+1;
                    spectrumfield2.String = specnum;
                    frfspectrumfield2.String = specnum;
                    %spectrumfield6.String = PE(1,specnum);
    end
    function rfJump_Callback(~,~)
        if 0<str2double(rfjumpto.String) && str2double(rfjumpto.String)<totalspecnum+1
            if modeflag ==0                
                    axes(ax)
                    plot(KE(:,str2double(rfjumpto.String)),y(:,str2double(rfjumpto.String)));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');
                    axes(axfrf)
                    plot(KE(:,str2double(rfjumpto.String)),sy(:,str2double(rfjumpto.String)));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');
            elseif modeflag ==1
                    axes(ax)
                    plot(KE(:,str2double(rfjumpto.String)),y(:,str2double(rfjumpto.String)));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');
                    axes(axfrf)
                    plot(KE(:,str2double(rfjumpto.String)),sy(:,str2double(rfjumpto.String)));
                    axis on
                    xlabel ('BE(eV)');
                    ylabel ('Intensity');   
            end

                    specnum = str2double(rfjumpto.String);
                    spectrumfield2.String = specnum;
                    frfspectrumfield2.String = specnum;
                    spectrumfield6.String = PE(1,specnum);
        elseif str2double(rfjumpto.String)>totalspecnum
            statusfield.String = 'Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.';
        elseif str2double(rfjumpto.String)<1
            statusfield.String = 'Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.';    
        end
    end        
    function SaveName_Callback(~,~)
        SaveTag = frfsave.String;
    end
    function SaveAllName_Callback(~,~)
        SaveAllTag = frfsaveall.String;
    end
    function SaveOne_Callback(~,~)
        onechar = char(location,'\','BGsubtracedSpectrum_',[num2str(specnum),'_'],SaveTag,'.dat');
        onefilename = strcat(onechar(1,:),onechar(2,1),onechar(3,:),onechar(4,:),onechar(5,:),onechar(6,1:4));
        if modeflag ==0
            onefile = cat(2,KE(:,specnum),sy(:,specnum));
        elseif modeflag ==1
            onefile = cat(2,KE(:,specnum),sy(:,specnum));
        end
        save(onefilename,'onefile','-ascii');
    end
    function SaveAll_Callback(~,~)
        
%         allfile = zeros(length(KE(:,1)),2*totalspecnum);
%         if modeflag ==0
%             for i=1:totalspecnum
%                 allfile(:,2*i-1:2*i) = cat(2,KE(:,i),sy(:,i));
%             end
%         elseif modeflag ==1
%             for i=1:totalspecnum
%                 allfile(:,2*i-1:2*i) = cat(2,KE(:,i),sy(:,i));
%             end      
%         end
        for i=1:totalspecnum
            rocktheworld = num2str(i+10);
            datavector = cat(2,KE(:,i),sy(:,i));
            allchar = char(location,'\',rocktheworld,'_Shirley_AR_',SaveAllTag,'_','.txt');
            allfilename = strcat(allchar(1,:),allchar(2,1),allchar(3,:),allchar(4,:),allchar(5,:),allchar(6,:),allchar(7,1:4));
            save(allfilename,'datavector','-ascii');
        end
        msgbox('Data generated. Notice that there are multiple files generated, starting from number 11.');
            
    end

    function f_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Yes','No','Yes');
        switch selection 
            case 'Yes'
                set(frf,'Visible','off')
                set(fShirley,'Visible','off')
                %delete(gcf)
            case 'No'
                return 
        end
    end
    function frf_closereq(~,~)
        % Close request function 
        % to display a question dialog box 
        selection = questdlg('Close This Figure?',...
            'Close Request Function',...
            'Close','Cancel','Close');
        switch selection
            case 'Close'
                set(frf,'Visible','off')
                
            case 'Cancel'
                return
        end
    end
    
        

    function Offset_Callback(~,~)
        yoffset = str2double(frfoffset2.String);
        sy(:,specnum) = sy(:,specnum)+yoffset;
            if modeflag ==0
                axes(axfrf)
                plot(KE(:,specnum),sy(:,specnum));
                axis on
                xlabel ('BE(eV)');
                ylabel ('Intensity');    
            elseif modeflag ==1
                axes(axfrf)
                plot(KE(:,specnum),sy(:,specnum));
                axis on
                xlabel ('KE(eV)');
                ylabel ('Intensity');   
            end
    end

%End of the app

end