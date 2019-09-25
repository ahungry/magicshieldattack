(ns msa.game.items
  (:require
   [clojure.spec.alpha :as s]
   [clojure.spec.gen.alpha :as gen]
   [clojure.spec.test.alpha :as stest]
   [clojure.repl :refer :all]
   [clojure.test :as t :refer [deftest testing is run-tests]])
  )

(defrecord ItemImage [png color])
(defrecord Item [back default about uuid name owner worn])

(s/def ::color-value number?)
(s/def ::r ::color-value)
(s/def ::g ::color-value)
(s/def ::b ::color-value)
(s/def ::color (s/keys :req-un [::r ::g ::b]))
(s/def ::non-empty-string (s/and string? #(> (count %) 0)))

;; See: sprites/README.md for more information on this format.
(s/def ::png ::non-empty-string)
(s/def ::item-image (s/keys :req-un [::png ::color]))
(s/def ::back ::item-image)
(s/def ::default ::item-image)
(s/def ::about ::non-empty-string)
(s/def ::uuid ::non-empty-string)
(s/def ::name ::non-empty-string)
(s/def ::slot ::non-empty-string)
(s/def ::owner ::non-empty-string)
(s/def ::worn boolean?)
(s/def ::item (s/keys :req-un [::back ::default ::about ::uuid ::name ::owner ::worn]))

(defn colors []
  {:r (random-color)
   :g (random-color)
   :b (random-color)})

(defn make-image [m]
  (let [model (map->ItemImage
               (conj {:png "32-head-shorthair-front" :color (colors)} m))]
    (if (s/valid? ::item-image model)
      model
      (throw (Throwable. (str (s/explain ::item-image model)))))))

(defn make
  "Create an item for future consumption."
  ([] (make {:png-back "32-head-shorthair-back"
             :png-front "32-head-shorthair-front"}))
  ([m]
   (let [model (map->Item
                (conj {:back (make-image {:png (:png-back m)})
                       :default (make-image {:png (:png-front m)})
                       :about "Just a basic item."
                       :name "Red Scarf"
                       :slot "head"
                       :uuid "0"
                       :worn false
                       :owner "nobody"
                       } m))]
     (if (s/valid? ::item model)
       model
       (throw (Throwable. (str (s/explain ::item model))))))))

(defn random-color []
  (float (/ (rand-int 1000) 1000)))

(deftest random-color-test
  (testing "We can generate a random color between 0 and 1."
    (let [c (random-color)]
      (is (>= c 0))
      (is (<= c 1)))))

(defn i-head-shorthair []
  (make {:png-back "32-head-shorthair-back"
         :png-front "32-head-shorthair-front"
         :about "A fancy short haircut."
         :name "Short Haircut"
         :slot "head"
         :uuid "1"
         }))

(defn i-red-scarf []
  (make {:png-back "32b-red-scarf"
         :png-front "32-red-scarf-front"
         :about "A warm red scarf with a long ponytail."
         :name "Scarf"
         :uuid "2"
         :slot "head"
         }))

(defn i-tunic []
  (make {:png-back "32-tunic"
         :png-front "32-tunic"
         :about "Cozy tunic to keep you warm."
         :name "Tunic"
         :uuid "3"
         :slot "chest"
         }))

(defn i-boots []
  (make {:png-back "32-boots"
         :png-front "32-boots"
         :about "Plain old boots."
         :name "Boots"
         :uuid "4"
         :slot "feet"
         }))
