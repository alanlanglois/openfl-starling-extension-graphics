package starling.display.graphicsEx;

import flash.errors.Error;
import flash.geom.Point;
import flash.display.GraphicsStroke;
import starling.display.util.StrokeExEvaluationData;
import starling.textures.Texture;
import starling.display.graphics.Stroke;
import starling.display.graphics.StrokeVertex;

class StrokeEx extends Stroke
{
    public var strokeVertices(get, never) : Array<StrokeVertex>;

    private var _lineLength : Float = 0;
    
    private static var sHelperPoint1 : Point = new Point();
    private static var sHelperPoint2 : Point = new Point();
    private static var sHelperPoint3 : Point = new Point();
    
    public function new()
    {
        super();
    }
    
    // Added to support post processing
    private function get_strokeVertices() : Array<StrokeVertex>
    {
        return _line;
    }
    
    override public function clearForReuse() : Void
    {
        super.clearForReuse();
        _lineLength = 0;
    }
    
    override public function clear() : Void
    {
        super.clear();
        _lineLength = 0;
    }
    
    public function invalidate() : Void
    {
        if (buffersInvalid == false)
        {
            setGeometryInvalid();
        }
    }
    
    public function strokeLength() : Float
    {
        if (_lineLength == 0)
        {
            if (_line == null || _line.length < 2)
            {
                return 0;
            }
            else
            {
                return calcStrokeLength();
            }
        }
        else
        {
            return _lineLength;
        }
    }
    
    private function calcStrokeLength() : Float
    {
        if (_line == null || _line.length < 2)
        {
            _lineLength = 0;
        }
        else
        {
            var i : Int = 1;
            var prevVertex : StrokeVertex = _line[0];
            var thisVertex : StrokeVertex = null;
            
            for (i in 1..._numVertices)
            {
                thisVertex = _line[i];
                
                var dx : Float = thisVertex.x - prevVertex.x;
                var dy : Float = thisVertex.y - prevVertex.y;
                var d : Float = Math.sqrt(dx * dx + dy * dy);
                _lineLength += d;
                prevVertex = thisVertex;
            }
        }
        return _lineLength;
    }
    
    
    public function evaluateGraphPoints(xValue : Float, positionArray : Array<Point>, tangentArray : Array<Point> = null, normalArray : Array<Point> = null) : Bool
    {
        var dx : Float;
        var dy : Float;
        
        var prevVertex : StrokeVertex = _line[0];
        var thisVertex : StrokeVertex = null;
        var invD : Float;
        
        for (i in 1..._numVertices)
        {
            thisVertex = _line[i];
            prevVertex = _line[i - 1];
            if (thisVertex.degenerate)
            {
                continue;
            }
            
            if ((prevVertex.x < xValue && thisVertex.x >= xValue) || (thisVertex.x < xValue && prevVertex.x >= xValue))
            {
                dx = thisVertex.x - prevVertex.x;
                dy = thisVertex.y - prevVertex.y;
                
                var lerp : Float = ((xValue - prevVertex.x) / (thisVertex.x - prevVertex.x));
                sHelperPoint1.x = xValue;
                sHelperPoint1.y = prevVertex.y + dy * lerp;
                positionArray.push(sHelperPoint1.clone());
                
                if (tangentArray != null)
                {
                    invD = 1.0 / Math.sqrt(dx * dx + dy * dy);
                    sHelperPoint2.x = dx * invD;
                    sHelperPoint2.y = dy * invD;
                    tangentArray.push(sHelperPoint2.clone());
                    if (normalArray != null)
                    {
                        sHelperPoint3.x = -sHelperPoint2.y;
                        sHelperPoint3.y = sHelperPoint2.x;
                        normalArray.push(sHelperPoint3.clone());
                    }
                }
                else
                {
                    if (normalArray != null)
                    {
                        invD = 1.0 / Math.sqrt(dx * dx + dy * dy);
                        sHelperPoint3.x = -dy * invD;
                        sHelperPoint3.y = dx * invD;
                        normalArray.push(sHelperPoint3.clone());
                    }
                }
            }
        }
        return positionArray.length > 0;
    }
    
    
    public function evaluateGraphPoint(xValue : Float, position : Point, evaluationData : StrokeExEvaluationData = null, tangent : Point = null, normal : Point = null) : Bool
    {
        if (evaluationData != null && evaluationData.internalStroke != this)
        {
            throw new Error("StrokeEx: evaluateGraphPoint method called with evaluationData pointing to wrong stroke");
        }
        
        var dx : Float;
        var dy : Float;
        
        var prevVertex : StrokeVertex = _line[0];
        var thisVertex : StrokeVertex = null;
        var invD : Float;
        var startIndex : Int = 1;
        
        if (evaluationData != null && evaluationData.internalStartVertSearchIndex > 0)
        {
            if (xValue >= evaluationData.internalLastX)
            {
                startIndex = evaluationData.internalStartVertSearchIndex;
            }
        }
        
        for (i in startIndex..._numVertices)
        {
            thisVertex = _line[i];
            prevVertex = _line[i - 1];
            if (thisVertex.degenerate)
            {
                continue;
            }
            
            if ((prevVertex.x < xValue && thisVertex.x >= xValue) || (thisVertex.x < xValue && prevVertex.x >= xValue))
            {
                dx = thisVertex.x - prevVertex.x;
                dy = thisVertex.y - prevVertex.y;
                
                var lerp : Float = ((xValue - prevVertex.x) / (thisVertex.x - prevVertex.x));
                position.x = xValue;
                position.y = prevVertex.y + dy * lerp;
                
                
                if (tangent != null)
                {
                    invD = 1.0 / Math.sqrt(dx * dx + dy * dy);
                    tangent.x = dx * invD;
                    tangent.y = dy * invD;
                    if (normal != null)
                    {
                        normal.x = -tangent.y;
                        normal.y = tangent.x;
                    }
                }
                else
                {
                    if (normal != null)
                    {
                        invD = 1.0 / Math.sqrt(dx * dx + dy * dy);
                        normal.x = -dy * invD;
                        normal.y = dx * invD;
                    }
                }
                if (evaluationData != null)
                {
                    evaluationData.internalLastX = xValue;
                    evaluationData.internalStartVertSearchIndex = i - 1;
                }
                return true;
            }
        }
        
        return false;
    }
    
