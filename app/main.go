package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	log.Print("Starting up!")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello world!")
	})

	// a truly basic health endpoint
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "looks good")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
