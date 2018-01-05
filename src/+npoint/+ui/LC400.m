classdef LC400 < mic.Base
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        cName = 'Test'

    end
    
    properties (Access = private)
        
        
        lDeviceIsSet
        
        % {uint8 24x24} - images for the device real/virtual toggle
        u8ToggleOn = imread(fullfile(mic.Utils.pathImg(), 'toggle', 'horiz-1', 'toggle-horiz-24-true.png'));     
        u8ToggleOff = imread(fullfile(mic.Utils.pathImg(), 'toggle', 'horiz-1', 'toggle-horiz-24-false-yellow.png'));           
        
        hAxes2D
        hAxes2DSim
        hAxes1D
        
        
        dWidth = 1010
        dHeight = 270
        
        dWidthPanelAxes = 610
        dHeightPanelAxes = 250
        dWidthAxes1D = 325
        dHeightAxes = 190
        
        dWidthPanelWavetable = 350
        dHeightPanelWavetable = 135
        
        dWidthPanelMotion = 350
        dHeightPanelMotion = 135
        
        dWidthButton = 110
        dHeightButton = 24
        dWidthEdit = 80
                
        hPanel
        hPanelWavetable
        hPanelMotion
        hPanelAxes
        
        % {function_handle 1x1} function called when user clicks write
        % @return [i32X, i32Y] wavetable values in [-2^20/2, +2^20/2] 
        fhGet20BitWaveforms
        
        cLabelWrite = 'Write'
        cLabelRead = 'Read & Plot'
        cLabelRecord = 'Record & Plot'
        
        uiButtonWrite
        uiButtonRead
        uiEditTimeRead
        
        uiToggleDevice
        uiTextLabelDevice
        lAskOnDeviceClick = true
        
        uiGetSetLogicalActive % Motion Start / Stop
        uiButtonRecord
        uiEditTimeRecord
        
        % {< noint.AbstractLC400 1x1}
        device = []
        
        % {< noint.AbstractLC400 1x1}
        deviceVirtual
        
        % {mic.Clock 1x1} clock - the clock
        clock
        
        
        
        % {double 1xm} storage for normalized wavetable values in [-1 1]
        dAmpCh1
        dAmpCh2
        dTime
        
        % {double 1x1} storage for normalized recorded sensor/command
        % values in [-1 1]
        dAmpRecordCommandCh1
        dAmpRecordCommandCh2
        dAmpRecordSensorCh1
        dAmpRecordSensorCh2
        dTimeRecord

        
    end
    
    
    properties (SetAccess = private)
        
    end
    
    
    methods
        
        function this = LC400(varargin)
            
            
            % Apply varargin
            
            for k = 1 : 2: length(varargin)
                % this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}), 3);
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
                        
            this.init();
            
        end
        
        
        function st = save(this)
            st = struct();
        end
        
        function load(this, st)
            % nothing
        end
        
        function delete(this)
            
            this.msg('delete', this.u8_MSG_TYPE_CLASS_INIT_DELETE);
            this.save();
            
            delete(this.uiButtonWrite)
            delete(this.uiButtonRead)
            delete(this.uiEditTimeRead)
        
            delete(this.uiToggleDevice)
            delete(this.uiTextLabelDevice)
            
            delete(this.uiGetSetLogicalActive) % Motion Start / Stop
            delete(this.uiButtonRecord)
            delete(this.uiEditTimeRecord)
            
        end
        
        % @param {< noint.AbstractLC400 1x1 or []} device
        
        function setDevice(this, device)
            
            if isempty(device)
                this.uiToggleDevice.disable();
                this.device = device;
                return;
            end
            
            if this.isDevice(device)
                this.device = device;
                this.uiToggleDevice.enable();
                
                % Connect the mic.ui.device.GetSetLogical to a device
                device = npoint.device.GetSetLogicalFromLLC400(this.device, 'active');
                this.uiGetSetLogicalActive.setDevice(device);
                                
            end
        end
        
        % @param {< noint.AbstractLC400 1x1} device
        function setDeviceVirtual(this, device)
            if ~isempty(this.deviceVirtual) && ...
                isvalid(this.deviceVirtual)
                delete(this.deviceVirtual);
            end
            
            if this.isDevice(device)
                this.deviceVirtual = device;
            end
            
        end
        
        function turnOn(this)
        
            if isempty(this.device)
                % show message
                
                cMsg = 'Cannot turn on mic.ui.device.* instances until a device that implements mic.interface.device.* has been provided with setDevice()';
                cTitle = 'turnOn() Error';
                msgbox(cMsg, cTitle, 'warn');
                
                this.uiToggleDevice.set(false);
                this.uiToggleDevice.setTooltip(this.cTooltipDeviceOff);
            
                return
            end
            
            this.uiToggleDevice.set(true);
            % this.uiToggleDevice.setTooltip(this.cTooltipDeviceOn);
            this.uiGetSetLogicalActive.turnOn();

            % notify(this, 'eTurnOn');
            
        end
        
        
        function turnOff(this)
        
            if isempty(this.deviceVirtual)
                this.setDeviceVirtual(this.newDeviceVirtual());
            end
            
            this.uiToggleDevice.set(false);
            % this.uiToggleDevice.setTooltip(this.cTooltipDeviceOff);
            
            this.uiGetSetLogicalActive.turnOff();
            % notify(this, 'eTurnOff');
        end
        
        function build(this, hParent, dLeft, dTop)
                    
            this.hPanel = uipanel( ...
                'Parent', hParent, ...
                'Units', 'pixels', ...
                'Title', sprintf('nPoint LC400 Control (%s)', this.cName), ...
                'Clipping', 'on', ...
                ...%'BackgroundColor', [200 200 200]./255, ...
                ...%'BorderType', 'none', ...
                ... % 'BorderWidth',0, ... 
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidth this.dHeight], hParent)...
            );
            drawnow;
            
            this.buildUiToggleDevice();
            this.buildPanelWavetable();
            this.buildPanelMotion();
            this.buildPanelAxes();
            
            
        end
        
        
    end
    
    
    methods (Access = private)
        
        function plotRecorded2D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes2D) 
                return
            end
            
            cla(this.hAxes2D)
            hold(this.hAxes2D, 'on');

            plot(...
                this.hAxes2D, ...
                this.dAmpRecordCommandCh1, this.dAmpRecordCommandCh2, 'b', ...
                'LineWidth', 2 ...
            );
            plot(...
                this.hAxes2D, ...
                this.dAmpRecordSensorCh1, this.dAmpRecordSensorCh2, 'b' ...
            );
            axis(this.hAxes2D, 'image')
            xlim(this.hAxes2D, [-1 1])
            ylim(this.hAxes2D, [-1 1])
            title(this.hAxes2D, 'x(t) vs. y(t)')
            hold(this.hAxes2D, 'off')
                            
        end
        
        function plotDefault(this)
            this.plotDefault1D()
            this.plotDefault2D()
        end
        
        function plotDefault2D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes2D) 
                return
            end
            
            xlim(this.hAxes2D, [-1 1])
            ylim(this.hAxes2D, [-1 1])
            title(this.hAxes2D, 'x(t) vs. y(t)')
            
        end
        
        
        function plotDefault1D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes1D) 
                return
            end
            
            xlabel(this.hAxes1D, 'Time [ms]')
            ylabel(this.hAxes1D, 'Amplitude')
            title(this.hAxes1D, 'wavetable x(t) and y(t)');
            
        end
        
        
        function plotRecorded(this)
            
            % set(this.hPanelAxes, 'Title', 'Recorded. Left: x(t), y(t). Right: x(t) vs. y(t)');
            this.plotRecorded1D()
            this.plotRecorded2D()
        end
        
        function plotRecorded1D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes1D)
                return 
            end
            
            cla(this.hAxes1D)
            hold(this.hAxes1D, 'on')
            plot(...
                this.hAxes1D, ...
                this.dTimeRecord * 1000, this.dAmpRecordCommandCh1, 'r', ...
                this.dTimeRecord * 1000, this.dAmpRecordCommandCh2, 'b', ...
                'LineWidth', 2 ...
            );
            plot(...
                this.hAxes1D, ...
                this.dTimeRecord * 1000, this.dAmpRecordSensorCh1, 'r', ...
                this.dTimeRecord * 1000, this.dAmpRecordSensorCh2, 'b', ...
                'LineWidth', 1 ...
            );
            hold(this.hAxes1D, 'off')

            xlabel(this.hAxes1D, 'Time [ms]')
            ylabel(this.hAxes1D, 'Amplitude')
            title(this.hAxes1D, 'recorded x(t) and y(t)');
            legend(this.hAxes1D, 'ch1 (x) command','ch2 (y) command', 'ch1 (x) sensor', 'ch2 (y) sensor');
            xlim(this.hAxes1D, [0 max(this.dTimeRecord * 1000)])
            ylim(this.hAxes1D, [-1 1])
            
        end
        
        function plotWavetable2D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes2D)
               return
            end
            
            cla(this.hAxes2D)
            plot(...
                this.hAxes2D, ...
                this.dAmpCh1, this.dAmpCh2, 'b' ...
            );
            
            axis(this.hAxes2D, 'image')
            xlim(this.hAxes2D, [-1 1])
            ylim(this.hAxes2D, [-1 1])
            title(this.hAxes2D, 'x(t) vs. y(t)')
            
        end
 
        function plotWavetable1D(this)
            
            if ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes1D)
                return
            end
            
            cla(this.hAxes1D)
            plot(...
                this.hAxes1D, ...
                this.dTime * 1000, this.dAmpCh1, 'r', ...
                this.dTime * 1000, this.dAmpCh2, 'b' ...
            );
            xlabel(this.hAxes1D, 'Time [ms]')
            ylabel(this.hAxes1D, 'Amplitude')
            title(this.hAxes1D, 'wavetable x(t) and y(t)');
            legend(this.hAxes1D, 'ch1 (x)','ch2 (y)')
            xlim(this.hAxes1D, [0 max(this.dTime * 1000)])
            ylim(this.hAxes1D, [-1 1])
            
        end
        
        
        function plotWavetable(this)
            
            % set(this.hPanelAxes, 'Title', 'Wavetable. Left: x(t), y(t), Right: x(t) vs. y(t)');
            
            this.plotWavetable1D()
            this.plotWavetable2D()
            
        end
        
        
        function onWrite(this, src, evt)
                                    
            [i32Ch1, i32Ch2] = this.fhGet20BitWaveforms();
            
            % Prepare UI for writing state
            this.uiButtonWrite.setText('Writing ...');
            
            % Stop motion
            this.uiGetSetLogicalActive.set(false);
            
            this.uiCommPrep();
            
            % Write data
            this.getDevice().setWavetable(uint8(1), i32Ch1');
            this.getDevice().setWavetable(uint8(2), i32Ch2');
            
            this.uiCommPrepUndo();
             
            this.uiButtonWrite.setText(this.cLabelWrite)
            drawnow;
            
            h = msgbox( ...
                'The waveform has been written.  Click "Start Scan" to start.', ...
                'Success!', ...
                'help', ...
                'modal' ...
            );            
        end
        
        
        
        
        function uiCommPrep(this)
            
            % If the mic.ui.device.GetSetLogical is polling
            % real hardware, turn it off (make it talk to virtual) while
            % reading so it doesn't interrupt
            
            if (this.uiToggleDevice.get())
                lVal = this.uiGetSetLogicalActive.get();
                this.uiGetSetLogicalActive.turnOff();
                this.uiGetSetLogicalActive.set(lVal); % so it shows "real" value when in virtual mode
            end
              
            % Disable 
            this.uiGetSetLogicalActive.disable();
            this.uiButtonRecord.disable();
            this.uiButtonWrite.disable();
            drawnow;
            
            
            
        end
        
        function uiCommPrepUndo(this)
            
            % Re-enable
            if (this.uiToggleDevice.get())
                this.uiGetSetLogicalActive.turnOn()
            end
            this.uiGetSetLogicalActive.enable();
            this.uiButtonRecord.enable();
            this.uiButtonWrite.enable();
            
            
        end
        
        function onUiToggleDeviceChange(this, src, evt)
            if src.get()
                this.turnOn();
            else
                this.turnOff();
            end
        end
        
        function onRead(this, src, evt)
                                    
            u32Samples = uint32(this.uiEditTimeRead.get() / 2000 * 83333);
            
            cLabel = sprintf('Reading %u ...', u32Samples);
            this.uiButtonRead.setText(cLabel);
                                   
            this.uiCommPrep()
            d = this.getDevice().getWavetables(u32Samples);
            this.uiCommPrepUndo()
            
            this.uiButtonRead.setText(this.cLabelRead);
            drawnow;

           
            
            this.dAmpCh1 = d(1, :) / 2^19;
            this.dAmpCh2 = d(2, :) / 2^19;
            this.dTime = 24e-6 * double(1 : u32Samples);
            this.plotWavetable();
            
        end
        
        
        function onRecord(this, src, evt)
                 
            
            u32Samples = uint32(this.uiEditTimeRecord.get() / 2000 * 83333);
            
            % Prepare UI for "record" state
            cMsg = sprintf('Rec. %u ...', u32Samples);
            this.uiButtonRecord.setText(cMsg);
            
            this.uiCommPrep();
            dResult = this.getDevice().record(u32Samples);
            this.uiCommPrepUndo();
            
            % Revert UI back to normal after recording done
            this.uiButtonRecord.setText(this.cLabelRecord);
            
            % Unpack
            
            dClockPeriod = 24e-6;
            dTime = double(1 : u32Samples) * dClockPeriod;
            
            this.dAmpRecordCommandCh1 = dResult(1, :);
            this.dAmpRecordSensorCh1 = dResult(2, :);
            this.dAmpRecordCommandCh2 = dResult(3, :);
            this.dAmpRecordSensorCh2 = dResult(4, :);
            this.dTimeRecord = dTime;
                
            this.plotRecorded();
            
        end
                
        function initPanelWavetable(this)
            
            this.uiButtonWrite = mic.ui.common.Button(...
                'cText', this.cLabelWrite, ...
                'fhOnClick', @this.onWrite ...
            );
        
           
        
            this.uiButtonRead = mic.ui.common.Button(...
                'cText', this.cLabelRead, ...
                'fhOnClick', @this.onRead ...
            );
            
            this.uiEditTimeRead = mic.ui.common.Edit(...
                'cLabel', 'Read Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', true);
            
            this.uiButtonWrite.setTooltip('Write the waveform data to the LC400 controller.  This can take several seconds');
            this.uiButtonRead.setTooltip('Read the LC400 wavetables (from memory) and plot');
            this.uiEditTimeRead.setTooltip('The time window for read  commands');

            
            % Default values
            this.uiEditTimeRead.setMax(2000);
            this.uiEditTimeRead.setMin(0);
            this.uiEditTimeRead.set(300);
        
        end
        
        function initPanelMotion(this)
            
            this.uiButtonRecord = mic.ui.common.Button(...
                'cText', this.cLabelRecord, ...
                'fhOnClick', @this.onRecord ...
            );
        
            this.uiEditTimeRecord = mic.ui.common.Edit(...
                'cLabel', 'Record Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', true);
            
            
            this.uiButtonRecord.setTooltip('Record the commanded + servo values and plot');
            this.uiEditTimeRecord.setTooltip('The time window for recording');            
            
            % Default values
            this.uiEditTimeRecord.setMax(2000);
            this.uiEditTimeRecord.setMin(0);
            this.uiEditTimeRecord.set(300);
            
            
            % Configure the mic.ui.common.Toggle instance
            ceVararginCommandToggle = {...
                'cTextTrue', 'Stop', ...
                'cTextFalse', 'Start' ...
            };

            % Store the delay for how often it calls get()
            config = mic.config.GetSetLogical();
            
            this.uiGetSetLogicalActive = mic.ui.device.GetSetLogical(...
                'clock', this.clock, ...
                'config', config, ...
                'ceVararginCommandToggle', ceVararginCommandToggle, ...
                'lShowInitButton', false, ...
                'lShowDevice', false, ...
                'lShowName', false, ...
                'cName', sprintf('npoint-lc400-ui-%s', this.cName), ...
                'dWidthName', 50, ...
                'dWidthCommand', this.dWidthButton - 24, ...
                'lShowLabels', false, ...
                'cLabel', 'Scanning:'...
            );
            
        end
        
        
        function init(this)
            
            this.setDeviceVirtual(this.newDeviceVirtual());
            this.initUiToggleDevice();
            this.initPanelWavetable();
            this.initPanelMotion();
        
        end
        
        function initUiToggleDevice(this)
            
            
            
            this.uiTextLabelDevice = mic.ui.common.Text(...
                'cVal', 'Api', ...
                'cAlign', 'center'...
            );
        
            st1 = struct();
            st1.lAsk        = this.lAskOnDeviceClick;
            st1.cTitle      = 'Switch?';
            st1.cQuestion   = 'Do you want to change from the virtual LC400 to the real LC400?';
            st1.cAnswer1    = 'Yes of course!';
            st1.cAnswer2    = 'No not yet.';
            st1.cDefault    = st1.cAnswer2;


            st2 = struct();
            st2.lAsk        = this.lAskOnDeviceClick;
            st2.cTitle      = 'Switch?';
            st2.cQuestion   = 'Do you want to change from the real LC400 to the virtual LC400?';
            st2.cAnswer1    = 'Yes of course!';
            st2.cAnswer2    = 'No not yet.';
            st2.cDefault    = st2.cAnswer2;

            this.uiToggleDevice = mic.ui.common.Toggle( ...
                'cTextFalse', 'enable', ...   
                'cTextTrue', 'disable', ...  
                'lImg', true, ...
                'u8ImgOff', this.u8ToggleOff, ...
                'u8ImgOn', this.u8ToggleOn, ...
                'stF2TOptions', st1, ...
                'stT2FOptions', st2 ...
            );
        
            this.uiToggleDevice.disable();
            addlistener(this.uiToggleDevice,   'eChange', @this.onUiToggleDeviceChange);
            
        end
        
        
        function buildPanelAxes(this)
            
            if ~ishandle(this.hPanel)
                return
            end
            
            dTop = 20;
            dLeft = 400;
            
            %dLeft = 0
            %dTop = 150
            
            this.hPanelAxes = uipanel(...
                'Parent', this.hPanel,...
                'Units', 'pixels',...
                ...%'Title', 'Plot',...
                'Title', blanks(0), ...
                'Clipping', 'on',...
                'BackgroundColor', [1 1 1], ...
                ... %'BackgroundColor', [100 100 100]./255, ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelAxes this.dHeightPanelAxes], this.hPanel) ...
            );
            drawnow;        
            
            dLeft = 50;
            dTop = 20;
            dSep = 30;
            
            this.hAxes1D = axes(...
                'Parent', this.hPanelAxes,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dLeft dTop this.dWidthAxes1D this.dHeightAxes], this.hPanelAxes),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'HandleVisibility','on'...
                );
            dLeft = dLeft + this.dWidthAxes1D + dSep;
            
            % Needs to be square
            this.hAxes2D = axes(...
                'Parent', this.hPanelAxes,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dLeft dTop this.dHeightAxes this.dHeightAxes], this.hPanelAxes),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
                );
            
            dLeft = dLeft + this.dHeightAxes + dSep;
            this.plotDefault();
            
        end
        
        
        function l = isActive(this)
            l = this.uiToggleDevice.get();
        end
        
        function device = getDevice(this)
            if this.uiToggleDevice.get()
                device = this.device;
            else
                device = this.deviceVirtual;
            end 
        end
                
        % @param {x 1x1} device - the value to check
        % @return {logical 1x1} 
        function l = isDevice(this, device)
            
            if ~isa(device, 'npoint.AbstractLC400')
                cMsg = '"npoint.ui.LC400" UI controls require devices that implement the "npoint.AbstractLC400" interface.';
                cTitle = 'Device error';
                msgbox(cMsg, cTitle, 'warn');
                l = false;
                return
            end
                            
            l = true;
            
        end
        
        function buildUiToggleDevice(this)
            
            dLeft = 10;
            dTop = 20;
            
            this.uiTextLabelDevice.build(this.hPanel, dLeft, dTop, 24, 24);
            this.uiToggleDevice.build(this.hPanel, dLeft, dTop + 24, 24, 24);
            this.uiToggleDevice.disable();
            
        end
        
        
        function buildPanelWavetable(this)
            
            dLeft = 50;
            dTop = 20;
            
            this.hPanelWavetable = uipanel( ...
                'Parent', this.hPanel, ...
                'Units', 'pixels', ...
                'Title', 'Wavetable', ... % blanks(0), ...
                'Clipping', 'on', ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelWavetable this.dHeightPanelWavetable], this.hPanel)...
            );
            drawnow;
            
            dSep = 10;
            dTop = 20;
            dLeft = 10;
            
            this.uiButtonWrite.build(this.hPanelWavetable, dLeft, dTop, this.dWidthButton, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthButton + dSep;
            
            this.uiButtonRead.build(this.hPanelWavetable, dLeft, dTop, this.dWidthButton, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthButton + dSep;
            
            dTop = 10;
            this.uiEditTimeRead.build(this.hPanelWavetable, dLeft, dTop, this.dWidthEdit, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthEdit + dSep;
            
        end
        
        function buildPanelMotion(this)
            
            dLeft = 10 + this.dWidthPanelWavetable + 10;
            dTop = 70;
            dLeft = 50;
            
            this.hPanelMotion = uipanel( ...
                'Parent', this.hPanel, ...
                'Units', 'pixels', ...
                'Title', 'Motion', ... % blanks(0), ...
                'Clipping', 'on', ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelMotion this.dHeightPanelMotion], this.hPanel)...
            );
            drawnow;
            
            dSep = 10;
            dTop = 20;
            dLeft = 10;
            
            this.uiGetSetLogicalActive.build(this.hPanelMotion, dLeft, dTop); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthButton + dSep;
            
            this.uiButtonRecord.build(this.hPanelMotion, dLeft, dTop, this.dWidthButton, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthButton + dSep;
            
            dTop = 10;
            this.uiEditTimeRecord.build(this.hPanelMotion, dLeft, dTop, this.dWidthEdit, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthEdit + dSep;
            
        end
        
        
        function device = newDeviceVirtual(this)
            device = npoint.LC400Virtual();
        end
        
    end
    
end

