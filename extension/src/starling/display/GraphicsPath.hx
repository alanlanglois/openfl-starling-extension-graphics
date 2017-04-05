package starling.display;


/**
	 * ...
	 * An implementation of flash.graphics.GraphicsPath
	 */
class GraphicsPath implements IGraphicsData
{
    public var data(get, never) : Array<Float>;
    public var commands(get, never) : Array<Int>;
    public var winding(get, set) : String;

    private var mCommands : Array<Int>;
    private var mData : Array<Float>;
    private var mWinding : String;
    
    public function new(commands : Array<Int> = null, data : Array<Float> = null, winding : String = "evenOdd")
    {
        mCommands = commands;
        mData = data;
        mWinding = winding;
        
        if (mCommands == null)
        {
            mCommands = new Array<Int>();
        }
        if (mData == null)
        {
            mData = new Array<Float>();
        }
    }
    
    private function get_data() : Array<Float>
    {
        return mData;
    }
    
    private function get_commands() : Array<Int>
    {
        return mCommands;
    }
    
    private function get_winding() : String
    {
        return mWinding;
    }
    
    private function set_winding(value : String) : String
    {
        mWinding = value;
        return value;
    }
    
    public function curveTo(controlX : Float, controlY : Float, anchorX : Float, anchorY : Float) : Void
    {
        mCommands.push(GraphicsPathCommands.CURVE_TO);
        mData.push(controlX);
        mData.push(controlY);
        mData.push(anchorX);
        mData.push(anchorY);
        
    }
    
    public function lineTo(x : Float, y : Float) : Void
    {
        mCommands.push(GraphicsPathCommands.LINE_TO);
        mData.push(x);
        mData.push(y);
        
    }
    
    public function moveTo(x : Float, y : Float) : Void
    {
        mCommands.push(GraphicsPathCommands.MOVE_TO);
        mData.push(x);
        mData.push(y);
        
    }
    
    public function wideLineTo(x : Float, y : Float) : Void
    {
        mCommands.push(GraphicsPathCommands.WIDE_LINE_TO);
        mData.push(x);
        mData.push(y);
        
    }
    
    public function wideMoveTo(x : Float, y : Float) : Void
    {
        mCommands.push(GraphicsPathCommands.WIDE_MOVE_TO);
        mData.push(x);
        mData.push(y);
        
    }
}

