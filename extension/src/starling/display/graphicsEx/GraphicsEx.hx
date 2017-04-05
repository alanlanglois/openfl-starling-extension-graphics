package starling.display.graphicsEx;

import flash.geom.Point;
import starling.display.geom.GraphicsPolygon;
import starling.display.graphics.Graphic;
import starling.display.graphics.Stroke;
import starling.display.graphics.StrokeVertex;
import starling.display.IGraphicsData;
import flash.display.GraphicsPath;
import flash.display.IGraphicsData;
import flash.display.IGraphicsFill;
import flash.display.GraphicsSolidFill;
import flash.display.GraphicsGradientFill;

import starling.textures.GradientTexture;
import starling.display.GraphicsPath;
import starling.display.GraphicsPathCommands;

import starling.display.Graphics;
import starling.textures.Texture;
import starling.display.materials.IMaterial;
import starling.display.DisplayObjectContainer;
import starling.display.util.CurveUtil;
import starling.display.graphics.Fill;

class GraphicsEx extends Graphics
{
    public var currentLineIndex(get, never) : Int;

    private var _currentStrokeEx : StrokeEx;
    private var _strokeCullDistance : Float;
    public function new(displayObjectContainer : DisplayObjectContainer, strokeCullDistance : Float = 0)
    {
        _strokeCullDistance = strokeCullDistance;
        
        super(displayObjectContainer);
    }
    
    override private function endStroke() : Void
    {
        super.endStroke();
        
        _currentStrokeEx = null;
    }
    
    private function get_currentLineIndex() : Int
    {
        if (_currentStroke != null)
        {
            return _currentStroke.numVertices;
        }
        else
        {
            return 0;
        }
    }
    
    public function currentLineLength() : Float
    {
        if (_currentStrokeEx != null)
        {
            return _currentStrokeEx.strokeLength();
        }
        else
        {
            return 0;
        }
    }
    
    public function currentStroke() : StrokeEx
    {
        return _currentStrokeEx;
    }
    
    public function drawGraphicsData(graphicsData : Array<flash.display.IGraphicsData>) : Void
    {
        var i : Int = 0;
        var vectorLength : Int = graphicsData.length;
        for (i in 0...vectorLength)
        {
            var gfxData : flash.display.IGraphicsData = graphicsData[i];
            handleGraphicsDataType(gfxData);
        }
    }
    
