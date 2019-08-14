(ns msa.util-test
  (:require [clojure.test :refer :all]
            [msa.util :as u]))

(deftest test-keys->keyword-keys
  (testing "if it will convert properly and as expected."
    (is (= {:x 1 :y 2} (u/keys->keyword-keys {"x" 1 "y" 2})))))
