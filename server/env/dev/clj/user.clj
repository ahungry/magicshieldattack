(ns user
  (:require [msa.config :refer [env]]
            [clojure.spec.alpha :as s]
            [expound.alpha :as expound]
            [mount.core :as mount]
            [msa.core :refer [start-app]]))

(alter-var-root #'s/*explain-out* (constantly expound/printer))

(defn start []
  (mount/start-without #'msa.core/repl-server))

(defn stop []
  (mount/stop-except #'msa.core/repl-server))

(defn restart []
  (stop)
  (start))


