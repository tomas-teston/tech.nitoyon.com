package {
	import flash.display.Sprite;
	import flash.events.Event;
	import five3D.geom.Matrix3D;

	[SWF(backgroundColor="0x000000")]
	public class Study3d2 extends Sprite{
		private var canvas:Sprite;
		private var cubes:Array;

		public function Study3d2(){
			stage.scaleMode = "noScale";
			stage.align = "TL";

			cubes = [];
			cubes.push(new Cube(0, 0, 0, 50));
			cubes.push(new Cube(0, 100, 0, 20));
			cubes.push(new Cube(0, -100, 0, 20));
			cubes.push(new Cube(100, 0, 0, 20));
			cubes.push(new Cube(-100, 0, 0, 20));

			canvas = new Sprite();
			addChild(canvas);
			canvas.x = 250;
			canvas.y = 150;

			stage.addEventListener("mouseMove", changeHandler);
			changeHandler(null);
		}

		private function changeHandler(event:Event):void {
			canvas.graphics.clear();

			// 回転行列を作成
			var matrix:Matrix3D = new Matrix3D();
			matrix.rotateY(stage.mouseX / 180 * Math.PI);
			matrix.rotateZ(stage.mouseY / 180 * Math.PI);

			// 描画
			for each(var c:Cube in cubes){
				c.draw(canvas.graphics, matrix);
			}
		}
	}
}

import flash.display.Graphics;
import five3D.geom.Point3D;
import five3D.geom.Matrix3D;

class Cube {
	private var points:Array = [];

	public function Cube(x:Number, y:Number, z:Number, len:Number){
		var diff:Function = function(f:Boolean):Number{return f ? len / 2 : -len / 2;};

		// 立方体の頂点８つを作成する
		for(var i:int = 0; i < 8; i++){
			var p:Point3D = new Point3D(x + diff(i % 4 % 3 == 0),  y + diff(i % 4 < 2), z + diff(i < 4));
			points.push(p);
		}
	}

	public function draw(g:Graphics, matrix:Matrix3D):void {
		// 回転後の各頂点の座標を計算
		var p:Array = [];
		for(var i:int = 0; i < points.length; i++){
			var pt:Point3D = matrix.transformPoint(points[i]);
			drawPoint(g, pt);
			p.push(pt);
		}

		// 頂点の間を線で結ぶ
		for(i = 0; i < 4; i++){
			drawLine(g, p[i], p[i + 4]);
			drawLine(g, p[i], p[(i + 1) % 4]);
			drawLine(g, p[i + 4], p[(i + 1) % 4 + 4]);
		}
	}

	private function drawPoint(g:Graphics, p:Point3D):void {
		g.beginFill(0xffffff);
		g.drawCircle(p.x, p.y, 3);
		g.endFill();
	}

	private function drawLine(g:Graphics, p1:Point3D, p2:Point3D):void {
		g.beginFill(0, 0);
		g.lineStyle(1, 0xffffff);
		g.moveTo(p1.x, p1.y);
		g.lineTo(p2.x, p2.y);
		g.lineStyle();
		g.endFill();
	}
}
