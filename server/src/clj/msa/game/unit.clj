(ns msa.game.unit
  (:require
   [clojure.spec.alpha :as s]
   [clojure.spec.gen.alpha :as gen]
   [clojure.spec.test.alpha :as stest]
   [clojure.repl :refer :all]))

;; https://www.braveclojure.com/multimethods-records-protocols/
(defrecord UnitModel
    [name chat animation_event was_hit feedback stance
     stance_preferred xp hp hpm atk def x y dir gear])

(defprotocol Mob
  "AI controlled unit."
  (mob [m] "Identify if it is a mob or not."))

(extend-type UnitModel
  Mob
  (mob [m] (:mob m)))

(s/def ::non-empty-string (s/and string? #(> (count %) 0)))
(s/def ::name ::non-empty-string)
(s/def ::unit-model (s/keys :req-un [::name]))

(defn make [m]
  (let [model
        (map->UnitModel
         (conj
          {
           :name name
           :chat "..."
           :animation_event {}
           :was_hit false
           :feedback ["You have joined the world."]
           :stance "attack"
           :xp 1 :hp 50 :hpm 50 :atk 5 :def 5
           :x 0 :y 0
           :dir "S"
           :gear []
           } m))]
    (if (s/valid? ::unit-model model) model
        (throw (Throwable. (str (s/explain ::unit-model model)))))))

(defmulti alive? class)
(defmethod alive? UnitModel [{:keys [hp]}]
  (> hp 0))

(defmulti dead? class)
(defmethod dead? UnitModel [m]
  (not (alive? m)))

(defmulti move dead?)

(defmethod move true [m]
  (throw (Error. "You can't move when dead...")))

(defmethod move false [m]
  (prn "About to move somewhere..."))

(defn chat [m message]
  (conj m {:chat message}))
