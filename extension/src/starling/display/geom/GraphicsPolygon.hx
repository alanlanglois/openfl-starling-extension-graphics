package starling.display.geom;

import openfl.Vector;
import starling.geom.Polygon;

/**
	 * ...
	 * @author IonSwitz
	 */
class GraphicsPolygon extends Polygon
{
    private var indices : Vector<Int>;
    
    public var lastVertexIndex : Int = -1;
    public var lastIndexIndex : Int = -1;
    //	protected var lastTriangulatedIndex:int = -1;
    
    public function new(vertices : Vector<Dynamic> = null, gfxIndices : Vector<Int> = null)
    {
        super(vertices);
        if (vertices != null)
        {
            lastVertexIndex = as3hx.Compat.parseInt(vertices.length - 1);
        }
        
        if (gfxIndices != null)
        {
            indices = gfxIndices.copy();
            lastIndexIndex = indices.length;
        }
        else
        {
            indices = new Vector<Int>();
        }
    }
    
    public function append(vertices : Vector<Dynamic>, gfxIndices : Vector<Int>) : Void
    {
        var i : Int;
        var num : Int = vertices.length;
        if (num == 0)
        {
            return;
        }
        
        if (lastVertexIndex == -1)
        {
            lastVertexIndex = 0;
        }
        
        for (i in 0...num)
        {
            addVertices(vertices[i]);
        }
        lastVertexIndex += Std.int(num / 2);
        
        var startIndex : Int = lastIndexIndex == -(1) ? 0 : lastIndexIndex;
        num = gfxIndices.length;
        for (i in startIndex...num)
        {
            indices.push(gfxIndices[i]);
        }
        
        lastIndexIndex = indices.length;
    }
    
    
    override public function triangulate(result : Vector<Int> = null) : Vector<Int>
    {
        if (result == null)
        {
            result = new Vector<Int>();
        }
        var numIndices : Int = indices.length;
        
        //		var startIndex:int = lastTriangulatedIndex <= 0 ? 0: lastTriangulatedIndex;
        for (i in 0...numIndices)
        {
            result.push(indices[i]);
        }
        
        //		lastTriangulatedIndex = numIndices - 1;
        
        return result;
    }
    
    /** Indicates if the polygon's line segments are not self-intersecting. */
    override private function get_isSimple() : Bool
    {
        return true;
    }
}

