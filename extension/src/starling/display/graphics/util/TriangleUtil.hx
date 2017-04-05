package starling.display.graphics.util;

import flash.geom.Point;

class TriangleUtil
{
    
    public function new()
    {
    }
    
    public static function isLeft(v0x : Float, v0y : Float, v1x : Float, v1y : Float, px : Float, py : Float) : Bool
    {
        return ((v1x - v0x) * (py - v0y) - (v1y - v0y) * (px - v0x)) < 0;
    }
    
    public static function isPointInTriangle(v0x : Float, v0y : Float, v1x : Float, v1y : Float, v2x : Float, v2y : Float, px : Float, py : Float) : Bool
    {
        if (isLeft(v2x, v2y, v0x, v0y, px, py))
        {
            return false;
        }  // In practical tests, this seems to be the one returning false the most. Put it on top as faster early out.  
        if (isLeft(v0x, v0y, v1x, v1y, px, py))
        {
            return false;
        }
        if (isLeft(v1x, v1y, v2x, v2y, px, py))
        {
            return false;
        }
        return true;
    }
    
    public static function isPointInTriangleBarycentric(v0x : Float, v0y : Float, v1x : Float, v1y : Float, v2x : Float, v2y : Float, px : Float, py : Float) : Bool
    {
        var alpha : Float = ((v1y - v2y) * (px - v2x) + (v2x - v1x) * (py - v2y)) / ((v1y - v2y) * (v0x - v2x) + (v2x - v1x) * (v0y - v2y));
        var beta : Float = ((v2y - v0y) * (px - v2x) + (v0x - v2x) * (py - v2y)) / ((v1y - v2y) * (v0x - v2x) + (v2x - v1x) * (v0y - v2y));
        var gamma : Float = 1.0 - alpha - beta;
        if (alpha > 0 && beta > 0 && gamma > 0)
        {
            return true;
        }
        return false;
    }
    
    public static function isPointOnLine(v0x : Float, v0y : Float, v1x : Float, v1y : Float, px : Float, py : Float, distance : Float) : Bool
    {
        var lineLengthSquared : Float = (v1x - v0x) * (v1x - v0x) + (v1y - v0y) * (v1y - v0y);
        
        var interpolation : Float = (((px - v0x) * (v1x - v0x)) + ((py - v0y) * (v1y - v0y))) / (lineLengthSquared);
        if (interpolation < 0.0 || interpolation > 1.0)
        {
            return false;
        }  // closest point does not fall within the line segment  
        
        var intersectionX : Float = v0x + interpolation * (v1x - v0x);
        var intersectionY : Float = v0y + interpolation * (v1y - v0y);
        
        var distanceSquared : Float = (px - intersectionX) * (px - intersectionX) + (py - intersectionY) * (py - intersectionY);
        
        var intersectThickness : Float = 1 + distance;
        
        if (distanceSquared <= intersectThickness * intersectThickness)
        {
            return true;
        }
        
        return false;
    }
    
    public static function lineIntersectLine(line1V0x : Float, line1V0y : Float, line1V1x : Float, line1V1y : Float, line2V0x : Float, line2V0y : Float, line2V1x : Float, line2V1y : Float, intersectPoint : Point) : Bool
    {
        var a1 : Float = line1V1y - line1V0y;
        var b1 : Float = line1V0x - line1V1x;
        var c1 : Float = line1V1x * line1V0y - line1V0x * line1V1y;
        
        var a2 : Float = line2V1y - line2V0y;
        var b2 : Float = line2V0x - line2V1x;
        var c2 : Float = line2V1x * line2V0y - line2V0x * line2V1y;
        
        var d : Float = a1 * b2 - a2 * b1;
        if (d == 0)
        {
            return false;
        }
        var invD : Float = 1.0 / d;
        var ptx : Float = (b1 * c2 - b2 * c1) * invD;
        var pty : Float = (a2 * c1 - a1 * c2) * invD;
        
        if (isPointOnLine(line1V0x, line1V0y, line1V1x, line1V1y, ptx, pty, 0) && isPointOnLine(line2V0x, line2V0y, line2V1x, line2V1y, ptx, pty, 0))
        {
            intersectPoint.x = ptx;
            intersectPoint.y = pty;
            return true;
        }
        return false;
    }
}

