package starling.display.materials;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import openfl.Vector;
import starling.display.shaders.IShader;
import starling.textures.Texture;

interface IMaterial
{
    
    var alpha(get, set) : Float;    
    
    var color(get, set) : Int;    
    
    var vertexShader(get, set) : IShader;    
    var fragmentShader(get, set) : IShader;    
    
    var textures(get, set) : Vector<Texture>;    
    var premultipliedAlpha(get, never) : Bool;

    function dispose() : Void
    ;
    function drawTriangles(context : Context3D, matrix : Matrix3D, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1, numTriangles : Int = -1) : Void
    ;
    function drawTrianglesEx(context : Context3D, matrix : Matrix3D, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1, numTriangles : Int = -1, startTriangle : Int = 0) : Void
    ;
    function restoreOnLostContext() : Void
    ;
    function releaseProgramRef() : Void
    ;
}

