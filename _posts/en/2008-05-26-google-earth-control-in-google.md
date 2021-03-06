---
layout: post
title: Google Earth control in Google Maps
lang: en
tags: [ActionScript, Google Maps]
---
I placed Google Earth control in Google Maps.

It is impossible to get the image data by `BitmapData.draw()`, so I used a `DisplacementMapFilter`.

{% include flash.html src="/misc/swf/GoogleEarthControl.swf" bgcolor="#ffffff" width="420" height="400" %}

Here is the code(185 lines):

{%highlight actionscript%}
package {
    import flash.display.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.filters.DisplacementMapFilter;
    import com.google.maps.*;

    [SWF(backgroundColor="0x000000")]
    public class GoogleEarthControl extends Sprite {
        private const WIDTH:int = 400;
        private const HEIGHT:int = 400;
        private const VIEWDISTANCE:Number = 500;
        private var map:Map;
        private var mapContainer:Sprite;
        private var bmd:BitmapData;

        public function GoogleEarthControl() {
            stage.scaleMode = "noScale";
            stage.align = "TL";

            mapContainer = new Sprite();
            addChild(mapContainer);

            map = new Map();
            map.key = "ABQIAAAA6de2NwhEAYfH7t7oAYcX3xRWPxFShKMZYAUclLzloAj2mNQgoRQZnk8BRyG0g_m2di3bWaT-Ji54Lg";
            map.setSize(new Point(WIDTH, HEIGHT));
            map.addEventListener(MapEvent.MAP_READY, function(event:*):void{
                map.setCenter(new LatLng(35.003759, 135.769322), 10, MapType.SATELLITE_MAP_TYPE);

                var mapMask:Sprite = new Sprite();
                mapMask.graphics.beginFill(0);
                mapMask.graphics.drawRect(0, 0, WIDTH, HEIGHT);
                mapMask.graphics.endFill();
                mapContainer.mask = mapMask;

                bmd = new BitmapData(WIDTH, HEIGHT);

                var s1:ScrollBar = new ScrollBar(50);
                addChild(s1);
                s1.rotation = -90
                s1.x = WIDTH - 100; s1.y = 30;
                s1.addEventListener("change", function(event:Event):void{
                    updateValue(s1.value);
                });
                s1.dispatchEvent(new Event("change"));

                var s2:ScrollBar = new ScrollBar(80);
                addChild(s2);
                s2.x = WIDTH - 10; s2.y = 50;
                s2.addEventListener("change", function(event:Event):void{
                    map.setZoom((100 - s2.value) / 100 * map.getMaxZoomLevel());
                });
                s2.dispatchEvent(new Event("change"));

                var r:RotationControl = new RotationControl(-10);
                addChild(r);
                r.x = WIDTH - 60; r.y = 90;
                r.addEventListener("change", function(event:Event):void{
                    var matrix:Matrix = new Matrix();
                    matrix.translate(-WIDTH / 2, -HEIGHT / 2);
                    matrix.rotate(r.value * Math.PI / 180);
                    matrix.translate(WIDTH / 2, HEIGHT / 2);
                    map.transform.matrix = matrix;
                });
                r.dispatchEvent(new Event("change"));
            });
            mapContainer.addChild(map);
        }

        private function updateValue(value:int):void{
            var rad:Number = value / 100 * 60 * Math.PI / 180;
            var p:Number = -Math.sin(rad) / VIEWDISTANCE;

            bmd.lock();
            var HW:int = WIDTH / 2;
            var HH:int = HEIGHT / 2;
            for(var j:int = -HH; j < HH; j++){
                var pj:Number = 1 + j * p;
                for(var i:int = -HW; i < HW; i++){
                    var _x:int = pj * i;
                    var _y:int = pj * j / Math.cos(rad);
                    bmd.setPixel(i + HW, j + HH, getColor((_x - i) * 1 + 0x80, (_y - j) * 1 + 0x80, 0));
                }
            }
            bmd.unlock();

            mapContainer.filters = [new DisplacementMapFilter(bmd, new Point(0, 0), 1, 2, 256, 256, "color")];
        }

        private static function bounds(val:Number, min:Number = Number.POSITIVE_INFINITY, max:Number = Number.NEGATIVE_INFINITY):Number {
            return Math.max(Math.min(val, max), min);
        }

        private static function getColor(r:int, g:int, b:int):uint {
            return Math.floor(bounds(r, 0, 255)) * 0x10000
                 + Math.floor(bounds(g, 0, 255)) * 0x100
                 + Math.floor(bounds(b, 0, 255));
        }
    }
}

import flash.display.Sprite;
import flash.events.*;
import flash.geom.Point;

class ScrollBar extends Sprite {
    public var value:int;

    public function ScrollBar(_value:int):void {
        value = _value;

        useHandCursor = buttonMode = true;
        graphics.beginFill(0xffffff);
        graphics.lineStyle(0);
        graphics.drawRect(0, -2, 8, 112);
        graphics.endFill();

        var tab:Sprite = new Sprite();
        tab.graphics.beginFill(0xffffff);
        tab.graphics.lineStyle(0);
        tab.graphics.drawRect(-8, 0, 24, 8);
        tab.graphics.endFill();
        tab.y = _value;
        addChild(tab);

        addEventListener("mouseDown", function(event:MouseEvent):void {
            stage.addEventListener("mouseMove", mouseMoveHandler);
            stage.addEventListener("mouseUp", mouseUpHandler);
            mouseMoveHandler(event);
        });

        var mouseMoveHandler:Function = function(event:MouseEvent):void {
            var p:Point = globalToLocal(new Point(stage.mouseX, stage.mouseY));
            tab.y = Math.min(Math.max(0, p.y), 100);
        }
        var mouseUpHandler:Function = function(event:MouseEvent):void {
            value = tab.y;
            dispatchEvent(new Event("change"));
            stage.removeEventListener("mouseMove", mouseMoveHandler);
            stage.removeEventListener("mouseUp", mouseUpHandler);
        }
    }
}

class RotationControl extends Sprite {
    public var value:int = 0;

    public function RotationControl(_value:int):void {
        value = _value;

        useHandCursor = buttonMode = true;
        graphics.beginFill(0xffffff);
        graphics.lineStyle(0);
        graphics.drawCircle(0, 0, 40);
        graphics.drawCircle(0, 0, 32);
        graphics.endFill();

        var tab:Sprite = new Sprite();
        tab.graphics.beginFill(0xffffff);
        tab.graphics.lineStyle(0);
        tab.graphics.drawRect(-44, -8, 16, 16);
        tab.graphics.endFill();
        tab.rotation = _value + 90;
        addChild(tab);

        addEventListener("mouseDown", function(event:MouseEvent):void {
            stage.addEventListener("mouseMove", mouseMoveHandler);
            stage.addEventListener("mouseUp", mouseUpHandler);
            mouseMoveHandler(event);
        });

        var mouseMoveHandler:Function = function(event:MouseEvent):void {
            var p:Point = globalToLocal(new Point(stage.mouseX, stage.mouseY));
            tab.rotation = p.x == 0 ? 90 : Math.atan(p.y / p.x) / Math.PI * 180 + (p.x > 0 ? 180 : 0);
            value = tab.rotation - 90;
            dispatchEvent(new Event("change"));
        }
        var mouseUpHandler:Function = function(event:MouseEvent):void {
            value = tab.rotation - 90;
            dispatchEvent(new Event("change"));
            stage.removeEventListener("mouseMove", mouseMoveHandler);
            stage.removeEventListener("mouseUp", mouseUpHandler);
        }
    }
}
{%endhighlight%}
