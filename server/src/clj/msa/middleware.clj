(ns msa.middleware
  (:require [msa.env :refer [defaults]]
            [cheshire.generate :as cheshire]
            [cognitect.transit :as transit]
            [clojure.tools.logging :as log]
            [msa.layout :refer [error-page]]
            ;; [ring.middleware.anti-forgery :refer [wrap-anti-forgery]]
            [ring.middleware.webjars :refer [wrap-webjars]]
            [msa.middleware.formats :as formats]
            [muuntaja.middleware :refer [wrap-format wrap-params]]
            [msa.config :refer [env]]
            [ring.middleware.flash :refer [wrap-flash]]
            [ring.middleware.defaults :refer [api-defaults wrap-defaults]])
  (:import
           ))

(defn wrap-internal-error [handler]
  (fn [req]
    (try
      (handler req)
      (catch Throwable t
        (log/error t (.getMessage t))
        (error-page {:status 500
                     :title "Something very bad has happened!"
                     :message "We've dispatched a team of highly trained gnomes to take care of the problem."})))))

;; (defn wrap-csrf [handler]
;;   (wrap-anti-forgery
;;     handler
;;     {:error-response
;;      (error-page
;;        {:status 403
;;         :title "Invalid anti-forgery token"})}))


(defn wrap-formats [handler]
  (let [wrapped (-> handler wrap-params (wrap-format formats/instance))]
    (fn [request]
      ;; disable wrap-formats for websockets
      ;; since they're not compatible with this middleware
      ((if (:websocket? request) handler wrapped) request))))

(defn wrap-nocache [handler]
  (fn [request]
    (let [response (handler request)]
      (assoc-in response [:headers  "Pragma"] "no-cache"))))

(defn wrap-cors [handler]
  (fn [request]
    (let [response (handler request)]
      (-> response
          (assoc-in [:headers  "Access-Control-Allow-Credentials"] "true")
          (assoc-in [:headers  "Access-Control-Allow-Methods"] "GET,HEAD,OPTIONS,POST,PUT,PATCH")
          (assoc-in [:headers  "Access-Control-Allow-Headers"] "Access-Control-Allow-Headers, Authorization, Origin, Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers")
          (assoc-in [:headers  "Access-Control-Allow-Origin"] "*"))
      )))

(defn wrap-base [handler]
  (-> ((:middleware defaults) handler)
      wrap-webjars
      wrap-flash
      wrap-nocache
      wrap-cors
      (wrap-defaults
       (-> api-defaults
           ;; (assoc-in [:security :anti-forgery] false)
           (dissoc :session)))
      wrap-internal-error
      ))
