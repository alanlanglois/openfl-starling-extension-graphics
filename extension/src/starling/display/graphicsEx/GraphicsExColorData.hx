package starling.display.graphicsEx;

import haxe.Constraints.Function;

class GraphicsExColorData
{
    // Parameters to control alpha and color along the segment
    public var endAlpha : Float = 1.0;
    public var endRed : Int = 0xFF;
    public var endGreen : Int = 0xFF;
    public var endBlue : Int = 0xFF;
    
    public var startAlpha : Float = 1.0;
    public var startRed : Int = 0xFF;
    public var startGreen : Int = 0xFF;
    public var startBlue : Int = 0xFF;
    
    public var colorCallback : Function = null;  // Color callback not yet supported  
    public var alphaCallback : Function = null;  // Alpha callback not yet supported  
    
    
    public function new(startColor : Int = 0xFFFFFF, endColor : Int = 0xFFFFFF, sAlpha : Float = 1.0, eAlpha : Float = 1.0, colorFunc : Function = null, alphaFunc : Function = null)
    {
        endAlpha = eAlpha;
        endRed = as3hx.Compat.parseInt(as3hx.Compat.parseInt(endColor >> 16) & 0xFF);
        endGreen = as3hx.Compat.parseInt(as3hx.Compat.parseInt(endColor >> 8) & 0xFF);
        endBlue = as3hx.Compat.parseInt(endColor & 0xFF);
        
        startAlpha = sAlpha;
        
        startRed = as3hx.Compat.parseInt(as3hx.Compat.parseInt(startColor >> 16) & 0xFF);
        startGreen = as3hx.Compat.parseInt(as3hx.Compat.parseInt(startColor >> 8) & 0xFF);
        startBlue = as3hx.Compat.parseInt(startColor & 0xFF);
        
        colorCallback = colorFunc;
        alphaCallback = alphaFunc;
    }
    
    public function clone() : GraphicsExColorData
    {
        var c : GraphicsExColorData = new GraphicsExColorData();
        
        c.endAlpha = endAlpha;
        c.endRed = endRed;
        c.endGreen = endGreen;
        c.endBlue = endBlue;
        
        c.startAlpha = startAlpha;
        c.startRed = startRed;
        c.startGreen = startGreen;
        c.startBlue = startBlue;
        
        c.alphaCallback = alphaCallback;
        
        c.colorCallback = colorCallback;
        
        return c;
    }
}

