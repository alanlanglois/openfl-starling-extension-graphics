package starling.display.graphicsEx;

import haxe.Constraints.Function;

class GraphicsExThicknessData
{
    
    // Parameters to control thickness along the segment
    public var startThickness : Float = -1;
    public var endThickness : Float = -1;
    public var thicknessCallback : Function = null;  // Callback function not yet supported  
    
    public function new(sThick : Int, eThick : Int, callback : Function = null)
    {
        startThickness = sThick;
        endThickness = eThick;
        thicknessCallback = callback;
    }
    
    public function clone() : GraphicsExThicknessData
    {
        var c : GraphicsExThicknessData = new GraphicsExThicknessData(startThickness, endThickness, thicknessCallback);
        
        return c;
    }
}

