function ARPES_Ef_analyzer
% This tool aims to find Fermi level, thermal broadening, and instrumental
% energy resolution using the Fermi spectrum.
%It can also fit up to two Gaussian features near the Fermi level. Thus it
%could be a useful tool to find insights on the Fermiology.

%First, clip the range of the data such that the data covers very near the
%fermi level. For this, refer to Joohyung Park's electronic lab note:
%Joohyung Park-2019 ->MoTe2->4/18 Fermi fitting function tool. This page
%shows an ideally clipped case.

%import the data by locating the folder where the files are stored. The files must contain the identifier - 'Fermi'
%Run smoothing if necessary. Don't smooth the spectra multiple times. It is okay to do it 2 times cumulatively at maximum but
%more than 2 is not recommended. 

%Don't put Gaussian broadening larger than 500meV.  
%Room temperature thermal energy (kT) is 0.025eV.
%Instrumental Fermi level is ~22.07 (some slits find 22.04) eV as of 2021.
%You will have to find an ideal set of fitting parameters. This includes not only the parameter values but also
%the allowed scale of variation. If you wish to let the fitting procedure have a wide range of fit parameter values to try on,
%increase the scale of the variation. Variation's scale is in absolute scale - no percentage.

%Also, the gaussian area is not an independent parameter as it will be proportional to the Fermi-Dirac distribution
%intensity (so called Multiplier in this app). It may sound weird that Fermi Dirac distribution can have instensity but due to channeltron's amplification,
%the whole detected signals are amplified - including the Fermi Dirac cutoff. Thus Multiplier term serves as to reflect the
%presence of the Channeltron. 
%Practically, if your spectrum has a base offset of 100 and spectral
%baseline has intensity of 1000, Baseline intensity is best to be set to
%100 and variation of less than 10. Multiplier value will be set as
%baseline-offset (1000-100) thus 900 or smaller. Variation won't need to be
%large. I usually put 5% of the Multiplier value as a variation.

