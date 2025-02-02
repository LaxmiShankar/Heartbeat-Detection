classdef Heartbeat_Detection_Code < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        File                         matlab.ui.container.Menu
        avginbeatssecEditField       matlab.ui.control.EditField
        avginbeatssecEditFieldLabel  matlab.ui.control.Label
        InitializeArduinoButton      matlab.ui.control.Button
        CollectSensorDataButton      matlab.ui.control.Button
        SaveSensorDataButton         matlab.ui.control.Button
        Lamp                         matlab.ui.control.Lamp
        MoveServoButton              matlab.ui.control.Button
        stopButton                   matlab.ui.control.Button
        ResetButton                  matlab.ui.control.Button
        LoadSensorDataButton         matlab.ui.control.Button
        findtheaverageheartrateofthisdataButton  matlab.ui.control.Button
        Image                        matlab.ui.control.Image
        waitatleast5secondsforinitializationtocompleteLabel  matlab.ui.control.Label
        Label                        matlab.ui.control.Label
        echopinEditField             matlab.ui.control.EditField
        echopinEditFieldLabel        matlab.ui.control.Label
        trigpinEditField             matlab.ui.control.EditField
        trigpinEditFieldLabel        matlab.ui.control.Label
        COMEditField                 matlab.ui.control.EditField
        COMEditFieldLabel            matlab.ui.control.Label
        UIAxes3                      matlab.ui.control.UIAxes
        UIAxes2                      matlab.ui.control.UIAxes
        UIAxes                       matlab.ui.control.UIAxes
    end


    properties (Access = private)
        a %creating arduino object
        Usensor %creating ultrasound sensor object
        Sservo %creating servo object
        stop %sets wether the stop button is pushed or not
        
        savex %collected x data
        savey %collected y data
        status %stores status of led
        tdistance %distance values array

        xFiltered %cleaned and filtered x data
        yFiltered %cleaned and filtered y data

    end
    
    methods (Access = private)
        
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: InitializeArduinoButton
        function InitializeArduinoButtonPushed(app, event)
            clc;clf;close all;%clearing everything
            clear app.a;clear app.ultrasonic;clear app.Sservo; clear COM; clear trigpin; clear echopin;
            %clearing any arduino objects that may be loaded from before
            
            if isempty(app.trigpinEditField.Value) && isempty(app.echopinEditField.Value) && isempty(app.COMEditField.Value) %if user does not input pins, set default pin to 7 & 6
                trigpin = 'D7';
                echopin = 'D6';
                COM = 'COM4';
            else %if user inputs pin, set pin to field value inputed
                trigpin = app.trigpinEditField.Value;
                echopin = app.echopinEditField.Value;
                COM = app.COMEditField.value;
            end
           
            app.a = arduino(COM, 'Uno', 'Libraries', {'Ultrasonic','Servo'}); %connecting port, creating arduino objects
            app.Usensor = ultrasonic(app.a, trigpin, echopin); 
            app.Sservo = servo(app.a,'D9');
            
            
          
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            cla(app.UIAxes, 'reset'); %Clears all plots
            cla(app.UIAxes2,'reset');
            cla(app.UIAxes3,'reset');
        end

        % Button pushed function: CollectSensorDataButton
        function CollectSensorDataButtonPushed(app, event)
           %function to collect real time ultrasonic data
            
            start= tic;% Set up the time measurement
            x = 0;
            y = 0;
          
            app.stop = true;
            %PLOTTING----------------------------------------------------------------------------------
            while  app.stop %if stop button is pushed, app.stop becomes false, breaking the loop. 
                %DATA COLLECTION
                app.tdistance = readDistance(app.Usensor);% Read distance from Ultrasonic Sensor
                Udistance = app.tdistance * 1000; %reading distance in mm
                %UPDATING PLOT
                elapsedTime = toc(start);
                x = [x, elapsedTime]; % concantenating the data
                y = [y, Udistance];
                %----------------------------------------------------------------------------------
         
                %REMOVING GAPS WHERE DATA IS INF
                ind = numel(y); %finding index
                if isinf(Udistance) && ind > 1 %&& (ind-1) <= numel(y)
                    app.status = 'bad'; %bad data collected
                    app.led();
                    indx = ind-1;
                    Udistance = y(indx); % set the inf value to previous value
                else
                    app.status = 'good';%good data collected
                    app.led(); %callback to led function to set led status
                end
                plot(app.UIAxes,x, y, 'k-*'); %plot data, black color and * symbol for data points       
                drawnow %plot lags without pause so using this
                %----------------------------------------------------------------------------------
            end
            

            app.savex = x; %saving to variables
            app.savey = y;
           

        end

        % Button pushed function: SaveSensorDataButton
        function SaveSensorDataButtonPushed(app, event)
