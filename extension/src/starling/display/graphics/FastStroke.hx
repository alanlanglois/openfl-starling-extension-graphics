package starling.display.graphics;

import flash.geom.Point;
import starling.display.graphics.StrokeVertex;
import starling.textures.Texture;
import starling.core.Starling;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import starling.core.RenderSupport;
import starling.display.BlendMode;
import starling.errors.MissingContextError;

class FastStroke extends Graphic
{
    private var _line : Array<StrokeVertex>;
    
    private var _lastX : Float;
    private var _lastY : Float;
    private var _lastR : Float;
    private var _lastG : Float;
    private var _lastB : Float;
    private var _lastA : Float;
    private var _lastThickness : Float;
    
    private var _numControlPoints : Int;
    private var _capacity : Int = -1;
    private var _numVertIndex : Int = 0;
    private var _numVerts : Int = 0;
    
    private var _verticesBufferAllocLen : Int = 0;
    private var _indicesBufferAllocLen : Int = 0;
    
    private var INDEX_STRIDE_FOR_QUAD : Int = 6;
    
    private var _lostContext : Bool = false;
    
    
    public function new()
    {
        super();
        clear();
    }
    
    public function setCapacity(capacity : Int) : Void
    {
        if (capacity > _capacity)
        {
            clear();
            vertices = new Array<Float>();
            indices = new Array<Int>();
            _capacity = capacity;
        }
    }
    
