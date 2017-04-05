package starling.display.graphics;

import flash.geom.Matrix;
import flash.geom.Point;
import openfl.Vector;
import starling.display.graphics.util.TriangleUtil;

class Fill extends Graphic
{
    public var numVertices(get, never) : Int;

    public static inline var VERTEX_STRIDE : Int = 9;
    
    private var fillVertices : VertexList;
    private var _numVertices : Int;
    private var _isConvex : Bool = true;
    
    public function new()
    {
        super();
        clear();
        
        _uvMatrix = new Matrix();
        _uvMatrix.scale(1 / 256, 1 / 256);
    }
    
    private function get_numVertices() : Int
    {
        return _numVertices;
    }
    
    public function clear() : Void
    {
        indices = new Vector<Int>();
        vertices = new Vector<Float>();
        if (minBounds != null)
        {
            minBounds.x = minBounds.y = 0;
            maxBounds.x = maxBounds.y = 0;
        }
        
        _numVertices = 0;
        VertexList.dispose(fillVertices);
        fillVertices = null;
        setGeometryInvalid();
        _isConvex = true;
    }
    
    override public function dispose() : Void
    {
        clear();
        fillVertices = null;
        super.dispose();
    }
    
    public function addDegenerates(destX : Float, destY : Float, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        if (_numVertices < 1)
        {
            return;
        }
        var lastVertex : Vector<Float> = fillVertices.prev.vertex;
        var lastColor : Int;
        lastColor = as3hx.Compat.parseInt(lastVertex[3] * 255) << 16;  // R  
        lastColor = lastColor | as3hx.Compat.parseInt(as3hx.Compat.parseInt(lastVertex[4] * 255) << 8);  // G  
        lastColor = lastColor | as3hx.Compat.parseInt(lastVertex[5] * 255);  // B  
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        addVertex(lastVertex[0], lastVertex[1], lastColor, lastVertex[6]);
        addVertex(destX, destY, color, alpha);
    }
    
    public function addVertexInConvexShape(x : Float, y : Float, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        addVertexInternal(x, y, color, alpha);
    }
    
    public function addVertex(x : Float, y : Float, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        _isConvex = false;
        addVertexInternal(x, y, color, alpha);
    }
    
    private function addVertexInternal(x : Float, y : Float, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        var r : Float = (color >> 16) / 255;
        var g : Float = ((color & 0x00FF00) >> 8) / 255;
        var b : Float = (color & 0x0000FF) / 255;
        
        var vertex : Vector<Float> = cast([x, y, 0, r, g, b, alpha, x, y], Vector<Float>);
        var node : VertexList = VertexList.getNode();
        if (_numVertices == 0)
        {
            fillVertices = node;
            node.head = node;
            node.prev = node;
        }
        
        node.next = fillVertices.head;
        node.prev = fillVertices.head.prev;
        node.prev.next = node;
        node.next.prev = node;
        node.index = _numVertices;
        node.vertex = vertex;
        
        if (x < minBounds.x)
        {
            minBounds.x = x;
        }
        else
        {
            if (x > maxBounds.x)
            {
                maxBounds.x = x;
            }
        }
        
        if (y < minBounds.y)
        {
            minBounds.y = y;
        }
        else
        {
            if (y > maxBounds.y)
            {
                maxBounds.y = y;
            }
        }
        
        _numVertices++;
        
        setGeometryInvalid();
    }
    
    override private function buildGeometry() : Void
    {
        if (_numVertices < 3)
        {
            return;
        }
        
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        
        triangulate(fillVertices, _numVertices, vertices, indices, _isConvex);
    }
    
    override public function shapeHitTest(stageX : Float, stageY : Float) : Bool
    {
        if (vertices == null)
        {
            return false;
        }
        if (numVertices < 3)
        {
            return false;
        }
        
        var pt : Point = globalToLocal(new Point(stageX, stageY));
        var wn : Int = windingNumberAroundPoint(fillVertices, pt.x, pt.y);
        if (isClockWise(fillVertices))
        {
            return wn != 0;
        }
        return wn == 0;
    }
    
