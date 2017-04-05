package starling.display.materials;

import starling.display.shaders.IShader;
import starling.display.shaders.fragment.TextureFragmentShader;
import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
import starling.display.shaders.fragment.VertexColorFragmentShader;
import starling.display.shaders.vertex.StandardVertexShader;
import starling.textures.Texture;

class TextureMaterial extends StandardMaterial
{
    public function new(texture : Texture, color : Int = 0xFFFFFF, premultipliedAlpha : Bool = true, mipmapping : Bool = false, repeat : Bool = false, smoothing : String = "bilinear")
    {
        super(new StandardVertexShader(), new TextureVertexColorFragmentShader(texture, mipmapping, repeat, smoothing));
        textures[0] = texture;
        this.color = color;
        
        // Texture data has likely come from flash's BitmapData class, which pre-multiplies the RGB channels
        // by the alpha channel. If using ATF textures - or images loaded via some other method, you'll want to
        // set this to false to get correct blending.
        _premultipliedAlpha = premultipliedAlpha;
    }
}

