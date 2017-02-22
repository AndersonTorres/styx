/* Library tests for Styx

   To see the tests report run:

     cat $(nix-build --no-out-link -A report tests/lib-au.nix)

   To check test coverage run:

     cat $(nix-build --no-out-link -A coverage tests/lib-au.nix)

*/
let
  pkgs = (import ../nixpkgs);
  lib = pkgs.callPackage pkgs.styx.lib {};
in with lib;
let
  namespaces = [
    "conf"
    "data"
    "generation"
    "pages"
    "proplist"
    "template"
    "themes"
    "utils"
  ];

  libs = map (x:
    mapAttrs' (k: v:
      { name = "lib.${x}.${k}"; value = v; }
    ) lib."${x}"
  ) namespaces;

  functions = fold (x: acc:
    acc // x
  ) {} libs;

  tests =
    let
      ex = mapAttrsToList (name: fn:
        let
          docFn = fn { _type = "genDoc"; };
          extract = imap (index: ex:
            optionalAttrs (ex ? code && ex ? expected)
            (ex // { inherit name index; })
          ) docFn.examples;
        in if docFn ? examples then extract else {}) functions;
    in (filter (x: x != {}) (flatten ex) ++ customTests);

   missingTests =
    let
      missing = mapAttrsToList (name: fn:
        let
          docFn = fn { _type = "genDoc"; };
          hasTest = any (ex: ex ? expected);
        in if   isDocFunction docFn
           then if   docFn ? examples && hasTest docFn.examples
                then null
                else name
           else null) functions;
    in filter (x: x != null) (flatten missing);

   runTests = fold (test: acc:
     if test.code == test.expected
     then (acc // { success  = acc.success ++ [ test ]; })
     else (acc // { failures = acc.failures ++ [ test ]; })
   ) { success = []; failures = []; };

   results = runTests tests;

   successNb  = length results.success;
   failuresNb = length results.failures;

   lsep  = "====================\n";
   sep   = "---\n";
   inSep = x: sep + x + sep;

   report = pkgs.writeText "lib-tests-report.txt" ''
     ---
     ${toString (successNb + failuresNb)} tests run.
     - ${toString successNb} success(es).
     - ${toString failuresNb} failure(s).
     ${optionalString (failuresNb > 0) ''

     Failures details:

     ${lsep}${mapTemplate (failure:
       let
         header = "${failure.name}${optionalString (failure ? index) ", example number ${toString failure.index}"}:\n";
         code = optionalString (failure ? literalCode) ("\ncode:\n" + inSep failure.literalCode);
         expected = "\nexpected:\n" + inSep "${prettyNix failure.expected}\n";
         got = "\ngot:\n" + inSep "${prettyNix failure.code}\n";
       in
         header + code + expected + got + lsep
     ) results.failures}''}
     ---
     '';

   coverage = pkgs.writeText "lib-tests-coverage.txt" ''
     ---
     ${toString (length missingTests)} functions missing tests:

     ${mapTemplate (f: " - ${f}") missingTests}
     ---
   '';

   mkLoadFileTest = file:
     let data = loadFile { inherit file; env = { inherit lib; foo = "bar"; }; };
         cleanData = removeAttrs data [ "fileData" ];
     in mapAttrs (k: v:
       if   k == "pages"
       then map (x: removeAttrs x [ "fileData" ]) v
       else v
     ) cleanData;

   customTests = [ {
     name = "loadFile - simple";
     function = "lib.data.loadFile";
     code = mkLoadFileTest ./data/simple.md;
     expected = {
       content = "<p>Content</p>\n";
     };
   } {
     name = "loadFile - meta";
     function = "lib.data.loadFile";
     code = mkLoadFileTest ./data/meta.md;
     expected = {
       content = "<p>Content</p>\n";
       foo = "bar";
     };
   } {
     name = "loadFile - pages";
     function = "lib.data.loadFile";
     code = mkLoadFileTest ./data/pages.md;
     expected = {
       pages = [
         { content = "<p>Page 1</p>\n"; }
         { content = "<p>Page 2</p>\n"; }
         { content = "<p>Page 3</p>\n"; }
       ];
     };
   } {
     name = "loadFile - escape";
     function = "lib.data.loadFile";
     code = mkLoadFileTest ./data/escape.md;
     expected = {
       content = ''
         <p>{&#8212;</p>

         <p>-&#8211;}</p>

         <pre><code>&lt;&lt;&lt;
         </code></pre>

         <pre><code>&gt;&gt;&gt;
         </code></pre>

         <p>{{ non evaluated nix }}</p>

         <p>this }} is not evaluated</p>

         <p>&#8217; &#8216;&#8217; &#8216;&#8217;&#8217; &#8216;&#8217;&#8216;&#8217;</p>
       '';
     };
   } {
     name = "loadFile - embedded";
     function = "lib.data.loadFile";
     code = mkLoadFileTest ./data/embedded.md;
     expected = {
       content = ''
         <p>2 + 2 = 4
         Answer is 42 and foo is bar</p>
       '';
     };
   } ];

in {
  inherit report results functions tests coverage;
  success = failuresNb == 0;
}
