package starling.display.graphicsEx;

import starling.display.GraphicsPathCommands;
import starling.display.IGraphicsData;

/**
	 * ...
	 * Making the spline usable for GraphicsPath as well
	 */
class GraphicsNaturalSpline implements IGraphicsData
{
    public var controlPoints(get, never) : Array<Dynamic>;
    public var closed(get, never) : Bool;
    public var steps(get, never) : Int;

    private var mControlPoints : Array<Dynamic>;
    private var mClosed : Bool;
    private var mSteps : Int;
    
    public function new(controlPoints : Array<Dynamic> = null, closed : Bool = false, steps : Int = 4)
    {
        mControlPoints = controlPoints;
        mClosed = closed;
        mSteps = steps;
        if (mControlPoints == null)
        {
            mControlPoints = [];
        }
    }
    
    private function get_controlPoints() : Array<Dynamic>
    {
        return mControlPoints;
    }
    
    private function get_closed() : Bool
    {
        return mClosed;
    }
    
    private function get_steps() : Int
    {
        return mSteps;
    }
}

