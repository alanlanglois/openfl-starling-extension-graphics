package starling.display;

import starling.textures.Texture;
import flash.geom.Matrix;

/**
	 * ...
	 * @author Henrik Jonsson
	 */
class GraphicsTextureFill implements IGraphicsData
{
    public var texture(get, never) : Texture;
    public var matrix(get, never) : Matrix;

    private var mTexture : Texture;
    private var mMatrix : Matrix;
    
    public function new(texture : Texture, matrix : Matrix = null)
    {
        mTexture = texture;
        mMatrix = matrix;
    }
    
    private function get_texture() : Texture
    {
        return mTexture;
    }
    
    private function get_matrix() : Matrix
    {
        return mMatrix;
    }
}