% Save X data into a file        
        xvar = app.savex;
        yvar = app.savey;
        [filenameX, pathX] = uiputfile('XdataFinal.mat');
        save(fullfile(pathX, filenameX), 'xvar', '-mat');

% Save Y data into a file
        [filenameY, pathY] = uiputfile('YdataFinal.mat');
        save(fullfile(pathY, filenameY), 'yvar', '-mat');
      

        end

        % Button pushed function: LoadSensorDataButton
        function LoadSensorDataButtonPushed(app, event)
        %loads the data collected and runs it through filters to create a
        %smooth plot
          
            [filex] = uigetfile("XdataFinal.mat"); %gets file that has been saved by user
            [filey] = uigetfile("YdataFinal.mat");
            xdat=load(filex);
            ydat=load(filey);
            xdata = xdat.xvar; %accesses the variable from file
            ydet = ydat.yvar; 
            ydata = ydet;
            %finding outliers
            threshold = 7;%sensitivity to outliers
            outlierIndex = isoutlier(ydata,'median','ThresholdFactor', threshold);
            ydata(outlierIndex) = Inf; %removing outlier
            %fill in missing gaps
            indexinf = isinf(ydata); %data points that are infinity
            noninf = find(~indexinf); %data points that are non infinity
            ydata(indexinf) = interp1(noninf, ydata(noninf), find(indexinf), 'linear'); %interpolation to fill in missing gap
            %median filter
            ydata = medfilt1(ydata,4); %change value of median filter for smoother curve
            
            plot(app.UIAxes2,xdata,ydata);%plotting filtered data
            axis(app.UIAxes2, 'tight');
            plot(app.UIAxes,xdata,ydet); %plotting real data
           
            % %servo code
            % xservo = xdata;
            % yservo = ydata;
            % Xlength = length(xservo);
            % for i = 1:Xlength
            % inext = i+1;
            % if(inext<=Xlength)
            % Delayvalue = xservo(inext) - xservo(i); %the delay for the servo was the interval between each y value collected (delta x)
            % Yval = (yservo(inext) - yservo(i))/2;
            % siny = abs(sin(Yval)); %running y data through a sin function so that the value will always be between 0 and 1 for the servo to move
            % 
            % writePosition(app.Sservo,siny);
            % pause(Delayvalue)
            % end
            % end
            
           app.xFiltered = xdata; %saving the filtered data
           app.yFiltered = ydata;
            
        end

        % Button pushed function: stopButton
        function stopButtonPushed(app, event)
           %stops data collection
            app.stop = false;
            clear app.a;
            clear app.ultrasonic;
            clear app.Sservo;
        end

        % Close request function: UIFigure
        function led(app, event)
         %sets status of led depending on if data collected is good or bad
            switch app.status
                case 'good'
                    app.Label.Text = "GOOD";
                    app.Lamp.Color = [0,1,0];
                    writeDigitalPin(app.a, 'D4', 0); % Turn off LED connected to pin 4 (red)
                    writeDigitalPin(app.a, 'D5', 1); % Turn on LED connected to pin 5 (green)

                case 'bad'
                    app.Label.Text = "BAD";
                    app.Lamp.Color = [1,0,0];
                    writeDigitalPin(app.a, 'D5', 0); % Turn off LED connected to pin 5 (green)
                    writeDigitalPin(app.a, 'D4', 1); % Turn on LED connected to pin 4 (red)

            end
        end

        % Button pushed function: MoveServoButton
        function MoveServoButtonPushed(app, event)
            %if the user wants to move the servo with real time data, they
            %can press this button

            %collecting real time data: repeating code from other callback,
            %but it has to be repeated as servo gets moved within the loop.
            %Therefore, the code cannot be called as a function due to
            %efficiency issues

            start= tic;% Set up the time measurement
            xReal = 0;
            yReal = 0;
            interval_size = 4; %important!! the data is collected at a rate of 1/4th of a second. So 4 values = 1 second interval.
            start_index = 1;
            i = start_index;
             app.stop = true;
            %PLOTTING----------------------------------------------------------------------------------
            while  app.stop %if stop button is pushed, app.stop becomes false, breaking the loop. 
                %DATA COLLECTION
                app.tdistance = readDistance(app.Usensor);% Read distance from Ultrasonic Sensor
                Udistance = app.tdistance * 1000; %reading distance in mm
                %UPDATING PLOT
                elapsedTime = toc(start);
                xReal = [xReal, elapsedTime]; % concantenating the data
                yReal = [yReal, Udistance];

                   %alerting good and bad data
                ind = numel(yReal); %finding index
                if isinf(Udistance) && ind > 1 %&& (ind-1) <= numel(y)
                    app.status = 'bad'; %bad data collected
                    app.led();
                    indx = ind-1;
                    Udistance = yReal(indx); % set the inf value to previous value
                else
                    app.status = 'good';%good data collected
                    app.led();
                end
                plot(app.UIAxes,xReal, yReal, 'k-*'); %plot data, black color and * symbol for data points       
                drawnow %plot lags without pause so using this
                %----------------------------------------------------------------------------------


                %real time curve fitting!
                x = xReal; 
                y = yReal;

                %setting any inf values to the last y value for polynomial
                %fitting purposes
                lastNonInfValue = yReal(find(~isinf(yReal), 1, 'last'));
                y(isinf(yReal)) = lastNonInfValue;
                

                %if 4 values have been collected, aka 1 second of data is used, start the loop. 
                if length(xReal)>=4 
                %if the data has 4 values for the last interval, continue
                %the loop
                if mod(length(xReal), 4) == 0
                x_interval = x(start_index:interval_size);
                y_interval = y(start_index:interval_size);
                
                %polynomial fitting calculations
                while i < (length(x)-interval_size+1)
                    x_intervalPrevious = x_interval; 
                    y_intervalPrevious = y_interval;
                    x_interval = x(i:i+interval_size-1); 
                    y_interval = y(i:i+interval_size-1);
                     p = polyfit([x_intervalPrevious(end),x_interval], [y_intervalPrevious(end),y_interval], 2);
                     x_fit = linspace(x_intervalPrevious(end), x_interval(end), 1000); %0 to 3 %from 3 to 7///
                    y_fit = polyval(p, x_fit);
                    %using the polynomial curve to predict one data point
                    %ahead (aka 0.1 seconds ahead)
                    x_fitPredicted = linspace(x_interval(end),x_interval(end)+1,1000);
                    y_fitPredicted = polyval(p, x_fitPredicted);
                        

                      Yval = y_fitPredicted(4);
                      %servo cannot move if the value is infinity, so
                      %setting it to 1 
