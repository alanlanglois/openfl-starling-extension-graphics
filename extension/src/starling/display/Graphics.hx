package starling.display;

import flash.errors.Error;
import flash.display.BitmapData;
import flash.geom.Matrix;
import openfl.Vector;
import starling.display.graphics.Fill;
import starling.display.graphics.Graphic;
import starling.display.graphics.NGon;
import starling.display.graphics.Plane;
import starling.display.graphics.RoundedRectangle;
import starling.display.graphics.Stroke;
import starling.display.graphics.StrokeVertex;
import starling.display.materials.IMaterial;
import starling.display.shaders.fragment.TextureFragmentShader;
import starling.display.util.CurveUtil;
import starling.textures.Texture;

class Graphics
{
    public var precisionHitTest(get, set) : Bool;
    public var precisionHitTestDistance(get, set) : Float;

    private static inline var BEZIER_ERROR : Float = 0.75;
    
    // Shared texture fragment shader used across all child Graphic's drawn
    // with a textured fill or stroke.
    private static var s_textureFragmentShader : TextureFragmentShader = new TextureFragmentShader();
    
    
    private var _container : DisplayObjectContainer;  // The owner of this Graphics instance.  
    private var _penPosX : Float;
    private var _penPosY : Float;
    
    // Fill state vars
    private var _currentFill : Fill;
    private var _fillStyleSet : Bool;
    private var _fillColor : Int;
    private var _fillAlpha : Float;
    private var _fillTexture : Texture;
    private var _fillMaterial : IMaterial;
    private var _fillMatrix : Matrix;
    
    // Stroke state vars
    private var _currentStroke : Stroke;
    private var _strokeStyleSet : Bool;
    private var _strokeThickness : Float;
    private var _strokeColor : Int;
    private var _strokeAlpha : Float;
    private var _strokeTexture : Texture;
    private var _strokeMaterial : IMaterial;
    private var _strokeInterrupted : Bool;
    
