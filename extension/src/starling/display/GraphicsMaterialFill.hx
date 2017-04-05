package starling.display;

import starling.display.IGraphicsData;
import starling.display.materials.IMaterial;
import flash.geom.Matrix;

/**
	 * ...
	 * @author Henrik Jonsson
	 */
class GraphicsMaterialFill implements IGraphicsData
{
    public var material(get, never) : IMaterial;
    public var matrix(get, never) : Matrix;

    private var mMaterial : IMaterial;
    private var mMatrix : Matrix;
    
    public function new(material : IMaterial, uvMatrix : Matrix = null)
    {
        mMaterial = material;
        mMatrix = uvMatrix;
    }
    
    private function get_material() : IMaterial
    {
        return mMaterial;
    }
    
    private function get_matrix() : Matrix
    {
        return mMatrix;
    }
}

