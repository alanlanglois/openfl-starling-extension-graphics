package starling.display.util;

import haxe.Constraints.Function;

class CurveUtil
{
    // State variables for quadratic subdivision.
    private static inline var STEPS : Int = 8;
    public static inline var BEZIER_ERROR : Float = 0.75;
    private static var _subSteps : Int = 0;
    private static var _bezierError : Float = BEZIER_ERROR;
    
    // ax1, ay1, cx, cy, ax2, ay2 for quadratic, or
    // ax1, ay1, cx1, cy1, cx2, cy2, ax2, ay2 for cubic
    private static var _terms : Array<Float> = new Array<Float>();
    
    public static function quadraticCurve(a1x : Float, a1y : Float, cx : Float, cy : Float, a2x : Float, a2y : Float, error : Float = BEZIER_ERROR) : Array<Float>
    {
        _subSteps = 0;
        _bezierError = error;
        
        _terms[0] = a1x;
        _terms[1] = a1y;
        _terms[2] = cx;
        _terms[3] = cy;
        _terms[4] = a2x;
        _terms[5] = a2y;
        
        var output : Array<Float> = new Array<Float>();
        
        subdivideQuadratic(0.0, 0.5, 0, output);
        subdivideQuadratic(0.5, 1.0, 0, output);
        
        return output;
    }
    
    public static function cubicCurve(a1x : Float, a1y : Float, c1x : Float, c1y : Float, c2x : Float, c2y : Float, a2x : Float, a2y : Float, error : Float = BEZIER_ERROR) : Array<Float>
    {
        _subSteps = 0;
        _bezierError = error;
        
        _terms[0] = a1x;
        _terms[1] = a1y;
        _terms[2] = c1x;
        _terms[3] = c1y;
        _terms[4] = c2x;
        _terms[5] = c2y;
        _terms[6] = a2x;
        _terms[7] = a2y;
        
        var output : Array<Float> = new Array<Float>();
        
        subdivideCubic(0.0, 0.5, 0, output);
        subdivideCubic(0.5, 1.0, 0, output);
        
        return output;
    }
    
    private static function quadratic(t : Float, axis : Int) : Float
    {
        var oneMinusT : Float = (1.0 - t);
        var a1 : Float = _terms[0 + axis];
        var c : Float = _terms[2 + axis];
        var a2 : Float = _terms[4 + axis];
        return (oneMinusT * oneMinusT * a1) + (2.0 * oneMinusT * t * c) + t * t * a2;
    }
    
    private static function cubic(t : Float, axis : Int) : Float
    {
        var oneMinusT : Float = (1.0 - t);
        
        var a1 : Float = _terms[0 + axis];
        var c1 : Float = _terms[2 + axis];
        var c2 : Float = _terms[4 + axis];
        var a2 : Float = _terms[6 + axis];
        return (oneMinusT * oneMinusT * oneMinusT * a1) + (3.0 * oneMinusT * oneMinusT * t * c1) + (3.0 * oneMinusT * t * t * c2) + t * t * t * a2;
    }
    
    /* Subdivide until an error metric is hit.
		* Uses depth first recursion, so that lineTo() can be called directory,
		* and the calls will be in the currect order.
		*/
    private static function subdivide(t0 : Float, t1 : Float, depth : Int, equation : Function, output : Array<Float>) : Void
    {
        var quadX : Float = equation((t0 + t1) * 0.5, 0);
        var quadY : Float = equation((t0 + t1) * 0.5, 1);
        
        var x0 : Float = equation(t0, 0);
        var y0 : Float = equation(t0, 1);
        var x1 : Float = equation(t1, 0);
        var y1 : Float = equation(t1, 1);
        
        var midX : Float = (x0 + x1) * 0.5;
        var midY : Float = (y0 + y1) * 0.5;
        
        var dx : Float = quadX - midX;
        var dy : Float = quadY - midY;
        
        var error2 : Float = dx * dx + dy * dy;
        
        if (error2 > (_bezierError * _bezierError))
        {
            subdivide(t0, (t0 + t1) * 0.5, depth + 1, equation, output);
            subdivide((t0 + t1) * 0.5, t1, depth + 1, equation, output);
        }
        else
        {
            ++_subSteps;
            output.push(x1);
            output.push(y1);
            
        }
    }
    
    private static function subdivideQuadratic(t0 : Float, t1 : Float, depth : Int, output : Array<Float>) : Void
    {
        var quadX : Float = quadratic((t0 + t1) * 0.5, 0);
        var quadY : Float = quadratic((t0 + t1) * 0.5, 1);
        
        var x0 : Float = quadratic(t0, 0);
        var y0 : Float = quadratic(t0, 1);
        var x1 : Float = quadratic(t1, 0);
        var y1 : Float = quadratic(t1, 1);
        
        var midX : Float = (x0 + x1) * 0.5;
        var midY : Float = (y0 + y1) * 0.5;
        
        var dx : Float = quadX - midX;
        var dy : Float = quadY - midY;
        
        var error2 : Float = dx * dx + dy * dy;
        
        if (error2 > (_bezierError * _bezierError))
        {
            subdivideQuadratic(t0, (t0 + t1) * 0.5, depth + 1, output);
            subdivideQuadratic((t0 + t1) * 0.5, t1, depth + 1, output);
        }
        else
        {
            ++_subSteps;
            output.push(x1);
            output.push(y1);
            
        }
    }
    
    private static function subdivideCubic(t0 : Float, t1 : Float, depth : Int, output : Array<Float>) : Void
    {
        var quadX : Float = cubic((t0 + t1) * 0.5, 0);
        var quadY : Float = cubic((t0 + t1) * 0.5, 1);
        
        var x0 : Float = cubic(t0, 0);
        var y0 : Float = cubic(t0, 1);
        var x1 : Float = cubic(t1, 0);
        var y1 : Float = cubic(t1, 1);
        
        var midX : Float = (x0 + x1) * 0.5;
        var midY : Float = (y0 + y1) * 0.5;
        
        var dx : Float = quadX - midX;
        var dy : Float = quadY - midY;
        
        var error2 : Float = dx * dx + dy * dy;
        
        if (error2 > (_bezierError * _bezierError))
        {
            subdivideCubic(t0, (t0 + t1) * 0.5, depth + 1, output);
            subdivideCubic((t0 + t1) * 0.5, t1, depth + 1, output);
        }
        else
        {
            ++_subSteps;
            output.push(x1);
            output.push(y1);
            
        }
    }

    public function new()
    {
    }
}
