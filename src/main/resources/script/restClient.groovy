import groovyx.net.http.RESTClient
import static groovyx.net.http.ContentType.*

def content = request.getContent().asMap()
def restRequest = new RESTClient( content.url )

try {
    def response = restRequest.post ([ body: content.body, requestContentType : URLENC ])

    return response.data
} catch (e) {
    return null;
}