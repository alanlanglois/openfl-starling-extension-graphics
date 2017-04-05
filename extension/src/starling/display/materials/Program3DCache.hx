package starling.display.materials;

import flash.errors.Error;
import flash.utils.Dictionary;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import starling.display.shaders.IShader;

class Program3DCache
{
    // The number of Program3D instances the cache will allow to sit
    // unreferenced before flushing unused instances.
    // Having this buffer avoids the (common) situation where a Program3D
    // gets created/destroyed each frame in-line with draw/clear() calls
    // to the graphics API. Which is expensive to say the least.
    private static inline var LAZY_CACHE_SIZE : Int = 8;
    
    private static var uid : Int = 0;
    private static var uidByShaderTable : Dictionary<IShader, Dynamic> = new Dictionary(true);
    private static var programByUIDTable : Dynamic = { };
    private static var uidByProgramTable : Dictionary<Program3D, Dynamic> = new Dictionary(false);
    private static var numReferencesByProgramTable : Dictionary<Program3D, Dynamic> = new Dictionary(false);
    private static var cacheSize : Int;  // The number of Program3D instances stored in this cache.  
    
    public static function getProgram3D(context : Context3D, vertexShader : IShader, fragmentShader : IShader) : Program3D
    {
        var vertexShaderUID : Int = uidByShaderTable[vertexShader];
        if (vertexShaderUID == 0)
        {
            vertexShaderUID = uidByShaderTable[vertexShader] = ++uid;
        }
        
        var fragmentShaderUID : Int = uidByShaderTable[fragmentShader];
        if (fragmentShaderUID == 0)
        {
            fragmentShaderUID = uidByShaderTable[fragmentShader] = ++uid;
        }
        
        var program3DUID : String = vertexShaderUID + "_" + fragmentShaderUID;
        
        var program3D : Program3D = Reflect.field(programByUIDTable, program3DUID);
        if (program3D == null)
        {
            program3D = context.createProgram();
			Reflect.setField( programByUIDTable, program3DUID, program3D );
            uidByProgramTable[program3D] = program3DUID;
            program3D.upload(vertexShader.opCode, fragmentShader.opCode);
            numReferencesByProgramTable[program3D] = 1;
            cacheSize++;
        }
        else
        {
            addRefProgram3D(program3D);
        }
        
        if (cacheSize > LAZY_CACHE_SIZE)
        {
            flush();
        }
        
        return program3D;
    }
    
    public static function addRefProgram3D(program3D : Program3D) : Void
    {
        if (numReferencesByProgramTable[program3D] == null)
        {
            throw (new Error("Program3D is not in cache"));
            return;
        }
        
        numReferencesByProgramTable[program3D]++;
    }
    
    public static function releaseProgram3D(program3D : Program3D, forceFlush : Bool = false) : Void
    {
        if (numReferencesByProgramTable[program3D] == null)
        {
            throw (new Error("Program3D is not in cache"));
            return;
        }
        
        numReferencesByProgramTable[program3D]--;
        if (forceFlush)
        {
            flush();
        }
    }
    
    /**
		 * This is called when the number of cached programs exceeds LAZY_CACHE_SIZE.
		 * Kicks out a single Program3D's with zero references.
		 */
    private static function flush() : Void
    {
        for (uid in Reflect.fields(programByUIDTable))
        {
            var program3D : Program3D = Reflect.field(programByUIDTable, uid);
            var numReferences : Int = numReferencesByProgramTable[program3D];
            if (numReferences > 0)
            {
                continue;
            }
            
            program3D.dispose();
            //This is an intentional compilation error. See the README for handling the delete keyword
            numReferencesByProgramTable[program3D] = null;
            var program3DUID : String = uidByProgramTable[program3D];
            Reflect.deleteField(programByUIDTable, program3DUID);
            //This is an intentional compilation error. See the README for handling the delete keyword
            //delete uidByProgramTable[program3D];
            uidByProgramTable[program3D] = null;
            cacheSize--;
            return;
        }
    }

    @:allow(starling.display.materials)
    private function new()
    {
    }
}
