// K-Means algorithm visualization
//  - requires sketchbook
//    http://sketchbook.libspark.org/
//  - requires tweener
//    http://code.google.com/p/tweener/
package{
import flash.display.*;
import flash.events.Event;
import flash.text.TextField;
import flash.geom.*;
import sketchbook.colors.ColorSB;
import caurina.transitions.Tweener;
import flash.system.Capabilities;

[SWF(backgroundColor="#223344", frameRate=18, width=400, height=400)]
public class KMeans3D extends Sprite{
	private var k:int;
	private var n:int;
	private var colors:Array;
	private var dots:Vector.<Dot>;
	private var dotsPos:Vector.<Number>;
	private var dotsView:Vector.<Number>;
	private var groups:Array;
	private var centers:Vector.<Center>;
	private var changed:Boolean;
	private var canvas:Sprite = new Sprite();
	private var lineCanvas:Sprite = new Sprite();
	private var started:Boolean = false;

	private var _matrix:Matrix3D = new Matrix3D;
	private var rotateAxis:Vector3D = new Vector3D( 0.2, 1.0, 0.1 );

	private const WIDTH:int = 400;
	private const HEIGHT:int = 300;
	private const SIZE:int = 200;
	private const ANIMATE:Number = .4;

	public function KMeans3D():void{
		stage.scaleMode = "noScale";

		var version:int = parseInt(Capabilities.version.split(" ")[1].split(",")[0]);
		if (version < 10){
			var tf:TextField = new TextField();
			tf.textColor = 0xffffff;
			tf.autoSize = "left";
			tf.text ="Flash Player 10 or later required.";
			addChild(tf);
			return;
		}

		// init canvas
		canvas.x = lineCanvas.x = WIDTH / 2;
		canvas.y = lineCanvas.y = HEIGHT / 2;
		canvas.graphics.beginFill(0x000000, 0);
		canvas.graphics.drawRect(-WIDTH / 2, -HEIGHT / 2, WIDTH, HEIGHT);
		canvas.graphics.endFill();
		canvas.useHandCursor = buttonMode = true;
		canvas.mouseChildren = false;
		addChild(lineCanvas);
		addChild(canvas);

		var state:int = 0;
		canvas.addEventListener("click", function(event:Event):void{
			if (!started){
				addEventListener("enterFrame", render);
				started = true;
				return;
			}

			if(state == 0){
				moveCenter();
			}else{
				updateGroups();
			}
			state = (state + 1) % 2;
		});

		// init inputs
		var nInput:Input = new Input("N (the number of node):", "100");
		nInput.y = HEIGHT + 5;
		addChild(nInput);

		var kInput:Input = new Input("K (the number of cluster):", "5");
		kInput.y = nInput.y + nInput.height + 5;
		addChild(kInput);

		var nextButton:Button = new Button("Step");
		nextButton.y = kInput.y + kInput.height + 5;
		addChild(nextButton);
		nextButton.addEventListener("click", canvas.dispatchEvent);

		var resetButton:Button = new Button("Restart");
		resetButton.x = nextButton.width + 5;
		resetButton.y = nextButton.y;
		addChild(resetButton);
		resetButton.addEventListener("click", function(event:Event):void{
			changed = true;
			state = 0;

			k = kInput.value;
			n = nInput.value;
			init();
		});
		resetButton.dispatchEvent(new Event("click"));
		render();
	}

	private function init():void{
		// remove previous sprites
		graphics.clear();
		for each(var dot:Dot in dots){
			canvas.removeChild(dot);
		}
		for each(var center:Center in centers){
			if(center) canvas.removeChild(center);
		}

		// init colors
		colors = [];
		for(var i:int = 0; i < k; i++){
			colors.push(ColorSB.createHSB(i * 360 / k, 90, 100).value);
		}

		// init dot
		dots = new Vector.<Dot>(n);
		dotsPos = new Vector.<Number>((n + k) * 3);
		dotsView = new Vector.<Number>((n + k) * 3);
		groups = [];
		centers = new Vector.<Center>(k);
		for(i = 0; i < n; i++){
			var group:int = Math.floor(Math.random() * k);
			dots[i] = new Dot(colors[group]);
			canvas.addChild(dots[i]);
			dotsPos[i * 3 + 0] = Math.random() * SIZE - SIZE / 2;
			dotsPos[i * 3 + 1] = Math.random() * SIZE - SIZE / 2;
			dotsPos[i * 3 + 2] = Math.random() * SIZE - SIZE / 2;

			if(!groups[group]) groups[group] = [];
			groups[group].push(i);
		}
	}

	private function render(event:Event = null):void{
		_matrix.appendRotation( 1, rotateAxis );
		_matrix.transformVectors(dotsPos, dotsView);

		//�`��
		for (var i:int = 0; i < n; i++){
			dots[i].update(dotsView[i * 3], 
			               dotsView[i * 3 + 1],
			               dotsView[i * 3 + 2]);
		}

		lineCanvas.graphics.clear();
		for (i = 0; i < k; i++){
			if (!centers[i]) continue;
			centers[i].update(dotsView[(n + i) * 3], 
			                  dotsView[(n + i) * 3 + 1],
			                  dotsView[(n + i) * 3 + 2]);
			var col:uint = colors[i];
			var cx:Number = centers[i].x;
			var cy:Number = centers[i].y;

			for each(var index:int in groups[i]){
				lineCanvas.graphics.lineStyle(0, col, .5);
				lineCanvas.graphics.moveTo(dots[index].x, dots[index].y);
				lineCanvas.graphics.lineTo(cx, cy);
				lineCanvas.graphics.lineStyle();
			}
		}
	}

	private function moveCenter():void{
		for each(var dot:Dot in dots) dot.glow = false;
		if(!changed) return;

		graphics.clear();
		var animated:Boolean = false;
		for(var i:int = 0; i < groups.length; i++){
			if(!groups[i] || !groups.length){
				continue;
			}

			// get center of gravity
			var x:Number = 0, y:Number = 0, z:Number = 0;
			for each(var index:int in groups[i]){
				x += dotsPos[index * 3];
				y += dotsPos[index * 3 + 1];
				z += dotsPos[index * 3 + 2];
			}
			var gc:int = groups[i].length;
			x /= gc;
			y /= gc;
			z /= gc;

			if(centers[i]){
				Tweener.addTween(centers[i], {
					ax: x, ay: y, az: z, time: ANIMATE
				});
				animated = true;
			}else{
				centers[i] = new Center(colors[i], dotsPos, (n + i) * 3);
				dotsPos[(n + i) * 3 + 0] = x;
				dotsPos[(n + i) * 3 + 1] = y;
				dotsPos[(n + i) * 3 + 2] = z;
				centers[i].update(x, y, z);
				canvas.addChild(centers[i]);
			}
		}
	}

	private function updateGroups():void{
		changed = false;
		groups = [];
		for (var i:int = 0; i < n; i++){
			// find the nearest group
			var min:Number = Infinity;
			var group:int = -1;
			for(var j:int = 0; j < k; j++){
				var center:Center = centers[j];
				if(!center) continue;

				var d:Number = Math.sqrt(
					  Math.pow(dotsPos[(n + j) * 3 + 0] - dotsPos[i * 3 + 0], 2)
					+ Math.pow(dotsPos[(n + j) * 3 + 1] - dotsPos[i * 3 + 1], 2)
					+ Math.pow(dotsPos[(n + j) * 3 + 2] - dotsPos[i * 3 + 2], 2));
				if(d < min){
					min = d;
					group = j;
				}
			}

			// update group
			var dot:Dot = dots[i];
			if(!groups[group]) groups[group] = [];
			groups[group].push(i);
			if(dot.color != colors[group]){
				dot.color = colors[group];
				dot.glow = true;
				changed = true;
			}
		}
	}
}
}

