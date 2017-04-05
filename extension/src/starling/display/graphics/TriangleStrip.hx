package starling.display.graphics;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.textures.Texture;
import starling.display.graphics.util.TriangleUtil;

class TriangleStrip extends Graphic
{
    private var numVertices : Int;
    
    public function new()
    {
        super();
    }
    
    public function addVertex(x : Float, y : Float,
            u : Float = 0, v : Float = 0,
            r : Float = 1, g : Float = 1, b : Float = 1, a : Float = 1) : Void
    {
        vertices.push(x);
        vertices.push(y);
        vertices.push(0);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
        vertices.push(a);
        vertices.push(u);
        vertices.push(v);
        
        numVertices++;
        
        minBounds.x = (x < minBounds.x) ? x : minBounds.x;
        minBounds.y = (y < minBounds.y) ? y : minBounds.y;
        maxBounds.x = (x > maxBounds.x) ? x : maxBounds.x;
        maxBounds.y = (y > maxBounds.y) ? y : maxBounds.y;
        
        if (numVertices > 2)
        {
            indices.push(numVertices - 3);
            indices.push(numVertices - 2);
            indices.push(numVertices - 1);
            
        }
        
        if (buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    public function clear() : Void
    {
        as3hx.Compat.setArrayLength(vertices, 0);
        as3hx.Compat.setArrayLength(indices, 0);
        numVertices = 0;
        setGeometryInvalid();
    }
    
    override private function shapeHitTestLocalInternal(localX : Float, localY : Float) : Bool
    {
        var numIndices : Int = indices.length;
        if (numIndices < 2)
        {
            return false;
        }
        
        var i : Int = 2;
        while (i < numIndices)
        {
            // slower version - should be complete though. For all triangles, check if point is in triangle
            var i0 : Int = indices[(i - 2)];
            var i1 : Int = indices[(i - 1)];
            var i2 : Int = indices[(i - 0)];
            
            var v0x : Float = vertices[VERTEX_STRIDE * i0 + 0];
            var v0y : Float = vertices[VERTEX_STRIDE * i0 + 1];
            var v1x : Float = vertices[VERTEX_STRIDE * i1 + 0];
            var v1y : Float = vertices[VERTEX_STRIDE * i1 + 1];
            var v2x : Float = vertices[VERTEX_STRIDE * i2 + 0];
            var v2y : Float = vertices[VERTEX_STRIDE * i2 + 1];
            if (TriangleUtil.isPointInTriangleBarycentric(v0x, v0y, v1x, v1y, v2x, v2y, localX, localY))
            {
                return true;
            }
            if (_precisionHitTestDistance > 0)
            {
                if (TriangleUtil.isPointOnLine(v0x, v0y, v1x, v1y, localX, localY, _precisionHitTestDistance))
                {
                    return true;
                }
                if (TriangleUtil.isPointOnLine(v0x, v0y, v2x, v2y, localX, localY, _precisionHitTestDistance))
                {
                    return true;
                }
                if (TriangleUtil.isPointOnLine(v1x, v1y, v2x, v2y, localX, localY, _precisionHitTestDistance))
                {
                    return true;
                }
            }
            i += 3;
        }
        return false;
    }
    
    override private function buildGeometry() : Void
    {
    }
}

