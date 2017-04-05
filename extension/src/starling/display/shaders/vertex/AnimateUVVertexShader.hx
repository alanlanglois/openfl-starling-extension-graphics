package starling.display.shaders.vertex;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import starling.display.shaders.AbstractShader;

class AnimateUVVertexShader extends AbstractShader
{
    public var uSpeed : Float = 1;
    public var vSpeed : Float = 1;
    
    public function new(uSpeed : Float = 1, vSpeed : Float = 1)
    {
        super();
        this.uSpeed = uSpeed;
        this.vSpeed = vSpeed;
        
        var agal : String = 
        "m44 op, va0, vc0 \n" +  // Apply matrix  
        "mov v0, va1 \n" +  // Copy color to v0  
        "sub vt0, va2, vc4 \n" +
        "mov v1, vt0 \n";
        
        compileAGAL(Context3DProgramType.VERTEX, agal);
    }
    
    override public function setConstants(context : Context3D, firstRegister : Int) : Void
    {
        var phase : Float = Math.round(haxe.Timer.stamp() * 1000) / 1000;
        var uOffset : Float = phase * uSpeed;
        var vOffset : Float = phase * vSpeed;
        
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, firstRegister, [uOffset, vOffset, 0, 0]);
    }
}
