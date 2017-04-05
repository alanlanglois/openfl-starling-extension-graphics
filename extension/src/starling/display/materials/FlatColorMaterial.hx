package starling.display.materials;

import starling.display.shaders.IShader;

class FlatColorMaterial extends StandardMaterial
{
    public function new(color : Int = 0xFFFFFF)
    {
        super();
        this.color = color;
    }
}
