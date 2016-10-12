{ templates, conf, lib, ... }:
with lib;
page:

let 
  content =
    ''
      <div class="row">
        <div class="col-md-12">
          <ul class="list-unstyled past-issues">
            <li class="nav-header disabled"><h2>${page.title}</h2></li>
            ${mapTemplate templates.post.list page.items}
          </ul>
        </div>
      </div>
      ${templates.partials.pagination { pages = page.pages; index = page.index; }}
    '';
in
 page // { inherit content; }
