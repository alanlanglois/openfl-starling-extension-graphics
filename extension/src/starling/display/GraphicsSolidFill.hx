package starling.display;

import starling.display.IGraphicsData;
import starling.display.materials.IMaterial;
import flash.geom.Matrix;

class GraphicsSolidFill implements IGraphicsData
{
    public var color(get, never) : Int;
    public var alpha(get, never) : Float;

    private var mColor : Int;
    private var mAlpha : Float;
    
    public function new(color : Int, alpha : Float)
    {
        mColor = color;
        mAlpha = alpha;
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

