package starling.display.graphics;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import openfl.Vector;
import openfl.utils.Dictionary;
import starling.display.geom.GraphicsPolygon;
import starling.display.graphics.util.IGraphicDrawHelper;
import starling.geom.Polygon;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.DisplayObject;
import starling.display.materials.IMaterial;
import starling.display.materials.StandardMaterial;
import starling.display.shaders.fragment.VertexColorFragmentShader;
import starling.display.shaders.vertex.StandardVertexShader;
import starling.errors.AbstractMethodError;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.utils.PowerOfTwo;
import starling.textures.Texture;
import starling.textures.SubTexture;

/**
	 * Abstract, do not instantiate directly
	 * Used as a base-class for all the drawing API sub-display objects (Like Fill and Stroke).
	 */
class Graphic extends DisplayObject
{
    public var material(get, set) : IMaterial;
    public var uvMatrix(get, set) : Matrix;
    public var precisionHitTest(get, set) : Bool;
    public var precisionHitTestDistance(get, set) : Float;
    public var graphicDrawHelper(get, set) : IGraphicDrawHelper;

    private static inline var VERTEX_STRIDE : Int = 9;
    private static var sHelperMatrix : Matrix = new Matrix();
    private static var defaultVertexShaderDictionary:Dictionary<Starling, Dynamic>;
    private static var defaultFragmentShaderDictionary:Dictionary<Starling, Dynamic>;
    
    private var _material : IMaterial;
    private var vertexBuffer : VertexBuffer3D;
    private var indexBuffer : IndexBuffer3D;
    private var vertices : Vector<Float>;
    private var indices : Vector<Int>;
    private var _uvMatrix : Matrix;
    
    private var buffersInvalid : Bool = false;
    private var geometryInvalid : Bool = false;
    private var uvsInvalid : Bool = false;
    private var uvMappingsChanged : Bool = false;
    private var isGeometryScaled : Bool = false;
    
    
    //	protected var hasValidatedGeometry:Boolean = false;
    
    private static var sGraphicHelperRect : Rectangle = new Rectangle();
    private static var sGraphicHelperPoint : Point = new Point();
    private static var sGraphicHelperPointTR : Point = new Point();
    private static var sGraphicHelperPointBL : Point = new Point();
    
    // Filled-out with min/max vertex positions
    // during addVertex(). Used during getBounds().
    private var minBounds : Point;
    private var maxBounds : Point;
    
    // used for geometry level hit tests. False gives boundingbox results, True gives geometry level results.
    // True is a lot more exact, but also slower.
    private var _precisionHitTest : Bool = false;
    private var _precisionHitTestDistance : Float = 0;  // This is added to the thickness of the line when doing precisionHitTest to make it easier to hit 1px lines etc  
    
    // Attempt to allow partial rendering of graphics. Mostly useful for Strokes, I would guess.
    private var _graphicDrawHelper : IGraphicDrawHelper = null;
    
    public function new()
    {
        super();
		defaultVertexShaderDictionary = new Dictionary(true);
		defaultFragmentShaderDictionary = new Dictionary(true);
        indices = new Vector<Int>();
        vertices = new Vector<Float>();
        
        var currentStarling : Starling = Starling.current;
        
        var vertexShader : StandardVertexShader = defaultVertexShaderDictionary[currentStarling];
        if (vertexShader == null)
        {
            vertexShader = new StandardVertexShader();
            defaultVertexShaderDictionary[currentStarling] = vertexShader;
        }
        
        var fragmentShader : VertexColorFragmentShader = defaultFragmentShaderDictionary[currentStarling];
        if (fragmentShader == null)
        {
            fragmentShader = new VertexColorFragmentShader();
            defaultFragmentShaderDictionary[currentStarling] = fragmentShader;
        }
        
        _material = new StandardMaterial(vertexShader, fragmentShader);
        
        minBounds = new Point();
        maxBounds = new Point();
        
        if (Starling.current != null)
        {
            Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }
    }
    
    private function onContextCreated(event : Event) : Void
    {
        geometryInvalid = true;
        
        buffersInvalid = true;
        uvsInvalid = true;
        _material.restoreOnLostContext();
        
        onGraphicLostContext();
    }
    
