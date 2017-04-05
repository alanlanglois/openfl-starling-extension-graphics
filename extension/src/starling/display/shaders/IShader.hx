package starling.display.shaders;

import flash.display3D.Context3D;
import flash.utils.ByteArray;

interface IShader
{
    
    var opCode(get, never) : ByteArray;
function setConstants(context : Context3D, firstRegister : Int) : Void
    ;
}
