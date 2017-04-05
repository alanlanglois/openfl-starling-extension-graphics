package starling.display.graphics;

import flash.errors.Error;
import haxe.Constraints.Function;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import openfl.Vector;
import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;

class Plane extends Graphic
{
    public var vertexFunction(get, set) : Function;

    private var _width : Float;
    private var _height : Float;
    private var _numVerticesX : Int;
    private var _numVerticesY : Int;
    private var _vertexFunction : Function;
    
    public function new(width : Float = 100, height : Float = 100, numVerticesX : Int = 2, numVerticesY : Int = 2, vertexFunction : Function = null)
    {
        super();
        _width = width;
        _height = height;
        _numVerticesX = numVerticesX;
        _numVerticesY = numVerticesY;
        if (vertexFunction == null)
        {
            _vertexFunction = defaultVertexFunction;
        }
        else
        {
            _vertexFunction = vertexFunction;
        }
        
        setGeometryInvalid();
    }
    
    public static function defaultVertexFunction(column : Int, row : Int, width : Float, height : Float, numVerticesX : Int, numVerticesY : Int, output : Vector<Float>, uvMatrix : Matrix = null) : Void
    {
        var segmentWidth : Float = width / (numVerticesX - 1);
        var segmentHeight : Float = height / (numVerticesY - 1);
        
        output.push(segmentWidth * column  // x  
        );
        output.push(
                segmentHeight * row  // y  
        );
        output.push(
                0  // z  
        );
        output.push(
                1
        );
        output.push(1);
        output.push(1);
        output.push(1  // rgba  
        );
        output.push(
                column / (numVerticesX - 1)  // u  
        );
        output.push(
                row / (numVerticesY - 1)
        );
        
    }
    
    public static function alphaFadeVertically(column : Int, row : Int, width : Float, height : Float, numVerticesX : Int, numVerticesY : Int, output : Vector<Float>, uvMatrix : Matrix = null) : Void
    {
        var segmentWidth : Float = width / (numVerticesX - 1);
        var segmentHeight : Float = height / (numVerticesY - 1);
        
        output.push(segmentWidth * column  // x  
        );
        output.push(
                segmentHeight * row  // y  
        );
        output.push(
                0  // z  
        );
        output.push(
                1
        );
        output.push(1);
        output.push(1  // rgb  
        );
        output.push(
                ((row == 0 || row == numVerticesY - 1)) ? 0 : 1  // a  
        );
        output.push(
                column / (numVerticesX - 1)  // u  
        );
        output.push(
                row / (numVerticesY - 1)
        );
        
    }
    
    public static function alphaFadeHorizontally(column : Int, row : Int, width : Float, height : Float, numVerticesX : Int, numVerticesY : Int, output : Vector<Float>, uvMatrix : Matrix = null) : Void
    {
        var segmentWidth : Float = width / (numVerticesX - 1);
        var segmentHeight : Float = height / (numVerticesY - 1);
        
        output.push(segmentWidth * column  // x  
        );
        output.push(
                segmentHeight * row  // y  
        );
        output.push(
                0  // z  
        );
        output.push(
                1
        );
        output.push(1);
        output.push(1  // rgb  
        );
        output.push(
                ((column == 0 || column == numVerticesX - 1)) ? 0 : 1  // a  
        );
        output.push(
                column / (numVerticesX - 1)  // u  
        );
        output.push(
                row / (numVerticesY - 1)
        );
        
    }
    
    public static function alphaFadeAllSides(column : Int, row : Int, width : Float, height : Float, numVerticesX : Int, numVerticesY : Int, output : Vector<Float>, uvMatrix : Matrix = null) : Void
    {
        var segmentWidth : Float = width / (numVerticesX - 1);
        var segmentHeight : Float = height / (numVerticesY - 1);
        
        output.push(segmentWidth * column  // x  
        );
        output.push(
                segmentHeight * row  // y  
        );
        output.push(
                0  // z  
        );
        output.push(
                1
        );
        output.push(1);
        output.push(1  // rgb  
        );
        output.push(
                ((column == 0 || column == numVerticesX - 1 || row == 0 || row == numVerticesY - 1)) ? 0 : 1  // a  
        );
        output.push(
                column / (numVerticesX - 1)  // u  
        );
        output.push(
                row / (numVerticesY - 1)
        );
        
    }
    
    private function set_vertexFunction(value : Function) : Function
    {
        if (value == null)
        {
            throw (new Error("Value must not be null"));
            return value;
        }
        _vertexFunction = value;
        setGeometryInvalid();
        return value;
    }
    
    private function get_vertexFunction() : Function
    {
        return _vertexFunction;
    }
    
    override private function buildGeometry() : Void
    {
        vertices = new Vector<Float>();
        indices = new Vector<Int>();
        
        // Generate vertices
        var numVertices : Int = as3hx.Compat.parseInt(_numVerticesX * _numVerticesY);
        for (i in 0...numVertices)
        {
            var column : Int = as3hx.Compat.parseInt(i % _numVerticesX);
            var row : Int = as3hx.Compat.parseInt(i / _numVerticesX);
            _vertexFunction(column, row, _width, _height, _numVerticesX, _numVerticesY, vertices, _uvMatrix);
        }
        
        // Generate indices
        var qn : Int = 0;  //quad number  
        for (m in 0..._numVerticesY - 1)
        {
            for (n in 0..._numVerticesX - 1)
            {
                //create quads out of the vertices
                {
                    if (m == 0 && n == 0)
                    {
                        indices.push(qn);
                        indices.push(qn + 1);
                        indices.push(qn + _numVerticesX + 1);
                        //upper face
                        indices.push(qn + _numVerticesX);
                        indices.push(qn + _numVerticesX + 1);
                        indices.push(qn);
                        
                    }
                    else
                    {
                        if (m == _numVerticesY - 2 && n == _numVerticesX - 2)
                        {
                            indices.push(qn);
                            indices.push(qn + _numVerticesX + 1);
                            indices.push(qn + 1);
                            //upper face
                            indices.push(qn);
                            indices.push(qn + _numVerticesX);
                            indices.push(qn + _numVerticesX + 1);
                            
                        }
                        else
                        {
                            indices.push(qn);
                            indices.push(qn + 1);
                            indices.push(qn + _numVerticesX);
                            //upper face
                            indices.push(qn + _numVerticesX);
                            indices.push(qn + _numVerticesX + 1);
                            indices.push(qn + 1);
                            
                        }
                    }
                    qn++;
                }
            }
            qn++;
        }
    }
    
    override public function getBounds(targetSpace : DisplayObject, resultRect : Rectangle = null) : Rectangle
    {
        minBounds.x = 0;
        minBounds.y = 0;
        maxBounds.x = _width;
        maxBounds.y = _height;
        return super.getBounds(targetSpace, resultRect);
    }
}
