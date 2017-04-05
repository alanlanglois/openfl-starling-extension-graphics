package starling.display.graphics;

import flash.geom.Matrix;
import flash.geom.Point;
import openfl.Vector;
import starling.display.geom.GraphicsPolygon;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.geom.Polygon;

class RoundedRectangle extends Graphic
{
    public var cornerRadius(get, set) : Float;
    public var topLeftRadius(get, set) : Float;
    public var topRightRadius(get, set) : Float;
    public var bottomLeftRadius(get, set) : Float;
    public var bottomRightRadius(get, set) : Float;

    private var DEGREES_TO_RADIANS : Float = Math.PI / 180;
    
    private var _width : Float;
    private var _height : Float;
    private var _topLeftRadius : Float;
    private var _topRightRadius : Float;
    private var _bottomLeftRadius : Float;
    private var _bottomRightRadius : Float;
    private var strokePoints : Vector<Float>;
    
    public function new(width : Float = 100, height : Float = 100, topLeftRadius : Float = 10, topRightRadius : Float = 10, bottomLeftRadius : Float = 10, bottomRightRadius : Float = 10)
    {
        super();
        this.width = width;
        this.height = height;
        this.topLeftRadius = topLeftRadius;
        this.topRightRadius = topRightRadius;
        this.bottomLeftRadius = bottomLeftRadius;
        this.bottomRightRadius = bottomRightRadius;
    }
    
    override private function set_width(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _width = value;
        maxBounds.x = _width;
        setGeometryInvalid();
        return value;
    }
    
    override private function get_height() : Float
    {
        return _height;
    }
    
    override private function set_height(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _height = value;
        maxBounds.y = _height;
        setGeometryInvalid();
        return value;
    }
    
    private function get_cornerRadius() : Float
    {
        return _topLeftRadius;
    }
    
    private function set_cornerRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _topLeftRadius = _topRightRadius = _bottomLeftRadius = _bottomRightRadius = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_topLeftRadius() : Float
    {
        return _topLeftRadius;
    }
    
    private function set_topLeftRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _topLeftRadius = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_topRightRadius() : Float
    {
        return _topRightRadius;
    }
    
    private function set_topRightRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _topRightRadius = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_bottomLeftRadius() : Float
    {
        return _bottomLeftRadius;
    }
    
    private function set_bottomLeftRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _bottomLeftRadius = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_bottomRightRadius() : Float
    {
        return _bottomRightRadius;
    }
    
