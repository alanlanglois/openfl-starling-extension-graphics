package starling.display.graphics.util;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Point;
import flash.geom.Matrix3D;
import starling.display.graphics.Graphic;
import starling.display.materials.IMaterial;
import starling.core.RenderSupport;
import starling.display.BlendMode;
import starling.core.Starling;

class RenderIntervalGraphicDrawHelper implements IGraphicDrawHelper
{
    private var _renderIntervals : Array<Point> = null;
    private var _colorVector : Array<Int> = null;
    private var _alphaVector : Array<Float> = null;
    private var _blendModeVector : Array<Dynamic> = null;
    private var _numVerts : Int = 0;
    
    public function new()
    {
    }
    
    public function initialize(numVerts : Int) : Void
    {
        _numVerts = numVerts;
    }
    
    public function addRenderInterval(startT : Float, endT : Float, color : Int, alpha : Float = 1, blendMode : String = "auto") : Void
    {
        if (_numVerts == 0)
        {
            return;
        }
        
        var numVerts : Int = _numVerts;
        var dt : Float = 1.0 / numVerts;
        
        var newStartIndex : Int = as3hx.Compat.parseInt(startT * numVerts);
        var newEndIndex : Int = as3hx.Compat.parseInt(endT * numVerts);
        if (newEndIndex >= numVerts - 1)
        {
            newEndIndex = as3hx.Compat.parseInt(numVerts - 2);
        }
        
        if (_renderIntervals == null)
        {
            _renderIntervals = new Array<Point>();
            _colorVector = new Array<Int>();
            _blendModeVector = new Array<Dynamic>();
            _alphaVector = new Array<Float>();
        }
        _renderIntervals.push(new Point(newStartIndex, newEndIndex));
        _colorVector.push(color);
        _blendModeVector.push(blendMode);
        _alphaVector.push(alpha);
        
        if (endT * numVerts > numVerts)
        {
            newStartIndex = as3hx.Compat.parseInt((startT * numVerts) % numVerts);
            
            newEndIndex = as3hx.Compat.parseInt((endT * numVerts) % numVerts);
            if (newEndIndex >= numVerts - 1)
            {
                newEndIndex = as3hx.Compat.parseInt(numVerts - 2);
            }
            if (newStartIndex > newEndIndex)
            {
                newStartIndex = 0;
            }
            
            _renderIntervals.push(new Point(newStartIndex, newEndIndex));
            _colorVector.push(color);
            _blendModeVector.push(blendMode);
            _alphaVector.push(alpha);
        }
    }
    
    public function clearRenderIntervals() : Void
    {
        _renderIntervals = null;
        _colorVector = null;
        _blendModeVector = null;
    }
    
    public function onDrawTriangles(material : IMaterial, renderSupport : RenderSupport, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1) : Void
    {
        var numTriangles : Int = -1;
        var startIndex : Int = 0;
        var origColor : Int = material.color;
        
        if (_renderIntervals != null && _renderIntervals.length > 0)
        {
            for (i in 0..._renderIntervals.length)
            {
                var startEnd : Point = _renderIntervals[i];
                numTriangles = as3hx.Compat.parseInt(startEnd.y - startEnd.x);
                startIndex = as3hx.Compat.parseInt(3 * startEnd.x);
                material.color = _colorVector[i];
                var blendMode : String = (_blendModeVector[i] == "auto") ? renderSupport.blendMode : _blendModeVector[i];
                RenderSupport.setBlendFactors(material.premultipliedAlpha, blendMode);
                
                material.drawTrianglesEx(Starling.context, renderSupport.mvpMatrix3D, vertexBuffer, indexBuffer, alpha * _alphaVector[i], numTriangles, startIndex);
                renderSupport.raiseDrawCount();
            }
        }
        material.color = origColor;
    }
}

