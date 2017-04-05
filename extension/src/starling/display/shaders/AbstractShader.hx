package starling.display.shaders;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.utils.ByteArray;
import openfl.utils.AGALMiniAssembler;

class AbstractShader implements IShader
{
    public var opCode(get, never) : ByteArray;

    private static var assembler : AGALMiniAssembler;
    
    private var _opCode : ByteArray;
    
    public function new()
    {
    }
    
    private function compileAGAL(shaderType : String, agal : String) : Void
    {
        if (assembler == null)
        {
            assembler = new AGALMiniAssembler();
        }
        assembler.assemble(shaderType, agal);
        _opCode = assembler.agalcode;
    }
    
    private function get_opCode() : ByteArray
    {
        return _opCode;
    }
    
    public function setConstants(context : Context3D, firstRegister : Int) : Void
    {
    }
}

