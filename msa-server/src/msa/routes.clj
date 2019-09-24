(ns msa.routes
  (:require
   ;; [compojure.route :only [files not-found] :as cr]
   [compojure.core :refer [defroutes GET POST DELETE ANY OPTIONS context]]
   [msa.world :as w]))

(defn json-login [req]
  (let [name (-> req :body-params :name)]
    {:body (w/handle-login {:name name})}))

(defn json-input [i]
  {:body (w/handle-input i)})

(defn json-world-map [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone "0"))]
    {:body (w/get-world-map zone-n)}))

(defn json-world-map-wrapped [{:keys [zone]}]
  (let [zone-n (Integer/parseInt (or zone "0"))]
    {:body {:map (w/get-world-map zone-n)}}))

(defn json-world [m]
  {:body (w/get-world-step m)})

(defn json-gear [m]
  {:body (w/handle-gear m)})

(defn version [req] {:body "0.0.1"})

(defroutes all-routes
  (GET "/version" [] version)
  (OPTIONS "/world-map.json" [] {:body []})
  (GET "/world-map.json" {query-params :query-params}
       (w/logp "World map was hit")
       (json-world-map query-params))
  (GET "/world-map-wrapped.json" {query-params :query-params}
       ;; (w/logp "World map wrapped was hit")
       (json-world-map-wrapped query-params))
  (OPTIONS "/world.json" [] {:body []})
  (GET "/world.json" {query-params :query-params}
       ;; (w/logp "World was hit")
       (json-world query-params))
  (OPTIONS "/login.json" [] {:body []})
  (POST "/login.json" [] json-login)

  (OPTIONS "/gear.json" [] {:body []})
  (GET "/gear.json" {query-params :query-params}
       (json-gear query-params))

  (OPTIONS "/input.json" [] {:body []})
  (POST "/input.json" req
        ;; (w/logp "Input was hit")
        ;; (w/logp (:body-params req))
        (json-input (:body-params req))))
