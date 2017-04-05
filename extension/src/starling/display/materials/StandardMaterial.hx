package starling.display.materials;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import openfl.Vector;
import starling.display.materials.Program3DCache;
import starling.display.shaders.IShader;
import starling.display.shaders.fragment.VertexColorFragmentShader;
import starling.display.shaders.vertex.StandardVertexShader;
import starling.textures.Texture;

class StandardMaterial implements IMaterial
{
    public var textures(get, set) : Vector<Texture>;
    public var vertexShader(get, set) : IShader;
    public var fragmentShader(get, set) : IShader;
    public var alpha(get, set) : Float;
    public var color(get, set) : Int;
    public var premultipliedAlpha(get, set) : Bool;

    private var program : Program3D;
    
    private var _vertexShader : IShader;
    private var _fragmentShader : IShader;
    private var _alpha : Float = 1;
    private var _color : Int;
    private var colorVector : Vector<Float>;
    private var _textures : Vector<Texture>;
    
    private var _premultipliedAlpha : Bool = false;
    
    public function new(vertexShader : IShader = null, fragmentShader : IShader = null)
    {
        this.vertexShader = (vertexShader != null ) ? vertexShader : new StandardVertexShader();
        this.fragmentShader = (fragmentShader != null ) ?  fragmentShader : new VertexColorFragmentShader();
        textures = new Vector<Texture>();
        colorVector = new Vector<Float>();
        color = 0xFFFFFF;
    }
    
    public function addProgramRef() : Void
    {
        if (program != null)
        {
            Program3DCache.addRefProgram3D(program);
        }
    }
    
    public function releaseProgramRef() : Void
    {
        if (program != null)
        {
            Program3DCache.releaseProgram3D(program);
        }
    }
    
    public function dispose() : Void
    {
        if (program != null)
        {
            Program3DCache.releaseProgram3D(program);
            program = null;
        }
        textures = new Vector<Texture>();
    }
    
    public function restoreOnLostContext() : Void
    {
        if (program != null)
        {
            Program3DCache.releaseProgram3D(program, true);
            program = null;
        }
    }
    
    private function set_textures(value : Vector<Texture>) : Vector<Texture>
    {
        _textures = value;
        return value;
    }
    
    private function get_textures() : Vector<Texture>
    {
        return _textures;
    }
    
    private function set_vertexShader(value : IShader) : IShader
    {
        _vertexShader = value;
        if (program != null)
        {
            Program3DCache.releaseProgram3D(program);
            program = null;
        }
        return value;
    }
    
    private function get_vertexShader() : IShader
    {
        return _vertexShader;
    }
    
    private function set_fragmentShader(value : IShader) : IShader
    {
        _fragmentShader = value;
        if (program != null)
        {
            Program3DCache.releaseProgram3D(program);
            program = null;
        }
        return value;
    }
    
    private function get_fragmentShader() : IShader
    {
        return _fragmentShader;
    }
    
    
    private function get_alpha() : Float
    {
        return _alpha;
    }
    
    private function set_alpha(value : Float) : Float
    {
        _alpha = value;
        return value;
    }
    
    private function get_color() : Int
    {
        return _color;
    }
    
    private function set_color(value : Int) : Int
    {
        _color = value;
        colorVector[0] = (_color >> 16) / 255;
        colorVector[1] = ((_color & 0x00FF00) >> 8) / 255;
        colorVector[2] = (_color & 0x0000FF) / 255;
        return value;
    }
    
    public function drawTriangles(context : Context3D, matrix : Matrix3D, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1, numTriangles : Int = -1) : Void
    {
        drawTrianglesEx(context, matrix, vertexBuffer, indexBuffer, alpha, numTriangles, 0);
    }
    
    public function drawTrianglesEx(context : Context3D, matrix : Matrix3D, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1, numTriangles : Int = -1, startTriangle : Int = 0) : Void
    {
        context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
        context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4);
        context.setVertexBufferAt(2, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_2);
        
        if (program == null && _vertexShader != null && _fragmentShader != null)
        {
            program = Program3DCache.getProgram3D(context, _vertexShader, _fragmentShader);
        }
        context.setProgram(program);
        
        for (i in 0...8)
        {
            context.setTextureAt(i, (i < _textures.length) ? _textures[i].base : null);
        }
        
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
        _vertexShader.setConstants(context, 4);
        colorVector[3] = _alpha * alpha;  // Multiply display obect's alpha by material alpha.  
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, colorVector);
        _fragmentShader.setConstants(context, 1);
        
        context.drawTriangles(indexBuffer, startTriangle, numTriangles);
    }
    
    
    private function get_premultipliedAlpha() : Bool
    {
        return _premultipliedAlpha;
    }
    
    private function set_premultipliedAlpha(value : Bool) : Bool
    {
        _premultipliedAlpha = value;
        return value;
    }
}
