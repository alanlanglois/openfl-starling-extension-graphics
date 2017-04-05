package starling.display.graphics.util;

import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import starling.core.RenderSupport;
import starling.display.materials.IMaterial;

interface IGraphicDrawHelper
{

    function initialize(numVerts : Int) : Void
    ;
    function onDrawTriangles(material : IMaterial, renderSupport : RenderSupport, vertexBuffer : VertexBuffer3D, indexBuffer : IndexBuffer3D, alpha : Float = 1) : Void
    ;
}