if Yval == inf || Yval == -inf || isnan(Yval)
Yval = 1;
end
%modifying data so it is always between 0 and 1
                            siny = abs(sin(Yval)); 
                            writePosition(app.Sservo,siny); %writing to servo
                            i = i+interval_size; %updating index
                            plot(app.UIAxes3,x_fitPredicted, y_fitPredicted, 'r-*')
                            drawnow
                            pause(1); %delaying 1 second so that the servo can move, and then resuming collecting the data
end
end
             end
            end
            

            
        end

        % Button pushed function: findtheaverageheartrateofthisdataButton
        function findtheaverageheartrateofthisdataButtonPushed(app, event)
           
            
            
           ydata = (app.yFiltered) - 100;
           xdata = (app.xFiltered);
           plot(xdata,ydata);
            
           
          [XinputAA,YinputAA] = ginput(2); %find approx value on curve
          %XinputAA = 7.9880;
          %YinputAA = 31.379;
           % Find the closest point on the curve
           [~, indexclose] = min((xdata - XinputAA(1)).^2 + (ydata - YinputAA(1)).^2); %euclidean method
           XinputA = xdata(indexclose); YinputA = ydata(indexclose);
           peak1 = YinputA; %value that user picked
          % Define a tolerance level
          tolerance = 0.1;
          % Xinput, Xinput(n-1)
          index = find(abs(xdata - XinputA) < tolerance, 1);
          XinputB = xdata(index+2);
          YinputB = ydata(index+2);
          error = 1;
          while error>=0.05
          Xinput1= XinputA;
          Xinput2 = XinputB;
          Yinput1 = YinputA;
          Yinput2 = YinputB;
          XinputNew = XinputA - ((YinputA*(XinputA - XinputB))/(YinputA-YinputB));
          differences = abs(xdata - XinputNew);
      
       %Find the index of the minimum difference
           [~, indexNew] = min(differences);
              YinputNew = ydata(indexNew);
          XinputB = XinputA;
          XinputA = XinputNew;
          YinputB = YinputA;
          YinputA = YinputNew;
          error = abs(((XinputNew-Xinput1) / XinputNew));
          end
           %----------------------------------------------------------------------------doing
           %it a second time 

           [~, indexclose1] = min((xdata - XinputAA(2)).^2 + (ydata - YinputAA(2)).^2); %euclidean method
           XinputA1 = xdata(indexclose1); YinputA1 = ydata(indexclose1);
           peak2 = YinputA1; %second peak value chosen by user
          % Define a tolerance level
          tolerance1 = 0.1;
          % Xinput, Xinput(n-1)
          index1 = find(abs(xdata - XinputA1) < tolerance1, 1);
          XinputB1 = xdata(index1+2);
          YinputB1 = ydata(index1+2);
          error1 = 1;
          while error1>=0.05
          Xinput11= XinputA1;
          Xinput21 = XinputB1;
          Yinput11 = YinputA1;
          Yinput21 = YinputB1;
          XinputNew1 = XinputA1 - ((YinputA1*(XinputA1 - XinputB1))/(YinputA1-YinputB1));
          differences1 = abs(xdata - XinputNew1);
      
          %Find the index of the minimum difference
          [~, indexNew1] = min(differences1);
          YinputNew1 = ydata(indexNew1);
          XinputB1 = XinputA1;
          XinputA1 = XinputNew1;
          YinputB1 = YinputA1;
          YinputA1 = YinputNew1;
          error1 = abs(((XinputNew1-Xinput11) / XinputNew1));
          end
        
          
            %XinputNew = x closest to 0, XinputNew1 is second x closest to
            %the 0
           
           %newtons method
           XNwtinput1=Xinput1 ;
