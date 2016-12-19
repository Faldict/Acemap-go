package main

import (
    "log"
    "fmt"
    "net/http"
    "io"
    // "net/http/httputil"
    // "net/url"
)

func main() {
    http.HandleFunc("/", Handler)

    log.Fatal(http.ListenAndServe(":9090", nil))    
}

func Handler(w http.ResponseWriter, req *http.Request) {
    fmt.Printf("URL: %s\n", req.URL)
    fmt.Printf("RemoteAddr: %s\n", req.RemoteAddr)
    fmt.Printf("RequestURI: %s\n", req.RequestURI)

    // remove requesturi
    resp, err := http.DefaultClient.Do(req)
    defer resp.Body.Close()
    if err != nil {
        panic(err)
    }

    for k,v := range resp.Header {
        for _, vv := range v {
            w.Header().Add(k, vv)
        }
    }

    w.WriteHeader(resp.StatusCode)
    result, err := ioutil.ReadAll(resp.Body)
    if err != nil && err != io.EOF {
        panic(err)
    }
    w.Write(result)
}