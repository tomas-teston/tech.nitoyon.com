package {
	import flash.display.*;
	import flash.geom.*;
	import flash.filters.DisplacementMapFilter;
	import flash.utils.setInterval;
	import com.google.maps.*;

	[SWF(backgroundColor="0x000000")]
	public class GoogleEarthAs3 extends Sprite {
		private const WIDTH:int = 800;
		private const HEIGHT:int = 500;
		private const RADIUS:int = 200;
		private var map:Map;

		public function GoogleEarthAs3() {
			stage.scaleMode = "noScale";
			stage.align = "TL";

			map = new Map();
			map.key = "ABQIAAAA6de2NwhEAYfH7t7oAYcX3xRWPxFShKMZYAUclLzloAj2mNQgoRQZnk8BRyG0g_m2di3bWaT-Ji54Lg";
			map.setSize(new Point(800, 500));
			map.addEventListener(MapEvent.MAP_READY, function(event:*):void{
				var lng:Number = 0;
				var types:Array = [MapType.SATELLITE_MAP_TYPE, MapType.PHYSICAL_MAP_TYPE, MapType.NORMAL_MAP_TYPE];
				var type:int = 0;
				map.setCenter(new LatLng(0, lng), 1, types[type]);
				map.disableDragging();

				setInterval(function():void
				{
					lng += 3;
					type = Math.random() < 0.05 ? (type + 1) % 3 : type;
					map.setCenter(new LatLng(0, lng), 1, types[type]);
					lng = lng % 360;
				}, 150);
			});

			var bmd:BitmapData = new BitmapData(WIDTH, HEIGHT, false, 0);
			for(var j:int = 0; j < RADIUS * 2; j++){
				var ay:Number = Math.PI / 2 - Math.acos(1 - j / RADIUS);
				var dy:Number = RADIUS - j - RADIUS * ay;
				var rx:Number = RADIUS * Math.cos(ay);
				for(var i:int = RADIUS - rx; i < RADIUS + rx; i++){
					var ax:Number = Math.PI / 2 - Math.acos(1 - (i - RADIUS + rx) / rx);
					var dx:Number = RADIUS - i - rx * ax;

					bmd.setPixel(i, j, getColor(dx + 128, dy + 128, 128));
				}
			}

			map.filters = [new DisplacementMapFilter(bmd, new Point(50, 50), 1, 2, 192, 150)];
			var matrix:Matrix = new Matrix();
			matrix.translate(-50, -50);
			map.transform.matrix = matrix;
			addChild(map);

			var msk:Sprite = new Sprite();
			msk.graphics.beginFill(0);
			msk.graphics.drawCircle(RADIUS, RADIUS, RADIUS);
			msk.graphics.endFill();
			addChild(msk);
			mask = msk;
		}

		private static function getColor(r:int, g:int, b:int):uint {
			return r * 0x10000 + g * 0x100 + b;
		}
	}
}