;; Main logic and handling for the grid/world system.
;; 0 - Unwalkable wall area
;; 1 - Walkable path of one terrain type
;; 3 - A stair element (something the player can step on to trigger loading to a different zone

(ns msa.game.grid
  (:require
   [clojure.repl :refer :all]
   [clojure.spec.alpha :as s]
   [clojure.spec.gen.alpha :as gen]
   [clojure.spec.test.alpha :as stest]))

(declare connect-rooms)

;; This has to match up with the client view / tile.
(def STAIRS 3)
(def map-size 10)

(defn my-rand-int [n]
  (int (* (+ 1 n) (rand 1))))

(defn one [n]
  (if (> n 0) n 1))

(defn map-into
  "Eagerly maps into a vector the user fn to the col."
  [fn col]
  (into [] (doall (map fn col))))

;; Wow, looks terrible!
(defn world-map-grid [n]
  (map-into (fn [x] (map-into (fn [y] (rand-int 2)) (range n))) (range n)))

(defn stub-map []
  [
   [1 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0 1]
   ])

(defn print-map [col]
  (doseq [x col]
    (print "\n")
    (doseq [y x]
      (print (if (= 0 y) " " "X")))))

;; Given the stub map, "walk" from one point to another.
;; TODO: Make this less "L" shaped and more random or something.
(defn connect-rooms-x [col sx sy dx dy]
  (cond
    (> dx sx) (connect-rooms (update-in col [(inc sx) sy] one) (inc sx) sy dx dy)
    (> dy sy) (connect-rooms (update-in col [sx (inc sy)] one) sx (inc sy) dx dy)
    (< dx sx) (connect-rooms (update-in col [(dec sx) sy] one) (dec sx) sy dx dy)
    (< dy sy) (connect-rooms (update-in col [sx (dec sy)] one) sx (dec sy) dx dy)
    :else col))

(defn connect-rooms-y [col sx sy dx dy]
  (cond
    (> dy sy) (connect-rooms (update-in col [sx (inc sy)] one) sx (inc sy) dx dy)
    (> dx sx) (connect-rooms (update-in col [(inc sx) sy] one) (inc sx) sy dx dy)
    (< dy sy) (connect-rooms (update-in col [sx (dec sy)] one) sx (dec sy) dx dy)
    (< dx sx) (connect-rooms (update-in col [(dec sx) sy] one) (dec sx) sy dx dy)
    :else col))

(defn connect-rooms [col sx sy dx dy]
  ;; Pick a random strategy.
  (if (and (= sx dx)
           (= sy dy)) col
      (if (= 0 (my-rand-int 1))
        (connect-rooms-x col sx sy dx dy)
        (connect-rooms-y col sx sy dx dy))))

(defn rand-tile [n]
  (my-rand-int (- n 1)))

;; https://stackoverflow.com/questions/12628286/simple-way-to-replace-nth-element-in-a-vector-in-clojure
;; (assoc [1 2 3] 1 5) => [1 5 3]
;; (update-in [1 2 3] [1] inc) => [1 3 3]
;; We can do this by planting some room seeds that we then connect.
(defn generate-room [col]
  (let [x (rand-tile (count col))
        y (rand-tile (count col))
        size (my-rand-int (int (/ map-size 4)))]
    (def icol (atom col))
    (doseq [ix (range x (+ x size))
            iy (range y (+ y size))]
      (when (and (< ix map-size)
                 (< iy map-size))
        (swap! icol update-in [ix iy] one)))
    (connect-rooms @icol 0 0 x y)))

(defn generate-world-map-halls [grid times acc]
  (if (> acc times) grid
      (recur (connect-rooms grid 0 0 (rand-tile (count grid)) (rand-tile (count grid)))
             times
             (+ 1 acc))))

(defn generate-world-map-rooms [grid times acc]
  (if (> acc times) grid
      (recur (generate-room grid)
             times
             (+ 1 acc))))

(defn set-stairs
  "Find a stair location, connect the entry path to it."
  [m]
  (let [x (rand-tile (count m))
        y (rand-tile (count m))]
    (-> m
        (assoc-in [x y] STAIRS)
        (connect-rooms 0 0 x y))))

(defn generate-world-map [n]
  (-> (world-map-grid (+ map-size n))
      (update-in [0 0] inc)   ; Ensure 0,0 is always a valid walk path
      (generate-world-map-halls 3 0)
      (generate-world-map-rooms 5 0)
      (set-stairs)))

(defn get-unit-on-type?
  "Check what type of tile a unit is on for some special types (like stairs)."
  [grid {:keys [x y] :as _unit}]
  (case (get-in grid [x y])
    3 :stairs
    1 :floor
    0 :wall
    :unknown))
