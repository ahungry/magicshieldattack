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

(defn json-world-map []
  {:body (w/get-world-map)})

(defn json-world-map-wrapped []
  {:body {:map (w/get-world-map)}})

(defn json-world [i]
  {:body (w/get-world-step i)})

(defroutes home-routes
  (OPTIONS "/world-map.json" [] {:body []})
  (GET "/world-map.json" []
       (w/logp "World map was hit")
       (json-world-map))
  (GET "/world-map-wrapped.json" []
       (w/logp "World map wrapped was hit")
       (json-world-map-wrapped))
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