    public function evaluate(t : Float, position : Point, evaluationData : StrokeExEvaluationData = null, tangent : Point = null, normal : Point = null) : Bool
    {
        if (t < 0 || t > 1.0)
        {
            return false;
        }
        
        if (evaluationData != null && evaluationData.internalStroke != this)
        {
            throw new Error("StrokeEx: evaluate method called with evaluationData pointing to wrong stroke");
        }
        
        var lineTotalLength : Float = strokeLength();
        var querydistanceAlongLine : Float = t * lineTotalLength;
        var remainingUntilQueryDistance : Float = querydistanceAlongLine;
        
        var prevVertex : StrokeVertex = _line[0];
        var thisVertex : StrokeVertex = null;
        var accumulatedLength : Float = 0;
        var startIndex : Int = 1;
        var evaluateForward : Bool = true;
        
        var debugNumLoops : Int = 0;
        
        if (evaluationData != null)
        {
            if (evaluationData.internalStartVertSearchIndex >= 1)
            {
                startIndex = evaluationData.internalStartVertSearchIndex;
                accumulatedLength = evaluationData.internalDistanceToPrevVert;
                accumulatedLength *= lineTotalLength / evaluationData.internalLastStrokeLength;
                
                remainingUntilQueryDistance -= evaluationData.internalDistanceToPrevVert;
                
                if (t < evaluationData.internalLastT)
                {
                    evaluateForward = false;
                }
            }
            evaluationData.internalLastStrokeLength = lineTotalLength;
        }
        
        var dx : Float;
        var dy : Float;
        var d : Float;
        var i : Int;
        var dt : Float;
        var invD : Float;
        var oneMinusDT : Float;
        
        if (evaluateForward)
        {
            for (i in startIndex..._numVertices)
            {
                thisVertex = _line[i];
                prevVertex = _line[i - 1];
                
                dx = thisVertex.x - prevVertex.x;
                dy = thisVertex.y - prevVertex.y;
                d = Math.sqrt(dx * dx + dy * dy);
                
                if (accumulatedLength + d > querydistanceAlongLine)
                {
                    if (d < 0.000001)
                    {
                        continue;
                    }
                    
                    invD = 1.0 / d;
                    
                    dt = remainingUntilQueryDistance * invD;
                    oneMinusDT = (1.0 - dt);
                    position.x = oneMinusDT * prevVertex.x + dt * thisVertex.x;
                    position.y = oneMinusDT * prevVertex.y + dt * thisVertex.y;
                    if (evaluationData != null)
                    {
                        evaluationData.internalLastT = t;
                        evaluationData.internalStartVertSearchIndex = i;
                        evaluationData.internalDistanceToPrevVert = accumulatedLength;
                        evaluationData.distance = querydistanceAlongLine;
                        evaluationData.thickness = oneMinusDT * prevVertex.thickness + dt * thisVertex.thickness;
                        evaluationData.r = oneMinusDT * prevVertex.r1 + dt * thisVertex.r1;
                        evaluationData.g = oneMinusDT * prevVertex.g1 + dt * thisVertex.g1;
                        evaluationData.b = oneMinusDT * prevVertex.b1 + dt * thisVertex.b1;
                        evaluationData.a = oneMinusDT * prevVertex.a1 + dt * thisVertex.a1;
                    }
                    if (tangent != null)
                    {
                        tangent.x = dx * invD;
                        tangent.y = dy * invD;
                        if (normal != null)
                        {
                            normal.x = -tangent.y;
                            normal.y = tangent.x;
                        }
                    }
                    else
                    {
                        if (normal != null)
                        {
                            normal.x = -dy * invD;
                            normal.y = dx * invD;
                        }
                    }
                    return true;
                }
                else
                {
                    accumulatedLength += d;
                    remainingUntilQueryDistance -= d;
                }
            }
        }
        else
        {
            i = startIndex;
            while (i > 0)
            {
                thisVertex = _line[i];
                prevVertex = _line[i - 1];
                
                dx = thisVertex.x - prevVertex.x;
                dy = thisVertex.y - prevVertex.y;
                d = Math.sqrt(dx * dx + dy * dy);
                
                if (accumulatedLength < querydistanceAlongLine && accumulatedLength + d > querydistanceAlongLine)
                {
                    if (d < 0.000001)
                    {
                        {--i;continue;
                        }
                    }
                    
                    invD = 1.0 / d;
                    
                    dt = (querydistanceAlongLine - accumulatedLength) * invD;
                    oneMinusDT = (1.0 - dt);
                    position.x = oneMinusDT * prevVertex.x + dt * thisVertex.x;
                    position.y = oneMinusDT * prevVertex.y + dt * thisVertex.y;
                    
                    if (evaluationData != null)
                    {
                        evaluationData.internalLastT = t;
                        evaluationData.internalStartVertSearchIndex = i;
                        evaluationData.internalDistanceToPrevVert = accumulatedLength;
                        evaluationData.distance = querydistanceAlongLine;
                        evaluationData.thickness = oneMinusDT * prevVertex.thickness + dt * thisVertex.thickness;
                        evaluationData.r = oneMinusDT * prevVertex.r1 + dt * thisVertex.r1;
                        evaluationData.g = oneMinusDT * prevVertex.g1 + dt * thisVertex.g1;
                        evaluationData.b = oneMinusDT * prevVertex.b1 + dt * thisVertex.b1;
                        evaluationData.a = oneMinusDT * prevVertex.a1 + dt * thisVertex.a1;
                    }
                    if (tangent != null)
                    {
                        tangent.x = dx * invD;
                        tangent.y = dy * invD;
                        if (normal != null)
                        {
                            normal.x = -tangent.y;
                            normal.y = tangent.x;
                        }
                    }
                    else
                    {
                        if (normal != null)
                        {
                            normal.x = -dy * invD;
                            normal.y = dx * invD;
                        }
                    }
                    
                    return true;
                }
                else
                {
                    if (i - 2 >= 0)
                    {
                        var prevPrevVertex : StrokeVertex = _line[i - 2];
                        dx = prevVertex.x - prevPrevVertex.x;
                        dy = prevVertex.y - prevPrevVertex.y;
                        d = Math.sqrt(dx * dx + dy * dy);
                        accumulatedLength -= d;
                    }
                    else
                    {
                        accumulatedLength = 0;
                    }
                }
                --i;
            }
        }
        return false;
    }
    
