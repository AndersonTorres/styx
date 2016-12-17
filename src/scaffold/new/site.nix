/*-----------------------------------------------------------------------------
   Init

   Initialization of Styx, should not be edited
-----------------------------------------------------------------------------*/

{ lib, styx, runCommand, writeText
, styx-themes
, extraConf ? {}
}@args:

rec {

  lib = import styx.lib args;

  /* Configuration loading
  */
  conf = lib.utils.loadConf {
    file = ./conf.nix;
    inherit themes extraConf;
  };

  /* Themes templates loading
  */
  templates = lib.themes.loadTemplates {
    inherit themes;
    environment = { inherit conf templates data pages lib; };
  };

  /* Themes static files loading
  */
  files = lib.themes.loadFiles themes;


/*-----------------------------------------------------------------------------
   Themes setup

-----------------------------------------------------------------------------*/

  /* Themes used

     Set the themes used here
     paths and packages can be used

     themes = [ ./themes/my-site styx-themes.showcase ];
  */
  themes = [ ];


/*-----------------------------------------------------------------------------
   Data

   This section declares the data used by the site
-----------------------------------------------------------------------------*/

  data = {

  };


/*-----------------------------------------------------------------------------
   Pages

   This section declares the pages that will be generated
-----------------------------------------------------------------------------*/

  pages = rec {

  };


/*-----------------------------------------------------------------------------
   Site

-----------------------------------------------------------------------------*/

  /* Converting the pages attribute set to a list
  */
  pagesList = lib.pagesToList pages;

  site = lib.generateSite { inherit files pagesList; };

}
