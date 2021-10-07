package main

import (
	"encoding/base64"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"
)

var serverID string

func main() {
	rand.Seed(time.Now().UTC().UnixNano())
	serverID = strconv.Itoa(rand.Intn(100) + 100)
	logger := log.New(os.Stdout, "", log.Lmicroseconds)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3030"
	}

	logger.Printf("server %s starting on port %s ...", serverID, port)

	http.HandleFunc("/health", Middle(logger, Health))
	http.HandleFunc("/hello", Middle(logger, Hello))
	http.HandleFunc("/keyword", Middle(logger, Keyword))

	if err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil); err != nil {
		logger.Panicln(err)
	}
}

func Middle(l *log.Logger, f http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		l.Println(r.Method, r.URL.Path, r.RemoteAddr, r.UserAgent())
		f(w, r)
	}
}

func Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s: ok", serverID)
}

func Hello(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s: response from the go-web-server 👋", serverID)
}

func Keyword(w http.ResponseWriter, r *http.Request) {
	phrase, _ := base64.StdEncoding.DecodeString("Z3JlZW4K")

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s: %s", serverID, phrase)
}
