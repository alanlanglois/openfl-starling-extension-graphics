package starling.display.graphics;

import flash.errors.Error;
import flash.geom.Point;
import flash.geom.Rectangle;
import openfl.Vector;
import starling.display.DisplayObject;
import starling.display.graphics.StrokeVertex;
import starling.textures.Texture;
import starling.display.graphics.util.TriangleUtil;
import starling.display.util.StrokeVertexUtil;
import starling.utils.MatrixUtil;



class Stroke extends Graphic
{
    public var numVertices(get, never) : Int;

    private var _line : Vector<StrokeVertex>;
    private var _numVertices : Int;
    private var _numAllocedVertices : Int;
    private var _indexOfLastRenderedVertex : Int = -1;
    
    private static inline var c_degenerateUseNext : Int = 1;
    private static inline var c_degenerateUseLast : Int = 2;
    private var _hasDegenerates : Bool = false;
    
    private static var sCollissionHelper : StrokeCollisionHelper = null;
    private var _cullDistanceSquared : Float = 0.0;
    private var _lastScale : Float = 1.0;
    private var _isReusingLine : Bool = false;
    
    public function new()
    {
        super();
        clear();
    }
    
    private function get_numVertices() : Int
    {
        return _numVertices;
    }
    
    override public function dispose() : Void
    {
        clear();
        super.dispose();
    }
    
    public function setPointCullDistance(cullDistance : Float = 0.0) : Void
    {
        _cullDistanceSquared = cullDistance * cullDistance;
    }
    
    // clearForReuse is only valid when adding exactly the same amount of vertices as existed before the clear call.
    // This method avoids the overhead of returning StrokeVertices to the pool
    public function clearForReuse() : Void
    {
        if (_line == null || _line.length == 0)
        {
            clear();
            return;
        }
        
        if (minBounds != null)
        {
            minBounds.x = minBounds.y = Math.POSITIVE_INFINITY;
            maxBounds.x = maxBounds.y = Math.NEGATIVE_INFINITY;
        }
        _numVertices = 0;
        setGeometryInvalid(false);
        _hasDegenerates = false;
        _indexOfLastRenderedVertex = -1;
        _isReusingLine = true;
    }
    public function clear() : Void
    {
        if (minBounds != null)
        {
            minBounds.x = minBounds.y = Math.POSITIVE_INFINITY;
            maxBounds.x = maxBounds.y = Math.NEGATIVE_INFINITY;
        }
        
        if (_line != null)
        {
            StrokeVertex.returnInstances(_line);
			
            //as3hx.Compat.set(_line, 0);
        }
        else
        {
            _line = new Vector<StrokeVertex>();
        }
        
        _numVertices = 0;
        _numAllocedVertices = 0;
        setGeometryInvalid();
        _hasDegenerates = false;
        _indexOfLastRenderedVertex = -1;
        _isReusingLine = false;
    }
    
    public function addDegenerates(destX : Float, destY : Float) : Void
    {
        if (_numVertices < 1)
        {
            return;
        }
        var lastVertex : StrokeVertex = _line[_numVertices - 1];
        addVertexInternal(lastVertex.x, lastVertex.y, 0.0);
        setLastVertexAsDegenerate(c_degenerateUseLast);
        addVertexInternal(destX, destY, 0.0);
        setLastVertexAsDegenerate(c_degenerateUseNext);
        _hasDegenerates = true;
    }
    
    private function setLastVertexAsDegenerate(type : Int) : Void
    {
        _line[_numVertices - 1].degenerate = type;
        _line[_numVertices - 1].u = 0.0;
    }
    
    public function lineTo(x : Float, y : Float, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        addVertexInternal(x, y, thickness, color, alpha, color, alpha);
    }
    
    public function moveTo(x : Float, y : Float, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1.0) : Void
    {
        addDegenerates(x, y);
    }
    