%Using no gaussians in your fit, the fit result will show you two set of guiding lines,red: 84/16 for the fitted
%curve, blue: suggested 84/16 lines for the raw data. It is your discretion
%whether or not to use the suggested lines for the raw data. 84/16 is
%statistically acceptable criteria. The energy width between the two red
%lines will be the thermal broadening term(thermal gap), determined by the fitting
%curve where an ideal case is simulated. The energy width of the raw data
%using 84/16 method will be the realistic boradening. Instrumental
%broadening comes into play such that 
%del(Raw) =sqrt(del(thermal)^2+del(instrumental)^2. This is not a perfect
%way of estimating the error propagation as the thermal error is not
%Gaussian. However, keeping this systematically through various setups will
%somehow provide insights to the instrumental energy resolution.

%Lastly, Invert Fermi Cutoff uses the Fit results to infer how the spectral
%intensity would look like if Fermi-Dirac cutoff didn't exist near the
%Fermi level. This function works best if you have a high-resolution
%settings (C4 + low temperature) and a finite density of states right at
%the Fermi level.
%==========================================================================
% >>>>>>>>>>>>>>>>>>>> Figures and Axes declaration <<<<<<<<<<<<<<<<<<<<<<<<<<<<
%==========================================================================
%figure and axis declaration
    fEf = figure('Visible','off','Position',[50,50,1000,720]);
    axEf = axes('Parent',fEf,'Units','Pixels','Position',[550,300,400,300]);
    resax = axes('Parent',fEf,'Units','Pixels','Position',[550,120,400,100]);
    fEf.Visible = 'on';
 %global variable declaration
 numfiles = 1;
 specnum = 0;
 filenames={};
 sw = 3;
  V1A = 1;
 V1C = 0;
 V1G = 50;
 V2A = 1;
 V2C = 0;
 V2G = 50;
 kT = 25;
 Ef = 22.08; 
 Base = 40;
 I = 100;
 BIVar = 10;
 MPVar = 10;
 G1WVar = 0.1;
 G1CVar = 0.05;
 G1AVar = 0.01;
 G2WVar = 0.1;
 G2CVar = 0.05;
 G2AVar = 0.01;
 gauss1flag = 0;
 gauss2flag = 0;
 guesswhat0 = [1,1,1,1,1];
 guesswhat1 = [1,1,1,1,1,1,1,1,];
 guesswhat2 = [1,1,1,1,1,1,1,1,1,1,1];
 sampleT = 23;
 kelvin = 273.15;
 thermalE = 0.025;
 instrumentalbroadening = 0;
 mysinglecoeff = zeros(4,1);
  mysinglecoeff2 = zeros(7,1);
   mysinglecoeff3 = zeros(10,1);
%  V1A = str2double(voigtfield.String);
%  V1C = str2double(voigtfield2.String);
%  V1L = str2double(voigtfield3.String);
%  V1G = str2double(voigtfield4.String);
%  V2A = str2double(voigt2field.String);
%  V2C = str2double(voigt2field2.String);
%  V2L = str2double(voigt2field3.String);
%  V2G = str2double(voigt2field4.String);
%  kT = str2double(Fermifield.String);
%  Ef = str2double(Fermifield2.String); 
%  Base = str2double(basefield.String);
    data = zeros(2,20);
    location = 'cd';
 %1. Buttons
    instructions1 = uicontrol('Parent',fEf,'Style','text','String',...
        'Spectrum and fit results','FontSize',16,'Position',[600,620,300,25]);
    instructions2 = uicontrol('Parent',fEf,'Style','text','String',...
        'Residuals','FontSize',16,'Position',[600,220,200,25]);    
     folder = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        'Data Folder',...
        'Position',[50,660,100,25],...
        'Callback',{@Folder_Callback});
     smoothbutton = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        'Run Smoothing',...
        'Position',[150,570,100,25],'Callback',{@Smoothdata_Callback});     
    smoothwindowtext = uicontrol('Parent',fEf,'Style','edit','String',...
        'Window size',...
        'Position',[50,570,100,25]);  
    smoothtext = uicontrol('Parent',fEf,'Style','text','String','Smoothing using Sgolay','Position',[50,600,150,25]);
    temperaturetext = uicontrol('Parent',fEf,'Style','text','String','Sample Temperature','Position',[300,600,150,25]);
    temperatureinput = uicontrol('Parent',fEf,'Style','edit','String','Celcius','Position',[300,570,150,25],'Callback',{@Temperature_Callback});
    gauss1 = uicontrol('Parent',fEf,'Style','checkbox','Position',[150,520,25,25],'Callback',{@V1_Callback});
    gauss1text = uicontrol('Parent',fEf,'Style','text','String','Include Gaussian 1','Position',[50,520,100,25]);
    gausstext2 = uicontrol('Parent',fEf,'Style','text','String','Enter in this order: Area, center, gaussian width with its own associated fit variation scale','Position',[5,490,500,25]);
        gauss1field = uicontrol('Parent',fEf,'Style','edit','String',...
        'Area','Position',[15,460,50,25]);
        gauss1field1var = uicontrol('Parent',fEf,'Style','edit','String',...
            'Area Var','Position',[70,460,50,25],'Callback',{@G1AV_Callback});
        gauss1field2 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Center','Position',[125,460,50,25]);    
        gauss1field2var = uicontrol('Parent',fEf,'Style','edit','String',...
            'Cnt Var','Position',[180,460,50,25],'Callback',{@G1CV_Callback});
        gauss1field4 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Width','Position',[235,460,50,25]);
    gauss1field4var = uicontrol('Parent',fEf,'Style','edit','String',...
        'width Var','Position',[290,460,50,25],'Callback',{@G1WV_Callback});
     gauss2 = uicontrol('Parent',fEf,'Style','checkbox','Position',[150,420,25,25],'Callback',{@V2_Callback});
    gauss2text = uicontrol('Parent',fEf,'Style','text','String','Include Gaussian 2','Position',[50,420,100,25]);
    %gauss2text2 = uicontrol('Parent',fEf,'Style','text','String','Enter in this order: Area, center(eV), gaussian width(eV)','Position',[10,490,400,25]);
        gauss2field = uicontrol('Parent',fEf,'Style','edit','String',...
        'Area','Position',[15,390,50,25]);
        gauss2field1var = uicontrol('Parent',fEf,'Style','edit','String',...
        'Area Var','Position',[70,390,50,25],'Callback',{@G2AV_Callback});
        gauss2field2 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Center','Position',[125,390,50,25]);
        gauss2field2var = uicontrol('Parent',fEf,'Style','edit','String',...
        'Cnt Var','Position',[180,390,50,25],'Callback',{@G2CV_Callback});
