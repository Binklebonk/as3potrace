﻿package 
{
	import flash.utils.getTimer;
	import com.bit101.components.PushButton;
	import com.powerflasher.as3potrace.POTrace;
	import com.powerflasher.as3potrace.backend.GraphicsDataBackend;
	import com.powerflasher.as3potrace.backend.IBackend;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.GraphicsEndFill;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	[SWF(backgroundColor="#FFFFFF", frameRate="31", width="640", height="480")]
	
	public class Main extends Sprite
	{
		[Embed(source="../bitmaps/cartoon.png")]
		public var CartoonBitmap:Class;
		[Embed(source="../bitmaps/pot1.png")]
		public var Pot1Bitmap:Class;
		[Embed(source="../bitmaps/pot2.png")]
		public var Pot2Bitmap:Class;
		
		private var imageContainer:Sprite;
		
		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			addChild(new PushButton(this, 10, 10, "Load Image", function():void {
				var ref:FileReference = new FileReference();
				ref.addEventListener(Event.SELECT, function(e:Event):void { ref.load(); });
				ref.addEventListener(Event.COMPLETE, function(e:Event):void { loadBytes(ref.data); });
				ref.browse([new FileFilter("PNG (*.png)", "*.png"), new FileFilter("JPG (*.jpg)", "*.jpg"), new FileFilter("GIF (*.gif)", "*.gif")]);
			}));
			
			addChild(new PushButton(this, 120, 10, "cartoon.png", function():void { traceExampleImage(CartoonBitmap); }));
			addChild(new PushButton(this, 230, 10, "pot1.png", function():void { traceExampleImage(Pot1Bitmap); }));
			addChild(new PushButton(this, 340, 10, "pot2.png", function():void { traceExampleImage(Pot2Bitmap); }));

			imageContainer = new Sprite();
			imageContainer.x = 10;
			imageContainer.y = 40;
			addChild(imageContainer);
		}
		
		protected function traceExampleImage(ImageClass:Class):void
		{
			traceImage(new ImageClass());
		}

		protected function traceImage(bitmap:Bitmap, bitmapOriginal:Bitmap = null):void
		{
			while(imageContainer.numChildren > 0) {
				imageContainer.removeChildAt(0);
			}
			
			var bm:Bitmap = (bitmapOriginal == null) ? bitmap : bitmapOriginal;
			bm.alpha = 0.5;
			imageContainer.addChild(bm);
			
			var curves:Sprite = new Sprite();
			imageContainer.addChild(curves);
			
			var gd:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();
			var strokeFill:GraphicsSolidFill = new GraphicsSolidFill(0xff0000, 1);
			gd.push(new GraphicsStroke(1, false, LineScaleMode.NONE, CapsStyle.ROUND, JointStyle.ROUND, 3, strokeFill));
			gd.push(new GraphicsSolidFill(0xff0000, 0.25));
			
			var backend:IBackend = new GraphicsDataBackend(gd);
			var potrace:POTrace = new POTrace();
			
			var t:int = getTimer();
			potrace.potrace_trace(bitmap.bitmapData, null, backend);
			t = getTimer() - t;
			
			trace(t + " ms");
			
			gd.push(new GraphicsEndFill());
			
			curves.graphics.drawGraphicsData(gd);
		}

		protected function loadBytes(image:ByteArray):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, initHandler);
			loader.loadBytes(image);
		}

		protected function initHandler(event:Event):void
		{
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			var loader:Loader = loaderInfo.loader;

			var xs:Number = (stage.stageWidth - 20) / loader.width;
			var ys:Number = (stage.stageHeight - 60) / loader.height;
			var s:Number = Math.min(xs, ys);
			
			var bmd:BitmapData = new BitmapData(loader.width * s, loader.height * s, false);
			var matrix:Matrix = new Matrix();
			matrix.createBox(s, s);
			bmd.draw(loader.content, matrix, null, null, null, true);
			
			var bmOriginal:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			
			bmd.applyFilter(bmd, bmd.rect, new Point(0, 0), grayscaleFilter);
			bmd.applyFilter(bmd, bmd.rect, new Point(0, 0), blurFilter);
			
			var bmd2:BitmapData = new BitmapData(bmd.width, bmd.height, false, 0xffffff);
			bmd2.threshold(bmd, bmd.rect, new Point(0, 0), ">=", 0x808080, 0x000000, 0xffffff, false);
			
			var bm:Bitmap = new Bitmap(bmd2, PixelSnapping.AUTO, true);
			
			traceImage(bm, bmOriginal);
		}
		
		protected function get grayscaleFilter():BitmapFilter
		{
			var r:Number = 0.212671;
			var g:Number = 0.715160;
			var b:Number = 0.072169;
			
			return new ColorMatrixFilter([
				r, g, b, 0, 0,
				r, g, b, 0, 0,
				r, g, b, 0, 0,
				0, 0, 0, 1, 0
			]);
		}
		
		protected function get blurFilter():BitmapFilter
		{
			return new BlurFilter(8, 8, BitmapFilterQuality.HIGH);
		}
	}
}