    override private function shapeHitTestLocalInternal(localX : Float, localY : Float) : Bool
    {
        // This method differs from shapeHitTest - the isClockWise test is compared with false rather than true. Not sure why, but this yields the correct result for me.
        var wn : Int = windingNumberAroundPoint(fillVertices, localX, localY);
        if (isClockWise(fillVertices))
        {
            return wn != 0;
        }
        return wn == 0;
    }
    /**
		 * Takes a list of arbitrary vertices. It will first decompose this list into
		 * non intersecting polygons, via convertToSimple. Then it uses an ear-clipping
		 * algorithm to decompose the polygons into triangles.
		 * @param vertices
		 * @param _numVertices
		 * @return 
		 * 
		 */
    private static function triangulate(vertices : VertexList, _numVertices : Int, outputVertices : Vector<Float>, outputIndices : Vector<Int>, isConvex : Bool) : Void
    {
        vertices = VertexList.clone(vertices);
        var openList : Vector<VertexList> = null;
        if (isConvex == false)
        {
            openList = convertToSimple(vertices);
        }
        else
        {
            openList = new Vector<VertexList>();
            openList.push(vertices);
        }
        
        flatten(openList, outputVertices);
        
        while (openList.length > 0)
        {
            var currentList : VertexList = openList.pop();
            
            if (isClockWise(currentList) == false)
            {
                VertexList.reverse(currentList);
            }
            
            var iter : Int = 0;
            var flag : Bool = false;
            var currentNode : VertexList = currentList.head;
            while (true)
            {
                if (iter > _numVertices * 3)
                {
                    break;
                }
                iter++;
                
                var n0 : VertexList = currentNode.prev;
                var n1 : VertexList = currentNode;
                var n2 : VertexList = currentNode.next;
                
                // If vertex list is 3 long.
                if (n2.next == n0)
                {
                    //trace( "making triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
                    outputIndices.push(n0.index);
                    outputIndices.push(n1.index);
                    outputIndices.push(n2.index);
                    
                    VertexList.releaseNode(n0);
                    VertexList.releaseNode(n1);
                    VertexList.releaseNode(n2);
                    break;
                }
                
                var v0x : Float = n0.vertex[0];
                var v0y : Float = n0.vertex[1];
                var v1x : Float = n1.vertex[0];
                var v1y : Float = n1.vertex[1];
                var v2x : Float = n2.vertex[0];
                var v2y : Float = n2.vertex[1];
                
                // Ignore vertex if not reflect
                //trace( "testing triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
                if (isReflex(v0x, v0y, v1x, v1y, v2x, v2y) == false)
                {
                    //trace("index is not reflex. Skipping. " + n1.index);
                    currentNode = currentNode.next;
                    continue;
                }
                
                // Check to see if building a triangle from these 3 vertices
                // would intersect with any other edges.
                var startNode : VertexList = n2.next;
                var n : VertexList = startNode;
                var found : Bool = false;
                while (n != n0)
                {
                    //trace("Testing if point is in triangle : " + n.index);
                    if (TriangleUtil.isPointInTriangle(v0x, v0y, v1x, v1y, v2x, v2y, n.vertex[0], n.vertex[1]))
                    {
                        found = true;
                        break;
                    }
                    n = n.next;
                }
                if (found)
                {
                    //trace("Point found in triangle. Skipping");
                    currentNode = currentNode.next;
                    continue;
                }
                
                // Build triangle and remove vertex from list
                //trace( "making triangle : " + n0.index + ", " + n1.index + ", " + n2.index );
                outputIndices.push(n0.index);
                outputIndices.push(n1.index);
                outputIndices.push(n2.index);
                
                
                //trace( "removing vertex : " + n1.index );
                if (n1 == n1.head)
                {
                    n1.vertex = n2.vertex;
                    n1.next = n2.next;
                    n1.index = n2.index;
                    n1.next.prev = n1;
                    VertexList.releaseNode(n2);
                }
                else
                {
                    n0.next = n2;
                    n2.prev = n0;
                    VertexList.releaseNode(n1);
                }
                
                currentNode = n0;
            }
            
            VertexList.dispose(currentList);
        }
    }
    
