package;

/*  OpenFL Preloader
 *  @version 1.2
 *  @author Simone Cingano (yupswing)
 *  @licence MIT
 *  web: http://akifox.com
 */

import openfl.Lib;
import openfl.display.Stage;
import openfl.display.Sprite;
import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;

//*SPLASH*import for the top picture
import openfl.display.Bitmap;
import openfl.display.BitmapData;

//in the preloader YOU HAVE TO use macro to load images or other assets
// instead of Assets.getXXX()

// please provide this files (or change them) in your assets folder
// and add this line to your project.xml
// <assets path="assets/preloader" include="*" if="web" />
@:font("assets/preloader/square.ttf") class DefaultFont extends Font {}
@:bitmap("assets/preloader/logo.png") class Splash extends BitmapData {}

class Preloader extends NMEPreloader
{
    // **** CUSTOMISE HERE ****
    static var color = 0xff9600; //the main color
    static var backgroundColor = 0x333333; //background color
    static var stringLoading = "Loading"; //the loading label text
    static var website = "http://akifox.com"; //your website, every click count!
    // **** END CUSTOMISE ****

    var originalBackgroundColor:Int;

    var w:Float; //height (5%) (bar height)
    var h:Float; //width (90%) (bar width)
    var r:Float; //radius (borders)
    var p:Float; //padding pixels
    var t:Float; //thickness (borders)

    var ww:Float; //current window width
    var hh:Float; //current window height

    var textPercent:TextField; // percentage label
    var textLoading:TextField; // loading label

    var oscillator:Float = 1.0; // alpha for glowing effect
    var oscillatorDirection:Int = -1; // increase or decrease

    // *SPLASH* variable for the top picture
    var splash:Bitmap;
    var splashHeight:Float;

    public function new () {

        super ();

        init ();

        //first resize and listener
        stage_onResize(null);
        Lib.current.stage.addEventListener(Event.RESIZE, stage_onResize);
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, onFrame);
        Lib.current.stage.addEventListener(MouseEvent.CLICK, gotoWebsite, false, 0, true);

        // listener to finish event
        addEventListener(Event.COMPLETE, onComplete);

    }
    public function onComplete (event:Event):Void {
        // restore original background color
        Lib.current.stage.color = originalBackgroundColor;
        Lib.current.stage.removeEventListener(Event.RESIZE, stage_onResize);
        Lib.current.stage.removeEventListener(Event.ENTER_FRAME, onFrame);
        Lib.current.stage.removeEventListener(MouseEvent.CLICK, gotoWebsite);
    }

    private function init ():Void {

        Font.registerFont (DefaultFont);

        //change background color (and back up the original one)
        originalBackgroundColor = Lib.current.stage.color;
        Lib.current.stage.color = backgroundColor;

        //*SPLASH* Prepare the top picture
        splash = new Bitmap(new Splash(0,0));
        splash.smoothing = true;
        addChild(splash); //add the logo
        splashHeight = splash.height;

        //prepare the percent label
        textPercent = new TextField();
        textPercent.embedFonts = true;
        textPercent.selectable = false;
        textPercent.text = "0%";
        addChild(textPercent);

        //prepare the loading label
        textLoading = new TextField();
        textLoading.embedFonts = true;
        textLoading.selectable = false;
        textLoading.text = stringLoading;
        addChild(textLoading);

    }


    private function stage_onResize (event:Event):Void {

        resize (Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);

    }

    private function resize (newWidth:Int, newHeight:Int):Void {

        ww = newWidth;
        hh = newHeight;

        h = 0.05 * hh;      //height (5%) (bar height)
        w = 0.9 * ww;       //width (90%) (bar width)
        p = hh/100;         //padding pixels
        r = hh/50;          //radius (borders)
        t = hh/250;         //thickness (borders)
        var x = (ww-w)/2;   //centered (center bar position x,y)
        var y = hh*0.8;

        //*SPLASH* Resize the picture
        var scale:Float = hh / 2 / splashHeight;
        splash.scaleX = scale;
        splash.scaleY = scale;
        splash.x = ww/2-splash.width/2;
        splash.y = hh/3-splash.height/2;

        outline.x = x-p;
        outline.y = y-p;
        outline.graphics.clear();
        outline.graphics.lineStyle(t, color, 1, true);
        outline.graphics.drawRoundRect(0,0,w+2*p,h+2*p,r*2,r*2);

        progress.x = x;
        progress.y = y;
        progress.scaleX = 1;
        progress.graphics.clear();
        progress.graphics.beginFill(color, 0.5);
        progress.graphics.drawRoundRect(0,0,w,h,r,r);
        progress.graphics.endFill();

        var formatLoading = new TextFormat ("SquareFont", Std.int(hh/10), color);
        textLoading.defaultTextFormat = formatLoading; //dynamic text (HTML5)
        textLoading.setTextFormat(formatLoading); //static text
        textLoading.autoSize = TextFieldAutoSize.CENTER;
        textLoading.x = ww/2-textLoading.textWidth/2;
        textLoading.y = y-textLoading.textHeight-0.5*h;

        var formatPercent = new TextFormat ("SquareFont", Std.int(hh/20), color);
        textPercent.defaultTextFormat = formatPercent; //dynamic text
        textPercent.setTextFormat(formatPercent); //static text
        textPercent.autoSize = TextFieldAutoSize.RIGHT;
        textPercent.x = ww-(ww-w)/2-textPercent.textWidth;
        textPercent.y = y+1.5*h;

    }

	public override function onUpdate(bytesLoaded:Int, bytesTotal:Int)
	{
        // calculate the percent loaded
		var percentLoaded = bytesLoaded / bytesTotal;
		if (percentLoaded > 1) percentLoaded = 1;

        // update the percent label
        textPercent.text = Std.int(percentLoaded*100) + "%";
        textPercent.x = ww-(ww-w)/2-textPercent.textWidth;

        // update the progress bar
        progress.graphics.clear();
		progress.graphics.beginFill(color, 0.8);
        progress.graphics.drawRoundRect(0,0,percentLoaded*w,h,r,r);
        progress.graphics.endFill();
	}

    private static inline var SKIP_FRAMES:Int=5;
    private var _skipped_frames:Int=1;

    public function onFrame(event:Event):Void {

        if (_skipped_frames==SKIP_FRAMES) {

            // oscillate from 0.3 to 1 and back for the glowing effect
            oscillator += oscillatorDirection * 0.06;
            if (oscillator > 1) {
                oscillatorDirection = -1;
                oscillator = 1.0;
            }
            if (oscillator < 0.3) {
                oscillatorDirection = 1;
                oscillator = 0.3;
            }

            // the glowing effect!
            textLoading.alpha = oscillator;
            outline.alpha = oscillator;

            _skipped_frames = 0;

        }
        _skipped_frames++;
    }

    private function gotoWebsite(event:MouseEvent):Void
    {
        // open an url
        Lib.getURL(new URLRequest (website));
    }

}