    private function onGraphicLostContext() : Void
    {
    }
    
    override public function dispose() : Void
    {
        if (Starling.current != null)
        {
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            super.dispose();
        }
        
        if (vertexBuffer != null)
        {
            vertexBuffer.dispose();
            vertexBuffer = null;
        }
        
        if (indexBuffer != null)
        {
            indexBuffer.dispose();
            indexBuffer = null;
        }
        
        if (material != null)
        {
            //material.dispose(); Material should NOT be disposed here. It can be used elsewhere - Graphic is NOT owner of Material.
            material.releaseProgramRef();  // However, the material needs to release a reference count in the program cache, through this new method.  
            material = null;
        }
        
        vertices = null;
        indices = null;
        _uvMatrix = null;
        minBounds = null;
        maxBounds = null;
        
        geometryInvalid = true;
    }
    
    private function set_material(value : IMaterial) : IMaterial
    {
        _material = value;
        return value;
    }
    
    private function get_material() : IMaterial
    {
        return _material;
    }
    
    private function get_uvMatrix() : Matrix
    {
        return _uvMatrix;
    }
    
    private function set_uvMatrix(value : Matrix) : Matrix
    {
        _uvMatrix = value;
        uvsInvalid = true;
        geometryInvalid = true;
        return value;
    }
    
    
    public function shapeHitTest(stageX : Float, stageY : Float) : Bool
    {
        var pt : Point = globalToLocal(new Point(stageX, stageY));
        return pt.x >= minBounds.x && pt.x <= maxBounds.x && pt.y >= minBounds.y && pt.y <= maxBounds.y;
    }
    
    private function set_precisionHitTest(value : Bool) : Bool
    {
        _precisionHitTest = value;
        return value;
    }
    private function get_precisionHitTest() : Bool
    {
        return _precisionHitTest;
    }
    private function set_precisionHitTestDistance(value : Float) : Float
    {
        _precisionHitTestDistance = value;
        return value;
    }
    private function get_precisionHitTestDistance() : Float
    {
        return _precisionHitTestDistance;
    }
    
    private function shapeHitTestLocalInternal(localX : Float, localY : Float) : Bool
    {
        return localX >= (minBounds.x - _precisionHitTestDistance) && localX <= (maxBounds.x + _precisionHitTestDistance) && localY >= (minBounds.y - _precisionHitTestDistance) && localY <= (maxBounds.y + _precisionHitTestDistance);
    }
    
    /** Returns the object that is found topmost beneath a point in local coordinates, or nil if 
     *  the test fails. If "forTouch" is true, untouchable and invisible objects will cause
     *  the test to fail. */
    override public function hitTest(localPoint : Point, forTouch : Bool = false) : DisplayObject
    {
        // on a touch test, invisible or untouchable objects cause the test to fail
        if (forTouch && (visible == false || touchable == false))
        {
            return null;
        }
        if (minBounds == null || maxBounds == null)
        {
            return null;
        }
        
        // otherwise, check bounding box
        if (getBounds(this, sGraphicHelperRect).containsPoint(localPoint))
        {
            if (_precisionHitTest)
            {
                if (shapeHitTestLocalInternal(localPoint.x, localPoint.y))
                {
                    return this;
                }
            }
            else
            {
                return this;
            }
        }
        
        return null;
    }
    
