package main

import (
    "log"
    "fmt"
    "net/http"
    // "io"
    // "net/http/httputil"
    // "net/url"
)

func main() {
    http.HandleFunc("/", Handler)

    log.Fatal(http.ListenAndServe(":8080", nil))    
}

func Handler(w http.ResponseWriter, req *http.Request) {
    fmt.Printf("URL: %s\n", req.URL)
    // client := &http.Client{}
    // resq, err := http.NewRequest(req.Method, req.URL.String(), req.Body)
    // if (err != nil) {
    //     log.Fatal(err)
    // }

    // defer resq.Body.Close()
    // rsp, err := client.Do(resq)
    // if (err != nil) {
    //     log.Fatal(err)
    // }
    // fmt.Printf("Status: %s\n", rsp.Status)
    w.Write([]byte("Hello world!\n"))
}