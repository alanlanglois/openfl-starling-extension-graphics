package starling.textures;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Matrix;
import starling.textures.Texture;

class GradientTexture
{
    public static function create(width : Float, height : Float, type : String, colors : Array<Dynamic>, alphas : Array<Dynamic>, ratios : Array<Dynamic>, matrix : Matrix = null, spreadMethod : String = "pad", interpolationMethod : String = "rgb", focalPointRatio : Float = 0) : Texture
    {
        var shape : Shape = new Shape();
        shape.graphics.beginGradientFill(type, colors, alphas, ratios, matrix, spreadMethod, interpolationMethod, focalPointRatio);
        shape.graphics.drawRect(0, 0, width, height);
        
        var bitmapData : BitmapData = new BitmapData(width, height, true);
        bitmapData.draw(shape);
        
        return Texture.fromBitmapData(bitmapData);
    }

    public function new()
    {
    }
}
