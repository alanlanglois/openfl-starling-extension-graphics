package starling.display.graphics;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.textures.Texture;

class TriangleFan extends Graphic
{
    private var numVertices : Int;
    
    public function new()
    {
        super();
        vertices.push(0);
        vertices.push(0);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(0);
        vertices.push(0);
        
        numVertices++;
    }
    
    public function addVertex(x : Float, y : Float, u : Float = 0, v : Float = 0, r : Float = 1, g : Float = 1, b : Float = 1, a : Float = 1) : Void
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
            indices.push(0);
            indices.push(numVertices - 2);
            indices.push(numVertices - 1);
            
        }
        
        setGeometryInvalid();
    }
    
    public function modifyVertexPosition(index : Int, x : Float, y : Float) : Void
    {
        vertices[index * 9] = x;
        vertices[index * 9 + 1] = y;
        
        if (buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    public function modifyVertexColor(index : Int, r : Float = 1, g : Float = 1, b : Float = 1, a : Float = 1) : Void
    {
        vertices[index * 9 + 3] = r;
        vertices[index * 9 + 4] = g;
        vertices[index * 9 + 5] = b;
        vertices[index * 9 + 6] = a;
        
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
    
    override private function buildGeometry() : Void
    {
    }
}
