(ns msa.core
  (:require
   [msa.util :as u]
   [msa.routes]
   [compojure.core :refer [defroutes GET POST DELETE ANY OPTIONS context] :as cc]
   [cheshire.core :as cheshire]
   [org.httpkit.server :as server])
  (:gen-class))

;; (defn app [req]
;;   {:status  200
;;    :headers {"Content-Type" "text/html"}
;;    :body    "hello HTTP!"})

(defn hello-world [req] {:body "Hello World"})
(defn version [req] {:body "0.0.1"})

(cc/defroutes all-routes
  (cc/GET "/" [] hello-world)
  (cc/GET "/version" [] version))

;; https://github.com/ring-clojure/ring/wiki/Concepts
(defn wrap-headers [handler]
  (fn [req]
    (let [res (handler req)]
      (-> res
          (assoc-in [:headers "content-type"] "application/json")
          ))))

(defn wrap-json [handler]
  (fn [req]
    (let [res (handler req)]
      (-> res
          (update-in [:body] cheshire/generate-string)))))

(defn wrap-cors [handler]
  (fn [req]
    (let [res (handler req)]
      (-> res
          (assoc-in [:headers "Access-Control-Allow-Credentials"] "true")
          (assoc-in [:headers "Access-Control-Allow-Methods"] "GET,HEAD,OPTIONS,POST,PUT,PATCH")
          (assoc-in [:headers "Access-Control-Allow-Headers"] "Access-Control-Allow-Headers, Authorization, Origin, Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
          (assoc-in [:headers "Access-Control-Allow-Origin"] "*")))))

(defn body->body-params [{:keys [body]}]
  (when body
    (-> body slurp cheshire/parse-string u/keys->keyword-keys)))

(defn wrap-body-params [handler]
  (fn [req]
    (-> req
        (assoc-in [:body-params] (body->body-params req))
        handler)))

(def app
  (cc/routes
   (-> msa.routes/all-routes
       (cc/wrap-routes #'wrap-body-params)
       (cc/wrap-routes #'wrap-cors)
       (cc/wrap-routes #'wrap-headers)
       (cc/wrap-routes #'wrap-json))))

(defonce server (atom nil))

(defn stop []
  (when-not (nil? @server)
    ;; graceful shutdown: wait 100ms for existing requests to be finished
    ;; :timeout is optional, when no timeout, stop immediately
    (@server :timeout 100)
    (reset! server nil)))

(defn start []
  ;; The #' is useful when you want to hot-reload code
  ;; You may want to take a look: https://github.com/clojure/tools.namespace
  ;; and http://http-kit.org/migration.html#reload
  (reset! server (server/run-server #'app {:port 3000})))

(defn -main [& args]
  (prn "Begin")
  (start))
