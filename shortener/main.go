package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type server struct {
	db    *pgxpool.Pool
	cache *redis.Client
}

func main() {
	ctx := context.Background()

	db, err := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("connect to postgres: %v", err)
	}
	defer db.Close()
	if _, err := db.Exec(ctx, "CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT NOT NULL)"); err != nil {
		log.Fatalf("create table: %v", err)
	}

	opts, err := redis.ParseURL(os.Getenv("REDIS_URL"))
	if err != nil {
		log.Fatalf("parse REDIS_URL: %v", err)
	}
	cache := redis.NewClient(opts)
	defer cache.Close()

	s := &server{db: db, cache: cache}
	mux := http.NewServeMux()
	mux.HandleFunc("POST /links", s.shorten)
	mux.HandleFunc("GET /{code}", s.follow)
	mux.HandleFunc("GET /{code}/stats", s.stats)

	addr := fmt.Sprintf("%s:%s", getenv("HOST", "127.0.0.1"), getenv("PORT", "8000"))
	log.Printf("listening on http://%s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func (s *server) shorten(w http.ResponseWriter, r *http.Request) {
	var body struct {
		URL string `json:"url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "invalid JSON", http.StatusUnprocessableEntity)
		return
	}
	u, err := url.ParseRequestURI(body.URL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
		http.Error(w, "url must be an absolute http(s) URL", http.StatusUnprocessableEntity)
		return
	}

	buf := make([]byte, 4)
	if _, err := rand.Read(buf); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	code := base64.RawURLEncoding.EncodeToString(buf)

	if _, err := s.db.Exec(r.Context(), "INSERT INTO links VALUES ($1, $2)", code, u.String()); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"code": code})
}

func (s *server) follow(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	code := r.PathValue("code")
	key := "link:" + code

	target, err := s.cache.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
		err = s.db.QueryRow(ctx, "SELECT url FROM links WHERE code = $1", code).Scan(&target)
		if errors.Is(err, pgx.ErrNoRows) {
			http.NotFound(w, r)
			return
		}
		if err == nil {
			err = s.cache.Set(ctx, key, target, time.Hour).Err()
		}
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := s.cache.Incr(ctx, "hits:"+code).Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, target, http.StatusTemporaryRedirect)
}

func (s *server) stats(w http.ResponseWriter, r *http.Request) {
	hits, err := s.cache.Get(r.Context(), "hits:"+r.PathValue("code")).Int()
	if err != nil && !errors.Is(err, redis.Nil) {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]int{"hits": hits})
}