XNwtinput2 = XinputNew;
YNwtinput1 = Yinput1;
YNwtinput2 = YinputNew;
XNwtdif12 = XinputNew-Xinput1;
YNwtdif12 = YinputNew-Yinput1;
Slope12 = YNwtdif12/XNwtdif12;
XNwt1 = ((0-YNwtinput1)/Slope12) + XNwtinput1;
%% Line: f(x) = YNwtinput1 + Slope12(XNwt1 - XNwtinput1)


%second time
 XNwtinput12= Xinput11;
XNwtinput22 = XinputNew1;
YNwtinput12 = Yinput11;
YNwtinput22 = YinputNew1;
XNwtdif122 = XinputNew1-Xinput11;
YNwtdif122 = YinputNew1-Yinput11;
Slope122 = YNwtdif122/XNwtdif122;
XNwt12 = ((0-YNwtinput12)/Slope122) + XNwtinput12;
%% Line: f(x) = YNwtinput1 + Slope12(XNwt1 - XNwtinput1)


   average = abs(((peak2-peak1)/(XNwt12-XNwt1)));
     
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.6196 0.7333 0.902];
            app.UIFigure.Position = [100 100 1064 649];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @led, true);

            % Create File
            app.File = uimenu(app.UIFigure);
            app.File.Text = 'File';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, {'Ultrasound Sensor'; 'Distance vs Time'})
            xlabel(app.UIAxes, 'Time(seconds)')
            ylabel(app.UIAxes, 'Distance(mm)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontName = 'Comic Sans MS';
            app.UIAxes.Position = [196 403 448 191];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Cleaned Plot')
            xlabel(app.UIAxes2, 'Time')
            ylabel(app.UIAxes2, 'Distance')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.FontName = 'Comic Sans MS';
            app.UIAxes2.Position = [213 60 448 185];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'Ultrasound Sensor - Predicted Values/Curve Fitting')
            xlabel(app.UIAxes3, 'Time(seconds)')
            ylabel(app.UIAxes3, 'Distance(mm)')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.Position = [659 403 384 157];

            % Create COMEditFieldLabel
            app.COMEditFieldLabel = uilabel(app.UIFigure);
            app.COMEditFieldLabel.HorizontalAlignment = 'right';
            app.COMEditFieldLabel.Position = [35 538 33 22];
            app.COMEditFieldLabel.Text = 'COM';

            % Create COMEditField
            app.COMEditField = uieditfield(app.UIFigure, 'text');
            app.COMEditField.Position = [91 538 35 22];

            % Create trigpinEditFieldLabel
            app.trigpinEditFieldLabel = uilabel(app.UIFigure);
            app.trigpinEditFieldLabel.HorizontalAlignment = 'right';
            app.trigpinEditFieldLabel.Position = [35 507 41 22];
            app.trigpinEditFieldLabel.Text = 'trig pin';

            % Create trigpinEditField
            app.trigpinEditField = uieditfield(app.UIFigure, 'text');
            app.trigpinEditField.Position = [91 507 35 22];

            % Create echopinEditFieldLabel
            app.echopinEditFieldLabel = uilabel(app.UIFigure);
            app.echopinEditFieldLabel.HorizontalAlignment = 'right';
            app.echopinEditFieldLabel.Position = [35 475 50 22];
            app.echopinEditFieldLabel.Text = 'echo pin';

            % Create echopinEditField
            app.echopinEditField = uieditfield(app.UIFigure, 'text');
            app.echopinEditField.Position = [91 475 35 22];

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.Position = [84 392 48 28];
            app.Label.Text = '';

            % Create waitatleast5secondsforinitializationtocompleteLabel
            app.waitatleast5secondsforinitializationtocompleteLabel = uilabel(app.UIFigure);
            app.waitatleast5secondsforinitializationtocompleteLabel.FontSize = 8;
            app.waitatleast5secondsforinitializationtocompleteLabel.FontWeight = 'bold';
            app.waitatleast5secondsforinitializationtocompleteLabel.Position = [29 593 209 18];
            app.waitatleast5secondsforinitializationtocompleteLabel.Text = '*wait at least 5 seconds for initialization to complete';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [713 60 100 100];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'download.jpg');

            % Create findtheaverageheartrateofthisdataButton
            app.findtheaverageheartrateofthisdataButton = uibutton(app.UIFigure, 'push');
            app.findtheaverageheartrateofthisdataButton.ButtonPushedFcn = createCallbackFcn(app, @findtheaverageheartrateofthisdataButtonPushed, true);
            app.findtheaverageheartrateofthisdataButton.Position = [674 207 219 23];
            app.findtheaverageheartrateofthisdataButton.Text = 'find the average heart rate of this data';

            % Create LoadSensorDataButton
            app.LoadSensorDataButton = uibutton(app.UIFigure, 'push');
            app.LoadSensorDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadSensorDataButtonPushed, true);
            app.LoadSensorDataButton.BackgroundColor = [0.4196 0.4706 0.9882];
            app.LoadSensorDataButton.FontColor = [1 1 1];
            app.LoadSensorDataButton.Position = [371 283 133 23];
            app.LoadSensorDataButton.Text = 'Load Sensor Data';

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.BackgroundColor = [0.4941 0.749 0.3451];
            app.ResetButton.FontColor = [1 1 1];
            app.ResetButton.Position = [911 67 100 22];
            app.ResetButton.Text = 'Reset';

            % Create stopButton
            app.stopButton = uibutton(app.UIFigure, 'push');
            app.stopButton.ButtonPushedFcn = createCallbackFcn(app, @stopButtonPushed, true);
            app.stopButton.BackgroundColor = [1 0.651 0.651];
            app.stopButton.FontColor = [1 1 1];
            app.stopButton.Position = [912 115 100 23];
            app.stopButton.Text = 'stop';

            % Create MoveServoButton
            app.MoveServoButton = uibutton(app.UIFigure, 'push');
            app.MoveServoButton.ButtonPushedFcn = createCallbackFcn(app, @MoveServoButtonPushed, true);
            app.MoveServoButton.Position = [783 331 137 43];
            app.MoveServoButton.Text = 'Move Servo';

            % Create Lamp
            app.Lamp = uilamp(app.UIFigure);
            app.Lamp.Position = [34 384 36 36];

            % Create SaveSensorDataButton
            app.SaveSensorDataButton = uibutton(app.UIFigure, 'push');
            app.SaveSensorDataButton.ButtonPushedFcn = createCallbackFcn(app, @SaveSensorDataButtonPushed, true);
            app.SaveSensorDataButton.BackgroundColor = [0.4196 0.4706 0.9882];
            app.SaveSensorDataButton.FontColor = [1 1 1];
            app.SaveSensorDataButton.Position = [29 331 133 23];
            app.SaveSensorDataButton.Text = 'Save Sensor Data';

            % Create CollectSensorDataButton
            app.CollectSensorDataButton = uibutton(app.UIFigure, 'push');
            app.CollectSensorDataButton.ButtonPushedFcn = createCallbackFcn(app, @CollectSensorDataButtonPushed, true);
            app.CollectSensorDataButton.BackgroundColor = [0.4196 0.4706 0.9882];
            app.CollectSensorDataButton.FontColor = [1 1 1];
            app.CollectSensorDataButton.Position = [29 438 133 23];
            app.CollectSensorDataButton.Text = 'Collect Sensor Data';

            % Create InitializeArduinoButton
            app.InitializeArduinoButton = uibutton(app.UIFigure, 'push');
            app.InitializeArduinoButton.ButtonPushedFcn = createCallbackFcn(app, @InitializeArduinoButtonPushed, true);
            app.InitializeArduinoButton.BackgroundColor = [0.4196 0.4706 0.9882];
            app.InitializeArduinoButton.FontColor = [1 1 1];
            app.InitializeArduinoButton.Position = [29 577 103 22];
            app.InitializeArduinoButton.Text = 'Initialize Arduino';

            % Create avginbeatssecEditFieldLabel
            app.avginbeatssecEditFieldLabel = uilabel(app.UIFigure);
            app.avginbeatssecEditFieldLabel.HorizontalAlignment = 'right';
            app.avginbeatssecEditFieldLabel.Position = [675 181 92 22];
            app.avginbeatssecEditFieldLabel.Text = 'avg in beats/sec';

            % Create avginbeatssecEditField
            app.avginbeatssecEditField = uieditfield(app.UIFigure, 'text');
            app.avginbeatssecEditField.Position = [780 181 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Heartbeat_Detection_Code

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end