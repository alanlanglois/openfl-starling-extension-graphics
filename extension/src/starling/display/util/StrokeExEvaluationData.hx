package starling.display.util;

import starling.display.graphicsEx.StrokeEx;

class StrokeExEvaluationData
{
    public var distance : Float;  // Distance holds the distance along the curve that the 't' value represents.  
    public var thickness : Float;
    public var r : Float;
    public var g : Float;
    public var b : Float;
    public var a : Float;
    
    // These are internal values, that should not be accessed by API users.
    public var internalLastT : Float;
    public var internalLastX : Float;
    public var internalStroke : StrokeEx;
    public var internalStartVertSearchIndex : Int;
    public var internalDistanceToPrevVert : Float;
    public var internalLastStrokeLength : Float;
    
    public function new(s : StrokeEx)
    {
        reset(s);
    }
    
    public function reset(s : StrokeEx) : Void
    {
        internalStroke = s;
        internalStartVertSearchIndex = -1;
        internalDistanceToPrevVert = internalLastT = -1;
        internalLastX = -1;
        internalLastStrokeLength = distance = 0;
    }
}