    override public function getBounds(targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
    {
        if (resultRect == null)
        {
            resultRect = new Rectangle();
        }
        
        if (targetSpace == this)
        {
            // optimization
            {
                resultRect.x = minBounds.x;
                resultRect.y = minBounds.y;
                resultRect.right = maxBounds.x;
                resultRect.bottom = maxBounds.y;
                if (_precisionHitTest)
                {
                    resultRect.x -= _precisionHitTestDistance;
                    resultRect.y -= _precisionHitTestDistance;
                    resultRect.width += _precisionHitTestDistance * 2;
                    resultRect.height += _precisionHitTestDistance * 2;
                }
                
                return resultRect;
            }
        }
        
        getTransformationMatrix(targetSpace, sHelperMatrix);
        var m : Matrix = sHelperMatrix;
        
        sGraphicHelperPointTR.x = minBounds.x + (maxBounds.x - minBounds.x);
        sGraphicHelperPointTR.y = minBounds.y;
        sGraphicHelperPointBL.x = minBounds.x;
        sGraphicHelperPointBL.y = minBounds.y + (maxBounds.y - minBounds.y);
        /*
			 * Old version, 2 point allocations
			 * var tr:Point = new Point(minBounds.x + (maxBounds.x - minBounds.x), minBounds.y);
			 * var bl:Point = new Point(minBounds.x , minBounds.y + (maxBounds.y - minBounds.y));
			 */
        
        var TL : Point = sHelperMatrix.transformPoint(minBounds);
        sGraphicHelperPointTR = sHelperMatrix.transformPoint(sGraphicHelperPointTR);
        var BR : Point = sHelperMatrix.transformPoint(maxBounds);
        sGraphicHelperPointBL = sHelperMatrix.transformPoint(sGraphicHelperPointBL);
        
        /*
			 * Old version, 2 point allocations through clone
			 var TL:Point = sHelperMatrix.transformPoint(minBounds.clone());
			 tr = sHelperMatrix.transformPoint(bl);
			 var BR:Point = sHelperMatrix.transformPoint(maxBounds.clone());
			 bl = sHelperMatrix.transformPoint(bl);
			*/
        
        
        resultRect.x = Math.min(Math.min(Math.min(TL.x, BR.x), sGraphicHelperPointTR.x), sGraphicHelperPointBL.x);
        resultRect.y = Math.min(Math.min(Math.min(TL.y, BR.y), sGraphicHelperPointTR.y), sGraphicHelperPointBL.y);
        resultRect.right = Math.max(Math.max(Math.max(TL.x, BR.x), sGraphicHelperPointTR.x), sGraphicHelperPointBL.x);
        resultRect.bottom = Math.max(Math.max(Math.max(TL.y, BR.y), sGraphicHelperPointTR.y), sGraphicHelperPointBL.y);
        if (_precisionHitTest)
        {
            resultRect.x -= _precisionHitTestDistance;
            resultRect.y -= _precisionHitTestDistance;
            resultRect.width += _precisionHitTestDistance * 2;
            resultRect.height += _precisionHitTestDistance * 2;
        }
        return resultRect;
    }
    
    private function buildGeometry() : Void
    {
        throw (new AbstractMethodError());
    }
    
    private function applyUVMatrix() : Void
    {
        if (vertices == null)
        {
            return;
        }
        if (_uvMatrix == null)
        {
            return;
        }
        
        var uv : Point = new Point();
        var i : Int = 0;
        while (i < vertices.length)
        {
            uv.x = vertices[i + 7];
            uv.y = vertices[i + 8];
            uv = _uvMatrix.transformPoint(uv);
            vertices[i + 7] = uv.x;
            vertices[i + 8] = uv.y;
            i += VERTEX_STRIDE;
        }
    }
    
    public function adjustUVMappings(x : Float, y : Float, texture : Texture) : Void
    {
        var w : Float = PowerOfTwo.getNextPowerOfTwo(Std.int(texture.nativeWidth));
        var h : Float = PowerOfTwo.getNextPowerOfTwo(Std.int(texture.nativeHeight));
        
        var invW : Float = 1.0 / w;
        var invH : Float = 1.0 / h;
        
        var vertX : Float;
        var vertY : Float;
        var u : Float;
        var v : Float;
        
        if (vertices == null || vertices.length == 0)
        {
            return;
        }
        var numVerts : Int = vertices.length;
        var i : Int = 0;
        while (i < numVerts)
        {
            vertX = vertices[i];
            vertY = vertices[i + 1];
            
            u = (x + vertX) * invW;
            v = (y + vertY) * invH;
            
            vertices[i + 7] = u;
            vertices[i + 8] = v;
            i += VERTEX_STRIDE;
        }
        
        uvMappingsChanged = true;
        _uvMatrix = null;
    }
    
    
    public function validateNow() : Void
    {
        if (geometryInvalid == false && uvMappingsChanged == false)
        {
            return;
        }
        
        if (vertexBuffer != null && (buffersInvalid || uvsInvalid || isGeometryScaled))
        {
            vertexBuffer.dispose();
            indexBuffer.dispose();
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
    
    private function setGeometryInvalid(invalidateBuffers : Bool = true) : Void
    {
        if (invalidateBuffers)
        {
            buffersInvalid = true;
        }
        geometryInvalid = true;
    }
    
    override public function render(renderSupport : RenderSupport, parentAlpha : Float) : Void
    {
        validateNow();
        
        if (indices == null || indices.length < 3)
        {
            return;
        }
        
        if (buffersInvalid || uvsInvalid || isGeometryScaled)
        {
            // Upload vertex/index buffers.
            var numVertices : Int = as3hx.Compat.parseInt(vertices.length / VERTEX_STRIDE);
            vertexBuffer = Starling.current.context.createVertexBuffer(numVertices, VERTEX_STRIDE);
            vertexBuffer.uploadFromVector(vertices, 0, numVertices);
            indexBuffer = Starling.current.context.createIndexBuffer(indices.length);
            indexBuffer.uploadFromVector(indices, 0, indices.length);
            buffersInvalid = uvsInvalid = isGeometryScaled = geometryInvalid = false;
        }
        else
        {
            if (geometryInvalid || uvMappingsChanged)
            {
                vertexBuffer.uploadFromVector(vertices, 0, Std.int(vertices.length / VERTEX_STRIDE));
                indexBuffer.uploadFromVector(indices, 0, indices.length);
                geometryInvalid = false;
                uvMappingsChanged = false;
            }
        }
        
        var context : Context3D = Starling.current.context;
        if (context == null)
        {
            throw new MissingContextError();
        }
        
        // always call this method when you write custom rendering code!
        // it causes all previously batched quads/images to render.
        renderSupport.finishQuadBatch();
        
        if (_graphicDrawHelper != null)
        {
            _graphicDrawHelper.onDrawTriangles(_material, renderSupport, vertexBuffer, indexBuffer, parentAlpha * this.alpha);
        }
        else
        {
            RenderSupport.setBlendFactors(_material.premultipliedAlpha, (this.blendMode == BlendMode.AUTO) ? renderSupport.blendMode : this.blendMode);
            _material.drawTriangles(Starling.current.context, renderSupport.mvpMatrix3D, vertexBuffer, indexBuffer, parentAlpha * this.alpha);
            renderSupport.raiseDrawCount();
        }
        
        
        
        
        context.setTextureAt(0, null);
        context.setTextureAt(1, null);
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
        context.setVertexBufferAt(2, null);
    }
    
    
    public function exportToPolygon(prevPolygon : GraphicsPolygon = null) : GraphicsPolygon
    {
        validateNow();
        
        var startIndex : Int = 0;
        var startIndices : Int = 0;
        
        if (prevPolygon != null)
        {
            startIndex = (prevPolygon.lastVertexIndex <= 0) ? 0 : prevPolygon.lastVertexIndex * VERTEX_STRIDE;
            startIndices = (prevPolygon.lastIndexIndex <= 0) ? 0 : prevPolygon.lastIndexIndex * VERTEX_STRIDE;
        }
        
        var newVertArray : Vector<Dynamic> = new Vector<Dynamic>();
        var vertLen : Int = vertices.length;
        
        var i : Int = startIndex;
        while (i < vertLen)
        {
            newVertArray.push(vertices[i + 0]);
            newVertArray.push(vertices[i + 1]);
            i += VERTEX_STRIDE;
        }
        
        if (prevPolygon == null)
        {
            var retval : GraphicsPolygon = new GraphicsPolygon(newVertArray, indices);
            return retval;
        }
        else
        {
            prevPolygon.append(newVertArray, indices);
            return prevPolygon;
        }
    }
    
    
    private function set_graphicDrawHelper(gdh : IGraphicDrawHelper) : IGraphicDrawHelper
    {
        validateNow();
        _graphicDrawHelper = gdh;
        _graphicDrawHelper.initialize(Std.int(vertices.length / VERTEX_STRIDE));
        return gdh;
    }
    
    private function get_graphicDrawHelper() : IGraphicDrawHelper
    {
        return _graphicDrawHelper;
    }
}
