classdef LC400 < mic.Base
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        cName = 'Test'
        
        % These are the UI for activating the hardware that gives the 
        % software real data
        
        
        dColorPlotFiducials = [0.3 0.3 0.3]
        dColorGreen = [.85, 1, .85];
        dColorRed = [1, .85, .85];

    end
    
    properties (Access = private)
        
        
        lDeviceIsSet
        
        
        % {uint8 24x24} - images for the device real/virtual toggle
        u8ToggleOn = imread(fullfile(mic.Utils.pathImg(), 'toggle', 'horiz-1', 'toggle-horiz-24-true.png'));     
        u8ToggleOff = imread(fullfile(mic.Utils.pathImg(), 'toggle', 'horiz-1', 'toggle-horiz-24-false-yellow.png'));           
        
        lShowDevice = false
        hAxes2D
        hAxes2DSim
        hAxes2DInt
        hAxes1D
        hPanel
        hPanelWavetable
        hPanelMotion
        hPanelAxes
        hFigure
        
        
        dWidthFigurePlotTools = 1420;
        dHeightFigurePlotTools = 460;
        
        dWidthPanelAxes = 1400
        dHeightPanelAxes = 360
        dWidthAxes1D = 325 + 265
        dHeightAxes = 280
        
        dWidthPanelWavetable = 350
        dHeightPanelWavetable = 135
        
        dWidthPanelMotion = 350
        dHeightPanelMotion = 135
        
        dWidthButton = 150
        dHeightButton = 24
        dWidthEdit = 80
        
        % {mic.TaskSequence 1x1} see getSequenceWriteIllum
        sequenceWriteIllum
                
        
        
        % {function_handle 1x1} function called when user clicks write
        % @return [i32X, i32Y] wavetable values in [-2^20/2, +2^20/2] 
        fhGet20BitWaveforms
        
        % {function_handle 1x1} returns {char 1xm} path of the recipe that
        % was used to create the waveforms returned by fhGet20BitWaveforms
        fhGetPathOfRecipe
        
        % {char 1xm} storage of the path of the recipe that is currently
        % loaded
        cPathOfRecipe = ''
        
        cLabelRead = 'Read Wavetable & Plot'
        cLabelRecord = 'Record Motion & Plot'
        
        uiButtonRead
        uiEditTimeRead
        
        uiButtonPlotTools
        uiEditOffsetX
        uiEditOffsetY
        uiSequenceWriteIllum
        
        uiEditSigOfKernel
        
        uiTextLabelDevice
        lAskOnDeviceClick = true
        
        uiButtonRecord
        uiEditTimeRecord
        
        
        
        % {mic.Clock 1x1} clock - the clock
        clock
        % {mic.Clock | mic.ui.Clock 1x1}
        uiClock
        
        
        
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

        dNumPixels = 257;
        
        % {function_handle 1x1} returns {< noint.AbstractLC400 1x1 or []}
        fhGetNPoint
        
        % {struct 1x1} cached values of wavetable written to hardware
        stCache
        
        hAxesPreview
        hPlotPreview
        
        % Exposing functions that can be passed in that 
        % will be evoked when the offset X or offset Y 
        % changes
        fhOnChangeOffsetX = @(src, evt) []
        fhOnChangeOffsetY = @(src, evt) []
        
    end
    
    
    properties (SetAccess = private)
        
        uiGetSetLogicalActive % Motion Start / Stop
        dWidth = 710
        dHeight = 100
        
        lWritingIllum = false
        
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
               
            
            if ~isa(this.clock, 'mic.Clock')
                error('clock must be mic.Clock');
            end
            
            if ~isa(this.uiClock, 'mic.Clock') && ~isa(this.uiClock, 'mic.ui.Clock')
                error('uiClock must be mic.Clock or mic.ui.Clock');
            end
            
            this.init();
            
        end
                
        function st = save(this)
            st = struct();
            st.uiEditOffsetX = this.uiEditOffsetX.save();
            st.uiEditOffsetY = this.uiEditOffsetY.save();
            st.uiEditTimeRead = this.uiEditTimeRead.save();
            st.uiEditTimeRecord = this.uiEditTimeRecord.save();
        end
        
        function load(this, st)
            
            if isfield(st, 'uiEditOffsetX')
                this.uiEditOffsetX.load(st.uiEditOffsetX);
            end
            
            if isfield(st, 'uiEditOffsetY')
                this.uiEditOffsetY.load(st.uiEditOffsetY);
            end
            
            if isfield(st, 'uiEditTimeRead')
                this.uiEditTimeRead.load(st.uiEditTimeRead);
            end
            
            if isfield(st, 'uiEditTimeRecord')
                this.uiEditTimeRecord.load(st.uiEditTimeRecord);
            end
            
        end
        
        function delete(this)
            
            this.uiClock.remove([this.id(), '-plot-preview']);
            
            this.msg('delete', this.u8_MSG_TYPE_CLASS_DELETE);
            this.save();
            
            delete(this.uiButtonRead)
            delete(this.uiEditTimeRead)
        
            delete(this.uiTextLabelDevice)
            
            delete(this.uiGetSetLogicalActive) % Motion Start / Stop
            delete(this.uiButtonRecord)
            delete(this.uiEditTimeRecord)
            
            if ishandle(this.hFigure)
                delete(this.hFigure);
            end
            
        end
        
        
        
        
        
       
        
       
        
        
    
        
        function build(this, hParent, dLeft, dTop)
                    
            
            this.hPanel = uipanel( ...
                'Parent', hParent, ...
                'Units', 'pixels', ...
                'Title', sprintf('nPoint LC400 %s', this.cName), ...
                'Clipping', 'on', ...
                ...%'BackgroundColor', [200 200 200]./255, ...
                ...%'BorderType', 'none', ...
                ...%'BorderWidth',0, ... 
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidth this.dHeight], hParent)...
            );
            
        
            dSep = 10;
            dTop = 20;
            dLeft = 10;
        
            dWidthUi = 220;
            this.uiSequenceWriteIllum.build(this.hPanel, dLeft, dTop + 10, dWidthUi);
            dLeft = dLeft + dWidthUi + dSep;
            
            dWidthUi = 50;
            this.uiEditOffsetX.build(this.hPanel, dLeft, dTop, dWidthUi, this.dHeightButton);
            dLeft = dLeft + dWidthUi + dSep;
            
            dWidthUi = 50;
            this.uiEditOffsetY.build(this.hPanel, dLeft, dTop, dWidthUi, this.dHeightButton);
            dLeft = dLeft + dWidthUi + dSep + 20;
            
            this.uiGetSetLogicalActive.build(this.hPanel, dLeft, dTop + 12); 
            % dTop = dTop + dSep - 10;
            dLeft = dLeft + 125 + dSep;
            
            dWidthUi = 100;
            this.uiButtonPlotTools.build(this.hPanel, dLeft, dTop + 10, dWidthUi, this.dHeightButton);
            dLeft = dLeft + dWidthUi + dSep;
            
            dSize = 80;
            dTop = 15;
            
            this.hAxesPreview = axes(...
                'Parent', this.hPanel,...
                'Units', 'pixels',...
                'Color', [0 0 0], ...
                'Position',mic.Utils.lt2lb([...
                    dLeft,...
                    dTop,...
                    dSize,...
                    dSize], this.hPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
           );
            
           dTop = dTop + 120;
           
           this.plotPreview();
            
                        
        end
        
        function plotPreview(this)
            
            if isempty(this.hAxesPreview)
                return
            end
            
            if ~ishandle(this.hAxesPreview)
                return
            end
            
            
            st = this.getWavetables();
            
            if isempty(this.hPlotPreview)
                this.hPlotPreview = plot(...
                    this.hAxesPreview, ...
                    st.x, st.y, 'm', ...
                    'LineWidth', 2 ...
                );
            
                % Create plotting data for circles at sigma = 0.3 - 1.0

                dSig = [0.3:0.1:1.0];
                dPhase = linspace(0, 2*pi, 100);

                for (k = 1:length(dSig))

                    x = dSig(k)*cos(dPhase);
                    y = dSig(k)*sin(dPhase);
                    line( ...
                        x, y, ...
                        'color', this.dColorPlotFiducials, ...
                        'LineWidth', 1, ...
                        'Parent', this.hAxesPreview ...
                    );

                end
            else
                this.hPlotPreview.XData = st.x;
                this.hPlotPreview.YData = st.y;
            end
            set(this.hAxesPreview, 'XTick', [], 'YTick', []);
            
            if this.getActive()
                set(this.hAxesPreview, 'Color', this.dColorGreen);
            else
                set(this.hAxesPreview, 'Color', this.dColorRed);
            end
            xlim(this.hAxesPreview, [-1 1])
            ylim(this.hAxesPreview, [-1 1])
            % axis(this.hAxesPreview, 'off')
            
            
        end
        
        
        
        % Returns{char 1xm} storage of the path of the recipe that is currently
        % loaded (that was loaded last).  No memory for MATLAB restarts. 
        function c = getPathOfRecipe(this)
            c = this.cPathOfRecipe;
        end
        
        function setWavetablesFromGetter(this)
            
            [i32Ch1, i32Ch2] = this.fhGet20BitWaveforms();
            this.cPathOfRecipe = this.fhGetPathOfRecipe();
            
            % Add offsets
            
            i32Ch1 = i32Ch1 + int32(this.uiEditOffsetX.get() * 2^19);
            i32Ch2 = i32Ch2 + int32(this.uiEditOffsetY.get() * 2^19);
            
            try
                comm = this.fhGetNPoint();
                comm.setWavetable(uint8(1), i32Ch1');
                comm.setWavetable(uint8(2), i32Ch2');
            catch
                return
            end
            
            % Update the cache 
            this.stCache.x = double(i32Ch1) / 2^19;
            this.stCache.y = double(i32Ch2) / 2^19;
            this.stCache.t = 24e-6 * double(1 : length(i32Ch1));
            
            this.plotPreview();
            
        end
        
        
        % Returns a {mic.TaskSequence 1x1} that: fetches the 20-bit waveforms
        % using the supplied getter (this.fhGet20BitWaveforms), applies the
        % offset in the edit boxes, writes the wavetables to the LC400 and
        % begins scanning.  
        % @return {mic.TaskSequence 1x1}
        
        function setWritingIllum(this, lVal)
            this.lWritingIllum = lVal;
        end
        
        function task = getSequenceWriteIllum(this)
            
            if isempty(this.sequenceWriteIllum)
                
                ceTasks = { ...
                    ... This task returns false while writing is true.  This is a "cute trick"
                    ... That allows sequences to return a correct state of false while executing
                    ... and true while not executing.  See the last task in the list as well.
                    %{
                    mic.Task( ...
                        'fhExecute', @() this.setWritingIllum(true), ...
                        'fhIsDone', @() this.lWritingIllum == false, ... 
                        'fhGetMessage', @() 'Setting writing state = true' ...
                    ), ...
                    %}
                    mic.Task( ...
                        'fhExecute', @() this.uiButtonRead.disable(), ...
                        'fhGetMessage', @() 'Disabling read button (plot tools)' ...
                    ), ...
                    mic.Task( ...
                        'fhExecute', @() this.uiButtonRecord.disable(), ...
                        'fhGetMessage', @() 'Disabling record button (plot tools)' ...
                    ), ...
                    mic.Task(...
                        'fhExecute', @() this.uiGetSetLogicalActive.disable(), ...
                        'fhGetMessage', @() 'Disabling start/stop button' ...
                    ), ...
                    ... % stop motion
                    mic.Task.fromUiGetSetLogical(this.uiGetSetLogicalActive, false, 'motion') ...
                    %{
                    mic.Task(...
                        'fhExecute', @() this.uiGetSetLogicalActive.set(false), ...
                        'fhGetMessage', @() 'Stopping Motion' ... 
                    ), ...
                    %}
                    ... % write the data
                    mic.Task(...
                        'fhExecute', @this.setWavetablesFromGetter, ...
                        'fhGetMessage', @() 'Writing 20-bit waveforms to LC400 ...' ...
                    ), ...
                    ... % start motion
                    mic.Task.fromUiGetSetLogical(this.uiGetSetLogicalActive, true, 'motion'), ... 
                    %{
                    mic.Task(...
                        'fhExecute', @() this.uiGetSetLogicalActive.set(true), ...
                        'fhGetMessage', @() 'Starting Motion' ... 
                    ), ...
                    %}
                    mic.Task(...
                        'fhExecute', @() this.uiGetSetLogicalActive.enable(), ...
                        'fhGetMessage', @() 'Enabling start/stop button' ...
                    ), ...
                    mic.Task( ...
                        'fhExecute', @() this.uiButtonRead.enable(), ...
                        'fhGetMessage', @() 'Enabling read button (plot tools)' ...
                    ), ...
                    mic.Task( ...
                        'fhExecute', @() this.uiButtonRecord.enable(), ...
                        'fhGetMessage', @() 'Enabling record button (plot tools)' ...
                    ), ...
                    ... This task returns true when writing is false.  This is a "cute trick"
                    ... That allows sequences to return a correct state of false while executing
                    ... and true while not executing.  See the last task in the list as well.
                    mic.Task( ...
                        'fhExecute', @() this.setWritingIllum(false), ...
                        'fhIsDone', @() this.lWritingIllum == false, ... 
                        'fhGetMessage', @() 'Setting writing state = false' ...
                    ) ...
                };

                % cStamp = datestr(datevec(now), 'yyyymmdd-HHMMSS', 'local');
                this.sequenceWriteIllum = mic.TaskSequence( ...
                    'cName', [this.cName, 'task-sequence-lc400-stop-then-write-wavetable-then-start'] , ...
                    'clock', this.clock, ...
                    'ceTasks', ceTasks, ...
                    'dPeriod', 0.25, ...
                    'fhGetMessage', @() 'Write Illum & Start Scan' ...
                );
            end
            
            task = this.sequenceWriteIllum;
        end
        
        function initUiSequenceWriteIllum(this)
            
            this.uiSequenceWriteIllum = mic.ui.TaskSequence(...
                'cName', [this.cName, 'ui-task-sequence-lc400-stop-then-write-wavetable-then-start'], ...
                'task', this.getSequenceWriteIllum(), ...
                'lShowIsDone', false, ...
                'clock', this.uiClock ...
            );
        
            
        end
        
        % Reads wavetable data from the hardware up to the end index
        % and updates local state stCache
        function updateCacheOfWavetable(this)
            
            try
            	comm = this.fhGetNPoint();
                u32Samples = comm.getEndIndexOfWavetable(1);
                d = comm.getWavetables(u32Samples);
            catch mE
                error(getReport(mE))
                return
            end
            
            this.stCache.x = d(1, :) / 2^19;
            this.stCache.y = d(2, :) / 2^19;
            this.stCache.t = 24e-6 * double(1 : u32Samples);
            
            this.plotPreview();

        end
        
        
        % Returns the wavetable data loaded on the hardware.  Amplitude is
        % relative [-1 : 1] to the max mechanical deflection of the hardware
        % @typedef {struct 1x1} WavetableData
        % @property {double 1xm} x - x amplitude [-1 : 1]
        % @property {double 1xm} y - y amplitude [-1 : 1]
        % @property {double 1xm} t - time (sec)
        % @return {WavetableData 1x1}
        
        function st = getWavetables(this)
            st = this.stCache;
        end

        function executePupilFillWriteSequence(this)
            this.uiSequenceWriteIllum.execute();
        end
        function abortPupilFillWriteSequence(this)
            this.uiSequenceWriteIllum.abort();
        end
        function lVal = isExecutingPupilFillSequence(this)
            lVal = this.uiSequenceWriteIllum.isExecuting();
        end
        function lVal = checkIsSequenceFinished(this)
            lVal = this.uiSequenceWriteIllum.isDone();
        end
        
        
                
        
    end
    
    
    methods (Access = private)
        
        function buildFigure(this)
            
            if ishghandle(this.hFigure)
                % Bring to front
                figure(this.hFigure);
                return
            end
            
            dScreenSize = get(0, 'ScreenSize');
            
            this.hFigure = figure( ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Name', sprintf('nPoint LC400 Plot Tools (%s)', this.cName), ...
                'Position', [ ...
                    (dScreenSize(3) - this.dWidthFigurePlotTools)/2 ...
                    (dScreenSize(4) - this.dHeightFigurePlotTools)/2 ...
                    this.dWidthFigurePlotTools ...
                    this.dHeightFigurePlotTools ...
                 ],... % left bottom width height
                'Resize', 'off', ...
                'HandleVisibility', 'on', ... % lets close all close the figure
                'Visible', 'on',...
                'CloseRequestFcn', @this.onFigureCloseRequest ...
            );
                        
            drawnow;
            
            % this.buildPanelWavetable();
            % this.buildPanelMotion();
            
            dTop = 10;
            dLeft = 10;
            dSep = 50;
            dSepH = 10;
            
            
            

            
            this.uiButtonRead.build(this.hFigure, dLeft, dTop + 12, this.dWidthButton, this.dHeightButton); 
            % dTop = dTop + dSep;
            dLeft = dLeft + this.dWidthButton + dSepH;
            
            
            this.uiEditTimeRead.build(this.hFigure, dLeft, dTop, this.dWidthEdit, this.dHeightButton); 
            dLeft = dLeft + this.dWidthEdit + dSep;
            %dTop = dTop + dSep;
            %dLeft = 10;
            
            
            
            this.uiButtonRecord.build(this.hFigure, dLeft, dTop + 12, this.dWidthButton, this.dHeightButton); 
            dLeft = dLeft + this.dWidthButton + dSepH;
            
            this.uiEditTimeRecord.build(this.hFigure, dLeft, dTop, this.dWidthEdit, this.dHeightButton); 
            dLeft = dLeft + this.dWidthEdit + dSep;

            %dTop = dTop + dSep;
            %dLeft = 10;
            
            dLeft = dLeft + 430;
            this.uiEditSigOfKernel.build(this.hFigure, dLeft, dTop, this.dWidthEdit, this.dHeightButton); 
            dLeft = dLeft + this.dWidthEdit + dSep;
                        
            
            this.buildPanelAxes();
            
        end
                
        
        function plotRecorded2D(this)
            
            if isempty(this.hPanel) || ~ishandle(this.hPanel) || ... 
               isempty(this.hAxes2D) || ~ishandle(this.hAxes2D) 
                return
            end
            
            cla(this.hAxes2D)
            hold(this.hAxes2D, 'on');

            plot(...
                this.hAxes2D, ...
                this.dAmpRecordCommandCh1, this.dAmpRecordCommandCh2, 'b', ...
                'LineWidth', 1 ...
            );
            plot(...
                this.hAxes2D, ...
                this.dAmpRecordSensorCh1, this.dAmpRecordSensorCh2, 'b', ...
                'LineWidth', 2 ...
            );
            axis(this.hAxes2D, 'image')
            xlim(this.hAxes2D, [-1 1])
            ylim(this.hAxes2D, [-1 1])
            title(this.hAxes2D, 'x(t) vs. y(t)')
            hold(this.hAxes2D, 'off')
                            
        end
        
        function plotRecorded2DInt(this)
            this.plot2DInt(this.dAmpRecordSensorCh1, this.dAmpRecordSensorCh2);
        end
        
        function plotWavetable2DInt(this)
            this.plot2DInt(this.dAmpCh1, this.dAmpCh2);
        end
        
        
        
        function plot2DInt(this, dX, dY)
            
            if isempty(this.hPanel) || ~ishandle(this.hPanel) || ... 
               isempty(this.hAxes2DInt) || ~ishandle(this.hAxes2DInt) 
                return
            end
            
            
            dInt = zeros(this.dNumPixels, this.dNumPixels);

            % Map each (vx,vy) pair to its corresponding pixel in the pupil
            % fill matrices.  For vy, need to flip its sign before
            % computing the pixel because of the way matlab does y
            % coordinates in an image plot

            
            dPixelX = round(dX * this.dNumPixels/2 + this.dNumPixels/2);
            dPixelY = round(dY * this.dNumPixels/2 + this.dNumPixels/2);                  
            

            % If any of the pixels lie outside the matrix, discard them

            dIndex = find(  dPixelX <= this.dNumPixels & ...
                            dPixelX > 0 & ...
                            dPixelY <= this.dNumPixels & ...
                            dPixelY > 0 ...
                            );

            dPixelX = dPixelX(dIndex);
            dPixelY = dPixelY(dIndex);

            % Add a "1" at each pixel where (vx,vy) pairs reside.  We may end up adding
            % "1" to a given pixel a few times - especially if the dwell is set to more
            % than 1.

            for n = 1:length(dPixelX)
                dInt(dPixelY(n), dPixelX(n)) = dInt(dPixelY(n), dPixelX(n)) + 1;
            end
            
            [dX, dY, dKernelInt] = this.getKernel();            

            dInt = conv2(dInt, dKernelInt.^2,'same');
            dInt = dInt./max(max(dInt));
            
            
            imagesc(...
                this.hAxes2DInt, ...
                dInt);
            axis(this.hAxes2DInt, 'image')
            colormap(this.hAxes2DInt, 'jet');
            set(this.hAxes2DInt,'XTickLabel',[]);
            set(this.hAxes2DInt,'YTickLabel',[]);
            title(this.hAxes2DInt, 'x(t) vs. y(t) intensity')
        end
        
        
        function plotDefault(this)
            this.plotDefault1D()
            this.plotDefault2D()
            this.plotDefault2DInt()
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
        
        function plotDefault2DInt(this)
            
            if isempty(this.hPanel) || ~ishandle(this.hPanel) || ... 
               isempty(this.hAxes2DInt) || ~ishandle(this.hAxes2DInt) 
                return
            end
            
            xlim(this.hAxes2DInt, [-1 1])
            ylim(this.hAxes2DInt, [-1 1])
            title(this.hAxes2DInt, 'x(t) vs. y(t) (intensity)')
            
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
            this.plotRecorded2DInt()
        end
        
        function plotRecorded1D(this)
            
            if isempty(this.hPanel) || ...
               isempty(this.hAxes1D) || ...
               ~ishandle(this.hPanel) || ... 
               ~ishandle(this.hAxes1D)
                return 
            end
            
            cla(this.hAxes1D)
            hold(this.hAxes1D, 'on')
            plot(...
                this.hAxes1D, ...
                this.dTimeRecord * 1000, this.dAmpRecordCommandCh1, 'r', ...
                this.dTimeRecord * 1000, this.dAmpRecordCommandCh2, 'b', ...
                'LineWidth', 1 ...
            );
            plot(...
                this.hAxes1D, ...
                this.dTimeRecord * 1000, this.dAmpRecordSensorCh1, 'r', ...
                this.dTimeRecord * 1000, this.dAmpRecordSensorCh2, 'b', ...
                'LineWidth', 2 ...
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
            
            if isempty(this.hPanel) || ~ishandle(this.hPanel) || ... 
               isempty(this.hAxes2D) || ~ishandle(this.hAxes2D)
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
            
            if isempty(this.hPanel) || ~ishandle(this.hPanel) || ... 
               isempty(this.hAxes1D) || ~ishandle(this.hAxes1D)
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
            this.plotWavetable2DInt()
            
        end
        
        
        function readWavetableToEndIndex(this)
            comm = this.fhGetNPoint();
            u32Samples = comm.getEndIndexOfWavetable(1);
            this.readWavetable(this, u32Samples);
        end
        
        function readWavetable(this, u32Samples)
            
            cLabel = sprintf('Reading %u ...', u32Samples);
            this.uiButtonRead.setText(cLabel);
                                   
            this.uiGetSetLogicalActive.disable();
            this.uiButtonRead.disable();
            this.uiButtonRecord.disable();
            
            this.uiSequenceWriteIllum.stop(); % stops simultaneous multi-communication with LC400
            
            comm = this.fhGetNPoint();
            d = comm.getWavetables(u32Samples);
            
            this.uiSequenceWriteIllum.start();
            
            this.uiGetSetLogicalActive.enable();
            this.uiButtonRead.enable();
            this.uiButtonRecord.enable();
            
            this.uiButtonRead.setText(this.cLabelRead);
            drawnow;

            this.dAmpCh1 = d(1, :) / 2^19;
            this.dAmpCh2 = d(2, :) / 2^19;
            this.dTime = 24e-6 * double(1 : u32Samples);
            
        end
        
        
        
        function onRead(this, src, evt)
                                    
            u32Samples = uint32(this.uiEditTimeRead.get() / 2000 * 83333);
            this.readWavetable(u32Samples);
            this.plotWavetable();
            
        end
        
        
        function onRecord(this, src, evt)
                 
            
            u32Samples = uint32(this.uiEditTimeRecord.get() / 2000 * 83333);
            
            % Prepare UI for "record" state
            cMsg = sprintf('Rec. %u ...', u32Samples);
            this.uiButtonRecord.setText(cMsg);
            
            this.uiGetSetLogicalActive.disable();
            this.uiButtonRead.disable();
            this.uiButtonRecord.disable();
            
            comm = this.fhGetNPoint();
            dResult = comm.record(u32Samples);
            
            
             this.uiGetSetLogicalActive.enable();
            this.uiButtonRead.enable();
            this.uiButtonRecord.enable();
            
            
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
        
        function onEditSigOfKernel(this, src, evt)
            this.plotRecorded();
        end
        
             
        
        
        function initUiButtonRead(this)
            this.uiButtonRead = mic.ui.common.Button(...
                'cText', this.cLabelRead, ...
                'fhOnClick', @this.onRead ...
            );
            this.uiButtonRead.setTooltip('Read the LC400 wavetables (from memory) and plot');
        end
        
        function initUiEditTimeRead(this)
            
            this.uiEditTimeRead = mic.ui.common.Edit(...
                'cLabel', 'Read Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', true);
            
            this.uiEditTimeRead.setTooltip('The time window for read  commands');

            
            % Default values
            this.uiEditTimeRead.setMax(2000);
            this.uiEditTimeRead.setMin(0);
            this.uiEditTimeRead.set(300);
        end
                
        function initUiButtonRecord(this)
            this.uiButtonRecord = mic.ui.common.Button(...
                'cText', this.cLabelRecord, ...
                'fhOnClick', @this.onRecord ...
            );
            this.uiButtonRecord.setTooltip('Record the commanded + servo values and plot');
        end
        
        function initUiEditTimeRecord(this)
            
            this.uiEditTimeRecord = mic.ui.common.Edit(...
                'cLabel', 'Record Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', true);
            
            
            this.uiEditTimeRecord.setTooltip('The time window for recording');            
            
            % Default values
            this.uiEditTimeRecord.setMax(2000);
            this.uiEditTimeRecord.setMin(0);
            this.uiEditTimeRecord.set(300);
            
        end
        
        
        
        
        function l = getActive(this)
            
            comm = this.fhGetNPoint();
            l = comm.getWavetableActive(1) && comm.getWavetableActive(2);
            
        end
        
        function setActive(this, lVal)
            
            comm = this.fhGetNPoint();
            if lVal
                % Enable, then set active
                comm.setWavetableEnable(uint8(1), lVal);
                comm.setWavetableEnable(uint8(2), lVal);
                comm.setTwoWavetablesActive(lVal);
            else
                % Set not active, then disable
                comm.setTwoWavetablesActive(lVal);
                comm.setWavetableEnable(uint8(1), lVal);
                comm.setWavetableEnable(uint8(2), lVal);
            end
        end
        
        
        function initUiGetSetLogicalActive(this)
            
            % Configure the mic.ui.common.Toggle instance
            ceVararginCommandToggle = {...
                'cTextTrue', 'Stop Motion', ...
                'cTextFalse', 'Start Motion' ...
            };

            % Store the delay for how often it calls get()
            config = mic.config.GetSetLogical();
            
            this.uiGetSetLogicalActive = mic.ui.device.GetSetLogical(...
                'clock', this.uiClock, ...
                'config', config, ...
                'ceVararginCommandToggle', ceVararginCommandToggle, ...
                'lShowInitButton', false, ...
                'lShowDevice', false, ...
                'lShowName', false, ...
                'cName', sprintf('npoint-lc400-ui-%s', this.cName), ...
                'dWidthName', 50, ...
                'dWidthCommand', 100, ...
                'lShowLabels', false, ...
                'fhGet', @() this.getActive(), ...
                'fhSet', @(lVal) this.setActive(lVal), ...
                'fhIsVirtual', @() false, ...
                'lUseFunctionCallbacks', true, ...
                'cLabel', 'Scanning:'...
            );
        
        end
        
        
        
        
        
        
        function init(this)
            
            this.initUiEditOffsetX();
            this.initUiEditOffsetY();
            this.initUiButtonPlotTools();
            % this.initPanelWavetable();
            % this.initPanelMotion();
            
            this.initUiButtonRead()
            this.initUiEditTimeRead()
            
            this.initUiButtonRecord()
            this.initUiEditTimeRecord()
            this.initUiGetSetLogicalActive()
            this.initUiEditSigOfKernel();
            
            % do last since may need access to several things
            this.initUiSequenceWriteIllum();
            
            this.stCache = struct();
            this.stCache.x = [];
            this.stCache.y = [];
            this.stCache.t = [];
            this.updateCacheOfWavetable();
            
            this.uiClock.add(...
                @this.plotPreview, ...
                [this.id(), '-plot-preview'], ...
                1 ...
            );

        end
        
        
        
        function initUiEditOffsetX(this)
            
            this.uiEditOffsetX = mic.ui.common.Edit( ...
                'cLabel', 'Offset X', ... 
                'fhDirectCallback', @this.fhOnChangeOffsetX, ...
                'cType', 'd' ...
            );
        
            this.uiEditOffsetX.setMin(-1);
            this.uiEditOffsetX.setMax(1);
            this.uiEditOffsetX.setTooltip('Global x offset to be applied to written waveform.');
        end
        
        
        function initUiEditOffsetY(this)
            
            this.uiEditOffsetY = mic.ui.common.Edit( ...
                'cLabel', 'Offset Y', ... 
                'fhDirectCallback', @this.fhOnChangeOffsetY, ...
                'cType', 'd' ...
            );
        
            this.uiEditOffsetY.setMin(-1);
            this.uiEditOffsetY.setMax(1);
            this.uiEditOffsetY.setTooltip('Global y offset to be applied to written waveform.');
            
        end
        
        function initUiEditSigOfKernel(this)
            
            this.uiEditSigOfKernel = mic.ui.common.Edit( ...
                'cLabel', 'Sigma of Beam', ... 
                'fhDirectCallback', @this.onEditSigOfKernel, ...
                'cType', 'd' ...
            );
        
            this.uiEditSigOfKernel.setMin(-1);
            this.uiEditSigOfKernel.setMax(1);
            this.uiEditSigOfKernel.set(0.05);
            this.uiEditSigOfKernel.setTooltip('Sigma of beam used to compute simulated 2D pupil fill.');
            
        end
        
        
        function initUiButtonPlotTools(this)
            
            this.uiButtonPlotTools = mic.ui.common.Button( ...
                'cText', 'Plot Tools', ...
                'fhDirectCallback', @this.onClickPlotTools ...
            );
        
            
        end
        
        

        
        
        
        function onClickPlotTools(this, src, evt)
            this.buildFigure()
        end
        
        
        
        
        function buildPanelAxes(this)
            
            if ~ishandle(this.hFigure)
                return
            end
            
            dTop = 70;
            dLeft = 0;
            
            %dLeft = 0
            %dTop = 150
            
            this.hPanelAxes = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                ...%'Title', 'Plot',...
                'Title', blanks(0), ...
                'Clipping', 'on',...
                'BackgroundColor', [1 1 1], ...
                ... %'BackgroundColor', [100 100 100]./255, ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelAxes this.dHeightPanelAxes], this.hFigure) ...
            );
            drawnow;        
            
            dLeft = 50;
            dTop = 30;
            dSep = 50;
            
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
            
            
            this.hAxes2DInt = axes(...
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
        

        
        
        
        function buildPanelWavetable(this)
            
            dLeft = 50;
            dTop = 20;
            
            this.hPanelWavetable = uipanel( ...
                'Parent', this.hFigure, ...
                'Units', 'pixels', ...
                'Title', 'Wavetable', ... % blanks(0), ...
                'Clipping', 'on', ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelWavetable this.dHeightPanelWavetable], this.hFigure)...
            );
            drawnow;
            
            dSep = 10;
            dTop = 20;
            dLeft = 10;
            
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
                'Parent', this.hFigure, ...
                'Units', 'pixels', ...
                'Title', 'Motion', ... % blanks(0), ...
                'Clipping', 'on', ...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([dLeft dTop this.dWidthPanelMotion this.dHeightPanelMotion], this.hFigure)...
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
        
        function onFigureCloseRequest(this, src, evt)
            this.msg('LC400.closeRequestFcn()', this.u8_MSG_TYPE_INFO);
            delete(this.hFigure);
            this.hFigure = [];
         end
        
        
        
        function [out] = gauss(this, x, sigx, y, sigy)

            if nargin == 5
                out = exp(-((x/sigx).^2/2+(y/sigy).^2/2)); 
            elseif nargin == 4;
                disp('Must input x,sigx,y,sigy in ''gauss'' function')
            elseif nargin == 3;
                out = exp(-x.^2/2/sigx^2);
            elseif nargin == 12;
                out = exp(-x.^2/2);
            end
            
        end
        
        function [X,Y] = getXY(this, Nx, Ny, Lx, Ly)

            % Sample spacing

            dx = Lx/Nx;
            dy = Ly/Ny;

            % Sampled simulation points 1D 

            x = -Lx/2:dx:Lx/2 - dx;
            y = -Ly/2:dy:Ly/2 - dy;
            % u = -1/2/dx: 1/Nx/dx: 1/2/dx - 1/Nx/dx;
            % v = -1/2/dy: 1/Ny/dy: 1/2/dy - 1/Ny/dy;

            [Y,X] = meshgrid(y,x);
            % [V,U] = meshgrid(v,u);
            
        end
        
        % @return {double m x n} return a matrix that represents the
        % intensity distribution of the scan kernel (beam intensity). 
        
        function [dX, dY, dKernelInt] = getKernel(this)
                        
            [dX, dY] = this.getXY(this.dNumPixels, this.dNumPixels, 2, 2);
            dKernelInt = this.gauss(dX, this.uiEditSigOfKernel.get(), dY, this.uiEditSigOfKernel.get());
            
        end
        
    end
    
end

