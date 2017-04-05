package starling.display.graphicsEx;

import starling.display.Graphics;
import starling.display.DisplayObjectContainer;

class ShapeEx extends DisplayObjectContainer
{
    public var graphics(get, never) : GraphicsEx;

    private var _graphics : GraphicsEx;
    
    public function new(strokeCullDistance : Float = 0)
    {
        super();
        _graphics = new GraphicsEx(this, strokeCullDistance);
    }
    
    private function get_graphics() : GraphicsEx
    {
        return _graphics;
    }
}
