package starling.display.graphics.util;

import flash.errors.Error;
import flash.geom.Point;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Rectangle;
import starling.display.graphics.Fill;
import starling.display.graphics.Graphic;
import starling.display.graphics.TriangleFan;
import starling.utils.ArrayUtil;
import starling.display.graphics.Stroke;
import flash.utils.ByteArray;

class BitmapContourUtil
{
    public function new()
    {
    }
    
    public static var trySortClockwise : Bool = true;
    
    public static function createContourFromColorBitmap(inputBitmap : Bitmap, graphic : Dynamic, excludeColor : Int = 0xFFFFFF, excludeDiff : Int = 32, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        var pointArray : Array<Point> = scanCountoursColor(inputBitmap.bitmapData, excludeColor, excludeDiff);
        
        var sortedArray : Array<Point> = new Array<Point>();
        sortPointArray(pointArray, sortedArray);
        
        populateGraphic(graphic, sortedArray, thickness, color, alpha);
    }
    
    public static function createContourFromAlphaBitmap(inputBitmap : Bitmap, graphic : Dynamic, alphaThreshold : Int = 0, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        var pointArray : Array<Point> = scanCountoursAlpha(inputBitmap.bitmapData, alphaThreshold);
        
        var sortedArray : Array<Point> = new Array<Point>();
        sortPointArray(pointArray, sortedArray);
        
        populateGraphic(graphic, sortedArray, thickness, color, alpha);
    }
    
    private static function populateGraphic(graphic : Dynamic, sortedArray : Array<Point>, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        if (Std.is(graphic, Array))
        {
            var array : Array<Dynamic> = try cast(graphic, Array</*AS3HX WARNING no type*/>) catch(e:Dynamic) null;
            for (i in 0...array.length)
            {
                var gfx : Graphic = array[i];
                if (Std.is(gfx, Fill) || Std.is(gfx, Stroke) || Std.is(gfx, TriangleFan))
                {
                    populateGraphicData(gfx, sortedArray, thickness, color, alpha);
                }
                else
                {
                    throw new Error("Wrong type sent to BitmapContourUtil. Only Fill, Stroke, TriangleFan and an Array of those types supported");
                }
            }
        }
        else
        {
            if (Std.is(graphic, Fill) || Std.is(graphic, Stroke) || Std.is(graphic, TriangleFan))
            {
                populateGraphicData(try cast(graphic, Graphic) catch(e:Dynamic) null, sortedArray, thickness, color, alpha);
            }
            else
            {
                throw new Error("Wrong type sent to BitmapContourUtil. Only Fill, Stroke, TriangleFan and an Array of those types supported");
            }
        }
    }
    
    private static function populateGraphicData(graphic : Graphic, sortedArray : Array<Point>, thickness : Float = 1, color : Int = 0xFFFFFF, alpha : Float = 1) : Void
    {
        var i : Int;
        var stroke : Stroke = try cast(graphic, Stroke) catch(e:Dynamic) null;
        if (stroke != null)
        {
            stroke.clear();
            for (i in 0...sortedArray.length)
            {
                stroke.lineTo(sortedArray[i].x, sortedArray[i].y, thickness, color, alpha);
            }
        }
        var fill : Fill = try cast(graphic, Fill) catch(e:Dynamic) null;
        if (fill != null)
        {
            fill.clear();
            for (i in 0...sortedArray.length)
            {
                fill.addVertex(sortedArray[i].x, sortedArray[i].y, color, alpha);
            }
        }
        var fan : TriangleFan = try cast(graphic, TriangleFan) catch(e:Dynamic) null;
        if (fan != null)
        {
            fan.clear();
            
            var minX : Float = Math.POSITIVE_INFINITY;
            var maxX : Float = Math.NEGATIVE_INFINITY;
            var minY : Float = Math.POSITIVE_INFINITY;
            var maxY : Float = Math.NEGATIVE_INFINITY;
            
            var r : Int = as3hx.Compat.parseInt(color & 0xFF);
            var g : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(color >> 8) & 0xFF);
            var b : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(color >> 16) & 0xFF);
            
            for (i in 0...sortedArray.length)
            {
                var x : Float = sortedArray[i].x;
                var y : Float = sortedArray[i].y;
                if (x < minX)
                {
                    minX = x;
                }
                if (x > maxX)
                {
                    maxX = x;
                }
                if (y < minY)
                {
                    minY = y;
                }
                if (y > maxY)
                {
                    maxY = y;
                }
            }
            var centerX : Float = minX + 0.5 * (maxX - minX);
            var centerY : Float = minY + 0.5 * (maxY - minY);
            
