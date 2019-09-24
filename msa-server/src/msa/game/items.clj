(ns msa.game.items
  (:require
   [clojure.repl :refer :all]
   [clojure.test :as t :refer [deftest testing is run-tests]])
  )

(defn random-color []
  (float (/ (rand-int 1000) 1000)))

(deftest random-color-test
  (testing "We can generate a random color between 0 and 1."
    (let [c (random-color)]
      (is (>= c 0))
      (is (<= c 1)))))

(defn colors []
  {:r (random-color)
   :g (random-color)
   :b (random-color)})

(defn i-head-shorthair []
  {:back {:png "32-head-shorthair-back" :color (colors)}
   :default {:png "32-head-shorthair-front" :color (colors)}})

(defn i-red-scarf []
  {:back {:png "32b-red-scarf" :color (colors)}
   :default {:png "32-red-scarf-front" :color (colors)}})

(defn i-tunic []
  {:back {:png "32-tunic" :color (colors)}
   :default {:png "32-tunic" :color (colors)}})

(defn i-boots []
  {:back {:png "32-boots" :color (colors)}
   :default {:png "32-boots" :color (colors)}})