    public static function blendStrokes(strokeA : StrokeEx, strokeB : StrokeEx, blendValue : Float, blendColor : Bool, outputStroke : StrokeEx, minSamplePoints : Int = -1) : Void
    {
        var numPointsA : Int = strokeA.numVertices;
        var numPointsB : Int = strokeB.numVertices;
        var numPoints : Int = Math.max(numPointsA, numPointsB);
        
        outputStroke.clearForReuse();
        var i : Int;
        var oneMinusBlendValue : Float = (1.0 - blendValue);
        var newX : Float;
        var newY : Float;
        var newThickness : Float;
        var newR : Int;
        var newG : Int;
        var newB : Int;
        var newA : Float;
        
        if (numPointsA == numPointsB)
        {
            for (i in 0...numPoints)
            {
                newX = strokeA._line[i].x * oneMinusBlendValue + strokeB._line[i].x * blendValue;
                newY = strokeA._line[i].y * oneMinusBlendValue + strokeB._line[i].y * blendValue;
                newThickness = strokeA._line[i].thickness * oneMinusBlendValue + strokeB._line[i].thickness * blendValue;
                
                newR = as3hx.Compat.parseInt(strokeA._line[i].r1 * oneMinusBlendValue + strokeB._line[i].r1 * blendValue);
                newG = as3hx.Compat.parseInt(strokeA._line[i].g1 * oneMinusBlendValue + strokeB._line[i].g1 * blendValue);
                newB = as3hx.Compat.parseInt(strokeA._line[i].b1 * oneMinusBlendValue + strokeB._line[i].b1 * blendValue);
                newA = strokeA._line[i].a1 * oneMinusBlendValue + strokeB._line[i].a1 * blendValue;
                
                outputStroke.addVertex(newX, newY, newThickness, (newR << 16) + (newG << 8) + newB, newA, (newR << 16) + (newG << 8) + newB, newA);
            }
        }
        else
        {
            var evalContextA : StrokeExEvaluationData = new StrokeExEvaluationData(strokeA);
            var evalContextB : StrokeExEvaluationData = new StrokeExEvaluationData(strokeB);
            var t : Float = 0.0;
            
            if (minSamplePoints > numPoints)
            {
                numPoints = minSamplePoints;
            }
            
            var invNumPoints : Float = 1.0 / numPoints;
            
            for (i in 0...numPoints + 1)
            {
                strokeA.evaluate(t, sHelperPoint1, evalContextA);
                strokeB.evaluate(t, sHelperPoint2, evalContextB);
                
                newX = sHelperPoint1.x * oneMinusBlendValue + sHelperPoint2.x * blendValue;
                newY = sHelperPoint1.y * oneMinusBlendValue + sHelperPoint2.y * blendValue;
                newThickness = evalContextA.thickness * oneMinusBlendValue + evalContextB.thickness * blendValue;
                
                newR = as3hx.Compat.parseInt(255 * (evalContextA.r * oneMinusBlendValue + evalContextB.r * blendValue));
                newG = as3hx.Compat.parseInt(255 * (evalContextA.g * oneMinusBlendValue + evalContextB.g * blendValue));
                newB = as3hx.Compat.parseInt(255 * (evalContextA.b * oneMinusBlendValue + evalContextB.b * blendValue));
                newA = evalContextA.a * oneMinusBlendValue + evalContextB.a * blendValue;
                outputStroke.addVertex(newX, newY, newThickness, (newR << 16) + (newG << 8) + newB, newA, (newR << 16) + (newG << 8) + newB, newA);
                t += invNumPoints;
            }
        }
    }
}


