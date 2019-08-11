(ns msa.test.world
  (:require [clojure.test :refer :all]
            [ring.mock.request :refer :all]
            [msa.world :as w]))

;; Set up a stub for the test here.
(swap! w/world-map conj {(keyword (str -1)) [[0 0] [0 3]]})

(w/process-zone-changes identity [{:x 1 :y 1 :zone -1 :hp 1}])

(deftest test-on-stairs?
  (testing "If I find match on stairs"
    (is (= true (w/on-stairs? {:x 1 :y 1 :zone -1})))))

(deftest test-process-zone-change
  (testing "works with empty collection"
    (is (= [] (w/process-zone-changes identity []))))

  (testing "works with non-empty collection"
    (is (= [] (w/process-zone-changes identity [{:x 0 :y 0 :zone -1 :hp 1}]))))

  (testing "works with non-empty collection and finds stair matches"
    (is (= (list "Jon") (w/process-zone-changes (fn [& r] (first r)) [{:name "Jon" :x 1 :y 1 :zone -1 :hp 1}]))))

  )
