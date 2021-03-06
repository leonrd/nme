package;

import haxe.io.Path;
import haxe.xml.Fast;
import sys.io.File;
import sys.FileSystem;
import NMEProject;
import platforms.Platform;

class HxParser
{
   var project:NMEProject;

   static var varMatch = new EReg("\\${(.*?)}", "");

   public function new(inProject:NMEProject, path:String )
   {
      project = inProject;

      var file = new Path(path).file;
      project.app.file = file;
      project.app.title = file;
      project.app.main = file;
      project.app.packageName = "com.nme." + file.toLowerCase();

      var haxelib = new Haxelib("nme");
      project.haxelibs.push(haxelib);

      var ndll = new NDLL("nme", haxelib, true, false);
      project.ndlls.push(ndll);

      process(path);
   }

   function process(inFilename:String)
   {
      try
      {
         var content = File.getContent(inFilename);
         var metaMatch = ~/^\s*\/\/\s*nme:\s*(\S*)\s*=(.*)/;
         var isApplication = ~/extends\s+NmeApplication/;
         var quotes = ~/^"(.*)"$/;
         for(line in content.split("\n"))
         {
            if (metaMatch.match(line))
            {
               var key = metaMatch.matched(1);
               var value = metaMatch.matched(2);
               if (quotes.match(value))
                  value = quotes.matched(1);
               setValue(key,value);
            }
            if (isApplication.match(line))
            {
               project.haxedefs.set("nme_application","1");
            }
         }
      }
      catch(e:Dynamic)
      {
         Log.error("Could not open project file " + inFilename + " " + e);
      }
   }



   function setValue(key:String, value:String)
   {
      switch(key)
      {
        case "path":
           project.app.binDir = value;
        case "bin":
           project.app.binDir = value;
        case "lib":
           project.addLib(value,"lib");
        case "ndll":
           project.addLib(value,"ndll");

        case "min-swf-version":
           var version = Std.parseFloat(value);

           if (version > project.app.swfVersion) 
               project.app.swfVersion = version;

        case "swf-version":
           project.app.swfVersion = Std.parseFloat(value);

        case "preloader":
           project.app.preloader = value;

        case "package", "packageName", "package-name":
           project.app.packageName = value;

        case "classPath", "classpath":
           project.classPaths.push(value);

        case "asset":
           var asset = new Asset(value, value, null, true);
           project.assets.push(asset);

        case "background", "width", "height", "fps", "vsync", "hardware", "depthBuffer", "stencilBuffer", "alphaBuffer":
            project.localDefines.set("WIN_" + key.toUpperCase(), value);
            Reflect.setField(project.window, key, value);


        case "title", "description", "version", "company", "company-id", "build-number", "companyId", "buildNumber":
            project.localDefines.set("APP_" + StringTools.replace(key, "-", "_").toUpperCase(), value);
            var name = NMMLParser.formatAttributeName(key);
            Reflect.setField(project.app, name, value);
       }
   }

}
