package hide.view;

import haxe.Json;
import h2d.col.Point;
import h2d.col.Polygon;
import js.html.MouseEvent;
import hrt.prefab.l3d.Camera;
import hxd.res.DefaultFont;
import h2d.Text;
import hxd.Math;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Graphics;

typedef RagData = {
    var scale:Float;
    var grounded:Array<Int>;
    var color:Array<Int>;
    var connections:Array<Array<Int>>;
    var points:Array<Array<Float>>;
  }

class RagsView extends FileView {
    
    var originData : String;
    var properties : hide.comp.PropsEditor;
    var scene : hide.comp.Scene;
	var camera : hide.view.l3d.CameraController2D;
    var grids : h2d.Graphics;
    var pointer : h2d.Graphics;
    var bmp : Bitmap;
    var tf : Text;
    var gridSize = 16;
    var invalidated = false;

    var points:Array<Point>;

    var polFillColor = 0xFF00FF;

    var g : Graphics;

    // onDisplay should create html layout of your view. It is also called each when file is changed externally.
    override public function onDisplay()
    {
        // Example of initial layout setup.
        element.html('
        <div class="flex">
            <div class="heaps-scene"></div>
            <div class="props"></div>
        </div>
        ');
        var tools = new hide.comp.Toolbar(null, element.find(".toolbar"));
        // Importantly, use `getPath()` to obtain file path that you can use for filesystem access.
        var path = getPath();

        //Load Points
        originData = sys.io.File.getContent(path);
        points = [];
        var rags:RagData = Json.parse(originData); 
        for (i in 0...rags.points.length) {
            points.push( new Point(rags.points[i][0], rags.points[i][1]) );
        }
        invalidated=true;

        // ... your code to fill content
        properties = new hide.comp.PropsEditor(undo, null, element.find(".props"));
        properties.saveDisplayKey = "ragsEditor";
				
        scene = new hide.comp.Scene(config, null,element.find(".heaps-scene"));
		scene.onReady = init;        
  }

  function init() {
        
        var root = new h2d.Layers();
        scene.s2d.addChild(root);
        camera = new hide.view.l3d.CameraController2D(root);
        camera.set(0, 0, 1);
        @:privateAccess camera.curPos.set(0, 0, 1);       

        initProperties();
        scene.init();
        scene.onUpdate = update;
        //scene.onResize = onResize;

        //bmp = new Bitmap(Tile.fromColor(0xFF0000,32,32,1.0), camera);
        grids = new h2d.Graphics(scene.s2d);
        grids.alpha = 0.25;

        pointer = new h2d.Graphics(camera);
        g = new Graphics(camera);
        //g.drawCircle(0,0,32,0);     
        		
        //grids.x-= 512;
        //grids.y-= 512;

        tf = new Text(DefaultFont.get(),scene.s2d);
        tf.text = "Works";
        
        //points = [];        

        pointer.beginFill(0x00FFFF);
        pointer.drawCircle(0,0,4);

        //camera.pushing
        /* scene.s2d.addEventListener( (f:hxd.Event) -> {
            trace("lol");
        }); */

        camera.onClick = (f:hxd.Event) -> {
            var camPos = camera.getAbsPos();
            var gridScaled = gridSize * camera.parent.scaleY;
            var offX = camPos.x % gridScaled;
            var offY = camPos.y % gridScaled;
            var mx = Math.floor(scene.s2d.mouseX/gridScaled)*gridScaled+offX;
            var my = Math.floor(scene.s2d.mouseY/gridScaled)*gridScaled+offY;
            
            var px = (mx - camPos.x) / camera.parent.scaleY;
            var py =  (my - camPos.y) / camera.parent.scaleY;

            //var worldX = Math.floor( mx/camera.parent.scaleY )/gridSize;
            //var worldY = Math.floor( my/camera.parent.scaleY )/gridSize;            
            trace("Clicked Grid: " + px + ":" + py);
            addPoint( Std.int(px/gridSize), Std.int(py/gridSize) );
            //redraw
            invalidated = true;

            set_modified(true);
        };
    }

    function strokePoly(poly:Array<h2d.col.Point>, color:Int)
    {        
        var n = poly.length;
        if (n<3) return; //poly at least 3 points
        g.lineStyle(4, color);
        g.moveTo(poly[0].x*gridSize, poly[0].y*gridSize);
        for( i in 1...n) g.lineTo(poly[i].x*gridSize, poly[i].y*gridSize);
        g.lineTo(poly[0].x*gridSize, poly[0].y*gridSize);
        g.endFill();
    }

    function drawPolyVertices(poly:Array<h2d.col.Point>, color:Int=0xFF0000, radius:Float = 2)
    {
        //debug vertices      
        g.beginFill(color);
        g.lineStyle(0);
        for (i in 0...poly.length) {                  
            g.drawCircle(poly[i].x*gridSize,poly[i].y*gridSize, 4, 0);
        } 
        g.endFill();
    }

    function fillPoly(polypoints:Array<h2d.col.Point>, color:Int)
    {            
        var poly = new Polygon(polypoints);
        //poly = poly.convexHull();        
        var tgs = poly.fastTriangulate(); // Delaunay.triangulate(poly);
        if (tgs != null) {            
            var n = Std.int(tgs.length/3);            
            for (i in 0...n) {
                var i0 = tgs[3*i  ];
                var i1 = tgs[3*i+1];
                var i2 = tgs[3*i+2];  
                g.beginFill(color);
                //g.beginTileFill(0,0, 1.0,1.0, Assets.tilesFlags.getTile("flags_br"));
                //g.lineStyle(1, 0x0000FF, 1.0);               
                g.moveTo(poly.points[i0].x*gridSize,poly.points[i0].y*gridSize);   
                g.lineTo(poly.points[i1].x*gridSize,poly.points[i1].y*gridSize);               
                g.lineTo(poly.points[i2].x*gridSize,poly.points[i2].y*gridSize);       
                g.endFill();
            }                        
        }
    }

    function addPoint(cx:Int, cy:Int) {

        points.push( new Point(cx,cy) );
    }

    function initProperties() {

        properties.clear();

        var extra = new Element('
        <div class="section">
            <h1>Manage</h1>
            <div class="content">
                <dl>
                    <dt></dt><dd><input type="button" class="eraseAll" value="Erase Points"/></dd>
                    <dt></dt><dd><input type="button" class="eraseLast" value="Erase Last"/></dd>
                    <dt></dt><dd><input type="button" class="changeCol" value="Polygon Color"/></dd>
                </dl>
            </div>
        </div>
		');
        extra = properties.add(extra);
		extra.find(".eraseAll").click(function(_) {
			trace("clicked new");
            points = [];
            invalidated = true;
		}, null);

        extra.find(".eraseLast").click(function(_) {			
            points.pop();
            invalidated = true;
		}, null);
        
        var el = extra.find(".changeCol");
        extra.find(".changeCol").click(function(_) {	
            var keyEl = new Element('<span class="key">').appendTo(el);

            var picker = new Element("<div></div>").css({
                "z-index": 100,
            }); //.appendTo(keyEl);
            properties.add(picker);

            var cp = new hide.comp.ColorPicker(false, picker);
            var prevCol:h3d.Vector = new h3d.Vector(0x0,0x00,0x00); // getKeyColor(key);
            cp.value = prevCol.toColor();
            
            cp.open();

            cp.onClose = function() {
                //picker.remove();
            };

            cp.onChange = function(dragging) {
              /*   if(dragging)
                    return; */
                polFillColor = cp.value;
                       
                invalidated = true;
            };            

            var colorStr = "#" + StringTools.hex(cp.value & 0xffffff, 6);
            el.css({background: colorStr});
		}, null);



    }

    inline public static function fmin(x:Float, y:Float):Float
    {
        return x < y ? x : y;
    }

    function update(dt : Float) {
		/* for (l in debugBounds)
			l.remove();
		debugBounds = [];
		if (uiProps.showBounds) {
			for (g in parts.getGroups())
				drawBounds(g);
		} */

        var camPos = camera.getAbsPos();
        grids.clear();
        grids.lineStyle(camera.parent.scaleY, 0x404040, 1.0);
        var gridScaled = gridSize * camera.parent.scaleY;
        var off = camPos.x % gridScaled;
        for(i in 0...Math.ceil(scene.s2d.width/gridScaled)) {
            grids.moveTo(i*gridScaled+off, 0);
            grids.lineTo(i*gridScaled+off, scene.s2d.height);
        }

        var off = camPos.y % gridScaled;
        for(i in 0...Math.ceil(scene.s2d.height/gridScaled)) {
            grids.moveTo(0, i*gridScaled+off);
            grids.lineTo(scene.s2d.width, i*gridScaled+off);
        }
        
        //tf.text = "Cam: " + camPos.x + ":"+camPos.y + "\nZoom:" + camera.parent.scaleY;
        var offX = camPos.x % gridScaled;
        var offY = camPos.y % gridScaled;
        var mx = Math.floor(scene.s2d.mouseX/gridScaled)*gridScaled+offX;
        var my = Math.floor(scene.s2d.mouseY/gridScaled)*gridScaled+offY;
        var px = (mx - camPos.x) / camera.parent.scaleY;
        var py =  (my - camPos.y) / camera.parent.scaleY;
        pointer.setPosition( px+0.1,  py+ 0.1);
        tf.text = "Pointer: " + px + ":"+ py + "\nZoom:" + camera.parent.scaleY;

        //draw points
        if (invalidated) {
            invalidated = false;
            g.clear();
            strokePoly(points, 0x00);    
            fillPoly(points, polFillColor);    
            
            drawPolyVertices(points, 0xFF0000);
        }
	}

    public override function canSave() {
		return true;
	}

    function onSave(data) {
        originData = data;
        modified = false;
        skipNextChange = true;
        sys.io.File.saveContent(getPath(), originData);
    }
  
  // Register the view with specific extensions.
  // Extensions starting with `json.` refer to `.json` files with `type` at root
  // object being second part of extension ("type": "customView" in this sample).
  // Otherwise it is treated as regular file extension.
  // Providing icon and createNew is optional. If createNew set, HIDE file tree will have a context menu item to create new file that FileView represents.
  static var _ = hide.view.FileTree.registerExtension(RagsView, ["rag"], { icon: "snowflake-o", createNew: "Rag Model" });
  
}