# Page and site generation functions

lib: pkgs:
with lib;
with import ./utils.nix lib;

rec {

/*
===============================================================

 generatePage

===============================================================
*/

  generatePage = documentedFunction {
    description = "Function to generate a page source, used by `mkSite`.";

    arguments = [
      {
        name = "page";
        description = "A page attribute set with at least `layout` and `template` defined.";
        type = "Page";
      }
    ];

    examples = [ (mkExample {
      literalCode = ''
        generatePage {
          layout = template: "<html><body>''${template}</body></html>";
          template = page: '''
            <h1>Styx example page</h1>
            ''${page.content}
          ''';
          content = "<p>Hello world!</p>";
        };
      '';
      code =
        generatePage {
          layout = template: "<html><body>${template}</body></html>";
          template = page: ''
            <h1>Styx example page</h1>
            ${page.content}
          '';
          content = "<p>Hello world!</p>";
        }
      ;
      expected = ''
        <html><body><h1>Styx example page</h1>
        <p>Hello world!</p>
        </body></html>'';
    }) ];

    return = "Page source";

    function = page: page.layout (page.template page);
  };


/*
===============================================================

 mkSite

===============================================================
*/

  mkSite = documentedFunction {
    description = "Generate a site, this is the main function of a styx site.";

    arguments = {
      meta = {
        description = "Meta attribute set of the generated site derivation.";
        type = "Attrs";
        default = {};
      };
      files = {
        description = "A list of static files directories to copy in the site.";
        type = "[ Path ]";
        default = [];
      };
      pageList = {
        description = "A list of pages attributes sets to generate.";
        type = "[ Page ]";
        default = [];
      };
      substitutions = {
        description = "A substitution set to apply to static files.";
        type = "Attrs";
        default = {};
      };
      preGen = {
        description = "A set of command to execute before generating the site.";
        type = "String";
        default = "";
      };
      postGen = {
        description = "A set of command to execute after generating the site.";
        type = "String";
        default = "";
      };
      genPageFn = {
        description = "Function to generate a page source from a page attribute set.";
        type = "Page -> String";
        default = literalExample "lib.generation.generatePage";
      };
      pagePathFn = {
        description = "Function to generate a page from a page attribute set.";
        type = "Page -> String";
        default = literalExample "page: page.path";
      };
    };

    examples = [ (mkExample {
      literalCode = ''
        mkSite { pageList = [ pages.index ]; }
      '';
    }) ];

    return = "The site derivation.";

    function = {
      meta ? {}
    , files ? []
    , pageList ? []
    , substitutions ? {}
    , preGen  ? ""
    , postGen ? ""
    , genPageFn ? generatePage
    , pagePathFn ? (page: page.path)
    }:
      let
        env = {
          meta = { platforms = lib.platforms.all; } // meta;
          buildInputs = [ pkgs.styx ];
          preferLocalBuild = true;
          allowSubstitutes = false;
        };
        name = meta.name or "styx-site";
      in
      pkgs.runCommand name env ''
        shopt -s globstar
        mkdir -p $out

        # check if a file is a text file
        text_file () {
          file $1 | grep text | cut -d: -f1
        }

        # run substitutions on a file
        # output results to subs
        run_subs () {
          cp $1 subs && chmod u+rw subs
          ${concatMapStringsSep "\n" (set:
            let key   = head (attrNames  set);
                value = head (attrValues set);
            in
            ''
              substituteInPlace subs \
                --subst-var-by "${key}" "${toString value}"
            ''
          ) (setToList substitutions)}
        }

        ${preGen}

        # FILES
        # files are copied only if necessary, else they are just linked from the source
        ${concatMapStringsSep "\n" (filesDir: ''
          for file in ${filesDir}/**/*; do

            # Ignoring folders
            if [ -d "$file" ]; then continue; fi

            # output path
            path=$(realpath --relative-to="${filesDir}" "$file")
            mkdir -p $(dirname $out/$path)

            if [ $(text_file $file) ]; then
              input=$file
              hasSubs=
              run_subs $file

              if [ $(cmp --silent subs $file || echo 1) ]; then
                input=subs
                hasSubs=1
              fi

              case "$file" in
                *.less)
                  path=$(echo "$path" | sed -r 's/[^.]+$/css/')
                  [ -f "$out/$path" ] && rm $out/$path
                  (
                    lessc $input 2>/dev/null > $out/$path
                    if [ ! -s "$out/$path" ]; then
                      echo "Warning: could not build '$path'"
                    fi
                  ) || (
                    [ -f "$out/$path" ] && rm $out/$path
                    echo "Warning: could not build '$path'"
                  )
                ;;
                *.s[ac]ss)
                  path=$(echo "$path" | sed -r 's/[^.]+$/css/')
                  [ -f "$out/$path" ] && rm $out/$path
                  (
                    sass $input 2>/dev/null > "$out/$path"
                    if [ ! -s "$out/$path" ]; then
                      echo "Warning: could not build '$path'"
                    fi
                  ) || (
                    [ -f "$out/$path" ] && rm "$out/$path"
                    echo "Warning: could not build '$path'"
                  )
                ;;
                *)
                  [ -f "$out/$path" ] && rm "$out/$path"
                  if [ "$hasSubs" ]; then
                    cp "$input" "$out/$path"
                  else
                    ln -s "$input" "$out/$path"
                  fi;
                ;;
              esac

            else
              [ -f "$out/$path" ] && rm "$out/$path"
              ln -s "$file" "$out/$path"
            fi
          done;
        '') files}

        # PAGES
        ${concatMapStringsSep "\n" (page: ''
          outPath="$out${pagePathFn page}"
          page=${pkgs.writeText "${name}-page" (genPageFn page)}
          mkdir -p "$(dirname "$outPath")"
          run_subs "$page"
          if [ $(cmp --silent subs $page || echo 1) ]; then
            cp "subs" "$outPath"
          else
            ln -s "$page" "$outPath"
          fi
        '') pageList}

        ${postGen}
      '';
  };


/*
===============================================================

 pagesToList

===============================================================
*/

  pagesToList = documentedFunction {
    description = "Convert a set of pages to a list of pages.";

    arguments = {
      pages = {
        description = "A set of page attribute sets.";
        type = "Attrs";
      };
      default = {
        description = "Attribute set of default values to add to every page set, useful to set `layout`.";
        type = "Attrs";
        default = {};
      };
    };

    return = "`[ Page ]`";

    examples = [ (mkExample {
      literalCode = ''
        pagelist = pagestolist {
          inherit pages;
          default.layout = templates.layout;
        };
      '';
    }) (mkExample {
      literalCode = ''
        pagesToList {
          pages = {
            foo = { path = "/foo.html"; };
            bar = [ { path = "/bar-1.html"; } { path = "/bar-2.html"; } ];
          };
          default = {
            baz = "baz";
          };
        }
      '';
      code =
        pagesToList {
          pages = {
            foo = { path = "/foo.html"; };
            bar = [ { path = "/bar-1.html"; } { path = "/bar-2.html"; } ];
          };
          default = {
            baz = "baz";
          };
        }
      ;
      expected = [
        { baz = "baz"; path = "/foo.html"; }
        { baz = "baz"; path = "/bar-1.html"; }
        { baz = "baz"; path = "/bar-2.html"; }
      ];
    }) ];

    function = {
      pages
    , default ? {}
    }:
      let pages' = attrValues pages;
      in fold (p: acc:
           if isList p
           then acc ++ (map (x: default // x) p)
           else if is "pages" p 
                then acc ++ (map (x: default // x) p.pages)
                else acc ++ [(default // p)]
         ) [] pages';
  };

}