    /**
		 * Decomposes a list of arbitrarily positioned vertices that may form self-intersecting
		 * polygons, into a list of non-intersecting polygons. This is then used as input
		 * for the triangulator. 
		 * @param vertexList
		 * @return 
		 */
    private static function convertToSimple(vertexList : VertexList) : Vector<VertexList>
    {
        var output : Vector<VertexList> = new Vector<VertexList>();
        var outputLength : Int = 0;
        
        var openList : Vector<VertexList> = new Vector<VertexList>();
        openList.push(vertexList);
        
        while (openList.length > 0)
        {
            var currentList : VertexList = openList.pop();
            
            var headA : VertexList = currentList.head;
            var nodeA : VertexList = headA;
            var isSimple : Bool = true;
            
            if (nodeA.next == nodeA || nodeA.next.next == nodeA || nodeA.next.next.next == nodeA)
            {
                output[outputLength++] = headA;
                continue;
            }
            
            do
            {
                var nodeB : VertexList = nodeA.next.next;
                do
                {
                    var isect : Vector<Float> = intersection(nodeA, nodeA.next, nodeB, nodeB.next);
                    
                    if (isect != null)
                    {
                        isSimple = false;
                        
                        var temp : VertexList = nodeA.next;
                        
                        var isectNodeA : VertexList = VertexList.getNode();
                        isectNodeA.vertex = isect;
                        isectNodeA.prev = nodeA;
                        isectNodeA.next = nodeB.next;
                        isectNodeA.next.prev = isectNodeA;
                        isectNodeA.head = headA;
                        nodeA.next = isectNodeA;
                        
                        var headB : VertexList = nodeB;
                        var isectNodeB : VertexList = VertexList.getNode();
                        isectNodeB.vertex = isect;
                        isectNodeB.prev = nodeB;
                        isectNodeB.next = temp;
                        isectNodeB.next.prev = isectNodeB;
                        isectNodeB.head = headB;
                        nodeB.next = isectNodeB;
                        do
                        {
                            nodeB.head = headB;
                            nodeB = nodeB.next;
                        }
                        while ((nodeB != headB));
                        
                        openList.push(headA);
                        openList.push(headB);
                        
                        
                        break;
                    }
                    nodeB = nodeB.next;
                }
                while ((nodeB != nodeA.prev && isSimple));
                
                nodeA = nodeA.next;
            }
            while ((nodeA != headA && isSimple));
            
            if (isSimple)
            {
                output[outputLength++] = headA;
            }
        }
        
        return output;
    }
    
    private static function flatten(vertexLists : Vector<VertexList>, output : Vector<Float>) : Void
    {
        var L : Int = vertexLists.length;
        var index : Int = 0;
        for (i in 0...L)
        {
            var vertexList : VertexList = vertexLists[i];
            var node : VertexList = vertexList.head;
            do
            {
                node.index = index++;
                output.push(node.vertex[0]);
                output.push(node.vertex[1]);
                output.push(node.vertex[2]);
                output.push(node.vertex[3]);
                output.push(node.vertex[4]);
                output.push(node.vertex[5]);
                output.push(node.vertex[6]);
                output.push(node.vertex[7]);
                output.push(node.vertex[8]);
                
                node = node.next;
            }
            while ((node != node.head));
        }
    }
    
    private static function windingNumberAroundPoint(vertexList : VertexList, x : Float, y : Float) : Int
    {
        var wn : Int = 0;
        var node : VertexList = vertexList.head;
        do
        {
            var v0y : Float = node.vertex[1];
            var v1y : Float = node.next.vertex[1];
            if ((y > v0y && y < v1y) || (y > v1y && y < v0y))
            {
                var v0x : Float = node.vertex[0];
                var v1x : Float = node.next.vertex[0];
                
                var isUp : Bool = v1y < y;
                if (isUp)
                {
                    //wn += isLeft( v0x, v0y, v1x, v1y, x, y ) ? 1 : 0;
                    // Inline version of above
                    if (wn != 0) {
						wn += (((v1x - v0x) * (y - v0y) - (v1y - v0y) * (x - v0x)) < 0) ? 1 : 0;
					}
                }
                else
                {
                    //wn += isLeft( v0x, v0y, v1x, v1y, x, y ) ? 0 : -1
                    // Inline version of above
                    if (wn != 0 ){
						wn += (((v1x - v0x) * (y - v0y) - (v1y - v0y) * (x - v0x)) < 0) ? 0 : -1;
					}
                }
            }
            
            node = node.next;
        }
        while ((node != vertexList.head));
        return wn;
    }
    
