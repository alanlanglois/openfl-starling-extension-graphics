package starling.display;

import starling.display.Graphics;

class Shape extends DisplayObjectContainer
{
    public var graphics(get, never) : Graphics;

    private var _graphics : Graphics;
    
    public function new()
    {
        super();
        _graphics = new Graphics(this);
    }
    
    private function get_graphics() : Graphics
    {
        return _graphics;
    }
}
