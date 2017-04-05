/*

	A fairly versatile primitive capable of representing circles, fans, hoops, and arcs.

	Contains a great sin/cos trick learned from Iñigo Quílez's site
	http://www.iquilezles.org/www/articles/sincos/sincos.htm

*/

package starling.display.graphics;

import flash.geom.Matrix;
import flash.geom.Point;
import openfl.Vector;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.graphics.util.TriangleUtil;
import starling.geom.Polygon;

class NGon extends Graphic
{
    public var endAngle(get, set) : Float;
    public var startAngle(get, set) : Float;
    public var radius(get, set) : Float;
    public var color(never, set) : Int;
    public var innerRadius(get, set) : Float;
    public var numSides(get, set) : Int;

    private var DEGREES_TO_RADIANS : Float = Math.PI / 180;
    
    private var _radius : Float;
    private var _innerRadius : Float;
    private var _startAngle : Float;
    private var _endAngle : Float;
    private var _numSides : Int;
    private var _color : Int = 0xFFFFFF;
    private var _textureAlongPath : Bool = false;
    private var _forceTexturedCircle : Bool = false;
    private var _forceAntiAliasedCircle : Bool = false;
    
    private static var _uv : Point;
    
    public function new(radius : Float = 100, numSides : Int = 10, innerRadius : Float = 0, startAngle : Float = 0, endAngle : Float = 360, textureAlongPath : Bool = false)
    {
        super();
        this.radius = radius;
        this.numSides = numSides;
        this.innerRadius = innerRadius;
        this.startAngle = startAngle;
        this.endAngle = endAngle;
        
        this._textureAlongPath = textureAlongPath;
        
        minBounds.x = minBounds.y = -radius;
        maxBounds.x = maxBounds.y = radius;
        
        if (_uv == null)
        {
            _uv = new Point();
        }
    }
    
    public static function createTexturedCircle(radius : Float = 100, numSides : Int = 10) : NGon
    {
        var retval : NGon = new NGon(radius, numSides, 0, 0, 360, false);
        retval._forceTexturedCircle = true;
        return retval;
    }
    
    public static function createAntiAliasedCircle(radius : Float = 100, numSides : Int = 10) : NGon
    {
        var retval : NGon = new NGon(radius, numSides, 0, 0, 360, false);
        retval._forceAntiAliasedCircle = true;
        return retval;
    }
    
    private function get_endAngle() : Float
    {
        return _endAngle;
    }
    
