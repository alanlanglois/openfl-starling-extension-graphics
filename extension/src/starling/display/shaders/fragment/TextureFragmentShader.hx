package starling.display.shaders.fragment;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import starling.display.shaders.AbstractShader;

/*
	* A pixel shader that multiplies a single texture with constants (the color transform).
	*/
class TextureFragmentShader extends AbstractShader
{
    public function new()
    {
        super();
        var agal : String = 
        "tex ft1, v1, fs0 <2d, repeat, linear> \n" +
        "mul oc, ft1, fc0";
        
        compileAGAL(Context3DProgramType.FRAGMENT, agal);
    }
}
