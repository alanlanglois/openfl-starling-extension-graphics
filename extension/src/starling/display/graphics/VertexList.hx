package starling.display.graphics;
import openfl.Vector;


@:final class VertexList
{
    public var vertex : Vector<Float>;
    public var next : VertexList;
    public var prev : VertexList;
    public var index : Int;
    public var head : VertexList;
    
    public function new()
    {
    }
    
    public static function insertAfter(nodeA : VertexList, nodeB : VertexList) : VertexList
    {
        var temp : VertexList = nodeA.next;
        nodeA.next = nodeB;
        nodeB.next = temp;
        nodeB.prev = nodeA;
        nodeB.head = nodeA.head;
        
        return nodeB;
    }
    
    public static function clone(vertexList : VertexList) : VertexList
    {
        var newHead : VertexList = null;
        
        var currentNode : VertexList = vertexList.head;
        var currentClonedNode : VertexList = null;
        do
        {
            var newClonedNode : VertexList;
            if (newHead == null)
            {
                newClonedNode = newHead = getNode();
            }
            else
            {
                newClonedNode = getNode();
            }
            
            newClonedNode.head = newHead;
            newClonedNode.index = currentNode.index;
            newClonedNode.vertex = currentNode.vertex;
            newClonedNode.prev = currentClonedNode;
            
            if (currentClonedNode != null)
            {
                currentClonedNode.next = newClonedNode;
            }
            currentClonedNode = newClonedNode;
            
            currentNode = currentNode.next;
        }
        while ((currentNode != currentNode.head));
        
        currentClonedNode.next = newHead;
        newHead.prev = currentClonedNode;
        
        return newHead;
    }
    
    public static function reverse(vertexList : VertexList) : Void
    {
        var node : VertexList = vertexList.head;
        do
        {
            var temp : VertexList = node.next;
            node.next = node.prev;
            node.prev = temp;
            
            node = temp;
        }
        while ((node != vertexList.head));
    }
    
    public static function dispose(node : VertexList) : Void
    {
        while (node != null && node.head != null)
        {
            releaseNode(node);
            var temp : VertexList = node.next;
            node.next = null;
            node.prev = null;
            node.head = null;
            node.vertex = null;
            
            node = node.next;
        }
    }
    
    private static var nodePool : Vector<VertexList> = new Vector<VertexList>();
    private static var nodePoolLength : Int = 0;
    
    public static function getNode() : VertexList
    {
        if (nodePoolLength > 0)
        {
            nodePoolLength--;
            return nodePool.pop();
        }
        return new VertexList();
    }
    
    public static function releaseNode(node : VertexList) : Void
    {
        node.prev = node.next = node.head = null;
        node.vertex = null;
        node.index = -1;
        nodePool[nodePoolLength++] = node;
    }
}
