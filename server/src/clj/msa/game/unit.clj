(ns msa.game.unit
  (:require
   [clojure.spec.alpha :as s]
   [clojure.spec.gen.alpha :as gen]
   [clojure.spec.test.alpha :as stest]
   [clojure.repl :refer :all]))

;; If this is ever an optimization issue, use subvec to avoid vec -> list -> vec
(defn take-latest-5 [col]
  (into [] (take-last 5 col)))

(defrecord UnitModel
    [name chat animation_event was_hit feedback stance
     stance_preferred xp hp hpm atk def x y dir gear zone])

(s/def ::non-empty-string (s/and string? #(> (count %) 0)))
(s/def ::name ::non-empty-string)
(s/def ::hp number?)
(s/def ::unit-model (s/keys :req-un [::name ::hp]))

(defn make [m]
  (let [model
        (map->UnitModel
         (conj
          {
           :zone 0
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

(defn alive? [{:keys [hp]}]
  (> hp 0))

(s/fdef alive?
  ;; :args (s/cat :m ::unit-model)
  :args (s/cat :m (s/keys :req-un [::hp]))
  :ret boolean?)
;; (stest/instrument `alive?) ; Use without an arg to enable all instrumentation (arg checks)
;; (stest/check `alive?) ; Run generative tests to assert return types.

(defn dead? [m]
  (not (alive? m)))

(defn chat [m message]
  (conj m {:chat message}))

(defn mob? [m]
  (:mob m))

(defn player? [m]
  (not (mob? m)))

;; Actions
(defn move-east [m]
  (conj m {:dir "E" :x (inc (:x m))}))

(defn move-west [m]
  (conj m {:dir "W" :x (dec (:x m))}))

(defn move-north [m]
  (conj m {:dir "N" :y (dec (:y m))}))

(defn move-south [m]
  (conj m {:dir "S" :y (inc (:y m))}))

(defn attack-east [m]
  (conj m {:dir "E" :x (inc (:x m))}))

(defn attack-west [m]
  (conj m {:dir "W" :x (dec (:x m))}))

(defn attack-north [m]
  (conj m {:dir "N" :y (dec (:y m))}))

(defn attack-south [m]
  (conj m {:dir "S" :y (inc (:y m))}))

(defn dir-to-move-fn [dir]
  (case dir
    "E" move-east
    "W" move-west
    "N" move-north
    "S" move-south
    nil))

(defn dir-to-attack-fn [dir]
  (case dir
    "E" attack-east
    "W" attack-west
    "N" attack-north
    "S" attack-south
    nil))

(defn move
  "Move a unit P in the specified direction DIR.
  Expects p to have :x and :y keys."
  [dir p]
  (let [mp ((dir-to-move-fn dir) p)]
    (conj
     mp
     {:feedback
      (take-latest-5
       (conj (:feedback mp)
             (format "You move to %s , %s." (:x mp) (:y mp))))})))

(defn attack
  "Attack a unit in the specified direction.
  Expects p to have :x and :y keys."
  [dir p]
  (let [mp ((dir-to-attack-fn dir) p)]
    (conj
     mp
     {:feedback
      (take-latest-5
       (conj (:feedback mp)
             (format "You attack %s , %s, hitting no one." (:x mp) (:y mp))))})))

(defn goto-origin
  "Return to the origin point."
  [m]
  (conj m {:x 0 :y 0}))

(defn goto-origin-next-zone
  "Go to the origin point of the next zone."
  [m]
  (-> (conj m {:x 0 :y 0})
      (update-in [:zone] inc)))
