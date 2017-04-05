package starling.display;


/**
	 * ...
	 * API-breaking class GraphicsLine, allowing for line thickness, color, alpha on line segments.
	 */
class GraphicsLine implements IGraphicsData
{
    public var thickness(get, never) : Float;
    public var color(get, never) : Int;
    public var alpha(get, never) : Float;

    private var mThickness : Float = Math.NaN;
    private var mColor : Int = 0;
    private var mAlpha : Float = 1.0;
    
    public function new(thickness : Float = Math.NaN, color : Int = 0, alpha : Float = 1.0)
    {
        mThickness = thickness;
        mColor = color;
        mAlpha = alpha;
    }
    
    private function get_thickness() : Float
    {
        return mThickness;
    }
    
    private function get_color() : Int
    {
        return mColor;
    }
    
    private function get_alpha() : Float
    {
        return mAlpha;
    }
}

