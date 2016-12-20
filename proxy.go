package main

import (
    "log"
    "fmt"
    "net/http"
    "io"
    // "io/ioutil"
    // "time"
    // "net/http/httputil"
    // "net/url"
)

func main() {
    http.HandleFunc("/", Handler)

    log.Fatal(http.ListenAndServe(":9090", nil))    
}

func Handler(w http.ResponseWriter, req *http.Request) {
    fmt.Printf("URL: %s\n", req.URL)

    o := new(http.Request)
 
    *o = *req

    o.Proto      = "HTTP/1.1" 
    o.ProtoMajor = 1 
    o.ProtoMinor = 1 
    o.Close      = false 
 
    transport := http.DefaultTransport
 
    res, err := transport.RoundTrip(o)
 
    if err != nil {
        log.Printf("http: proxy error: %v", err)
        w.WriteHeader(http.StatusInternalServerError)
        return 
    }
 
    hdr := w.Header()
 
    for k, vv := range res.Header {
        for _, v := range vv {
            hdr.Add(k, v)
        }
    }
 
    // for _, c := range res.SetCookie {
    //     w.Header().Add("Set-Cookie", c.Raw)
    // }
 
    w.WriteHeader(res.StatusCode)
 
    if res.Body != nil {
        io.Copy(w, res.Body)
    }    
}