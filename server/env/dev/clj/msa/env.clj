(ns msa.env
  (:require [selmer.parser :as parser]
            [clojure.tools.logging :as log]
            [msa.dev-middleware :refer [wrap-dev]]))

(def defaults
  {:init
   (fn []
     (parser/cache-off!)
     (log/info "\n-=[msa started successfully using the development profile]=-"))
   :stop
   (fn []
     (log/info "\n-=[msa has shut down successfully]=-"))
   :middleware wrap-dev})
