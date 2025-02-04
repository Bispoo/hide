package hrt.prefab.rfx;

class RendererFX extends Prefab implements h3d.impl.RendererFX {

	@:s var enableInEditor = true;

	public function begin( r : h3d.scene.Renderer, step : h3d.impl.RendererFX.Step ) {
	}

	public function end( r : h3d.scene.Renderer, step : h3d.impl.RendererFX.Step ) {
	}

	public function dispose() {
	}

	inline function checkEnabled() {
		return enabled #if editor && enableInEditor #end;
	}

	#if editor
	override function getHideProps() : hide.prefab.HideProps {
		return { name : Type.getClassName(Type.getClass(this)).split(".").pop(), icon : "plus-circle" };
	}
	override function edit(ctx:EditContext) {
		ctx.properties.add(new hide.Element('
		<dl>
			<dt>Enable in Hide</dt><dd><input type="checkbox" field="enableInEditor"/></dd>
		</dl>
		'), this);
	}
	#end

}