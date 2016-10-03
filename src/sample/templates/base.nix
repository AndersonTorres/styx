{ conf, ... }:
{ title
, content
}:
  ''
    <!DOCTYPE html>
    <html>
  
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width; initial-scale=1">
  
      <title>${title}</title>
  
      <link
          href="${conf.siteUrl}/atom.xml"
          type="application/atom+xml"
          rel="alternate"
          title="${conf.siteTitle}"
          />
  
      <link
          rel="stylesheet"
          href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">

      <link
          rel="stylesheet"
          href="${conf.siteUrl}/style.css">
    </head>
  
    <body>
  
      <header class="site-header">
        <div class="container wrapper">
          <a class="site-title" href="${conf.siteUrl}">${conf.siteTitle}</a>
        </div>
      </header>

      <div class="page-content">
        <div class="container wrapper">
          ${content}
        </div>
      </div>

      <footer>
        <div class="container wrapper">
          <div class="row">
            <div class="col-sm-4 col-xs-4">
              <p>${conf.siteTitle}</p>
            </div>
            <div class="col-sm-4 col-xs-4">
              <ul class="list-unstyled">
                <li><a href="https://nixos.org/Nix">Nix</a></li>
              </ul>
            </div>
            <div class="col-sm-4 col-xs-4">
              <p>${conf.siteDescription}</p>
            </div>
          </div>
        </div>
      </footer>
  
    </body>
    </html>
  ''
