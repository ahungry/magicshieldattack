(ns msa.routes.home
  (:require [msa.layout :as layout]
            [msa.world :as w]
            [compojure.core :refer [defroutes GET POST OPTIONS]]
            [ring.util.http-response :as response]
            [clojure.java.io :as io]))

(defn home-page []
  (layout/render
    "home.html" {:docs (-> "docs/docs.md" io/resource slurp)}))

(defn about-page []
  (layout/render "about.html"))

(defn json-login [i]
  {:body (w/handle-login i)})

(defn json-input [i]
  {:body (w/handle-input i)})

(defn json-world-map [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone 0))]
    {:body (w/get-world-map zone-n)}))

(defn json-world-map-wrapped [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone 0))]
    {:body {:map (w/get-world-map zone-n)}}))

(defn json-world [params]
  {:body (w/get-world-step params)})

(defroutes home-routes
  (OPTIONS "/world-map.json" [] {:body []})
  (GET "/world-map.json" {params :params}
       (w/logp "World map was hit")
       (json-world-map params))
  (GET "/world-map-wrapped.json" {params :params}
       (w/logp "World map wrapped was hit")
       (json-world-map-wrapped params))
  (OPTIONS "/world.json" [] {:body []})
  (GET "/world.json" {params :params}
       (w/logp "World was hit")
       (json-world params))
  (OPTIONS "/login.json" [] {:body []})
  (POST "/login.json" req
        (w/logp "Login was hit")
        (w/logp req)
        (json-login (:body-params req)))
  (OPTIONS "/input.json" [] {:body []})
  (POST "/input.json" req
        (w/logp "Input was hit")
        (w/logp (:body-params req))
        (json-input (:body-params req)))
  (OPTIONS "/" [] {:body []})
  (GET "/" [] (home-page))
  (OPTIONS "/about" [] {:body []})
  (GET "/about" [] (about-page)))