    public function moveTo(x : Float, y : Float, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        setCurrentPosition(x, y);
        setCurrentColor(color, alpha);
        setCurrentThickness(thickness);
    }
    
    
    public function lineTo(x : Float, y : Float, thickness : Float = 1.0, color : Int = 0xFFFFFF, a : Float = 1.0) : Void
    {
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        var halfThickness : Float = (0.5 * thickness);
        
        var dx : Float = x - _lastX;
        var dy : Float = y - _lastY;
        var halfLastThickness : Float = _lastThickness * 0.5;
        if (dy == 0)
        {
            pushVerts(vertices, _numControlPoints, _lastX, _lastY + halfLastThickness, _lastX, _lastY - halfLastThickness, _lastR, _lastG, _lastB, _lastA);
            pushVerts(vertices, _numControlPoints + 1, x, y + halfThickness, x, y - halfThickness, r, g, b, a);
        }
        else
        {
            if (dx == 0)
            {
                pushVerts(vertices, _numControlPoints, _lastX + halfLastThickness, _lastY, _lastX - halfLastThickness, _lastY, _lastR, _lastG, _lastB, _lastA);
                pushVerts(vertices, _numControlPoints + 1, x + halfThickness, y, x - halfThickness, y, r, g, b, a);
            }
            else
            {
                var d : Float = Math.sqrt(dx * dx + dy * dy);
                
                var nx : Float = -dy / d;
                var ny : Float = dx / d;
                
                var cnx : Float = nx;
                var cny : Float = ny;
                
                var cnInv : Float = (1 / Math.sqrt(cnx * cnx + cny * cny));
                var c : Float = cnInv * halfLastThickness;
                cnx = nx * c;
                cny = ny * c;
                
                var v1xPos : Float = _lastX + cnx;
                var v1yPos : Float = _lastY + cny;
                var v1xNeg : Float = _lastX - cnx;
                var v1yNeg : Float = _lastY - cny;
                
                pushVerts(vertices, _numControlPoints, v1xPos, v1yPos, v1xNeg, v1yNeg, _lastR, _lastG, _lastB, _lastA);
                
                c = cnInv * halfThickness;
                cnx = nx * c;
                cny = ny * c;
                
                v1xPos = x + cnx;
                v1yPos = y + cny;
                v1xNeg = x - cnx;
                v1yNeg = y - cny;
                
                pushVerts(vertices, _numControlPoints + 1, v1xPos, v1yPos, v1xNeg, v1yNeg, r, g, b, a);
            }
        }
        
        _lastX = x;
        _lastY = y;
        _lastR = r;
        _lastG = g;
        _lastB = b;
        _lastA = a;
        _lastThickness = thickness;
        
        // This needs fixing, not accurate at the moment, since thickness is ignored here.
        minBounds.x = (x < minBounds.x) ? x : minBounds.x;
        minBounds.y = (y < minBounds.y) ? y : minBounds.y;
        maxBounds.x = (x > maxBounds.x) ? x : maxBounds.x;
        
        maxBounds.y = (y > maxBounds.y) ? y : maxBounds.y;
        
        if (_numControlPoints < (_capacity) * 2)
        {
            var i : Int = _numControlPoints;
            var i2 : Int = as3hx.Compat.parseInt(i << 1);
            
            var counter : Int = as3hx.Compat.parseInt(i * INDEX_STRIDE_FOR_QUAD);
            indices[counter++] = i2;
            indices[counter++] = i2 + 2;
            indices[counter++] = i2 + 1;
            indices[counter++] = i2 + 1;
            indices[counter++] = i2 + 2;
            indices[counter++] = i2 + 3;
            
            _numVertIndex += INDEX_STRIDE_FOR_QUAD * 2;
        }
        
        _numControlPoints += 2;
        _numVerts += 18 * 2;
        
        if (buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    
    override public function dispose() : Void
    {
        clear();
        vertices = new Array<Float>();
        indices = new Array<Int>();
        
        super.dispose();
        _capacity = -1;
    }
    
    public function clear() : Void
    {
        _numControlPoints = 0;
        _numVerts = 0;
        _numVertIndex = 0;
        _lastX = 0;
        _lastY = 0;
        _lastThickness = 1;
        _lastR = _lastG = _lastB = _lastA = 1.0;
        
        setGeometryInvalid();
    }
    
    override private function buildGeometry() : Void
    {
    }
    
    
    private function setCurrentPosition(x : Float, y : Float) : Void
    {
        _lastX = x;
        _lastY = y;
    }
    
    private function setCurrentColor(color : Int, alpha : Float = 1) : Void
    {
        _lastR = (color >> 16) / 255;
        _lastG = ((color & 0x00FF00) >> 8) / 255;
        _lastB = (color & 0x0000FF) / 255;
        _lastA = alpha;
    }
    
    private function setCurrentThickness(thickness : Float) : Void
    {
        _lastThickness = thickness;
    }
    
    override private function shapeHitTestLocalInternal(localX : Float, localY : Float) : Bool
    {
        if (_line == null)
        {
            return false;
        }
        if (_line.length < 2)
        {
            return false;
        }
        
        var numLines : Int = _line.length;
        
        for (i in 1...numLines)
        {
            var v0 : StrokeVertex = _line[i - 1];
            var v1 : StrokeVertex = _line[i];
            
            var lineLengthSquared : Float = (v1.x - v0.x) * (v1.x - v0.x) + (v1.y - v0.y) * (v1.y - v0.y);
            
            var interpolation : Float = (((localX - v0.x) * (v1.x - v0.x)) + ((localY - v0.y) * (v1.y - v0.y))) / (lineLengthSquared);
            if (interpolation < 0.0 || interpolation > 1.0)
            {
                continue;
            }  // closest point does not fall within the line segment  
            
            var intersectionX : Float = v0.x + interpolation * (v1.x - v0.x);
            var intersectionY : Float = v0.y + interpolation * (v1.y - v0.y);
            
            var distanceSquared : Float = (localX - intersectionX) * (localX - intersectionX) + (localY - intersectionY) * (localY - intersectionY);
            
            var intersectThickness : Float = (v0.thickness * (1.0 - interpolation) + v1.thickness * interpolation);  // Support for varying thicknesses  
            
            intersectThickness += _precisionHitTestDistance;
            
            if (distanceSquared <= intersectThickness * intersectThickness)
            {
                return true;
            }
        }
        
        return false;
    }
    
    override public function validateNow() : Void
    {
        if (geometryInvalid == false)
        {
            return;
        }
        
        
        if (vertexBuffer && (buffersInvalid || uvsInvalid))
        {  //		vertexBuffer.dispose();  
            //		indexBuffer.dispose();
            
        }
        
        if (buffersInvalid || geometryInvalid)
        {
            buildGeometry();
            applyUVMatrix();
        }
        else
        {
            if (uvsInvalid)
            {
                applyUVMatrix();
            }
        }
    }
    
    override public function render(renderSupport : RenderSupport, parentAlpha : Float) : Void
    {
        validateNow();
        
        if (indices.length < 3)
        {
            return;
        }
        
        var numIndices : Int = _numVertIndex;
        if (buffersInvalid || uvsInvalid)
        {
            // Upload vertex/index buffers.
            
            var numVertices : Int = as3hx.Compat.parseInt(_numControlPoints * 2);
            if (numVertices > _verticesBufferAllocLen || _lostContext)
            {
                if (vertexBuffer != null)
                {
                    vertexBuffer.dispose();
                }
                vertexBuffer = Starling.context.createVertexBuffer(numVertices, VERTEX_STRIDE);
                _verticesBufferAllocLen = numVertices;
            }
            
            vertexBuffer.uploadFromVector(vertices, 0, numVertices);
            
            if (numIndices > _indicesBufferAllocLen || _lostContext)
            {
                if (indexBuffer != null)
                {
                    indexBuffer.dispose();
                }
                indexBuffer = Starling.context.createIndexBuffer(numIndices);
                _indicesBufferAllocLen = numIndices;
            }
            
            indexBuffer.uploadFromVector(indices, 0, numIndices);
            
            _lostContext = buffersInvalid = uvsInvalid = false;
        }
        
        
        // always call this method when you write custom rendering code!
        // it causes all previously batched quads/images to render.
        renderSupport.finishQuadBatch();
        renderSupport.raiseDrawCount();
        
        var context : Context3D = Starling.context;
        if (context == null)
        {
            throw new MissingContextError();
        }
        
        RenderSupport.setBlendFactors(material.premultipliedAlpha, (this.blendMode == BlendMode.AUTO) ? renderSupport.blendMode : this.blendMode);
        _material.drawTriangles(Starling.context, renderSupport.mvpMatrix3D, vertexBuffer, indexBuffer, parentAlpha * this.alpha, _numVertIndex / 3);
        
        context.setTextureAt(0, null);
        context.setTextureAt(1, null);
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
        context.setVertexBufferAt(2, null);
    }
    
    @:meta(inline())

    private static function pushVerts(vertices : Array<Float>, _numControlPoints : Float, x1 : Float, y1 : Float, x2 : Float, y2 : Float, r : Float, g : Float, b : Float, a : Float) : Void
    {
        var u : Float = 0;  // Todo uv mapping in this case?  
        var i : Int = as3hx.Compat.parseInt(_numControlPoints * 18);
        vertices[i++] = x1;
        vertices[i++] = y1;
        vertices[i++] = 0;
        vertices[i++] = r;
        vertices[i++] = g;
        vertices[i++] = b;
        vertices[i++] = a;
        vertices[i++] = u;
        vertices[i++] = 0;
        
        vertices[i++] = x2;
        vertices[i++] = y2;
        vertices[i++] = 0;
        vertices[i++] = r;
        vertices[i++] = g;
        vertices[i++] = b;
        vertices[i++] = a;
        vertices[i++] = u;
        vertices[i++] = 1;
    }
    
    override private function onGraphicLostContext() : Void
    {
        _lostContext = true;
    }
}