    private function handleGraphicsDataType(gfxData : flash.display.IGraphicsData) : Void
    {
        if (Std.is(gfxData, flash.display.GraphicsPath))
        {
            var gfxPath : flash.display.GraphicsPath = try cast(gfxData, flash.display.GraphicsPath) catch(e:Dynamic) null;
            if (gfxPath != null)
            {
                var cmds : Array<Int> = try cast(gfxPath.commands, Array/*Vector.<T> call?*/) catch(e:Dynamic) null;
                var data : Array<Float> = try cast(gfxPath.data, Array/*Vector.<T> call?*/) catch(e:Dynamic) null;
                var winding : String = Std.string(gfxPath.winding);
                if (cmds != null && data != null && winding != null)
                {
                    drawPath(cmds, data, winding);
                }
            }
        }
        else
        {
            if (Std.is(gfxData, flash.display.GraphicsEndFill))
            {
                endFill();
            }
            else
            {
                //	else if ( gfxData is flash.display.GraphicsBitmapFill ) // TODO - With the righteous removal of GraphicsBitmapFill, how do we solve this? /IonSwitz  //		beginBitmapFill(flash.display.GraphicsBitmapFill(gfxData).bitmapData, flash.display.GraphicsBitmapFill(gfxData).matrix);  if (Std.is(gfxData, flash.display.GraphicsSolidFill))
                {
                    beginFill(flash.display.GraphicsSolidFill(gfxData).color, flash.display.GraphicsSolidFill(gfxData).alpha);
                }
                else
                {
                    if (Std.is(gfxData, flash.display.GraphicsGradientFill))
                    {
                        var gradientFill : flash.display.GraphicsGradientFill = try cast(gfxData, flash.display.GraphicsGradientFill) catch(e:Dynamic) null;
                        var gradTexture : Texture = GradientTexture.create(128, 128, gradientFill.type, gradientFill.colors, gradientFill.alphas, gradientFill.ratios, gradientFill.matrix, gradientFill.spreadMethod, gradientFill.interpolationMethod, gradientFill.focalPointRatio);
                        beginTextureFill(gradTexture);
                    }
                    else
                    {
                        if (Std.is(gfxData, flash.display.GraphicsStroke))
                        {
                            var solidFill : flash.display.GraphicsSolidFill = try cast(flash.display.GraphicsStroke(gfxData).fill, flash.display.GraphicsSolidFill) catch(e:Dynamic) null;
                            var bitmapFill : flash.display.GraphicsBitmapFill = try cast(flash.display.GraphicsStroke(gfxData).fill, flash.display.GraphicsBitmapFill) catch(e:Dynamic) null;
                            var strokeGradientFill : flash.display.GraphicsGradientFill = try cast(flash.display.GraphicsStroke(gfxData).fill, flash.display.GraphicsGradientFill) catch(e:Dynamic) null;
                            if (solidFill != null)
                            {
                                lineStyle(flash.display.GraphicsStroke(gfxData).thickness, solidFill.color, solidFill.alpha);
                            }
                            else
                            {
                                if (bitmapFill != null)
                                {
                                    lineTexture(flash.display.GraphicsStroke(gfxData).thickness, Texture.fromBitmapData(bitmapFill.bitmapData, false));
                                }
                                else
                                {
                                    if (strokeGradientFill != null)
                                    {
                                        var strokeGradTexture : Texture = GradientTexture.create(128, 128, strokeGradientFill.type, strokeGradientFill.colors, strokeGradientFill.alphas, strokeGradientFill.ratios, strokeGradientFill.matrix, strokeGradientFill.spreadMethod, strokeGradientFill.interpolationMethod, strokeGradientFill.focalPointRatio);
                                        lineTexture(flash.display.GraphicsStroke(gfxData).thickness, strokeGradTexture);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public function drawGraphicsDataEx(graphicsData : Array<starling.display.IGraphicsData>) : Void
    {
        var i : Int = 0;
        var vectorLength : Int = graphicsData.length;
        for (i in 0...vectorLength)
        {
            var gfxData : starling.display.IGraphicsData = graphicsData[i];
            handleGraphicsDataTypeEx(gfxData);
        }
    }
    
    private function handleGraphicsDataTypeEx(gfxData : starling.display.IGraphicsData) : Void
    {
        if (Std.is(gfxData, GraphicsNaturalSpline))
        {
            naturalCubicSplineTo(cast((gfxData), GraphicsNaturalSpline).controlPoints, cast((gfxData), GraphicsNaturalSpline).closed, cast((gfxData), GraphicsNaturalSpline).steps);
        }
        else
        {
            if (Std.is(gfxData, starling.display.GraphicsPath))
            {
                drawPath(starling.display.GraphicsPath(gfxData).commands, starling.display.GraphicsPath(gfxData).data, starling.display.GraphicsPath(gfxData).winding);
            }
            else
            {
                if (Std.is(gfxData, starling.display.GraphicsEndFill))
                {
                    endFill();
                }
                else
                {
                    if (Std.is(gfxData, starling.display.GraphicsTextureFill))
                    {
                        beginTextureFill(starling.display.GraphicsTextureFill(gfxData).texture, starling.display.GraphicsTextureFill(gfxData).matrix);
                    }
                    else
                    {
                        //	else if ( gfxData is starling.display.GraphicsBitmapFill ) // TODO - With the righteous removal of GraphicsBitmapFill, how do we solve this? /IonSwitz  //		beginBitmapFill(starling.display.GraphicsBitmapFill(gfxData).bitmapData, starling.display.GraphicsBitmapFill(gfxData).matrix);  if (Std.is(gfxData, starling.display.GraphicsMaterialFill))
                        {
                            beginMaterialFill(starling.display.GraphicsMaterialFill(gfxData).material, starling.display.GraphicsMaterialFill(gfxData).matrix);
                        }
                        else
                        {
                            if (Std.is(gfxData, starling.display.GraphicsLine))
                            {
                                lineStyle(starling.display.GraphicsLine(gfxData).thickness, starling.display.GraphicsLine(gfxData).color, starling.display.GraphicsLine(gfxData).alpha);
                            }
                        }
                    }
                }
            }
        }
    }
    
    private function drawCommandInternal(command : Int, data : Array<Float>, dataCounter : Int, winding : String) : Int
    {
        if (command == GraphicsPathCommands.NO_OP)
        {
            return 0;
        }
        else
        {
            if (command == GraphicsPathCommands.MOVE_TO)
            {
                moveTo(data[dataCounter], data[dataCounter + 1]);
                return 2;
            }
            else
            {
                if (command == GraphicsPathCommands.LINE_TO)
                {
                    lineTo(data[dataCounter], data[dataCounter + 1]);
                    return 2;
                }
                else
                {
                    if (command == GraphicsPathCommands.CURVE_TO)
                    {
                        curveTo(data[dataCounter], data[dataCounter + 1], data[dataCounter + 2], data[dataCounter + 3]);
                        return 4;
                    }
                    else
                    {
                        if (command == GraphicsPathCommands.CUBIC_CURVE_TO)
                        {
                            cubicCurveTo(data[dataCounter], data[dataCounter + 1], data[dataCounter + 2], data[dataCounter + 3], data[dataCounter + 4], data[dataCounter + 5]);
                            return 6;
                        }
                        else
                        {
                            if (command == GraphicsPathCommands.WIDE_MOVE_TO)
                            {
                                moveTo(data[dataCounter + 2], data[dataCounter + 3]);
                                return 4;
                            }
                            else
                            {
                                if (command == GraphicsPathCommands.WIDE_LINE_TO)
                                {
                                    lineTo(data[dataCounter + 2], data[dataCounter + 3]);
                                    return 4;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return 0;
    }
    
    public function drawPath(commands : Array<Int>, data : Array<Float>, winding : String = "evenOdd") : Void
    {
        var i : Int = 0;
        var commandLength : Int = commands.length;
        var dataCounter : Int = 0;
        for (i in 0...commandLength)
        {
            var cmd : Int = commands[i];
            dataCounter += drawCommandInternal(cmd, data, dataCounter, winding);
        }
    }
    
    
    
    /**
		 * performs the natural cubic slipne transformation
		 * @param	controlPoints a Vector.<Point> of the control points
		 * @param	closed a boolean to tell wether the curve is opened or closed
		 * @param   steps - an int indicating the number of steps between control points
		 */
    
    public function naturalCubicSplineTo(controlPoints : Array<Dynamic>, closed : Bool, steps : Int = 4) : Void
    {
        var i : Int = 0;
        var j : Float = 0;
        
        var numPoints : Int = controlPoints.length;
        var xpoints : Array<Float> = new Array<Float>();
        var ypoints : Array<Float> = new Array<Float>();
        
        for (i in 0...controlPoints.length)
        {
            xpoints[i] = controlPoints[i].x;
            ypoints[i] = controlPoints[i].y;
        }
        
        var X : Array<Cubic>;
        var Y : Array<Cubic>;
        
        if (closed)
        {
            X = calcClosedNaturalCubic(numPoints - 1, xpoints);
            Y = calcClosedNaturalCubic(numPoints - 1, ypoints);
        }
        else
        {
            X = calcNaturalCubic(numPoints - 1, xpoints);
            Y = calcNaturalCubic(numPoints - 1, ypoints);
        }
        
        
        /* very crude technique - just break each segment up into _steps lines */
        var points : Array<Float> = new Array<Float>();
        
        var invSteps : Float = 1.0 / steps;
        for (i in 0...X.length)
        {
            for (j in 0...steps)
            {
                var u : Float = j * invSteps;
                var valueX : Float = X[i].eval(u);
                var valueY : Float = Y[i].eval(u);
                points[j * 2] = valueX;
                points[j * 2 + 1] = valueY;
            }
            
            drawPointsInternal(points);
        }
    }
    
    public function postProcess(startIndex : Int, endIndex : Int, thicknessData : GraphicsExThicknessData = null, colorData : GraphicsExColorData = null) : Bool
    {
        if (_currentStrokeEx == null)
        {
            return false;
        }
        
        var verts : Array<StrokeVertex> = _currentStrokeEx.strokeVertices;
        var totalVerts : Int = _currentStrokeEx.numVertices;
        if (startIndex >= totalVerts || startIndex < 0)
        {
            return false;
        }
        if (endIndex >= totalVerts || endIndex < 0)
        {
            return false;
        }
        if (startIndex == endIndex)
        {
            return false;
        }
        
        var numVerts : Int = as3hx.Compat.parseInt(endIndex - startIndex);
        if (colorData != null)
        {
            if (thicknessData != null)
            {
                postProcessThicknessColorInternal(numVerts, startIndex, endIndex, verts, thicknessData, colorData);
            }
            else
            {
                postProcessColorInternal(numVerts, startIndex, endIndex, verts, colorData);
            }
        }
        else
        {
            if (thicknessData != null)
            {
                postProcessThicknessInternal(numVerts, startIndex, endIndex, verts, thicknessData);
            }
        }
        _currentStrokeEx.invalidate();
        return true;
    }
    
    private function postProcessThicknessColorInternal(numVerts : Int, startIndex : Int, endIndex : Int, verts : Array<StrokeVertex>, thicknessData : GraphicsExThicknessData, colorData : GraphicsExColorData) : Void
    {
        var invNumVerts : Float = 1.0 / numVerts;
        var lerp : Float = 0;
        var inv255 : Float = 1.0 / 255.0;
        
        var t : Float;  // thickness  
        var r : Float;
        var g : Float;
        var b : Float;
        var a : Float;
        var i : Float;
        
        for (i in startIndex...endIndex + 1)
        {
            t = (thicknessData.startThickness * (1.0 - lerp)) + thicknessData.endThickness * lerp;
            
            r = inv255 * ((colorData.startRed * (1.0 - lerp)) + colorData.endRed * lerp);
            g = inv255 * ((colorData.startGreen * (1.0 - lerp)) + colorData.endGreen * lerp);
            b = inv255 * ((colorData.startBlue * (1.0 - lerp)) + colorData.endBlue * lerp);
            a = ((colorData.startAlpha * (1.0 - lerp)) + colorData.endAlpha * lerp);
            
            Reflect.setField(verts, Std.string(i), t).thickness;
            
            Reflect.setField(verts, Std.string(i), r).r1;
            Reflect.setField(verts, Std.string(i), r).r2;
            Reflect.setField(verts, Std.string(i), g).g1;
            Reflect.setField(verts, Std.string(i), g).g2;
            Reflect.setField(verts, Std.string(i), b).b1;
            Reflect.setField(verts, Std.string(i), b).b2;
            Reflect.setField(verts, Std.string(i), a).a1;
            Reflect.setField(verts, Std.string(i), a).a2;
            
            lerp += invNumVerts;
        }
    }
    
    private function postProcessColorInternal(numVerts : Int, startIndex : Int, endIndex : Int, verts : Array<StrokeVertex>, colorData : GraphicsExColorData) : Void
    {
        var invNumVerts : Float = 1.0 / numVerts;
        var lerp : Float = 0;
        var inv255 : Float = 1.0 / 255.0;
        
        var r : Float;
        var g : Float;
        var b : Float;
        var a : Float;
        
        var i : Float;
        
        for (i in startIndex...endIndex + 1)
        {
            r = inv255 * ((colorData.startRed * (1.0 - lerp)) + colorData.endRed * lerp);
            g = inv255 * ((colorData.startGreen * (1.0 - lerp)) + colorData.endGreen * lerp);
            b = inv255 * ((colorData.startBlue * (1.0 - lerp)) + colorData.endBlue * lerp);
            a = ((colorData.startAlpha * (1.0 - lerp)) + colorData.endAlpha * lerp);
            
            Reflect.setField(verts, Std.string(i), r).r1;
            Reflect.setField(verts, Std.string(i), r).r2;
            Reflect.setField(verts, Std.string(i), g).g1;
            Reflect.setField(verts, Std.string(i), g).g2;
            Reflect.setField(verts, Std.string(i), b).b1;
            Reflect.setField(verts, Std.string(i), b).b2;
            Reflect.setField(verts, Std.string(i), a).a1;
            Reflect.setField(verts, Std.string(i), a).a2;
            
            lerp += invNumVerts;
        }
    }
    
    private function postProcessThicknessInternal(numVerts : Int, startIndex : Int, endIndex : Int, verts : Array<StrokeVertex>, thicknessData : GraphicsExThicknessData) : Void
    {
        var invNumVerts : Float = 1.0 / numVerts;
        var lerp : Float = 0;
        var inv255 : Float = 1.0 / 255.0;
        
        var t : Float;  // thickness  
        var i : Float;
        
        for (i in startIndex...endIndex + 1)
        {
            t = (thicknessData.startThickness * (1.0 - lerp)) + thicknessData.endThickness * lerp;
            Reflect.setField(verts, Std.string(i), t).thickness;
            lerp += invNumVerts;
        }
    }
    
    override private function getStrokeInstance() : Stroke
    {
        // Created to be able to extend class with different strokes for different folks.
        _currentStrokeEx = new StrokeEx();
        _currentStrokeEx.setPointCullDistance(_strokeCullDistance);
        return try cast(_currentStrokeEx, Stroke) catch(e:Dynamic) null;
    }
    
    private function drawPointsInternal(points : Array<Float>) : Void
    {
        var L : Int = points.length;
        if (L > 0)
        {
            var invHalfL : Float = 1.0 / (0.5 * L);
            var i : Int = 0;
            while (i < L)
            {
                var x : Float = points[i];
                var y : Float = points[i + 1];
                
                if (i == 0 && (_penPosX != _penPosX))
                {
                    // Alledgedly the fastest way to do "isNaN(x)". All comparisons with NaN yields false
                    {
                        moveTo(x, y);
                    }
                }
                else
                {
                    lineTo(x, y);
                }
                i += 2;
            }
        }
    }
    
    
    
    private function calcNaturalCubic(n : Int, x : Array<Float>) : Array<Cubic>
    {
        var i : Int;
        var gamma : Array<Float> = new Array<Float>();
        var delta : Array<Float> = new Array<Float>();
        var D : Array<Float> = new Array<Float>();
        
        gamma[0] = 1.0 / 2.0;
        for (i in 1...n)
        {
            gamma[i] = 1 / (4 - gamma[i - 1]);
        }
        gamma[n] = 1 / (2 - gamma[n - 1]);
        
        delta[0] = 3 * (x[1] - x[0]) * gamma[0];
        
        
        for (i in 1...n)
        {
            delta[i] = (3 * (x[i + 1] - x[i - 1]) - delta[i - 1]) * gamma[i];
        }
        delta[n] = (3 * (x[n] - x[n - 1]) - delta[n - 1]) * gamma[n];
        
        
        D[n] = delta[n];
        
        i = as3hx.Compat.parseInt(n - 1);
        while (i >= 0)
        {
            D[i] = delta[i] - gamma[i] * D[i + 1];
            i--;
        }
        
        /* now compute the coefficients of the cubics */
        var C : Array<Cubic> = new Array<Cubic>();
        
        for (i in 0...n)
        {
            C[i] = new Cubic(
                    x[i], 
                    D[i], 
                    3 * (x[i + 1] - x[i]) - 2 * D[i] - D[i + 1], 
                    2 * (x[i] - x[i + 1]) + D[i] + D[i + 1]);
        }
        return C;
    }
    
    
    
    private function calcClosedNaturalCubic(n : Int, x : Array<Float>) : Array<Cubic>
    {
        var w : Array<Float> = new Array<Float>();
        var v : Array<Float> = new Array<Float>();
        var y : Array<Float> = new Array<Float>();
        var D : Array<Float> = new Array<Float>();
        var z : Float;
        var F : Float;
        var G : Float;
        var H : Float;
        var k : Int;
        
        w[1] = v[1] = z = 1 / 4;
        y[0] = z * 3 * (x[1] - x[n]);
        H = 4;
        F = 3 * (x[0] - x[n - 1]);
        G = 1;
        for (k in 1...n)
        {
            v[k + 1] = z = 1 / (4 - v[k]);
            w[k + 1] = -z * w[k];
            y[k] = z * (3 * (x[k + 1] - x[k - 1]) - y[k - 1]);
            H = H - G * w[k];
            F = F - G * y[k - 1];
            G = -v[k] * G;
        }
        H = H - (G + 1) * (v[n] + w[n]);
        y[n] = F - (G + 1) * y[n - 1];
        
        
        D[n] = y[n] / H;
        
        /* This equation is WRONG! in my copy of Spath */
        D[n - 1] = y[n - 1] - (v[n] + w[n]) * D[n];
        k = as3hx.Compat.parseInt(n - 2);
        while (k >= 0)
        {
            D[k] = y[k] - v[k + 1] * D[k + 1] - w[k + 1] * D[n];
            k--;
        }
        
        
        /* now compute the coefficients of the cubics */
        var C : Array<Cubic> = new Array<Cubic>();
        for (k in 0...n)
        {
            C[k] = new Cubic(
                    x[k], 
                    D[k], 
                    3 * (x[k + 1] - x[k]) - 2 * D[k] - D[k + 1], 
                    2 * (x[k] - x[k + 1]) + D[k] + D[k + 1]);
        }
        C[n] = new Cubic(
                x[n], 
                D[n], 
                3 * (x[0] - x[n]) - 2 * D[n] - D[0], 
                2 * (x[n] - x[0]) + D[n] + D[0]);
        return C;
    }
    
    public function exportStrokesToPolygons() : Array<GraphicsPolygon>
    {
        var retval : Array<GraphicsPolygon> = new Array<GraphicsPolygon>();
        for (i in 0..._container.numChildren)
        {
            if (Std.is(_container.getChildAt(i), Stroke))
            {
                retval.push((cast((_container.getChildAt(i)), Stroke)).exportToPolygon());
            }
        }
        
        return retval;
    }
    
    public function exportFillsToPolygons() : Array<GraphicsPolygon>
    {
        var retval : Array<GraphicsPolygon> = new Array<GraphicsPolygon>();
        for (i in 0..._container.numChildren)
        {
            if (Std.is(_container.getChildAt(i), Fill))
            {
                retval.push((cast((_container.getChildAt(i)), Fill)).exportToPolygon());
            }
        }
        
        return retval;
    }
}



class Cubic
{
    /** this class represents a cubic polynomial */
    private var a : Float;private var b : Float;private var c : Float;private var d : Float;  /* a + b*u + c*u^2 +d*u^3 */  
    
    public function new(a : Float, b : Float, c : Float, d : Float)
    {
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
    }
    
    /** evaluate cubic */
    public function eval(u : Float) : Float
    {
        return (((d * u) + c) * u + b) * u + a;
    }
}

