backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

 sub vcl_recv {

    if (! (req.url ~ "^/openidm/") ) {
      set req.url = regsub(req.url, "^/", "/sqlfiddle/");
    }

    if ( req.url == "/sqlfiddle/") {
      set req.url = "/sqlfiddle/index.html"; 
    }

    if (req.request == "GET" && req.url != "/openidm/info/login") {
        unset req.http.cookie;
    }

 }