    public function modifyVertexPosition(index : Int, x : Float, y : Float) : Void
    {
        var v : StrokeVertex = _line[index];
        v.x = x;
        v.y = y;
        if (buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    public function fromBounds(boundingBox : Rectangle, thickness : Int = 1) : Void
    {
        clear();
        addVertex(boundingBox.x, boundingBox.y, thickness);
        addVertex(boundingBox.x + boundingBox.width, boundingBox.y, thickness);
        addVertex(boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height, thickness);
        addVertex(boundingBox.x, boundingBox.y + boundingBox.height, thickness);
        addVertex(boundingBox.x, boundingBox.y, thickness);
    }
    
    
    //	[Deprecated(replacement="starling.display.graphics.Stroke.lineTo()")]
    public function addVertex(x : Float, y : Float, thickness : Float = 1,
            color0 : Int = 0xFFFFFF, alpha0 : Float = 1,
            color1 : Int = 0xFFFFFF, alpha1 : Float = 1) : Void
    {
        addVertexInternal(x, y, thickness, color0, alpha0, color1, alpha1);
    }
    
    private function addVertexInternal(x : Float, y : Float, thickness : Float = 1,
            color0 : Int = 0xFFFFFF, alpha0 : Float = 1,
            color1 : Int = 0xFFFFFF, alpha1 : Float = 1) : Void
    {
        var u : Float = 0;
        var textures : Vector<Texture> = _material.textures;
        if (textures.length > 0 && _numVertices > 0)
        {
            var prevVertex : StrokeVertex = _line[_numVertices - 1];
            var dx : Float = x - prevVertex.x;
            var dy : Float = y - prevVertex.y;
            var d : Float = Math.sqrt(dx * dx + dy * dy);
            u = prevVertex.u + (d / textures[0].width);
        }
        
        var r0 : Float = (color0 >> 16) / 255;
        var g0 : Float = ((color0 & 0x00FF00) >> 8) / 255;
        var b0 : Float = (color0 & 0x0000FF) / 255;
        var r1 : Float = (color1 >> 16) / 255;
        var g1 : Float = ((color1 & 0x00FF00) >> 8) / 255;
        var b1 : Float = (color1 & 0x0000FF) / 255;
        if (_cullDistanceSquared > 0 && _numVertices > 0)
        {
            var cullDX : Float = (x - _line[_numVertices - 1].x) * (x - _line[_numVertices - 1].x);
            var cullDY : Float = (y - _line[_numVertices - 1].y) * (y - _line[_numVertices - 1].y);
            if ((cullDY + cullDX) < _cullDistanceSquared)
            {
                return;
            }
        }
        var v : StrokeVertex;
        if (_isReusingLine)
        {
            v = _line[_numVertices];
        }
        else
        {
            v = StrokeVertex.getInstance();
            _line[_numVertices] = v;
        }
        v.x = x;
        v.y = y;
        v.r1 = r0;
        v.g1 = g0;
        v.b1 = b0;
        v.a1 = alpha0;
        v.r2 = r1;
        v.g2 = g1;
        v.b2 = b1;
        v.a2 = alpha1;
        v.u = u;
        v.v = 0;
        v.thickness = thickness;
        v.degenerate = 0;
        if (_numAllocedVertices == _numVertices)
        {
            _numAllocedVertices++;
        }
        
        _numVertices++;
        
        var halfThickness : Float = 0.5 * thickness;
        
        if ((x - halfThickness) < minBounds.x)
        {
            minBounds.x = (x - halfThickness);
        }
        else
        {
            if ((x + halfThickness) > maxBounds.x)
            {
                maxBounds.x = (x + halfThickness);
            }
        }
        
        if ((y - halfThickness) < minBounds.y)
        {
            minBounds.y = (y - halfThickness);
        }
        else
        {
            if ((y + halfThickness) > maxBounds.y)
            {
                maxBounds.y = (y + halfThickness);
            }
        }
        
        if (maxBounds.x == Math.NEGATIVE_INFINITY)
        {
            maxBounds.x = x;
        }
        if (maxBounds.y == Math.NEGATIVE_INFINITY)
        {
            maxBounds.y = y;
        }
        
        if (_isReusingLine == false && buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    
    public function getVertexPosition(index : Int, prealloc : Point = null) : Point
    {
        var point : Point = prealloc;
        if (point == null)
        {
            point = new Point();
        }
        
        point.x = _line[index].x;
        point.y = _line[index].y;
        return point;
    }
    
    override private function buildGeometry() : Void
    {
        buildGeometryPreAllocatedVectors();
    }
    
    private function buildGeometryPreAllocatedVectors() : Void
    {
        if (_line == null || _line.length <= 1)
        {
            return;
        }  // block against odd cases.  
        if (_numAllocedVertices != _numVertices)
        {
            throw new Error("Stroke: Only use clearForReuse() when adding exactly the right number of vertices");
        }
        
        // This is the code that uses the preAllocated code path for createPolyLinePreAlloc
        var indexOffset : Int = 0;
        // First remove all deformed things in _line
        _numVertices = fixUpPolyLine(_line);
        if (_cullDistanceSquared > 0.1)
        {
            _numVertices = cullPolyLineByDistance(_line, _cullDistanceSquared, _indexOfLastRenderedVertex);
            _numAllocedVertices = _numVertices;
        }
        
        // Then use the line lenght to pre allocate the vertex vectors
        var numVerts : Int = as3hx.Compat.parseInt(_line.length * 18);  // this looks odd, but for each StrokeVertex, we generate 18 verts in createPolyLine  
        var numIndices : Int = as3hx.Compat.parseInt((_line.length - 1) * 6);  // this looks odd, but for each StrokeVertex-1, we generate 6 indices in createPolyLine  
        
        // In special cases, there is some time to save here.
        // If the new number of vertices is the same as in the previous list of vertices, there's no need to recreate the buffer of vertices and indices
        if (_indexOfLastRenderedVertex == -1)
        {
            if (vertices == null || numVerts != vertices.length)
            {
                vertices = new Vector<Float>();
            }
            if (indices == null || numIndices != indices.length)
            {
                indices = new Vector<Int>();
            }
        }
        else
        {
            if (vertices.fixed)
            {
                vertices = vertices.copy();
            }  // need to do this to change fixed length into dynamic  
            if (indices.fixed)
            {
                indices = indices.copy();
            }
        }
        
        createPolyLinePreAlloc(_line, vertices, indices, _hasDegenerates, _indexOfLastRenderedVertex);
        
        var oldVerticesLength : Int = 0;  // this is always zero in the old code, even if we use vertices.length in the original code. Not sure why it is here.  
        var oneOverVertexStride : Float = 1 / Graphic.VERTEX_STRIDE;
        indexOffset += Std.int((vertices.length - oldVerticesLength) * oneOverVertexStride);
        _indexOfLastRenderedVertex = Std.int(_line.length - 1);
    }
    
    ///////////////////////////////////
    // Static helper methods
    ///////////////////////////////////
    //@:meta(inline())

    private static function createPolyLinePreAlloc(_line : Vector<StrokeVertex>,
            vertices : Vector<Float>,
            indices : Vector<Int>,
            _hasDegenerates : Bool,
            indexOfLastRenderedVertex : Int) : Void
    {
        var numVertices : Int = _line.length;
        var PI : Float = Math.PI;
        var lastD0 : Float = 0;
        var lastD1 : Float = 0;
        var degenerate : Int = 0;
        var idx : Int = 0;
        var treatAsFirst : Bool;
        var treatAsLast : Bool;
        var startIndex : Int = (indexOfLastRenderedVertex <= 0) ? 0 : indexOfLastRenderedVertex - 1;
        var vertCounter : Int = as3hx.Compat.parseInt(startIndex * 18);
        var indiciesCounter : Int = as3hx.Compat.parseInt(startIndex * 6);
        var prevV1xPos : Float = 0.0;
        var prevV1xNeg : Float = 0.0;
        var prevV1yPos : Float = 0.0;
        var prevV1yNeg : Float = 0.0;
        var usePreviousVertPositionsOnNextLoop : Bool = false;
        var usePreviousVertPositions : Bool = false;
        
        
        for (i in startIndex...numVertices)
        {
            idx = i;
            if (_hasDegenerates)
            {
                degenerate = _line[i].degenerate;
                if (degenerate != 0)
                {
                    idx = ((degenerate == c_degenerateUseLast)) ? (i - 1) : (i + 1);
                }
                treatAsFirst = (idx == 0) || (_line[idx - 1].degenerate > 0);
                treatAsLast = (idx == numVertices - 1) || (_line[idx + 1].degenerate > 0);
            }
            else
            {
                treatAsFirst = (idx == 0);
                treatAsLast = (idx == numVertices - 1);
            }
            if (usePreviousVertPositionsOnNextLoop)
            {
                usePreviousVertPositionsOnNextLoop = false;
                usePreviousVertPositions = true;
            }
            else
            {
                usePreviousVertPositions = false;
            }
            
            var treatAsRegular : Bool = treatAsFirst == false && treatAsLast == false;
            
            var idx0 : Int = (treatAsFirst) ? idx : (idx - 1);
            var idx2 : Int = (treatAsLast) ? idx : (idx + 1);
            
            var v0 : StrokeVertex = _line[idx0];
            var v1 : StrokeVertex = _line[idx];
            var v2 : StrokeVertex = _line[idx2];
            
            var vThickness : Float = v1.thickness;
            
            var v0x : Float = v0.x;
            var v0y : Float = v0.y;
            var v1x : Float = v1.x;
            var v1y : Float = v1.y;
            var v2x : Float = v2.x;
            var v2y : Float = v2.y;
            
            var d0x : Float = v1x - v0x;
            var d0y : Float = v1y - v0y;
            var d1x : Float = v2x - v1x;
            var d1y : Float = v2y - v1y;
            
            if (treatAsRegular == false)
            {
                if (treatAsLast)
                {
                    v2x += d0x;
                    v2y += d0y;
                    
                    d1x = v2x - v1x;
                    d1y = v2y - v1y;
                }
                
                if (treatAsFirst)
                {
                    v0x -= d1x;
                    v0y -= d1y;
                    
                    d0x = v1x - v0x;
                    d0y = v1y - v0y;
                }
            }
            
            var d0 : Float = Math.sqrt(d0x * d0x + d0y * d0y);
            var d1 : Float = Math.sqrt(d1x * d1x + d1y * d1y);
            
            var elbowThickness : Float = vThickness * 0.5;
            if (treatAsRegular)
            {
                if (d0 == 0)
                {
                    d0 = lastD0;
                }
                else
                {
                    lastD0 = d0;
                }
                
                if (d1 == 0)
                {
                    d1 = lastD1;
                }
                else
                {
                    lastD1 = d1;
                }
                
                // Thanks to Tom Clapham for spotting this relationship.
                var dot : Float = (d0x * d1x + d0y * d1y) / (d0 * d1);
                var arcCosDot : Float = Math.acos(dot);
                elbowThickness /= Math.sin((PI - arcCosDot) * 0.5);
                
                if (elbowThickness != elbowThickness)
                {
                    // faster NaN comparison
                    {
                        elbowThickness = vThickness * 0.5;
                    }
                }
                else
                {
                    if (elbowThickness > vThickness * 4)
                    {
                        elbowThickness = vThickness * 4;
                    }
                }
                if (dot <= 0 && d1 < vThickness * 0.5)
                {
                    usePreviousVertPositionsOnNextLoop = true;
                }
            }
            else
            {
                lastD0 = d0;
                lastD1 = d1;
            }
            
            var n0x : Float = -d0y / d0;
            var n0y : Float = d0x / d0;
            var n1x : Float = -d1y / d1;
            var n1y : Float = d1x / d1;
            
            var cnx : Float = n0x + n1x;
            var cny : Float = n0y + n1y;
            
            var c : Float = (1 / Math.sqrt(cnx * cnx + cny * cny)) * elbowThickness;
            cnx *= c;
            cny *= c;
            
            var v1xPos : Float = v1x + cnx;
            var v1yPos : Float = v1y + cny;
            var v1xNeg : Float = ((degenerate != 0)) ? v1xPos : (v1x - cnx);
            var v1yNeg : Float = ((degenerate != 0)) ? v1yPos : (v1y - cny);
            
            vertices[vertCounter++] = (usePreviousVertPositions == false) ? v1xPos : prevV1xPos;
            vertices[vertCounter++] = (usePreviousVertPositions == false) ? v1yPos : prevV1yPos;
            vertices[vertCounter++] = 0;
            vertices[vertCounter++] = v1.r2;
            vertices[vertCounter++] = v1.g2;
            vertices[vertCounter++] = v1.b2;
            vertices[vertCounter++] = v1.a2;
            vertices[vertCounter++] = v1.u;
            vertices[vertCounter++] = 1;
            vertices[vertCounter++] = v1xNeg;
            vertices[vertCounter++] = v1yNeg;
            
            vertices[vertCounter++] = 0;
            vertices[vertCounter++] = v1.r1;
            vertices[vertCounter++] = v1.g1;
            vertices[vertCounter++] = v1.b1;
            vertices[vertCounter++] = v1.a1;
            vertices[vertCounter++] = v1.u;
            vertices[vertCounter++] = 0;
            
            prevV1xPos = v1xPos;
            prevV1xNeg = v1xNeg;
            prevV1yPos = v1yPos;
            prevV1yNeg = v1yNeg;
            
            if (i < numVertices - 1)
            {
                var i2 : Int = as3hx.Compat.parseInt(i << 1);
                indices[indiciesCounter++] = i2;
                indices[indiciesCounter++] = i2 + 1;
                indices[indiciesCounter++] = i2 + 2;
                indices[indiciesCounter++] = i2 + 3;
                indices[indiciesCounter++] = i2 + 2;
                indices[indiciesCounter++] = i2 + 1;
            }
        }
    }
    
    
    private static function fixUpPolyLine(vertices : Vector<StrokeVertex>) : Int
    {
        if (vertices.length > 0 && vertices[0].degenerate > 0)
        {
            throw (new Error("Degenerate on first line vertex"));
        }
        var idx : Int = as3hx.Compat.parseInt(vertices.length - 1);
        
        while (idx > 0 && vertices[idx].degenerate > 0)
        {
            vertices.pop();
            idx--;
        }
        return vertices.length;
    }
    
    private static function cullPolyLineByDistance(line : Vector<StrokeVertex>, cullDistanceSquared : Float, indexOfLastRenderedVertex : Int) : Int
    {
        if (line == null)
        {
            return 0;
        }
        
        if (line.length < 2)
        {
            return line.length;
        }
        
        var num : Int = line.length;
        var startIndex : Int = (indexOfLastRenderedVertex < 2) ? 1 : indexOfLastRenderedVertex - 1;
        var prevIndex : Int = as3hx.Compat.parseInt(startIndex - 1);
		var j:Int;
        for (i in startIndex...num)
        {
			j = cast( i, Int);
            var xDist : Float = line[prevIndex].x - line[i].x;
            var yDist : Float = line[prevIndex].y - line[i].y;
            var distanceFromLast : Float = xDist * xDist + yDist * yDist;
            if (distanceFromLast < cullDistanceSquared)
            {
                StrokeVertexUtil.removeStrokeVertexAt(line, j);
                num--;
                if (j > num)
                {
                    return num;
                }
                j --;
            }
            else
            {
                prevIndex = j;
            }
        }
        return line.length;
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
    
    /** Transforms a point from the local coordinate system to parent coordinates.
     *  If you pass a 'resultPoint', the result will be stored in this point instead of 
     *  creating a new object. */
    public function localToParent(localPoint : Point, resultPoint : Point = null) : Point
    {
        return MatrixUtil.transformCoords(transformationMatrix, localPoint.x, localPoint.y, resultPoint);
    }
    
    
    public static function strokeCollideTest(s1 : Stroke, s2 : Stroke, intersectPoint : Point, staticLenIntersectPoints : Array<Point> = null) : Bool
    {
        if (s1 == null || s2 == null || s1._line == null || s1._line == null)
        {
            return false;
        }
        
        
        if (sCollissionHelper == null)
        {
            sCollissionHelper = new StrokeCollisionHelper();
        }
        sCollissionHelper.testIntersectPoint.x = 0;
        sCollissionHelper.testIntersectPoint.y = 0;
        intersectPoint.x = 0;
        intersectPoint.y = 0;
        var hasSameParent : Bool = false;
        if (s1.parent == s2.parent)
        {
            hasSameParent = true;
        }
        
        s1.getBounds((hasSameParent) ? s1.parent : s1.stage, sCollissionHelper.bounds1);
        s2.getBounds((hasSameParent) ? s2.parent : s2.stage, sCollissionHelper.bounds2);
        if (sCollissionHelper.bounds1.intersects(sCollissionHelper.bounds2) == false)
        {
            return false;
        }
        
        
        if (intersectPoint == null)
        {
            intersectPoint = new Point();
        }
        var numLinesS1 : Int = s1._line.length;
        var numLinesS2 : Int = s2._line.length;
        var hasHit : Bool = false;
        
        
        if (sCollissionHelper.s2v0Vector == null || sCollissionHelper.s2v0Vector.length < numLinesS2)
        {
            sCollissionHelper.s2v0Vector = new Array<Point>();
            sCollissionHelper.s2v1Vector = new Array<Point>();
        }
        
        var pointCounter : Int = 0;
        var maxPointCounter : Int = 0;
        if (staticLenIntersectPoints != null)
        {
            maxPointCounter = staticLenIntersectPoints.length;
        }
        
        for (i in 1...numLinesS1)
        {
            var s1v0 : StrokeVertex = s1._line[i - 1];
            var s1v1 : StrokeVertex = s1._line[i];
            
            sCollissionHelper.localPT1.setTo(s1v0.x, s1v0.y);
            sCollissionHelper.localPT2.setTo(s1v1.x, s1v1.y);
            if (hasSameParent)
            {
                s1.localToParent(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
                s1.localToParent(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
            }
            else
            {
                s1.localToGlobal(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
                s1.localToGlobal(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
            }
            
            
            for (j in 1...numLinesS2)
            {
                var s2v0 : StrokeVertex = s2._line[j - 1];
                var s2v1 : StrokeVertex = s2._line[j];
                
                if (i == 1)
                {
                    // when we do the first loop through this set, we can cache all global points in s2v0Vector and s2v1Vector, to avoid slow localToGlobals on next loop passes
                    sCollissionHelper.localPT3.setTo(s2v0.x, s2v0.y);
                    sCollissionHelper.localPT4.setTo(s2v1.x, s2v1.y);
                    
                    if (hasSameParent)
                    {
                        s2.localToParent(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
                        s2.localToParent(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
                    }
                    else
                    {
                        s2.localToGlobal(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
                        s2.localToGlobal(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
                    }
                    
                    if (sCollissionHelper.s2v0Vector[j] == null)
                    {
                        sCollissionHelper.s2v0Vector[j] = new Point(sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y);
                        sCollissionHelper.s2v1Vector[j] = new Point(sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y);
                    }
                    else
                    {
                        sCollissionHelper.s2v0Vector[j].x = sCollissionHelper.globalPT3.x;
                        sCollissionHelper.s2v0Vector[j].y = sCollissionHelper.globalPT3.y;
                        sCollissionHelper.s2v1Vector[j].x = sCollissionHelper.globalPT4.x;
                        sCollissionHelper.s2v1Vector[j].y = sCollissionHelper.globalPT4.y;
                    }
                }
                else
                {
                    sCollissionHelper.globalPT3.x = sCollissionHelper.s2v0Vector[j].x;
                    sCollissionHelper.globalPT3.y = sCollissionHelper.s2v0Vector[j].y;
                    
                    sCollissionHelper.globalPT4.x = sCollissionHelper.s2v1Vector[j].x;
                    sCollissionHelper.globalPT4.y = sCollissionHelper.s2v1Vector[j].y;
                }
                
                if (TriangleUtil.lineIntersectLine(sCollissionHelper.globalPT1.x, sCollissionHelper.globalPT1.y, sCollissionHelper.globalPT2.x, sCollissionHelper.globalPT2.y, sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y, sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y, sCollissionHelper.testIntersectPoint))
                {
                    if (staticLenIntersectPoints != null && pointCounter < (maxPointCounter - 1))
                    {
                        if (hasSameParent)
                        {
                            s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, staticLenIntersectPoints[pointCounter]);
                        }
                        else
                        {
                            staticLenIntersectPoints[pointCounter].x = sCollissionHelper.testIntersectPoint.x;
                            staticLenIntersectPoints[pointCounter].y = sCollissionHelper.testIntersectPoint.y;
                        }
                        pointCounter++;
                        staticLenIntersectPoints[pointCounter].x = Math.NaN;
                        staticLenIntersectPoints[pointCounter].y = Math.NaN;
                    }
                    
                    if (sCollissionHelper.testIntersectPoint.length > intersectPoint.length)
                    {
                        if (hasSameParent)
                        {
                            s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, intersectPoint);
                        }
                        else
                        {
                            intersectPoint.x = sCollissionHelper.testIntersectPoint.x;
                            intersectPoint.y = sCollissionHelper.testIntersectPoint.y;
                        }
                    }
                    hasHit = true;
                }
            }
        }
        
        return hasHit;
    }
    
    public function scaleGeometry(newScale : Float) : Void
    {
        if (newScale == _lastScale || newScale <= 0)
        {
            return;
        }
        
        adjustThicknessOfGeometry(vertices, _lastScale, newScale);
        isGeometryScaled = true;
        
        _lastScale = newScale;
    }
    
    private static function adjustThicknessOfGeometry(vertices : Vector<Float>, oldScale : Float, newScale : Float) : Void
    {
        var numVerts : Int = vertices.length;
        var scaleFactor : Float = oldScale / newScale;
        
        var i : Int = 0;
        while (i < numVerts)
        {
            var posX : Float = vertices[i];
            var posY : Float = vertices[i + 1];
            var negX : Float = vertices[i + 9];
            var negY : Float = vertices[i + 10];
            
            var helpPointA_x : Float = posX;
            var helpPointA_y : Float = posY;
            var helpPointB_x : Float = negX;
            var helpPointB_y : Float = negY;
            
            var distance_x : Float = helpPointB_x - helpPointA_x;
            var distance_y : Float = helpPointB_y - helpPointA_y;
            
            var halfDistance_x : Float = distance_x * 0.5;
            var halfDistance_y : Float = distance_y * 0.5;
            
            var midPoint_x : Float = helpPointA_x + halfDistance_x;
            var midPoint_y : Float = helpPointA_y + halfDistance_y;
            
            halfDistance_x *= scaleFactor;
            halfDistance_y *= scaleFactor;
            
            posX = midPoint_x + halfDistance_x;
            posY = midPoint_y + halfDistance_y;
            negX = midPoint_x - halfDistance_x;
            negY = midPoint_y - halfDistance_y;
            
            vertices[i] = posX;
            vertices[i + 1] = posY;
            vertices[i + 9] = negX;
            vertices[i + 10] = negY;
            i += 18;
        }
    }
}



class StrokeCollisionHelper
{
    public var localPT1 : Point = new Point();
    public var localPT2 : Point = new Point();
    public var localPT3 : Point = new Point();
    public var localPT4 : Point = new Point();
    
    public var globalPT1 : Point = new Point();
    public var globalPT2 : Point = new Point();
    public var globalPT3 : Point = new Point();
    public var globalPT4 : Point = new Point();
    
    public var bounds1 : Rectangle = new Rectangle();
    public var bounds2 : Rectangle = new Rectangle();
    
    public var testIntersectPoint : Point = new Point();
    public var s1v0Vector : Array<Point> = null;
    public var s1v1Vector : Array<Point> = null;
    public var s2v0Vector : Array<Point> = null;
    public var s2v1Vector : Array<Point> = null;

    public function new()
    {
    }
}