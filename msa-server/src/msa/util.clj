(ns msa.util)

;; Just an assortment of helpers and utilities that don't have anywhere else to go.

(defn keys->keyword-keys
  "When we have string keys, force them to be kw based."
  [m]
  (let [ks (keys m)
        vs (vals m)]
    (zipmap (map keyword ks) vs)))