%         gauss2field3 = uicontrol('Parent',f,'Style','edit','String',...
%         'Lorentzian','Position',[125,390,55,25]);
        gauss2field4 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Width','Position',[235,390,50,25]);   
        gauss2field4var = uicontrol('Parent',fEf,'Style','edit','String',...
        'Width Var','Position',[290,390,50,25],'Callback',{@G2WV_Callback});
     instructionfield = uicontrol('Parent',fEf,'Style','text','String',...
        'This GUI can include two Gaussian features. Use the check box to include those. Use smoothing if necessary. The data will smooth over and over so DO NOT repeat this. For detailed instructions, refer to the preamble in the code script.',...
        'Position',[10,10,700,25]);      
     fermiinstructionfield = uicontrol('Parent',fEf,'Style','text','String',...
        'Fermi energy section. Guess the data kT in eV which contains both Instrumental Broadening and Fermi Instrinsic Broadening. Use Multiplier to limit the height of the Fermi function. Put an estimated Ef.',...
        'Position',[15,360,500,25]);          
        Fermifield = uicontrol('Parent',fEf,'Style','edit','String',...
        'kT','Position',[15,330,50,25]);
        Fermifield2 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Ef','Position',[70,330,50,25]);  
        Fermifield3 = uicontrol('Parent',fEf,'Style','edit','String',...
        'Multiplier','Position',[130,330,50,25]);    
        Fermifield3Var = uicontrol('Parent',fEf,'Style','edit','String',...
            'Multipl Var','Position',[190,330,50,25],'Callback',{@MultiplierVar_Callback});
     baselineinstructionfield = uicontrol('Parent',fEf,'Style','text','String',...
        'Measure the baseline intensity and type in here with the fit variation you want.',...
        'Position',[15,300,400,25]);      
     basefield = uicontrol('Parent',fEf,'Style','edit','String',...
        'BaseIntensity','Position',[15,270,100,25]);
     basefieldvar = uicontrol('Parent',fEf,'Style','edit','String',...
        'BI Var','Position',[120,270,50,25],'Callback',{@BIVar_Callback});    
     fitbutton = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        'Fit Spectrum',...
        'Position',[15,200,100,50],'Callback',{@Fitit_Callback});    
     invertbutton = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        'Invert Fermi Cutoff',...
        'Position',[15,130,100,50],'Callback',{@Invert_Callback});        
    fitresultinstructions = uicontrol('Parent',fEf,'Style','text','String',...
        'Fit Results','Position',[220,250,70,25]);
    fitresultinstructions2 = uicontrol('Parent',fEf,'Style','text','String',...
        'Ef','Position',[130,220,70,25]);    
    fitresultinstructions3 = uicontrol('Parent',fEf,'Style','text','String',...
        'kT','Position',[130,190,70,25]); 
    fitresultinstructions4 = uicontrol('Parent',fEf,'Style','text','String',...
        'Multiplier','Position',[130,160,70,25]);  
    fitresultinstructions5 = uicontrol('Parent',fEf,'Style','text','String',...
        'Base','Position',[130,130,70,25]);     
    fitresultinstructions6 = uicontrol('Parent',fEf,'Style','text','String',...
        'Data.Width','Position',[130,100,70,25]);     
    v1fitresultinstructions = uicontrol('Parent',fEf,'Style','text','String',...
        'Gaussian 1','Position',[350,250,70,25]);    
    v1fitresultinstructions2 = uicontrol('Parent',fEf,'Style','text','String',...
        'Center','Position',[280,220,70,25]);    
    v1fitresultinstructions3 = uicontrol('Parent',fEf,'Style','text','String',...
        'Area','Position',[280,190,70,25]); 
%     v1fitresultinstructions4 = uicontrol('Parent',f,'Style','text','String',...
%         'Lorentz','Position',[280,160,70,25]);  
    v1fitresultinstructions5 = uicontrol('Parent',fEf,'Style','text','String',...
        'Gauss','Position',[280,130,70,25]);      
    v2fitresultinstructions = uicontrol('Parent',fEf,'Style','text','String',...
        'Gaussian 2','Position',[420,250,70,25]);        
    displayThermalE2 = uicontrol('Parent',fEf,'Style','text','String',...
        'eV is the sample thermal energy','Position',[350,540,170,25]);
    displayThermalE1 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[300,540,50,25]);
    displayEf = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,220,70,25]);  
    displaykT = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,190,70,25]);   
    displayI = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,160,70,25]); 
    displayB = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,130,70,25]);      
    displaydelFermi = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,100,70,25]);
    displayC1 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[350,220,70,25]);  
    displayA1 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[350,190,70,25]);   
%     displayL1 = uicontrol('Parent',f,'Style','text','String',...
%         'N/A','Position',[350,160,70,25]); 
    displayG1 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[350,130,70,25]);      
    displayC2 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[420,220,70,25]);  
    displayA2 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[420,190,70,25]);   
%     displayL2 = uicontrol('Parent',f,'Style','text','String',...
%         'N/A','Position',[420,160,70,25]); 
    displayG2 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[420,130,70,25]);      
    displayintrinsic = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,70,70,25]); 
    displayinstrumental = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[200,40,70,25]); 
    intrnsicinstruction = uicontrol('Parent',fEf,'Style','text','String',...
        'Intrinsic Fermi','Position',[130,70,70,25]);
    instrumentalinstruction = uicontrol('Parent',fEf,'Style','text','String',...
        'Inst. Width','Position',[130,40,70,25]);    
    whatisintrnsicFermi = uicontrol('Parent',fEf,'Style','text','String',...
        'Intrinsic Fermi means the width between 16/84 of the Fermi function intensity.','Position',[270,70,400,25]);
    whatisdatagap = uicontrol('Parent',fEf,'Style','text','String',...
        'Data width means the width between 16/84 of the data Fermi function.','Position',[270,100,250,25]);
    whatisinstgap = uicontrol('Parent',fEf,'Style','text','String',...
        'Inst. width means the broadening caused by the slit/aperture settings.','Position',[270,40,350,25]);    
    previous = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        '<==',...
        'Position',[550,650,50,25],...
        'Callback',{@Previous_Callback});    
    next = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        '==>',...
        'Position',[600,650,50,25],...
        'Callback',{@Next_Callback});       
    jumpto = uicontrol('Parent',fEf,'Style','edit','String',...
        'where to?',...
        'Position',[770,650,80,25]);
    jumpit = uicontrol('Parent',fEf,'Style','pushbutton','String',...
        'Jump!',...
        'Position',[850,650,100,25],'Callback',{@Jump_Callback});      
    spectruminstruction = uicontrol('Parent',fEf,'Style','text','String',...
        'Current Spectrum name:','Position',[400,690,150,25]);
    spectruminstruction2 = uicontrol('Parent',fEf,'Style','text','String',...
        'N/A','Position',[550,690,300,25]);
    
