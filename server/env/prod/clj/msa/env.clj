(ns msa.env
  (:require [clojure.tools.logging :as log]))

(def defaults
  {:init
   (fn []
     (log/info "\n-=[msa started successfully]=-"))
   :stop
   (fn []
     (log/info "\n-=[msa has shut down successfully]=-"))
   :middleware identity})
