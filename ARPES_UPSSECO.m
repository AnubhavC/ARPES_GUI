%DESCRIPTION
%This program was designed to analyze PES data to determine the work 
%function of the sample.  
 
%The data is fit with a smoothing spline function from which the inflection
%point is found. The secondary cut off is determined as the x-intercept of 
%a line drawn from the inflection point and having a slope equal to the derivative
%at the inflection point. The work function is then calculated from the 
%Fermi level,the secondary cut off, and the photon energy. 

%For the program to work and be accurate, it is necessary to take a scan of just the 
%secondary cutoff region of the spectrum AND you MUST input the correct 
%Fermi level (use the "UPSFermiFinder" script to find this). Again, the 
%script can analyze multipledata files at once.

%To use: copy file into data folder, change appropriate inputs (below), Run
function wf = ARPES_UPSSECO(data,fermi)

        
        %------------------------------  Script   -------------------------------

        %The following block will call the energy and intensity data from the 'filedata' 
        %cell aray, one file at a time, and perform the SECO finding algorithm. 
        %For performance validation, a plot of each dataset and fit can be generated.


            x=data(:,1);
            y=data(:,2);
            fit1=fit(x,y,'smoothingspline','smoothingparam',0.99999); %Fit the data 
            d1 = differentiate(fit1,x); 
            [Md1,Md1I]=max(d1(:)); %Identifies the index for the inflection point
            xMd1=x(Md1I);   %Identifies the x-value (from KE) inflection coordinate
            yMd1=y(Md1I);   %Identifies the y-value (from cts) inflection coordinate
            b=yMd1-Md1*xMd1; % solve the equation of a line for the y-intercept
            cutoff = -b/Md1;
            workfunction = 21.218-(fermi-cutoff);% workfunction is calculated from the photon energy and spectral width
            l1=Md1*x+b;
            workfxnlist=workfunction; % add calculated workfunction to this array

            %Performance evaluation plot
            figure('Position',[100 100 300 500])
            hold on
            plot(fit1,'r',x,y,'k') % plot the data and the fit
            axis([min(x) max(x) -0.2*max(y) max(y)+max(y)*0.2])
            grid on
            plot (x,l1,'bl', 'linewidth',1) % plot the cutoff line
        
        wf = workfxnlist;
end