import flash.display.*;
import flash.text.*;
import flash.filters.GlowFilter;

const F:Number = 400;

class Sprite3D extends Sprite{
	public function update(_x:Number, _y:Number, _z:Number):void{
		var vz:Number = F / (_z + F);
		x = _x * vz;
		y = _y * vz;
		scaleX = scaleY = vz - .5;
	}
}

class Dot extends Sprite3D{
	private var _color:uint;
	public function get color():uint{return _color;}
	public function set color(v:uint):void{
		_color = v;
		draw();
	}

	public function set glow(v:Boolean):void{
		if(v) filters = [new GlowFilter(0xffffff, 1, 5, 5)];
		else filters = [];
	}

	public function Dot(col:uint){
		color = col;
	}

	private function draw():void{
		graphics.clear();
		graphics.beginFill(_color);
		graphics.drawCircle(0, 0, 5);
		graphics.endFill();
	}
}

class Center extends Sprite3D{
	private var dots:Vector.<Number>;
	private var index:int;

	public function get ax():Number{ return dots[index]; }
	public function get ay():Number{ return dots[index + 1]; }
	public function get az():Number{ return dots[index + 2]; }
	public function set ax(v:Number):void{ dots[index] = v; }
	public function set ay(v:Number):void{ dots[index + 1] = v; }
	public function set az(v:Number):void{ dots[index + 2] = v; }

	public function Center(col:uint, dots:Vector.<Number>, index:int){
		this.dots = dots;
		this.index = index;

		graphics.lineStyle(3, 0xffffff);
		draw();
		graphics.endFill();

		graphics.lineStyle(2, col);
		draw();
		graphics.endFill();
	}

	private function draw():void{
		graphics.moveTo(-5, -5);
		graphics.lineTo(5, 5);
		graphics.moveTo(5, -5);
		graphics.lineTo(-5, 5);
	}
}

class Button extends Sprite{
	public function Button(label:String){
		useHandCursor = buttonMode = true;
		mouseChildren = false;

		var t:TextField = new TextField();
		t.text = label;
		t.autoSize = "left";
		t.selectable = false;
		t.x = t.y = 5
		addChild(t);

		graphics.beginFill(0xcccccc);
		graphics.drawRect(0, 0, t.width + 10, t.height + 10);
		graphics.endFill();
	}
}

class Input extends Sprite{
	private var input:TextField;

	public function get value():int{
		return parseInt(input.text, 10);
	}

	public function Input(labelStr:String, valueStr:String):void{
		var tf:TextFormat = new TextFormat();
		tf.size = 20;

		var label:TextField = new TextField();
		input = new TextField();
		input.textColor = label.textColor = 0xffffff;
		input.defaultTextFormat = label.defaultTextFormat = tf;

		label.text = labelStr;
		label.autoSize = "left";
		addChild(label);

		input.border = true;
		input.borderColor = 0x999999;
		input.type = "input";
		input.text = valueStr;
		input.height = 22;
		addChild(input).x = 220;
	}
}
