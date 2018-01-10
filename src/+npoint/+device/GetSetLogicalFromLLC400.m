classdef GetSetLogicalFromLLC400 < mic.interface.device.GetSetLogical
        
    properties (Access = private)
        
        % {< npoint.LLC400 1x1}
        comm
        
        % {char 1xm} 
        cProp
    end
    
    methods
        
        function this = GetSetLogicalFromLLC400(comm, cProp)
            this.comm = comm;
            this.cProp = cProp;
        end
        
        function lReturn = get(this)
            switch (this.cProp)
                case 'active'
                lReturn = this.comm.getWavetableActive(1) && this.comm.getWavetableActive(2);
            end
        end

        function set(this, lVal)
            switch (this.cProp)
                case 'active'
                    
                if lVal
                    % Enable, then set active
                    this.comm.setWavetableEnable(uint8(1), lVal);
                    this.comm.setWavetableEnable(uint8(2), lVal);
                    this.comm.setTwoWavetablesActive(lVal);
                else
                    % Set not active, then disable
                    this.comm.setTwoWavetablesActive(lVal);
                    this.comm.setWavetableEnable(uint8(1), lVal);
                    this.comm.setWavetableEnable(uint8(2), lVal);
                end
            end
        end 
                
        function initialize(this)
            
        end
        
        function l = isInitialized(this)
            l = true;
        end
        
    end
        
    
end