    private function set_endAngle(value : Float) : Float
    {
        _endAngle = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_startAngle() : Float
    {
        return _startAngle;
    }
    
    private function set_startAngle(value : Float) : Float
    {
        _startAngle = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_radius() : Float
    {
        return _radius;
    }
    
    private function set_color(value : Int) : Int
    {
        _color = value;
        setGeometryInvalid();
        return value;
    }
    
    private function set_radius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _radius = value;
        var maxRadius : Float = Math.max(_radius, _innerRadius);
        minBounds.x = minBounds.y = -maxRadius;
        maxBounds.x = maxBounds.y = maxRadius;
        setGeometryInvalid();
        return value;
    }
    
    private function get_innerRadius() : Float
    {
        return _innerRadius;
    }
    
    private function set_innerRadius(value : Float) : Float
    {
        value = (value < 0) ? 0 : value;
        _innerRadius = value;
        var maxRadius : Float = Math.max(_radius, _innerRadius);
        minBounds.x = minBounds.y = -maxRadius;
        maxBounds.x = maxBounds.y = maxRadius;
        setGeometryInvalid();
        return value;
    }
    
    private function get_numSides() : Int
    {
        return _numSides;
    }
    
    private function set_numSides(value : Int) : Int
    {
        value = (value < 3) ? 3 : value;
        _numSides = value;
        setGeometryInvalid();
        return value;
    }
    
    override private function buildGeometry() : Void
    {
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        
        // Manipulate the input startAngle and endAngle values
        // into sa and ea. sa will always end up less than
        // ea, and ea-sa is the shortest clockwise distance
        // between them.
        var sa : Float = _startAngle;
        var ea : Float = _endAngle;
        var isEqual : Bool = sa == ea;
        var sSign : Int = (sa < 0) ? -1 : 1;
        var eSign : Int = (ea < 0) ? -1 : 1;
        sa *= sSign;
        ea *= eSign;
        ea = ea % 360;
        ea *= eSign;
        sa = sa % 360;
        if (ea < sa)
        {
            ea += 360;
        }
        sa *= sSign * DEGREES_TO_RADIANS;
        ea *= DEGREES_TO_RADIANS;
        if (ea - sa > Math.PI * 2)
        {
            ea -= Math.PI * 2;
        }
        
        // Manipulate innerRadius and outRadius in r and ir.
        // ir will always be less than r.
        var innerRadius : Float = (_innerRadius < _radius) ? _innerRadius : _radius;
        var radius : Float = (_radius > _innerRadius) ? _radius : _innerRadius;
        
        // Based upon the input values, choose from
        // 4 primitive types. Each more complex than the next.
        var isSegment : Bool = (sa != 0 || ea != 0);
        if (isSegment == false)
        {
            isSegment = isEqual;
        }  // if sa and ea are equal, treat that as a segment, not a full lap around a circle.  
        
        if (innerRadius == 0 && !isSegment)
        {
            if (_forceAntiAliasedCircle)
            {
                buildAntiAliasedCircle(radius, numSides, vertices, indices, _uvMatrix, _color);
            }
            else
            {
                if (_forceTexturedCircle)
                {
                    buildTexturedCircle(radius, numSides, vertices, indices, _uvMatrix, _color);
                }
                else
                {
                    buildSimpleNGon(radius, _numSides, vertices, indices, _uvMatrix, _color);
                }
            }
        }
        else
        {
            if (innerRadius != 0 && !isSegment)
            {
                buildHoop(innerRadius, radius, _numSides, vertices, indices, _uvMatrix, _color, _textureAlongPath);
            }
            else
            {
                if (innerRadius == 0)
                {
                    buildFan(radius, sa, ea, _numSides, vertices, indices, _uvMatrix, _color);
                }
                else
                {
                    buildArc(innerRadius, radius, sa, ea, _numSides, vertices, indices, _uvMatrix, _color, _textureAlongPath);
                }
            }
        }
    }
    
    override private function shapeHitTestLocalInternal(localX : Float, localY : Float) : Bool
    {
        var numIndices : Int = indices.length;
        if (numIndices < 2)
        {
            validateNow();
            numIndices = indices.length;
            if (numIndices < 2)
            {
                return false;
            }
        }
        
        if (_innerRadius == 0 && _radius > 0 && _startAngle == 0 && _endAngle == 360 && _numSides > 20)
        {
            // simple - faster - if ngon is circle shape and numsides more than 20, assume circle is desired.
            if (Math.sqrt(localX * localX + localY * localY) < _radius)
            {
                return true;
            }
            return false;
        }
        
        var i : Int = 2;
        while (i < numIndices)
        {
            // slower version - should be complete though. For all triangles, check if point is in triangle
            var i0 : Int = indices[(i - 2)];
            var i1 : Int = indices[(i - 1)];
            var i2 : Int = indices[(i - 0)];
            
            var v0x : Float = vertices[Graphic.VERTEX_STRIDE * i0 + 0];
            var v0y : Float = vertices[Graphic.VERTEX_STRIDE * i0 + 1];
            var v1x : Float = vertices[Graphic.VERTEX_STRIDE * i1 + 0];
            var v1y : Float = vertices[Graphic.VERTEX_STRIDE * i1 + 1];
            var v2x : Float = vertices[Graphic.VERTEX_STRIDE * i2 + 0];
            var v2y : Float = vertices[Graphic.VERTEX_STRIDE * i2 + 1];
            if (TriangleUtil.isPointInTriangle(v0x, v0y, v1x, v1y, v2x, v2y, localX, localY))
            {
                return true;
            }
            i += 3;
        }
        return false;
    }
    
    private static function buildSimpleNGon(radius : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int) : Void
    {
        var numVertices : Int = 0;
        
        _uv.x = 0;
        _uv.y = 0;
        if (uvMatrix != null)
        {
            _uv = uvMatrix.transformPoint(_uv);
        }
        
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        vertices.push(0);
        vertices.push(0);
        vertices.push(0);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
        vertices.push(1);
        vertices.push(_uv.x);
        vertices.push(_uv.y);
        
        numVertices++;
        
        var anglePerSide : Float = (Math.PI * 2) / numSides;
        var cosA : Float = Math.cos(anglePerSide);
        var sinB : Float = Math.sin(anglePerSide);
        var s : Float = 0.0;
        var c : Float = 1.0;
        
        for (i in 0...numSides)
        {
            var x : Float = s * radius;
            var y : Float = -c * radius;
            _uv.x = x;
            _uv.y = y;
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            indices.push(0);
            indices.push(numVertices - 1);
            indices.push((i == numSides - 1) ? 1 : numVertices);
            
            
            var ns : Float = sinB * c + cosA * s;
            var nc : Float = cosA * c - sinB * s;
            c = nc;
            s = ns;
        }
    }
    
    private static function buildTexturedCircle(radius : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int) : Void
    {
        var numVertices : Int = 0;
        
        _uv.x = 0.5;
        _uv.y = 0.5;
        if (uvMatrix != null)
        {
            _uv = uvMatrix.transformPoint(_uv);
        }
        
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        vertices.push(0);
        vertices.push(0);
        vertices.push(0);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
        vertices.push(1);
        vertices.push(_uv.x);
        vertices.push(_uv.y);
        
        numVertices++;
        
        var anglePerSide : Float = (Math.PI * 2) / numSides;
        var cosA : Float = Math.cos(anglePerSide);
        var sinB : Float = Math.sin(anglePerSide);
        var s : Float = 0.0;
        var c : Float = 1.0;
        var halfInvRadius : Float = 0.5 * (1.0 / radius);
        
        for (i in 0...numSides)
        {
            var x : Float = s * radius;
            var y : Float = -c * radius;
            _uv.x = 0.5 + x * halfInvRadius;
            _uv.y = 0.5 + y * halfInvRadius;
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            indices.push(0);
            indices.push(numVertices - 1);
            indices.push((i == numSides - 1) ? 1 : numVertices);
            
            
            var ns : Float = sinB * c + cosA * s;
            var nc : Float = cosA * c - sinB * s;
            c = nc;
            s = ns;
        }
    }
    
    private static function buildAntiAliasedCircle(radius : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int) : Void
    {
        var numVertices : Int = 0;
        
        _uv.x = 0.5;
        _uv.y = 1.0;
        if (uvMatrix != null)
        {
            _uv = uvMatrix.transformPoint(_uv);
        }
        
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        vertices.push(0);
        vertices.push(0);
        vertices.push(0);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
        vertices.push(1);
        vertices.push(_uv.x);
        vertices.push(_uv.y);
        
        numVertices++;
        
        var anglePerSide : Float = (Math.PI * 2) / numSides;
        var cosA : Float = Math.cos(anglePerSide);
        var sinB : Float = Math.sin(anglePerSide);
        var s : Float = 0.0;
        var c : Float = 1.0;
        var halfInvRadius : Float = 0.5 * (1.0 / radius);
        
        for (i in 0...numSides)
        {
            var x : Float = s * radius;
            var y : Float = -c * radius;
            _uv.x = 0.5 + x * halfInvRadius;
            _uv.y = 0;
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            indices.push(0);
            indices.push(numVertices - 1);
            indices.push((i == numSides - 1) ? 1 : numVertices);
            
            
            var ns : Float = sinB * c + cosA * s;
            var nc : Float = cosA * c - sinB * s;
            c = nc;
            s = ns;
        }
    }
    
    
    private static function buildHoop(innerRadius : Float, radius : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int, textureAlongPath : Bool) : Void
    {
        var numVertices : Int = 0;
        
        var anglePerSide : Float = (Math.PI * 2) / numSides;
        var cosA : Float = Math.cos(anglePerSide);
        var sinB : Float = Math.sin(anglePerSide);
        var s : Float = 0.0;
        var c : Float = 1.0;
        
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        for (i in 0...numSides)
        {
            var x : Float = s * radius;
            var y : Float = -c * radius;
            if (textureAlongPath)
            {
                _uv.x = i / numSides;
                _uv.y = 0;
            }
            else
            {
                _uv.x = x;
                _uv.y = y;
            }
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            
            x = s * innerRadius;
            y = -c * innerRadius;
            if (textureAlongPath)
            {
                _uv.x = i / numSides;
                _uv.y = 1;
            }
            else
            {
                _uv.x = x;
                _uv.y = y;
            }
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            
            if (i == numSides - 1)
            {
                indices.push(numVertices - 2);
                indices.push(numVertices - 1);
                indices.push(0);
                indices.push(0);
                indices.push(numVertices - 1);
                indices.push(1);
                
            }
            else
            {
                indices.push(numVertices - 2);
                indices.push(numVertices);
                indices.push(numVertices - 1);
                indices.push(numVertices);
                indices.push(numVertices + 1);
                indices.push(numVertices - 1);
                
            }
            
            var ns : Float = sinB * c + cosA * s;
            var nc : Float = cosA * c - sinB * s;
            c = nc;
            s = ns;
        }
    }
    
    private static function buildFan(radius : Float, startAngle : Float, endAngle : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int) : Void
    {
        var numVertices : Int = 0;
        
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        vertices.push(0);
        vertices.push(0);
        vertices.push(0);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
        vertices.push(1);
        vertices.push(0.5);
        vertices.push(0.5);
        
        numVertices++;
        
        var radiansPerDivision : Float = (Math.PI * 2) / numSides;
        var startRadians : Float = (startAngle / radiansPerDivision);
        startRadians = (startRadians < 0) ? -Math.ceil(-startRadians) : as3hx.Compat.parseInt(startRadians);
        startRadians *= radiansPerDivision;
        
        
        
        for (i in 0...numSides + 1 + 1)
        {
            var radians : Float = startRadians + i * radiansPerDivision;
            var nextRadians : Float = radians + radiansPerDivision;
            if (nextRadians < startAngle)
            {
                continue;
            }
            
            var x : Float = Math.sin(radians) * radius;
            var y : Float = -Math.cos(radians) * radius;
            var prevRadians : Float = radians - radiansPerDivision;
            
            var t : Float;
            if (radians < startAngle)
            {
                var nextX : Float = Math.sin(nextRadians) * radius;
                var nextY : Float = -Math.cos(nextRadians) * radius;
                t = (startAngle - radians) / radiansPerDivision;
                x += t * (nextX - x);
                y += t * (nextY - y);
            }
            else
            {
                if (radians > endAngle)
                {
                    var prevX : Float = Math.sin(prevRadians) * radius;
                    var prevY : Float = -Math.cos(prevRadians) * radius;
                    
                    t = (endAngle - prevRadians) / radiansPerDivision;
                    x = prevX + t * (x - prevX);
                    y = prevY + t * (y - prevY);
                }
            }
            
            _uv.x = x;
            _uv.y = y;
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            numVertices++;
            
            if (vertices.length > 2 * 9)
            {
                indices.push(0);
                indices.push(numVertices - 2);
                indices.push(numVertices - 1);
                
            }
            
            if (radians >= endAngle)
            {
                break;
            }
        }
    }
    
    private static function buildArc(innerRadius : Float, radius : Float, startAngle : Float, endAngle : Float, numSides : Int, vertices : Vector<Float>, indices : Vector<Int>, uvMatrix : Matrix, color : Int, textureAlongPath : Bool) : Void
    {
        var nv : Int = 0;
        var radiansPerDivision : Float = (Math.PI * 2) / numSides;
        var startRadians : Float = (startAngle / radiansPerDivision);
        startRadians = (startRadians < 0) ? -Math.ceil(-startRadians) : as3hx.Compat.parseInt(startRadians);
        startRadians *= radiansPerDivision;
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        for (i in 0...numSides + 1 + 1)
        {
            var angle : Float = startRadians + i * radiansPerDivision;
            var nextAngle : Float = angle + radiansPerDivision;
            if (nextAngle < startAngle)
            {
                continue;
            }
            
            var sin : Float = Math.sin(angle);
            var cos : Float = Math.cos(angle);
            
            var x : Float = sin * radius;
            var y : Float = -cos * radius;
            var x2 : Float = sin * innerRadius;
            var y2 : Float = -cos * innerRadius;
            
            var prevAngle : Float = angle - radiansPerDivision;
            
            var t : Float;
            if (angle < startAngle)
            {
                sin = Math.sin(nextAngle);
                cos = Math.cos(nextAngle);
                var nextX : Float = sin * radius;
                var nextY : Float = -cos * radius;
                var nextX2 : Float = sin * innerRadius;
                var nextY2 : Float = -cos * innerRadius;
                t = (startAngle - angle) / radiansPerDivision;
                x += t * (nextX - x);
                y += t * (nextY - y);
                x2 += t * (nextX2 - x2);
                y2 += t * (nextY2 - y2);
            }
            else
            {
                if (angle > endAngle)
                {
                    sin = Math.sin(prevAngle);
                    cos = Math.cos(prevAngle);
                    var prevX : Float = sin * radius;
                    var prevY : Float = -cos * radius;
                    var prevX2 : Float = sin * innerRadius;
                    var prevY2 : Float = -cos * innerRadius;
                    
                    t = (endAngle - prevAngle) / radiansPerDivision;
                    x = prevX + t * (x - prevX);
                    y = prevY + t * (y - prevY);
                    x2 = prevX2 + t * (x2 - prevX2);
                    y2 = prevY2 + t * (y2 - prevY2);
                }
            }
            if (textureAlongPath)
            {
                _uv.x = i / numSides;
                _uv.y = 0;
            }
            else
            {
                _uv.x = x;
                _uv.y = y;
            }
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x);
            vertices.push(y);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            nv++;
            if (textureAlongPath)
            {
                _uv.x = i / numSides;
                _uv.y = 1;
            }
            else
            {
                _uv.x = x2;
                _uv.y = y2;
            }
            if (uvMatrix != null)
            {
                _uv = uvMatrix.transformPoint(_uv);
            }
            
            vertices.push(x2);
            vertices.push(y2);
            vertices.push(0);
            vertices.push(r);
            vertices.push(g);
            vertices.push(b);
            vertices.push(1);
            vertices.push(_uv.x);
            vertices.push(_uv.y);
            
            nv++;
            
            if (vertices.length > 3 * 9)
            {
                //indices.push( nv-1, nv-2, nv-3, nv-3, nv-2, nv-4 );
                indices.push(nv - 3);
                indices.push(nv - 2);
                indices.push(nv - 1);
                indices.push(nv - 3);
                indices.push(nv - 4);
                indices.push(nv - 2);
                
            }
            
            if (angle >= endAngle)
            {
                break;
            }
        }
    }
}
