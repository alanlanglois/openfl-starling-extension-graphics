package starling.display.util;

import openfl.Vector;
import starling.display.graphics.StrokeVertex;

class StrokeVertexUtil
{
    
    /** Removes the value at the specified index from the 'StrokeVertex'-Vector. Pass a negative
     *  index to specify a position relative to the end of the vector. */
    public static function removeStrokeVertexAt(vector : Vector<StrokeVertex>, index : Int) : StrokeVertex
    {
        var i : Int;
        var length : Int = vector.length;
        
        if (index < 0)
        {
            index += length;
        }
        if (index < 0)
        {
            index = 0;
        }
        else
        {
            if (index >= length)
            {
                index = as3hx.Compat.parseInt(length - 1);
            }
        }
        
        var value : StrokeVertex = vector[index];
        
        for (i in index + 1...length)
        {
            vector[i - 1] = vector[i];
        }
        
        //as3hx.Compat.setArrayLength(vector, length - 1);
		vector.length = length - 1;
        return value;
    }

    public function new()
    {
    }
}