    public static function isClockWise(vertexList : VertexList) : Bool
    {
        var wn : Float = 0;
        var node : VertexList = vertexList.head;
        do
        {
            wn += (node.next.vertex[0] - node.vertex[0]) * (node.next.vertex[1] + node.vertex[1]);
            node = node.next;
        }
        while ((node != vertexList.head));
        
        return wn <= 0;
    }
    
    private static function windingNumber(vertexList : VertexList) : Int
    {
        var wn : Int = 0;
        var node : VertexList = vertexList.head;
        do
        {
            //wn += isLeft( node.vertex[0], node.vertex[1], node.next.vertex[0], node.next.vertex[1], node.next.next.vertex[0], node.next.next.vertex[1] ) ? -1 : 1;
            
            // Inline version of above
            if(wn != 0){
				wn += (((node.next.vertex[0] - node.vertex[0]) * (node.next.next.vertex[1] - node.vertex[1]) - (node.next.next.vertex[0] - node.vertex[0]) * (node.next.vertex[1] - node.vertex[1])) < 0) ? -1 : 1;
			}
            
            node = node.next;
        }
        while ((node != vertexList.head));
        
        return wn;
    }
    
    
    private static function isReflex(v0x : Float, v0y : Float, v1x : Float, v1y : Float, v2x : Float, v2y : Float) : Bool
    {
        if (TriangleUtil.isLeft(v0x, v0y, v1x, v1y, v2x, v2y))
        {
            return false;
        }
        if (TriangleUtil.isLeft(v1x, v1y, v2x, v2y, v0x, v0y))
        {
            return false;
        }
        
        // Inline version of above ( this prevents the fill to be drawn on iOS with AIR > 3.6, so we roll back to isLeft())
        //if ( ((v1x - v0x) * (v2y - v0y) - (v2x - v0x) * (v1y - v0y)) < 0 ) return false;
        //if ( ((v2x - v1x) * (v0y - v1y) - (v0x - v1x) * (v2y - v1y)) < 0 ) return false;
        
        return true;
    }
    
    private static inline var EPSILON : Float = 0.0000001;
    private static function intersection(a0 : VertexList, a1 : VertexList, b0 : VertexList, b1 : VertexList) : Vector<Float>
    {
        var ux : Float = (a1.vertex[0]) - (a0.vertex[0]);
        var uy : Float = (a1.vertex[1]) - (a0.vertex[1]);
        
        var vx : Float = (b1.vertex[0]) - (b0.vertex[0]);
        var vy : Float = (b1.vertex[1]) - (b0.vertex[1]);
        
        var wx : Float = (a0.vertex[0]) - (b0.vertex[0]);
        var wy : Float = (a0.vertex[1]) - (b0.vertex[1]);
        
        var D : Float = ux * vy - uy * vx;
        if (((D < 0) ? -D : D) < EPSILON)
        {
            return null;
        }
        
        var t : Float = (vx * wy - vy * wx) / D;
        if (t < 0 || t > 1)
        {
            return null;
        }
        var t2 : Float = (ux * wy - uy * wx) / D;
        if (t2 < 0 || t2 > 1)
        {
            return null;
        }
        
        var vertexA : Vector<Float> = a0.vertex;
        var vertexB : Vector<Float> = a1.vertex;
        
		
		
        return cast([vertexA[0] + t * (vertexB[0] - vertexA[0]), 
                vertexA[1] + t * (vertexB[1] - vertexA[1]), 
                0, 
                vertexA[3] + t * (vertexB[3] - vertexA[3]), 
                vertexA[4] + t * (vertexB[4] - vertexA[4]), 
                vertexA[5] + t * (vertexB[5] - vertexA[5]), 
                vertexA[6] + t * (vertexB[6] - vertexA[6]), 
                vertexA[7] + t * (vertexB[7] - vertexA[7]), 
                vertexA[8] + t * (vertexB[8] - vertexA[8])
        ], Vector<Float>);
    }
}