            fan.addVertex(centerX, centerY, 0, 0, r, g, b, alpha);
            for (i in 0...sortedArray.length)
            {
                fan.addVertex(sortedArray[i].x, sortedArray[i].y, color, alpha);
            }
        }
    }
    
    
    private static function sortPointArray(pointArray : Array<Point>, sortedArray : Array<Point>) : Void
    {
        var index : Int = 0;
        var len : Int = pointArray.length;
        var startSearchPoint : Int = 0;
        var sortedIndex : Int = 0;
        var startPoint : Point = pointArray[index];
        if (trySortClockwise)
        {
            index = 1;
            startPoint = pointArray[index];
        }
        
        while (len > 0)
        {
            var currentPt : Point = pointArray[index];
            sortedArray[sortedIndex++] = currentPt;
            
            pointArray.splice(index, 1);
            
            len = pointArray.length;
            if (len == 0)
            {
                sortedArray[sortedIndex] = startPoint;
                return;
            }
            
            var closestDistanceSq : Float = 6666666;
            var closestDistanceIndex : Int = -1;
            
            for (i in startSearchPoint...len)
            {
                var pt : Point = pointArray[i];
                var dx : Float = pt.x - currentPt.x;
                var dy : Float = pt.y - currentPt.y;
                var dx2 : Float = dx * dx;
                var dy2 : Float = dy * dy;
                if (dx2 > closestDistanceSq && dy2 > closestDistanceSq)
                {
                    break;
                }
                
                var d : Float = dx2 + dy2;
                if (d < closestDistanceSq)
                {
                    closestDistanceSq = d;
                    closestDistanceIndex = i;
                }
            }
            
            index = closestDistanceIndex;
            var numSteps : Int = 30;
            if (index < numSteps)
            {
                startSearchPoint = 0;
            }
            else
            {
                startSearchPoint = as3hx.Compat.parseInt(index - numSteps);
            }
        }
    }
    
    private static function scanCountoursAlpha(bitmapData : BitmapData, alphaThreshold : Int = 0) : Array<Point>
    {
        var retval : Array<Point> = new Array<Point>();
        var pixels : ByteArray = bitmapData.getPixels(bitmapData.rect);
        pixels.position = 0;
        var bmdWidth : Int = bitmapData.width;
        var bmdHeight : Int = bitmapData.height;
        
        for (y in 0...bmdHeight)
        {
            var isScanningPixels : Bool = false;
            for (x in 0...bmdWidth)
            {
                var pixel : Int = pixels.readUnsignedInt();
                var a : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(pixel >> 24) & 0xFF);
                if (isScanningPixels && a <= alphaThreshold)
                {
                    isScanningPixels = false;
                    
                    retval.push(new Point(x, y));
                }
                else
                {
                    if (isScanningPixels == false && a > alphaThreshold)
                    {
                        isScanningPixels = true;
                        retval.push(new Point(x, y));
                    }
                }
            }
        }
        return retval;
    }
    
    private static function scanCountoursColor(bitmapData : BitmapData, excludeColor : Int, excludeColorDiff : Int = 10) : Array<Point>
    {
        var retval : Array<Point> = new Array<Point>();
        var pixels : ByteArray = bitmapData.getPixels(bitmapData.rect);
        pixels.position = 0;
        var bmdWidth : Int = bitmapData.width;
        var bmdHeight : Int = bitmapData.height;
        var excludeR : Int = as3hx.Compat.parseInt(excludeColor & 0xFF);
        var excludeG : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(excludeColor >> 8) & 0xFF);
        var excludeB : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(excludeColor >> 16) & 0xFF);
        var threshholdR : Int = as3hx.Compat.parseInt(excludeR + excludeColorDiff);
        var threshholdG : Int = as3hx.Compat.parseInt(excludeG + excludeColorDiff);
        var threshholdB : Int = as3hx.Compat.parseInt(excludeB + excludeColorDiff);
        var acceptUp : Bool = true;
        if (excludeR > 128)
        {
            acceptUp = false;
            threshholdR = as3hx.Compat.parseInt(excludeR - excludeColorDiff);
            threshholdG = as3hx.Compat.parseInt(excludeG - excludeColorDiff);
            threshholdB = as3hx.Compat.parseInt(excludeB - excludeColorDiff);
        }
        
        for (y in 0...bmdHeight)
        {
            var isScanningPixels : Bool = false;
            var lastXPos : Int = 0;
            var firstXPos : Int = 0;
            for (x in 0...bmdWidth)
            {
                var pixel : Int = pixels.readUnsignedInt();
                var r : Int = as3hx.Compat.parseInt(pixel & 0xFF);
                var g : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(pixel >> 8) & 0xFF);
                var b : Int = as3hx.Compat.parseInt(as3hx.Compat.parseInt(pixel >> 16) & 0xFF);
                if (acceptUp)
                {
                    if (isScanningPixels && (r > threshholdR || g > threshholdG || b > threshholdB))
                    {
                        lastXPos = x;
                    }
                    else
                    {
                        if (isScanningPixels == false && (r > threshholdR || g > threshholdG || b > threshholdB))
                        {
                            isScanningPixels = true;
                            firstXPos = x;
                        }
                    }
                }
                else
                {
                    if (isScanningPixels && (r < threshholdR || g < threshholdG || b < threshholdB))
                    {
                        lastXPos = x;
                    }
                    else
                    {
                        if (isScanningPixels == false && (r < threshholdR || g < threshholdG || b < threshholdB))
                        {
                            isScanningPixels = true;
                            firstXPos = x;
                        }
                    }
                }
            }
            if (isScanningPixels)
            {
                if (firstXPos > 0 && lastXPos > firstXPos)
                {
                    retval.push(new Point(firstXPos, y));
                    retval.push(new Point(lastXPos, y));
                }
            }
        }
        return retval;
    }
}


