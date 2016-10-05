{ lib, templates, conf, ... }:
with lib;
post:
let
  content = ''
    <div class="post">

      <header class="post-header">
        <div class="text-center">
          <time pubdate="pubdate" datetime="${post.timestamp}">${prettyTimestamp post.timestamp}${optionalString (attrByPath ["isDraft"] false post) " <span class=\"glyphicon glyphicon-edit\"></span>"}</time>
        </div>
      </header>

      <article class="post-content">
        ${post.html}
      </article>

    </div>
  '';
in
  templates.base (post // { inherit content; })
