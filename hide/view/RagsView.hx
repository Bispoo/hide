package hide.view;

import hrt.prefab.l3d.Camera;
import hxd.res.DefaultFont;
import h2d.Text;
import hxd.Math;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Graphics;

class RagsView extends FileView {
    
    var originData : String;
    var properties : hide.comp.PropsEditor;
    var scene : hide.comp.Scene;
	var camera : hide.view.l3d.CameraController2D;
    var grids : h2d.Graphics;
    var bmp : Bitmap;
    var tf : Text;

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
        g = new Graphics(camera);
        //g.drawCircle(0,0,32,0);     
        grids = new h2d.Graphics(camera);		
        //grids.x-= 512;
        //grids.y-= 512;

        tf = new Text(DefaultFont.get(),scene.s2d);
        tf.text = "Works";
        
        g.beginFill(0x00FFFF);
        g.drawCircle(0,0,4);
        g.drawCircle(512,512,4);
    }

    function initProperties() {

        properties.clear();

        var extra = new Element('
        <div class="section">
            <h1>Manage</h1>
            <div class="content">
                <dl>
                    <dt></dt><dd><input type="button" class="new" value="New Group"/></dd>
                </dl>
            </div>
        </div>
		');
        extra = properties.add(extra);
		extra.find(".new").click(function(_) {
			trace("clicked new");

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
        grids.x = camPos.x;
        grids.y = camPos.y;
        grids.clear();
        grids.lineStyle(camera.zoomAmount, 0xFF0000, 1.0);
        var g = 16 * camera.zoomAmount;
        var off = camPos.x % g;
        for(i in 0...Math.ceil(scene.s2d.width/g)) {
            grids.moveTo(i*g+off, 0);
            grids.lineTo(i*g+off, scene.s2d.height);
        }

        var off = camPos.y % g;
        for(i in 0...Math.ceil(scene.s2d.height/g)) {
            grids.moveTo(0, i*g+off);
            grids.lineTo(scene.s2d.width, i*g+off);
        }
        
        tf.text = "Works: " + camPos.x + ":"+camPos.y + "\nZoom:" + camera.zoomAmount;
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