    private var _precisionHitTest : Bool = false;
    private var _precisionHitTestDistance : Float = 0;
    
    
    public function new(displayObjectContainer : DisplayObjectContainer)
    {
        _container = displayObjectContainer;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    /////////////////////////////////////////////////////////////////////////////////////////
    
    public function clear() : Void
    {
        while (_container.numChildren > 0)
        {
            var child : DisplayObject = _container.getChildAt(0);
            child.dispose();
            _container.removeChildAt(0);
        }
        
        _penPosX = Math.NaN;
        _penPosY = Math.NaN;
        
        endStroke();
        endFill();
    }
    
    public function dispose() : Void
    {
        while (_container.numChildren > 0)
        {
            var child : DisplayObject = _container.getChildAt(0);
            child.dispose();
            _container.removeChildAt(0);
        }
        
        _penPosX = Math.NaN;
        _penPosY = Math.NaN;
        
        disposeStroke();
        disposeFill();
    }
    
    ////////////////////////////////////////
    // Fill-style
    ////////////////////////////////////////
    
    public function beginFill(color : Int, alpha : Float = 1.0) : Void
    {
        endFill();
        
        _fillStyleSet = true;
        _fillColor = color;
        _fillAlpha = alpha;
        _fillTexture = null;
        _fillMaterial = null;
        _fillMatrix = null;
    }
    
    public function beginTextureFill(texture : Texture, uvMatrix : Matrix = null, color : Int = 0xFFFFFF, alpha : Float = 1.0) : Void
    {
        endFill();
        
        _fillStyleSet = true;
        _fillColor = color;
        _fillAlpha = alpha;
        _fillTexture = texture;
        _fillMaterial = null;
        _fillMatrix = new Matrix();
        
        if (uvMatrix != null)
        {
            _fillMatrix = uvMatrix.clone();
            _fillMatrix.invert();
        }
        else
        {
            _fillMatrix = new Matrix();
        }
        
        _fillMatrix.scale(1 / texture.width, 1 / texture.height);
    }
    
    public function beginMaterialFill(material : IMaterial, uvMatrix : Matrix = null) : Void
    {
        endFill();
        
        _fillStyleSet = true;
        _fillColor = material.color;
        _fillAlpha = material.alpha;
        _fillTexture = null;
        _fillMaterial = material;
        if (uvMatrix != null)
        {
            _fillMatrix = uvMatrix.clone();
            _fillMatrix.invert();
        }
        else
        {
            _fillMatrix = new Matrix();
        }
        if (material.textures.length > 0)
        {
            _fillMatrix.scale(1 / material.textures[0].width, 1 / material.textures[0].height);
        }
    }
    
    public function endFill() : Void
    {
        _fillStyleSet = false;
        _fillColor = Std.int(Math.NaN);
        _fillAlpha = Std.int(Math.NaN);
        _fillTexture = null;
        _fillMaterial = null;
        _fillMatrix = null;
        
        // If we started drawing with a fill, but ended drawing
        // before we did anything visible with it, dispose it here.
        if (_currentFill != null && _currentFill.numVertices < 3)
        {
            _currentFill.dispose();
            _container.removeChild(_currentFill);
        }
        _currentFill = null;
    }
    
    private function disposeFill() : Void
    {
        _fillStyleSet = false;
        _fillColor = Std.int(Math.NaN);
        _fillAlpha = Std.int(Math.NaN);
        _fillTexture = null;
        _fillMaterial = null;
        _fillMatrix = null;
        
        if (_currentFill != null)
        {
            _currentFill.dispose();
            _container.removeChild(_currentFill);
        }
        _currentFill = null;
    }
    
    ////////////////////////////////////////
    // Stroke-style
    ////////////////////////////////////////
    
    public function lineStyle(thickness : Float = -1, color : Int = 0, alpha : Float = 1.0) : Void
    {
        endStroke();
        
        _strokeStyleSet = !Math.isNaN(thickness) && thickness > 0;
        _strokeThickness = thickness;
        _strokeColor = color;
        _strokeAlpha = alpha;
        _strokeTexture = null;
        _strokeMaterial = null;
    }
    
    public function lineTexture(thickness : Float = -1, texture : Texture = null) : Void
    {
        endStroke();
        
        _strokeStyleSet = (thickness != -1) && (thickness > 0) && (texture != null);
        _strokeThickness = thickness;
        _strokeColor = 0xFFFFFF;
        _strokeAlpha = 1;
        _strokeTexture = texture;
        _strokeMaterial = null;
    }
    
    public function lineMaterial(thickness : Float = -1, material : IMaterial = null) : Void
    {
        endStroke();
        
        _strokeStyleSet = (thickness != -1) && thickness > 0 && material != null;
        _strokeThickness = thickness;
        _strokeColor = (material != null) ? material.color : 0xFFFFFF;
        _strokeAlpha = (material != null) ? material.alpha : 1;
        _strokeTexture = null;
        _strokeMaterial = material;
    }
    
    private function endStroke() : Void
    {
        _strokeStyleSet = false;
        _strokeThickness = Math.NaN;
        _strokeColor = Std.int(Math.NaN);
        _strokeAlpha = Std.int(Math.NaN);
        _strokeTexture = null;
        _strokeMaterial = null;
        
        // If we started drawing with a stroke, but ended drawing
        // before we did anything visible with it, dispose it here.
        if (_currentStroke != null && _currentStroke.numVertices < 2)
        {
            _currentStroke.dispose();
        }
        
        _currentStroke = null;
    }
    
    private function disposeStroke() : Void
    {
        _strokeStyleSet = false;
        _strokeThickness = Math.NaN;
        _strokeColor = Std.int(Math.NaN);
        _strokeAlpha = Std.int(Math.NaN);
        _strokeTexture = null;
        _strokeMaterial = null;
        
        if (_currentStroke != null)
        {
            _currentStroke.dispose();
        }
        
        _currentStroke = null;
    }
    
    
    ////////////////////////////////////////
    // Draw commands
    ////////////////////////////////////////
    
    public function moveTo(x : Float, y : Float) : Void
    {
        // Use degenerate methods for moveTo calls.
        // Degenerates allow for better performance as they do not terminate
        // the vertex buffer but instead use zero size polygons to translate
        // from the end point of the last section of the stroke to the
        // start of the new point.
        if (_strokeStyleSet && _currentStroke != null)
        {
            _currentStroke.addDegenerates(x, y);
        }
        
        if (_fillStyleSet)
        {
            if (_currentFill == null)
            {
                // Added to make sure that the first vertex in a shape gets added to the fill as well.
                createFill();
                _currentFill.addVertex(x, y);
            }
            else
            {
                _currentFill.addDegenerates(x, y);
            }
        }
        
        _penPosX = x;
        _penPosY = y;
        _strokeInterrupted = true;
    }
    
    public function lineTo(x : Float, y : Float) : Void
    {
        if (Math.isNaN(_penPosX))
        {
            moveTo(0, 0);
        }
        
        if (_strokeStyleSet)
        {
            // Create a new stroke Graphic if this is the first
            // time we've start drawing something with it.
            if (_currentStroke == null)
            {
                createStroke();
            }
            
            if (_strokeInterrupted || _currentStroke.numVertices == 0)
            {
                if (_strokeMaterial != null)
                {
                    // If we have a material, we don't set the vertex color here, relying on material color during rendering
                    _currentStroke.lineTo(_penPosX, _penPosY, _strokeThickness);
                }
                else
                {
                    _currentStroke.lineTo(_penPosX, _penPosY, _strokeThickness, _strokeColor, _strokeAlpha);
                }
                
                _strokeInterrupted = false;
            }
            if (_strokeMaterial != null)
            {
                // If we have a material, we don't set the vertex color here, relying on material color during rendering
                _currentStroke.lineTo(x, y, _strokeThickness);
            }
            else
            {
                _currentStroke.lineTo(x, y, _strokeThickness, _strokeColor, _strokeAlpha);
            }
        }
        
        if (_fillStyleSet)
        {
            if (_currentFill == null)
            {
                createFill();
            }
            _currentFill.addVertex(x, y);
        }
        
        _penPosX = x;
        _penPosY = y;
    }
    
    public function curveTo(cx : Float, cy : Float, a2x : Float, a2y : Float, error : Float = BEZIER_ERROR) : Void
    {
        var startX : Float = _penPosX;
        var startY : Float = _penPosY;
        
        if (Math.isNaN(startX))
        {
            startX = 0;
            startY = 0;
        }
        
        var points : Array<Float> = CurveUtil.quadraticCurve(startX, startY, cx, cy, a2x, a2y, error);
        
        var L : Int = points.length;
        var i : Int = 0;
        while (i < L)
        {
            var x : Float = points[i];
            var y : Float = points[i + 1];
            
            if (i == 0 && Math.isNaN(_penPosX))
            {
                moveTo(x, y);
            }
            else
            {
                lineTo(x, y);
            }
            i += 2;
        }
        
        _penPosX = a2x;
        _penPosY = a2y;
    }
    
    public function cubicCurveTo(c1x : Float, c1y : Float, c2x : Float, c2y : Float, a2x : Float, a2y : Float, error : Float = BEZIER_ERROR) : Void
    {
        var startX : Float = _penPosX;
        var startY : Float = _penPosY;
        
        if (Math.isNaN(startX))
        {
            startX = 0;
            startY = 0;
        }
        
        var points : Array<Float> = CurveUtil.cubicCurve(startX, startY, c1x, c1y, c2x, c2y, a2x, a2y, error);
        
        var L : Int = points.length;
        var i : Int = 0;
        while (i < L)
        {
            var x : Float = points[i];
            var y : Float = points[i + 1];
            
            if (i == 0 && Math.isNaN(_penPosX))
            {
                moveTo(x, y);
            }
            else
            {
                lineTo(x, y);
            }
            i += 2;
        }
        
        _penPosX = a2x;
        _penPosY = a2y;
    }
    
    public function drawCircle(x : Float, y : Float, radius : Float) : Void
    {
        drawEllipse(x, y, radius * 2, radius * 2);
    }
    
    public function drawEllipse(x : Float, y : Float, width : Float, height : Float) : Void
    {
        // Calculate num-sides based on a blend between circumference of width and circumference of height.
        // Should provide good results for ellipses with similar widths/heights.
        // Will look bad on very thin ellipses.
        var numSides : Int = as3hx.Compat.parseInt(Math.PI * (width * 0.5 + height * 0.5) * 0.25);
        numSides = (numSides < 6) ? 6 : numSides;
        
        // Use an NGon primitive instead of fill to bypass triangulation.
        if (_fillStyleSet)
        {
            var nGon : NGon = new NGon(width * 0.5, numSides);
            nGon.x = x;
            nGon.y = y;
            nGon.scaleY = height / width;
            
            applyFillStyleToGraphic(nGon);
            
            var m : Matrix = new Matrix();
            m.scale(width, height);
            if (_fillMatrix != null)
            {
                m.concat(_fillMatrix);
            }
            nGon.uvMatrix = m;
            nGon.precisionHitTest = _precisionHitTest;
            nGon.precisionHitTestDistance = _precisionHitTestDistance;
            
            _container.addChild(nGon);
        }
        
        // Draw the stroke
        if (_strokeStyleSet)
        {
            // Null the currentFill after storing it in a local var.
            // This ensures the moveTo/lineTo calls for the stroke below don't
            // end up adding any points to a current fill (as we've already done
            // this in a more efficient manner above).
            var storedFill : Fill = _currentFill;
            _currentFill = null;
            var storedFillStyleSet : Bool = _fillStyleSet;
            _fillStyleSet = false;
            
            var halfWidth : Float = width * 0.5;
            var halfHeight : Float = height * 0.5;
            var anglePerSide : Float = (Math.PI * 2) / (numSides);
            var a : Float = Math.cos(anglePerSide);
            var b : Float = Math.sin(anglePerSide);
            var s : Float = 0.0;
            var c : Float = 1.0;
            
            for (i in 0...numSides + 1)
            {
                var sx : Float = s * halfWidth + x;
                var sy : Float = -c * halfHeight + y;
                if (i == 0)
                {
                    moveTo(sx, sy);
                }
                else
                {
                    lineTo(sx, sy);
                }
                
                var ns : Float = b * c + a * s;
                var nc : Float = a * c - b * s;
                c = nc;
                s = ns;
            }
            
            // Reinstate the fill
            _currentFill = storedFill;
            _fillStyleSet = storedFillStyleSet;
        }
    }
    
    
    public function drawRect(x : Float, y : Float, width : Float, height : Float) : Void
    {
        // Use a Plane primitive instead of fill to side-step triangulation.
        if (_fillStyleSet)
        {
            var plane : Plane = new Plane(width, height);
            
            applyFillStyleToGraphic(plane);
            
            var m : Matrix = new Matrix();
            m.scale(width, height);
            if (_fillMatrix != null)
            {
                m.concat(_fillMatrix);
            }
            plane.uvMatrix = m;
            plane.x = x;
            plane.y = y;
            _container.addChild(plane);
        }
        
        // Draw the stroke
        if (_strokeStyleSet)
        {
            // Null the currentFill after storing it in a local var.
            // This ensures the moveTo/lineTo calls for the stroke below don't
            // end up adding any points to a current fill (as we've already done
            // this in a more efficient manner above).
            var storedFill : Fill = _currentFill;
            _currentFill = null;
            var storedFillStyleSet : Bool = _fillStyleSet;
            _fillStyleSet = false;
            
            moveTo(x, y);
            lineTo(x + width, y);
            lineTo(x + width, y + height);
            lineTo(x, y + height);
            lineTo(x, y - (_strokeThickness * 0.5));  // adding this to solve upper left corner being misshapen. Issue https://github.com/StarlingGraphics/Starling-Extension-Graphics/issues/109  
            
            _currentFill = storedFill;
            _fillStyleSet = storedFillStyleSet;
        }
    }
    
    public function drawRoundRect(x : Float, y : Float, width : Float, height : Float, radius : Float) : Void
    {
        drawRoundRectComplex(x, y, width, height, radius, radius, radius, radius);
    }
    
    public function drawRoundRectComplex(x : Float, y : Float, width : Float, height : Float,
            topLeftRadius : Float, topRightRadius : Float,
            bottomLeftRadius : Float, bottomRightRadius : Float) : Void
    {
		var storedFill : Fill = null;
		
        // Early-out if not fill or stroke style set.
        if (!_fillStyleSet && !_strokeStyleSet)
        {
            return;
        }
        
        var roundedRect : RoundedRectangle = new RoundedRectangle(width, height, topLeftRadius, 
        topRightRadius, bottomLeftRadius, 
        bottomRightRadius);
        
        // Draw fill
        if (_fillStyleSet)
        {
            applyFillStyleToGraphic(roundedRect);
            
            var m : Matrix = new Matrix();
            m.scale(width, height);
            if (_fillMatrix != null)
            {
                m.concat(_fillMatrix);
            }
            roundedRect.uvMatrix = m;
            roundedRect.x = x;
            roundedRect.y = y;
            _container.addChild(roundedRect);
        }
        _currentFill = storedFill;
        
        if (_strokeStyleSet)
        {
            // Null the currentFill after storing it in a local var.
            // This ensures the moveTo/lineTo calls for the stroke below don't
            // end up adding any points to a current fill (as we've already done
            // this in a more efficient manner above).
            storedFill = _currentFill;
            _currentFill = null;
            var storedFillStyleSet : Bool = _fillStyleSet;
            _fillStyleSet = false;
            
            var strokePoints : Vector<Float> = roundedRect.getStrokePoints();
            var i : Int = 0;
            while (i < strokePoints.length)
            {
                if (i == 0)
                {
                    moveTo(x + strokePoints[i], y + strokePoints[i + 1]);
                }
                else
                {
                    if (i == strokePoints.length - 2)
                    {
                        var lastYPointOffset : Float = 0;
                        if (topLeftRadius < _strokeThickness)
                        {
                            lastYPointOffset = topLeftRadius * 0.5;
                        }
                        else
                        {
                            lastYPointOffset = _strokeThickness * 0.5;
                        }
                        
                        lineTo(x + strokePoints[i], y + strokePoints[i + 1] - lastYPointOffset);
                    }
                    else
                    {
                        lineTo(x + strokePoints[i], y + strokePoints[i + 1]);
                    }
                }
                i += 2;
            }
            
            _currentFill = storedFill;
            _fillStyleSet = storedFillStyleSet;
        }
    }
    
    
    /**
		 * Used for geometry level hit tests. 
		 * False gives boundingbox results, True gives geometry level results.
		 * True is a lot more exact, but also slower. 
		 */
    private function set_precisionHitTest(value : Bool) : Bool
    {
        _precisionHitTest = value;
        if (_currentFill != null)
        {
            _currentFill.precisionHitTest = value;
        }
        if (_currentStroke != null)
        {
            _currentStroke.precisionHitTest = value;
        }
        return value;
    }
    
    private function get_precisionHitTest() : Bool
    {
        return _precisionHitTest;
    }
    
    private function set_precisionHitTestDistance(value : Float) : Float
    {
        _precisionHitTestDistance = value;
        if (_currentFill != null)
        {
            _currentFill.precisionHitTestDistance = value;
        }
        if (_currentStroke != null)
        {
            _currentStroke.precisionHitTestDistance = value;
        }
        return value;
    }
    
    private function get_precisionHitTestDistance() : Float
    {
        return _precisionHitTestDistance;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // PROTECTED
    /////////////////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////
    // Overridable functions for custom
    // Fill/Stroke types
    ////////////////////////////////////////
    
    private function getStrokeInstance() : Stroke
    {
        return new Stroke();
    }
    
    private function getFillInstance() : Fill
    {
        return new Fill();
    }
    
    /**
		 * Creates a Stroke instance and inits its material based on the
		 * currently set stroke style.
		 * Result is stored in _currentStroke.
		 */
    private function createStroke() : Void
    {
        if (_currentStroke != null)
        {
            throw (new Error("Current stroke should be disposed via endStroke() first."));
        }
        
        _currentStroke = getStrokeInstance();
        _currentStroke.precisionHitTest = _precisionHitTest;
        _currentStroke.precisionHitTestDistance = _precisionHitTestDistance;
        
        applyStrokeStyleToGraphic(_currentStroke);
        
        _container.addChild(_currentStroke);
    }
    
    /**
		 * Creates a Fill instance and inits its material based on the
		 * currently set fill style.
		 * Result is stored in _currentFill.
		 */
    private function createFill() : Void
    {
        if (_currentFill != null)
        {
            throw (new Error("Current stroke should be disposed via endFill() first."));
        }
        
        _currentFill = getFillInstance();
        if (_fillMatrix != null)
        {
            _currentFill.uvMatrix = _fillMatrix;
        }
        _currentFill.precisionHitTest = _precisionHitTest;
        _currentFill.precisionHitTestDistance = _precisionHitTestDistance;
        applyFillStyleToGraphic(_currentFill);
        
        _container.addChild(_currentFill);
    }
    
    private function applyStrokeStyleToGraphic(graphic : Graphic) : Void
    {
        if (_strokeMaterial != null)
        {
            graphic.material = _strokeMaterial;
        }
        else
        {
            if (_strokeTexture != null)
            {
                graphic.material.fragmentShader = s_textureFragmentShader;
                graphic.material.textures[0] = _strokeTexture;
            }
        }
        graphic.material.color = _strokeColor;
        graphic.material.alpha = _strokeAlpha;
    }
    
    private function applyFillStyleToGraphic(graphic : Graphic) : Void
    {
        if (_fillMaterial != null)
        {
            graphic.material = _fillMaterial;
        }
        else
        {
            if (_fillTexture != null)
            {
                graphic.material.fragmentShader = s_textureFragmentShader;
                graphic.material.textures[0] = _fillTexture;
            }
        }
        if (_fillMatrix != null)
        {
            graphic.uvMatrix = _fillMatrix;
        }
        graphic.material.color = _fillColor;
        graphic.material.alpha = _fillAlpha;
    }
}