    private function set_bottomRightRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _bottomRightRadius = value;
        setGeometryInvalid();
        return value;
    }
    
    public function getStrokePoints() : Vector<Float>
    {
        validateNow();
        return strokePoints;
    }
    
    override private function buildGeometry() : Void
    {
        strokePoints = new Vector<Float>();
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        
        var halfWidth : Float = _width * 0.5;
        var halfHeight : Float = _height * 0.5;
        var tlr : Float = Math.min(Math.min(halfWidth, halfHeight), _topLeftRadius);
        var trr : Float = Math.min(Math.min(halfWidth, halfHeight), _topRightRadius);
        var blr : Float = Math.min(Math.min(halfWidth, halfHeight), _bottomLeftRadius);
        var brr : Float = Math.min(Math.min(halfWidth, halfHeight), _bottomRightRadius);
        
        vertices.push(tlr);
        vertices.push(0);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(tlr / _width);
        vertices.push(0);
        
        vertices.push(tlr);
        vertices.push(tlr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(tlr / _width);
        vertices.push(tlr / _height);
        
        vertices.push(0);
        vertices.push(tlr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(0);
        vertices.push(tlr / _height);
        
        
        vertices.push(_width - trr);
        vertices.push(0);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push((_width - trr) / _width);
        vertices.push(0);
        
        vertices.push(_width - trr);
        vertices.push(trr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push((_width - trr) / _width);
        vertices.push(trr / _height);
        
        vertices.push(_width);
        vertices.push(trr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(trr / _height);
        
        
        vertices.push(blr);
        vertices.push(_height);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(blr / _width);
        vertices.push(1);
        
        vertices.push(blr);
        vertices.push(_height - blr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(blr / _width);
        vertices.push((_height - blr) / _height);
        
        vertices.push(0);
        vertices.push(_height - blr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(0);
        vertices.push((_height - blr) / _height);
        
        
        vertices.push(_width - brr);
        vertices.push(_height);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push((_width - brr) / _width);
        vertices.push(1);
        
        vertices.push(_width - brr);
        vertices.push(_height - brr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push((_width - brr) / _width);
        vertices.push((_height - brr) / _height);
        
        vertices.push(_width);
        vertices.push(_height - brr);
        vertices.push(0);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push(1);
        vertices.push((_height - brr) / _height);
        
        
        var numVertices : Int = 12;
        
        indices.push(0);
        indices.push(3);
        indices.push(1);
        indices.push(1);
        indices.push(3);
        indices.push(4);
        indices.push(2);
        indices.push(1);
        indices.push(8);
        indices.push(8);
        indices.push(1);
        indices.push(7);
        indices.push(7);
        indices.push(1);
        indices.push(4);
        indices.push(7);
        indices.push(4);
        indices.push(10);
        indices.push(10);
        indices.push(4);
        indices.push(5);
        indices.push(10);
        indices.push(5);
        indices.push(11);
        indices.push(6);
        indices.push(7);
        indices.push(10);
        indices.push(6);
        indices.push(10);
        indices.push(9);
        
        
        strokePoints.push(0);
        strokePoints.push(tlr);
        
        
        var numSides : Int;
		var radians : Float;
		var sin : Float;
		var cos : Float;
		
        if (tlr > 0)
        {
            numSides = as3hx.Compat.parseInt(tlr * 0.25);
            numSides = (numSides < 1) ? 1 : numSides;
            for (i in 0...numSides)
            {
                radians = ((i + 1) / (numSides + 1)) * Math.PI * 0.5;
                radians += Math.PI * 1.5;
                sin = Math.sin(radians);
                cos = Math.cos(radians);
                var x : Float = tlr + sin * tlr;
                var y : Float = tlr - cos * tlr;
                
                vertices.push(x);
                vertices.push(y);
                vertices.push(0);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(x / _width);
                vertices.push(y / _height);
                
                strokePoints.push(x);
                strokePoints.push(y);
                
                numVertices++;
                
                if (i == 0)
                {
                    indices.push(1);
                    indices.push(2);
                    indices.push(numVertices - 1);
                    
                }
                else
                {
                    indices.push(1);
                    indices.push(numVertices - 2);
                    indices.push(numVertices - 1);
                    
                }
                
                if (i == numSides - 1)
                {
                    indices.push(1);
                    indices.push(numVertices - 1);
                    indices.push(0);
                    
                }
            }
        }
        
        strokePoints.push(tlr);
        strokePoints.push(0);
        
        strokePoints.push(_width - trr);
        strokePoints.push(0);
        
        
        if (trr > 0)
        {
            numSides = as3hx.Compat.parseInt(trr * 0.25);
            numSides = (numSides < 1) ? 1 : numSides;
            for (i in 0...numSides)
            {
                radians = ((i + 1) / (numSides + 1)) * Math.PI * 0.5;
                sin = Math.sin(radians);
                cos = Math.cos(radians);
                x = _width - trr + sin * trr;
                y = trr - cos * trr;
                
                vertices.push(x);
                vertices.push(y);
                vertices.push(0);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(x / _width);
                vertices.push(y / _height);
                
                strokePoints.push(x);
                strokePoints.push(y);
                
                numVertices++;
                
                if (i == 0)
                {
                    indices.push(4);
                    indices.push(3);
                    indices.push(numVertices - 1);
                    
                }
                else
                {
                    indices.push(4);
                    indices.push(numVertices - 2);
                    indices.push(numVertices - 1);
                    
                }
                
                if (i == numSides - 1)
                {
                    indices.push(4);
                    indices.push(numVertices - 1);
                    indices.push(5);
                    
                }
            }
        }
        
        strokePoints.push(_width);
        strokePoints.push(trr);
        
        strokePoints.push(_width);
        strokePoints.push(_height - brr);
        
        
        if (brr > 0)
        {
            numSides = as3hx.Compat.parseInt(brr * 0.25);
            numSides = (numSides < 1) ? 1 : numSides;
            for (i in 0...numSides)
            {
                radians = ((i + 1) / (numSides + 1)) * Math.PI * 0.5;
                radians += Math.PI * 0.5;
                sin = Math.sin(radians);
                cos = Math.cos(radians);
                x = _width - brr + sin * brr;
                y = _height - brr - cos * brr;
                
                vertices.push(x);
                vertices.push(y);
                vertices.push(0);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(x / _width);
                vertices.push(y / _height);
                
                strokePoints.push(x);
                strokePoints.push(y);
                
                numVertices++;
                
                if (i == 0)
                {
                    indices.push(10);
                    indices.push(11);
                    indices.push(numVertices - 1);
                    
                }
                else
                {
                    indices.push(10);
                    indices.push(numVertices - 2);
                    indices.push(numVertices - 1);
                    
                }
                
                if (i == numSides - 1)
                {
                    indices.push(10);
                    indices.push(numVertices - 1);
                    indices.push(9);
                    
                }
            }
        }
        
        strokePoints.push(_width - brr);
        strokePoints.push(_height);
        
        strokePoints.push(blr);
        strokePoints.push(_height);
        
        
        if (blr > 0)
        {
            numSides = as3hx.Compat.parseInt(blr * 0.25);
            numSides = (numSides < 1) ? 1 : numSides;
            for (i in 0...numSides)
            {
                radians = ((i + 1) / (numSides + 1)) * Math.PI * 0.5;
                radians += Math.PI;
                sin = Math.sin(radians);
                cos = Math.cos(radians);
                x = blr + sin * blr;
                y = _height - blr - cos * blr;
                
                vertices.push(x);
                vertices.push(y);
                vertices.push(0);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(1);
                vertices.push(x / _width);
                vertices.push(y / _height);
                
                strokePoints.push(x);
                strokePoints.push(y);
                
                numVertices++;
                
                if (i == 0)
                {
                    indices.push(7);
                    indices.push(6);
                    indices.push(numVertices - 1);
                    
                }
                else
                {
                    indices.push(7);
                    indices.push(numVertices - 2);
                    indices.push(numVertices - 1);
                    
                }
                
                if (i == numSides - 1)
                {
                    indices.push(7);
                    indices.push(numVertices - 1);
                    indices.push(8);
                    
                }
            }
        }
        
        strokePoints.push(0);
        strokePoints.push(_height - blr);
        
        strokePoints.push(0);
        strokePoints.push(tlr);
        
    }
}