%2. Functions Callback
    function BIVar_Callback(~,~)
       BIVar =  str2double(basefieldvar.String);
    end
    function MultiplierVar_Callback(~,~)
        MPVar = str2double(Fermifield3Var.String);
    end
    function G1AV_Callback(~,~)
        G1AVar = str2double( gauss1field1var.String);
    end
    function G1CV_Callback(~,~)
        G1CVar = str2double(gauss1field2var.String);
    end
    function G1WV_Callback(~,~)
        G1WVar = str2double(gauss1field4var.String);
    end
    function G2AV_Callback(~,~)
        G2AVar = str2double(gauss2field1var.String);
    end
    function G2CV_Callback(~,~)
        G2CVar = str2double(gauss2field2var.String);
    end
    function G2WV_Callback(~,~)
        G2WVar = str2double(gauss2field4var.String);
    end
     
    function Folder_Callback(~,~)
        location = uigetdir();
        filemarker='*Fermi*'; 
        
        plotfile=dir(fullfile(location,filemarker));%Identify the image file location    
        numfiles=length(plotfile);%calculate the number of spectra
        filenames={plotfile,plotfile.name};%construct an array of file names
        filenames(:,1) = []; %removing unnecessary data     
        data = [];
        for i=1:numfiles      %populate the empty array with the imported data
          data=[data,importdata(fullfile(location,filenames{1,i}))];%Due to a particular mechanism that this concatenating method, preallocation is not possible.
        end
        specnum =1;
        spectruminstruction2.String = filenames(1,specnum);
        axes(axEf)
        plot(data(:,1),data(:,2));
        xlabel ('KE(eV)');
        ylabel ('Intensity');          
    end
   function Previous_Callback(~,~)
        if specnum>1
            axes(axEf)
            plot(data(:,2*(specnum-1)-1),data(:,2*(specnum-1)));
            axis on
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            specnum = specnum-1;
            spectruminstruction2.String = filenames(1,specnum);
        else
            msgbox('You are at the first data.');
        end

    end
    function Next_Callback(~,~)
                if specnum<numfiles
                    axes(axEf)
                    plot(data(:,2*(specnum+1)-1),data(:,2*(specnum+1)));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                    specnum = specnum+1;
                    spectruminstruction2.String = filenames(1,specnum);
                else
                    msgbox('Error: no next data exists');
                end
    end
    function Jump_Callback(~,~)
        if 0<str2double(jumpto.String) && str2double(jumpto.String)<numfiles+1
                    axes(axEf)
                    plot(data(:,2*(str2double(jumpto.String))-1),data(:,2*(str2double(jumpto.String))));
                    axis on
                    xlabel ('KE(eV)');
                    ylabel ('Intensity');
                    specnum = str2double(jumpto.String);
                    spectruminstruction2.String = filenames(1,specnum);
            
        elseif str2double(jumpto.String)>numfiles
            msgbox ('Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.');
        elseif str2double(jumpto.String)<1
            msgbox('Current Status: Error occured with the number you chose to jump. Choose the number from 1 to the total number of spectra.');    
        end
    end
    function Smoothdata_Callback(~,~)
        sw = str2double(smoothwindowtext.String);
        data = smoothdata(data,'Sgolay',sw);
        axes(axEf)
        plot(data(:,2*specnum-1),data(:,2*specnum));
        xlabel ('KE(eV)');
        ylabel ('Intensity');       
    end
    function V1_Callback(~,~)
        if gauss1.Value == 1
            msgbox('Gaussian function 1 will be included in the fitting');
            gauss1flag = 1;
        elseif gauss1.Value ==0
            msgbox('Gaussian function 1 will be excluded');
            gauss1flag =0;
        end
    end
    function V2_Callback(~,~)
        if gauss2.Value == 1
            msgbox('Gaussian function 2 will be included in the fitting');
            gauss2flag = 1;
        elseif gauss2.Value ==0
            msgbox('Gaussian function 2 will be excluded');
            gauss2flag =0;
        end
    end
    function Temperature_Callback(~,~)
        sampleT = str2double(temperatureinput.String);
        kelvin = sampleT + 273.15;
        thermalE = kelvin*(8.61732814*10^-5);
        displayThermalE1.String = num2str(thermalE);
        
        
    end
    function Fitit_Callback(~,~)
        if gauss1flag ==0 && gauss2flag ==0 %No surface state or plasmon considering-case.
            kT = str2double(Fermifield.String);
            Ef = str2double(Fermifield2.String);
            Base = str2double(basefield.String);
            I = str2double(Fermifield3.String);
            
            guesswhat0 = [kT,Ef,Base,I];%Initial guess value for the fitting. data(1,2) is the initial guess value for intensity multiplier. Fermi distribution function is normalized to 1 by definition. Thus this multiplier renormalizes.
            
            myfitoptions1 = fitoptions('Method','NonlinearLeastSquares','Robust','LAR','Lower',[kT-0.0005,Ef-0.005,Base-BIVar,I-MPVar],'Upper',[kT+0.0005,Ef+0.005,Base+BIVar,I+MPVar],'StartPoint',guesswhat0);

            myfittype1 = fittype(@(a,b,c,d,x)(d./(exp((x-b)./a)+1)+c),'independent',{'x'},'dependent',{'y'},'coefficients',{'a','b','c','d'},'options',myfitoptions1);%a,b,c,d,e are kT,Ef,Baseline,Intensity Multiplier, and gaussian standard dev for each.
            [myglobalfit,gof,output] = fit(data(:,2*specnum-1),data(:,2*specnum),myfittype1,'StartPoint',guesswhat0);
            mysinglecoeff1 = coeffvalues(myglobalfit);
            J = output.Jacobian;
            N = output.numobs;
            p = output.numparam;
            R = output.residuals;
            MSE = (R'*R)/(N-p);
            CovB = inv(J'*J).*MSE;
            index = size(CovB);
            CorrelationCoefficients = ones(index(1,1),index(1,2));
            rsq = num2str(gof.rsquare);
            rsqdisplay = strcat('Rsq=',rsq);            
            InstructionVector = {'kT','Ef','Base','Multiplier'};
            for i=1:index(1,1)
                for j=1:index(1,1)
                    if i~=j
                        CorrelationCoefficients(i,j) = CovB(i,j)./sqrt(CovB(i,i)*CovB(j,j));
                    end
                end
            end
            FitresultsTable = table(CorrelationCoefficients(:,1),CorrelationCoefficients(:,2),CorrelationCoefficients(:,3),CorrelationCoefficients(:,4),'VariableNames',InstructionVector,'RowNames',InstructionVector);
                        
            y = feval(myglobalfit,data(:,2*specnum-1));
            
            displayEf.String = num2str(mysinglecoeff1(1,2));
            displaykT.String = num2str(mysinglecoeff1(1,1));
            displayB.String = num2str(mysinglecoeff1(1,3));
            displayI.String = num2str(mysinglecoeff1(1,4));
            
            x = data(:,2*specnum-1);
            x = interp1(x,x,min(x):0.001:max(x));
            simy = 1./(exp((x-mysinglecoeff1(1,2))/mysinglecoeff1(1,1))+1);
            [min84,index84] = min(abs(simy-0.84));
            [min16,index16] = min(abs(simy-0.16));
      
            x16 = x(1,index16);
            x84 = x(1,index84);    
            datagap=x16-x84;
            displaydelFermi.String = num2str(datagap);  
            simy2 = 1./(exp((x-mysinglecoeff1(1,2))/thermalE)+1);
            [min84,index842] = min(abs(simy2-0.84));
            [min16,index162] = min(abs(simy2-0.16));                  
            x162 = x(1,index162);
            x842 = x(1,index842);   
            intrinsicgap = x162-x842;
            displayintrinsic.String = num2str(intrinsicgap);
            
            instrumentalbroadening = sqrt(datagap^2-intrinsicgap^2);
            displayinstrumental.String = instrumentalbroadening;
            axes(axEf)
            plot(myglobalfit,data(:,2*specnum-1),data(:,2*specnum));
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            axis 'tight';
            hold on
            xline(x16,'b');
            xline(x84,'g');
            %legend('data','fitted curve','16','84');
            txt = {'16 and 84 for the fit';'The width value provided in the fitting results'};
            text(mysinglecoeff1(1,2)-0.5,mysinglecoeff1(1,4),txt);            
            text(min(data(:,2*specnum-1))+0.05,max(data(:,2*specnum)),rsqdisplay,'verticalAlignment', 'top');            
            
            hold off
            
            axes(resax)
            plot(data(:,2*specnum-1),(data(:,2*specnum)-y)/max(data(:,2*specnum)));
            xlabel ('KE(eV)');
            ylabel ('Relative Residuals/100');
            axis 'tight';
            fig = uifigure('Name','Correlation Coefficient Matrix');
            fig.Position(3:4) = [720 260];
            uit = uitable(fig,'Data',FitresultsTable,'Position',[10 10 700 230]);
        elseif gauss1flag ==1 && gauss2flag ==0 %One spectral feature is included in your data.
            kT = str2double(Fermifield.String);
            Ef = str2double(Fermifield2.String);
            Base = str2double(basefield.String);
            I = str2double(Fermifield3.String);
             V1A = str2double(gauss1field.String);
             V1C = str2double(gauss1field2.String);
             %V1L = str2double(gauss1field3.String);
             V1G = str2double(gauss1field4.String);     
             guesswhat1 = [kT,Ef,Base,data(1,2),V1A,V1C,V1G];
            myfitoptions1 = fitoptions('Method','NonlinearLeastSquares','Robust','LAR','Lower',[kT-0.0005,Ef-0.005,Base-BIVar,I-MPVar,V1A-G1AVar,V1C-G1CVar,V1G-G1WVar],'Upper',[kT+0.0005,Ef+0.005,Base+BIVar,I+MPVar,V1A+G1AVar,V1C+G1CVar,V1G+G1WVar],'StartPoint',guesswhat1);
            myfittype1 = fittype(@(a,b,c,d,e,f,h,x)(d./(exp((x-b)./a)+1)+c+(d./(exp((x-b)./a)+1)*(2/6.28*sqrt(4*0.69314/3.14)).*e.*exp(-4*0.69314.*((x-f)./h).^2)./h)),'independent',{'x'},'dependent',{'y'},'coefficients',{'a','b','c','d','e','f','h'},'options',myfitoptions1);%a,b,c,d are kT,Ef,Baseline,Intensity Multiplier for each.
%e,f,h are the Gaussian function's area, center and gaussian width
            [myglobalfit,gof,output] = fit(data(:,2*specnum-1),data(:,2*specnum),myfittype1,'StartPoint',guesswhat1);
            mysinglecoeff1 = coeffvalues(myglobalfit);
            J = output.Jacobian;
            N = output.numobs;
            p = output.numparam;
            R = output.residuals;
            MSE = (R'*R)/(N-p);
            CovB = inv(J'*J).*MSE;
            index = size(CovB);
            CorrelationCoefficients = ones(index(1,1),index(1,2));
            rsq = num2str(gof.rsquare);
            rsqdisplay = strcat('Rsq=',rsq);            
            InstructionVector = {'kT','Ef','Base','Multiplier','Area','Center','GaussianWidth'};
            for i=1:index(1,1)
                for j=1:index(1,1)
                    if i~=j
                        CorrelationCoefficients(i,j) = CovB(i,j)./sqrt(CovB(i,i)*CovB(j,j));
                    end
                end
            end
            FitresultsTable = table(CorrelationCoefficients(:,1),CorrelationCoefficients(:,2),CorrelationCoefficients(:,3),CorrelationCoefficients(:,4),CorrelationCoefficients(:,5),CorrelationCoefficients(:,6),CorrelationCoefficients(:,7),'VariableNames',InstructionVector,'RowNames',InstructionVector);
            y = feval(myglobalfit,data(:,2*specnum-1));
            displayEf.String = num2str(mysinglecoeff1(1,2));
            displaykT.String = num2str(mysinglecoeff1(1,1));
            displayB.String = num2str(mysinglecoeff1(1,3));
            displayI.String = num2str(mysinglecoeff1(1,4));
            displayC1.String = num2str(mysinglecoeff1(1,6));
            displayA1.String = num2str(mysinglecoeff1(1,5));
            displayG1.String = num2str(mysinglecoeff1(1,7));
            %displayL1.String = num2str(mysinglecoeff1(1,7));

            x = data(:,2*specnum-1);
            x = interp1(x,x,min(x):0.001:max(x));
            simy = 1./(exp((x-mysinglecoeff1(1,2))/mysinglecoeff1(1,1))+1);
            [min84,index84] = min(abs(simy-0.84));
            [min16,index16] = min(abs(simy-0.16));
            x16 = x(1,index16);
            x84 = x(1,index84);
            datagap=x16-x84;
            y16 = mysinglecoeff1(1,4)*0.16;
            y84 = mysinglecoeff1(1,4)*0.84;

           
            displaydelFermi.String = num2str(datagap);    
            simy2 = 1./(exp((x-mysinglecoeff1(1,2))/thermalE)+1);%This estimates the intrinsic thermal broadening of Fermi
            simyfermi = mysinglecoeff1(1,4)./(exp((x-mysinglecoeff1(1,2))/mysinglecoeff1(1,1))+1)+mysinglecoeff1(1,3);%simulated Fermi based on the fit results
            simygaussian = mysinglecoeff1(1,4)./(exp((x-mysinglecoeff1(1,2))./mysinglecoeff1(1,1))+1)*(2/6.28*sqrt(4*0.69314/3.14)).*mysinglecoeff1(1,5).*exp(-4*0.69314.*((x-mysinglecoeff1(1,6))./mysinglecoeff1(1,7)).^2)./mysinglecoeff1(1,7);
            
            [min84,index842] = min(abs(simy2-0.84));
            [min16,index162] = min(abs(simy2-0.16));                  
            x162 = x(1,index162);
            x842 = x(1,index842);   
            intrinsicgap = x162-x842;
            displayintrinsic.String = num2str(intrinsicgap);
            instrumentalbroadening = sqrt(datagap^2-intrinsicgap^2);
            displayinstrumental.String = instrumentalbroadening;
            
            axes(axEf)

            
            plot(myglobalfit,data(:,2*specnum-1),data(:,2*specnum));  
            axis 'tight';
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            hold on
            plot(transpose(x),transpose(simyfermi),'c',transpose(x),transpose(simygaussian),'c');
            legend('Data','Fit','Fermi','Fermi-Gaussian');
            hold off

%             xline(x16,'g');
%             xline(x84,'g');
%             yline(y16+mysinglecoeff1(1,3),'b');
%             yline(y84+mysinglecoeff1(1,3),'b');     
% 
%             txt = {'16 and 84 for the fit';'The gap value provided in the fitting results'};
%             text(mysinglecoeff1(1,2)-0.5,mysinglecoeff1(1,4),txt);      
            text(min(data(:,2*specnum-1))+0.05,max(data(:,2*specnum)),rsqdisplay,'verticalAlignment', 'top');
            
            axes(resax)
            plot(data(:,2*specnum-1),(data(:,2*specnum)-y)/max(data(:,2*specnum)));
            xlabel ('KE(eV)');
            ylabel ('Relative Residuals/100');
            axis 'tight';
            fig = uifigure('Name','Correlation Coefficient Matrix');
            fig.Position(3:4) = [720 340];
            uit = uitable(fig,'Data',FitresultsTable,'Position',[10 10 700 300]);
        elseif gauss1flag ==1 && gauss2flag ==1
            kT = str2double(Fermifield.String);
            Ef = str2double(Fermifield2.String);
            Base = str2double(basefield.String);
            I = str2double(Fermifield3.String);
             V1A = str2double(gauss1field.String);
             V1C = str2double(gauss1field2.String);
             %V1L = str2double(gauss1field3.String);
             V1G = str2double(gauss1field4.String);     
             V2A = str2double(gauss2field.String);
             V2C = str2double(gauss2field2.String);
             %V2L = str2double(gauss2field3.String);
             V2G = str2double(gauss2field4.String);                 
             guesswhat2 = [kT,Ef,Base,data(1,2),V1A,V1C,V1G,V2A,V2C,V2G];
            myfitoptions1 = fitoptions('Method','NonlinearLeastSquares','Robust','LAR','Lower',[kT-0.0005,Ef-0.005,Base-BIVar,I-MPVar,V1A-G1AVar,V1C-G1CVar,V1G-G1WVar,V2A-G2AVar,V2C-G2CVar,V2G-G2WVar],'Upper',[kT+0.0005,Ef+0.005,Base+BIVar,I+MPVar,V1A+G1AVar,V1C+G1CVar,V1G+G1WVar,V2A+G2AVar,V2C+G2CVar,V2G+G2WVar],'StartPoint',guesswhat2);
            myfittype1 = fittype(@(a,b,c,d,e,f,h,e2,f2,h2,x)(d./(exp((x-b)./a)+1)+c+(d./(exp((x-b)./a)+1)*(2/6.28*sqrt(4*0.69314/3.14)).*e.*exp(-4*0.69314.*((x-f)./h).^2)./h)+(d./(exp((x-b)./a)+1)*(2/6.28*sqrt(4*0.69314/3.14)).*e2.*exp(-4*0.69314.*((x-f2)./h2).^2)./h2)),'independent',{'x'},'dependent',{'y'},'coefficients',{'a','b','c','d','e','f','h','e2','f2','h2'},'options',myfitoptions1);%a,b,c,d are kT,Ef,Baseline,Intensity Multiplier, and gaussian standard dev for each.
%e,f,h are the Gaussian function's area, center, and
%gaussian width. So are e2,f2,h2.
            [myglobalfit,gof,output] = fit(data(:,2*specnum-1),data(:,2*specnum),myfittype1,'StartPoint',guesswhat2);
            mysinglecoeff1 = coeffvalues(myglobalfit);
            J = output.Jacobian;
            N = output.numobs;
            p = output.numparam;
            R = output.residuals;
            MSE = (R'*R)/(N-p);
            CovB = inv(J'*J).*MSE;
            index = size(CovB);
            CorrelationCoefficients = ones(index(1,1),index(1,2));
            rsq = num2str(gof.rsquare);
            rsqdisplay = strcat('Rsq=',rsq);
            InstructionVector = {'kT','Ef','Base','Multiplier','G1Area','G1Center','G1GaussianWidth','G2A','G2C','G2Width'};
            for i=1:index(1,1)
                for j=1:index(1,1)
                    if i~=j
                        CorrelationCoefficients(i,j) = CovB(i,j)./sqrt(CovB(i,i)*CovB(j,j));
                    end
                end
            end
            FitresultsTable = table(CorrelationCoefficients(:,1),CorrelationCoefficients(:,2),CorrelationCoefficients(:,3),CorrelationCoefficients(:,4),CorrelationCoefficients(:,5),CorrelationCoefficients(:,6),CorrelationCoefficients(:,7),CorrelationCoefficients(:,8),CorrelationCoefficients(:,9),CorrelationCoefficients(:,10),'VariableNames',InstructionVector,'RowNames',InstructionVector);      
            y = feval(myglobalfit,data(:,2*specnum-1));
            displayEf.String = num2str(mysinglecoeff1(1,2));
            displaykT.String = num2str(mysinglecoeff1(1,1));
            displayB.String = num2str(mysinglecoeff1(1,3));
            displayI.String = num2str(mysinglecoeff1(1,4));
            displayC1.String = num2str(mysinglecoeff1(1,6));
            displayA1.String = num2str(mysinglecoeff1(1,5));
            displayG1.String = num2str(mysinglecoeff1(1,7));
            %displayL1.String = num2str(mysinglecoeff1(1,7));
            displayC2.String = num2str(mysinglecoeff1(1,9));
            displayA2.String = num2str(mysinglecoeff1(1,8));
            displayG2.String = num2str(mysinglecoeff1(1,10));
            %displayL2.String = num2str(mysinglecoeff1(1,11));
            x = data(:,2*specnum-1);
            x = interp1(x,x,min(x):0.001:max(x));
            simy = 1./(exp((x-mysinglecoeff1(1,2))/mysinglecoeff1(1,1))+1);
            [min84,index84] = min(abs(simy-0.84));
            [min16,index16] = min(abs(simy-0.16));
            x16 = x(1,index16);
            x84 = x(1,index84);
            datagap=x16-x84;
            y16 = mysinglecoeff1(1,4)*0.16;
            y84 = mysinglecoeff1(1,4)*0.84;

           
            displaydelFermi.String = num2str(datagap);     
            simy2 = 1./(exp((x-mysinglecoeff1(1,2))/thermalE)+1);
            simyfermi = mysinglecoeff1(1,4)./(exp((x-mysinglecoeff1(1,2))/mysinglecoeff1(1,1))+1)+mysinglecoeff1(1,3);%simulated Fermi based on the fit results
            simygaussian = mysinglecoeff1(1,4)./(exp((x-mysinglecoeff1(1,2))./mysinglecoeff1(1,1))+1)*(2/6.28*sqrt(4*0.69314/3.14)).*mysinglecoeff1(1,5).*exp(-4*0.69314.*((x-mysinglecoeff1(1,6))./mysinglecoeff1(1,7)).^2)./mysinglecoeff1(1,7);
            simygaussian2 = mysinglecoeff1(1,4)./(exp((x-mysinglecoeff1(1,2))./mysinglecoeff1(1,1))+1)*(2/6.28*sqrt(4*0.69314/3.14)).*mysinglecoeff1(1,8).*exp(-4*0.69314.*((x-mysinglecoeff1(1,9))./mysinglecoeff1(1,10)).^2)./mysinglecoeff1(1,10);

            
            
            [min84,index842] = min(abs(simy2-0.84));
            [min16,index162] = min(abs(simy2-0.16));                  
            x162 = x(1,index162);
            x842 = x(1,index842);   
            intrinsicgap = x162-x842;
            displayintrinsic.String = num2str(intrinsicgap);     
            instrumentalbroadening = sqrt(datagap^2-intrinsicgap^2);
            displayinstrumental.String = instrumentalbroadening;            
            axes(axEf)
            plot(myglobalfit,data(:,2*specnum-1),data(:,2*specnum));
            
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            axis 'tight';
            hold on
            plot(x,simyfermi,x,simygaussian,x,simygaussian2);
            legend('Data','Fit','Fermi','F-G1','F-G2');
%             xline(x16,'r');
%             xline(x84,'r');
%             yline(y16+mysinglecoeff1(1,3),'b');
%             yline(y84+mysinglecoeff1(1,3),'b');            
%             
%             txt = {'16 and 84 for the fit';'The gap value provided in the fitting results'};
%             text(mysinglecoeff1(1,2)-0.5,mysinglecoeff1(1,4),txt);       
            text(min(data(:,2*specnum-1))+0.05,max(data(:,2*specnum)),rsqdisplay,'verticalAlignment', 'top');            
            hold off
            axes(resax)
            plot(data(:,2*specnum-1),(data(:,2*specnum)-y)/max(data(:,2*specnum)));
            xlabel ('Kinetic Energy(eV)');
            ylabel ('Relative Residuals/100');
            axis 'tight';
            fig = uifigure('Name','Correlation Coefficient Matrix');
            fig.Position(3:4) = [1024 440];
            uit = uitable(fig,'Data',FitresultsTable,'Position',[10 10 1000 350]);

        end
    end
    function Invert_Callback(~,~)
        Fermi = 1./(1+exp((data(:,2*specnum-1)-Ef)./kT));
        [row,column] = find(Ef+0.2<data(:,2*specnum-1));
        Fermi(row)=1;
        yFermi = (data(:,2*specnum)-min(data(:,2*specnum)))./Fermi;
        Diff = diff(data(:,2*specnum))./((data(2,2*specnum-1)-data(1,2*specnum-1))*10);
        Difield = zeros(length(Diff)+1,1);
        for i=1:length(Diff)
            Difield(i+1,1) = Diff(i,1);
        end
            axes(axEf)
            xlabel ('KE(eV)');
            ylabel ('Intensity');
            axis 'tight';        
            plot(data(:,2*specnum-1),yFermi,data(:,2*specnum-1),data(:,2*specnum),data(:,2*specnum-1),Difield);
            hold on
            yline(0);
            legend('Fermi Cutoff Inverted','Raw','First derivative');
            hold off
            
        
    end
end