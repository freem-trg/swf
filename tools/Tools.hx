package;


import flash.utils.ByteArray;
import format.swf.SWFLibrary;
import format.SWF;
import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import helpers.PlatformHelper;
import helpers.StringHelper;
import openfl.Assets;
import project.Architecture;
import project.Asset;
import project.AssetEncoding;
import project.HXProject;
import project.Platform;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class Tools {
	
	
	#if (neko && (haxe_210 || haxe3))
	public static function __init__ () {
		
		var haxePath = Sys.getEnv ("HAXEPATH");
		var command = (haxePath != null && haxePath != "") ? haxePath + "/haxelib" : "haxelib";
		
		var process = new Process (command, [ "path", "lime-tools" ]);
		var path = "";
		
		try {
			
			var lines = new Array <String> ();
			
			while (true) {
				
				var length = lines.length;
				var line = process.stdout.readLine ();
				
				if (length > 0 && StringTools.trim (line) == "-D lime-tools") {
					
					path = StringTools.trim (lines[length - 1]);
					
				}
				
				lines.push (line);
         		
   			}
   			
		} catch (e:Dynamic) {
			
			process.close ();
			
		}
		
		path += "/ndll/";
		
		switch (PlatformHelper.hostPlatform) {
			
			case WINDOWS:
				
				untyped $loader.path = $array (path + "Windows/", $loader.path);
				
			case MAC:
				
				untyped $loader.path = $array (path + "Mac/", $loader.path);
				untyped $loader.path = $array (path + "Mac64/", $loader.path);
				
			case LINUX:
				
				var arguments = Sys.args ();
				var raspberryPi = false;
				
				for (argument in arguments) {
					
					if (argument == "-rpi") raspberryPi = true;
					
				}
				
				if (raspberryPi) {
					
					untyped $loader.path = $array (path + "RPi/", $loader.path);
					
				} else if (PlatformHelper.hostArchitecture == Architecture.X64) {
					
					untyped $loader.path = $array (path + "Linux64/", $loader.path);
					
				} else {
					
					untyped $loader.path = $array (path + "Linux/", $loader.path);
					
				}
			
			default:
			
		}
		
	}
	#end
	
	
	public static function main () {
		
		var arguments = Sys.args ();
		
		if (arguments.length > 0) {
			
			// When the command-line tools are called from haxelib, 
			// the last argument is the project directory and the
			// path SWF is the current working directory 
			
			var lastArgument = "";
			
			for (i in 0...arguments.length) {
				
				lastArgument = arguments.pop ();
				if (lastArgument.length > 0) break;
				
			}
			
			lastArgument = new Path (lastArgument).toString ();
			
			if (((StringTools.endsWith (lastArgument, "/") && lastArgument != "/") || StringTools.endsWith (lastArgument, "\\")) && !StringTools.endsWith (lastArgument, ":\\")) {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				Sys.setCwd (lastArgument);
				
			}
			
		}
		
		if (arguments.length > 2 && arguments[0] == "process") {
			
			try {
				
				var inputPath = arguments[1];
				var outputPath = arguments[2];
				
				var projectData = File.getContent (inputPath);
				
				var unserializer = new Unserializer (projectData);
				unserializer.setResolver (cast { resolveEnum: Type.resolveEnum, resolveClass: resolveClass });
				var project:HXProject = unserializer.unserialize ();
				
				var output = processLibraries (project);
				
				if (output != null) {
					
					File.saveContent (outputPath, Serializer.run (output));
					
				}
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	private static function processLibraries (project:HXProject):HXProject {
		
		var output = new HXProject ();
		var embedded = false;
		
		for (library in project.libraries) {
			
			var type = library.type;
			
			if (type == null) {
				
				type = Path.extension (library.sourcePath).toLowerCase ();
				
			}
			
			if (type == "swf" && project.target != Platform.HTML5) {
				
				var swf = new Asset (library.sourcePath, "libraries/" + library.name + ".swf", AssetType.BINARY);
				
				if (library.embed != null) {
					
					swf.embed = library.embed;
					
				}
				
				output.assets.push (swf);
				
				var data = new SWFLibrary ("libraries/" + library.name + ".swf");
				var asset = new Asset ("", "libraries/" + library.name + ".dat", AssetType.TEXT);
				asset.data = Serializer.run (data);
				output.assets.push (asset);
				
				embedded = true;
				//project.haxelibs.push (new Haxelib ("swf"));
				//output.assets.push (new Asset (library.sourcePath, "libraries/" + library.name + ".swf", AssetType.BINARY));
				
			}
			
		}
		
		if (embedded) {
			
			output.haxeflags.push ("format.swf.SWFLibrary");
			output.haxeflags.push ("--remap flash:flash");
			
			return output;
			
		}
		
		return null;
		
	}
	
	
	private static function resolveClass (name:String):Class <Dynamic> {
		
		var result = Type.resolveClass (name);
		
		if (result == null) {
			
			result = HXProject;
			
		}
		
		return result;
		
	}
	
	
}