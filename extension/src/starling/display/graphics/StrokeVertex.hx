package starling.display.graphics;
import openfl.Vector;


class StrokeVertex
{
    public var x : Float;
    public var y : Float;
    public var u : Float;
    public var v : Float;
    public var r1 : Float;
    public var g1 : Float;
    public var b1 : Float;
    public var a1 : Float;
    public var r2 : Float;
    public var g2 : Float;
    public var b2 : Float;
    public var a2 : Float;
    public var thickness : Float;
    public var degenerate : Int;
    
    public function new()
    {
    }
    
    public function clone() : StrokeVertex
    {
        var vertex : StrokeVertex = getInstance();
        vertex.x = x;
        vertex.y = y;
        vertex.r1 = r1;
        vertex.g1 = g1;
        vertex.b1 = b1;
        vertex.a1 = a1;
        vertex.u = u;
        vertex.v = v;
        vertex.degenerate = degenerate;
        return vertex;
    }
    
    private static var pool : Vector<StrokeVertex> = new Vector<StrokeVertex>();
    private static var poolLength : Int = 0;
    
    public static function getInstance() : StrokeVertex
    {
        if (poolLength == 0)
        {
            return new StrokeVertex();
        }
        poolLength--;
        return pool.pop();
    }
    
    public static function returnInstance(instance : StrokeVertex) : Void
    {
        pool[poolLength] = instance;
        poolLength++;
    }
    
    public static function returnInstances(instances : Vector<StrokeVertex>) : Void
    {
        var L : Int = instances.length;
        for (i in 0...L)
        {
            pool[poolLength] = instances[i];
            poolLength++;
        }
    }
}

