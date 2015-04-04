backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {

    if (req.request == "POST" && !req.http.Content-Length) {
        error 411 "Content-Length required";
    }

    # Require that the content be less than 8000 characters
    if (req.request == "POST" && !req.http.Content-Length ~ "^[1-7]?[0-9]{1,3}$") {
        error 413 "Request content too large (>8000)";
    }

    if (! (req.url ~ "^/openidm/") ) {
      set req.url = regsub(req.url, "^/", "/sqlfiddle/");
    }

    if ( req.url == "/sqlfiddle/") {
      set req.url = "/sqlfiddle/index.html"; 
    }

    if (req.request == "GET" && req.url != "/openidm/info/login" && req.url != "/openidm/endpoint/favorites?_queryId=myFavorites") {
        unset req.http.cookie;
    }
}

sub vcl_fetch {
    if (req.request == "GET" && req.url != "/openidm/info/login" && req.url != "/openidm/endpoint/favorites?_queryId=myFavorites") {
        set beresp.ttl = 60m;
    }
    if (beresp.status != 200) {
        set beresp.ttl = 0s;
    }
}
