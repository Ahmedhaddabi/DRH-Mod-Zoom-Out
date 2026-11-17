package mods.zoom_out;

import brain.camera.Camera;
import mods.api.Context;
import mods.api.Mod;
import mods.api.settings.Flag;
import mods.api.settings.Slider;
import openfl.events.Event;
import openfl.ui.Keyboard;

/**
	Zooms the dungeon camera out (or in) by a factor the player picks.

	The game keeps a "default zoom" on its camera: 1 when your hero spawns, and
	whatever the server asks for in some boss rooms. Attacks that zoom the camera
	return to that default afterwards. This mod watches the default the game wants
	and replaces it with `default * factor`, so every zoom the game does still
	happens, just relative to your chosen view.
**/
class Main extends Mod {
	static inline final EPSILON:Float = 0.0005;
	static inline final STEP:Float = 0.05;

	var ctx:Context;
	var enabled:Flag;
	var factor:Slider;

	/** The default zoom the game itself asked for. */
	var gameDefault:Float = Math.NaN;

	/** The default zoom this mod last wrote, to tell the game's changes from ours. */
	var written:Float = Math.NaN;

	var camera:Camera;
	var listening:Bool = false;

	override public function init(context:Context):Void {
		ctx = context;

		enabled = context.settings.flag("enabled", "Zoom Out", "Use your own camera zoom in dungeons.", true);
		factor = context.settings.slider("factor", "Camera zoom", "Below 1 shows more of the floor.", 0.5, 1.5, 0.05, 0.75, 2);

		context.keys.action("zoomOut", "Zoom out", "Shows more of the floor.", Keyboard.MINUS).onPress(function() {
			factor.value = factor.value - STEP;
		});
		context.keys.action("zoomIn", "Zoom in", "Shows less of the floor.", Keyboard.EQUAL).onPress(function() {
			factor.value = factor.value + STEP;
		});

		enabled.onChange(function(_) apply(true));
		factor.onChange(function(_) apply(true));

		context.onFloorEnter(function(_) start());
		context.onFloorExit(function(_) stop());
	}

	override public function dispose():Void {
		stop();
	}

	function start():Void {
		gameDefault = Math.NaN;
		written = Math.NaN;
		camera = null;
		if (!listening) {
			ctx.overlay.addEventListener(Event.ENTER_FRAME, onFrame);
			listening = true;
		}
	}

	function stop():Void {
		if (listening) {
			ctx.overlay.removeEventListener(Event.ENTER_FRAME, onFrame);
			listening = false;
		}
		restore();
		camera = null;
	}

	function currentFactor():Float {
		return enabled.value ? factor.value : 1;
	}

	function findCamera():Null<Camera> {
		var facade = ctx.core.facade;
		return facade == null ? null : facade.camera;
	}

	function onFrame(_:Event):Void {
		apply(false);
	}

	/**
		Keeps the camera at the game's zoom times the player's factor.
		`now` also moves the current zoom at once, for a change of setting.
	**/
	function apply(now:Bool):Void {
		if (!listening) {
			return;
		}
		var cam = findCamera();
		if (cam == null) {
			return;
		}
		if (cam != camera) {
			camera = cam;
			gameDefault = Math.NaN;
			written = Math.NaN;
		}

		var current = cam.defaultZoom;
		if (Math.isNaN(current)) {
			return; // the hero is not set up yet
		}
		if (Math.isNaN(written) || Math.abs(current - written) > EPSILON) {
			// The game set a new default (hero spawned, boss room...): take it as the base.
			gameDefault = current;
		}

		var target = gameDefault * currentFactor();
		if (Math.abs(current - target) > EPSILON) {
			cam.defaultZoom = target;
		}
		written = target;

		if (now) {
			cam.killTweenZooms();
			cam.zoom = target;
		} else if (Math.abs(cam.zoom - gameDefault) < EPSILON && Math.abs(target - gameDefault) > EPSILON) {
			// The game snapped the zoom straight to its own default: bring it to ours.
			cam.zoom = target;
		}
	}

	/** Gives the camera back the game's own zoom. */
	function restore():Void {
		var cam = camera != null ? camera : findCamera();
		if (cam == null || Math.isNaN(gameDefault)) {
			return;
		}
		cam.killTweenZooms();
		cam.defaultZoom = gameDefault;
		cam.zoom = gameDefault;
		written = Math.NaN;
	}
}
