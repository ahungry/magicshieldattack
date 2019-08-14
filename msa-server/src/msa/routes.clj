(ns msa.routes
  (:require
   ;; [compojure.route :only [files not-found] :as cr]
   [compojure.core :refer [defroutes GET POST DELETE ANY OPTIONS context]]
   [msa.world :as w]))

(defn json-login [i]
  {:body (w/handle-login i)})

(defn json-input [i]
  {:body (w/handle-input i)})

(defn json-world-map [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone "0"))]
    {:body (w/get-world-map zone-n)}))

(defn json-world-map-wrapped [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone "0"))]
    {:body {:map (w/get-world-map zone-n)}}))

(defn json-world [params]
  {:body (w/get-world-step params)})

(defn version [req] {:body "0.0.1"})

(defroutes all-routes
  (GET "/version" [] version)
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
        (json-input (:body-params req))))
