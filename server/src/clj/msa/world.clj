(ns msa.world
  (:require
   [clojure.repl :refer :all]
   [clojure.spec.alpha :as s]
   [clojure.spec.gen.alpha :as gen]
   [clojure.spec.test.alpha :as stest]))

(declare add-feedback-to-player)
(declare connect-rooms)
(declare valid-coords?)
(declare update-stance!)
(declare mob-ai-stance)

(def verbosep nil)
(def save-file-path "/tmp/msa.edn")

(defn flip
  "Reverse function f arguments."
  [f]
  (fn [& xs]
    (apply f (reverse xs))))

(defn logp [s]
  (when verbosep
    (println s)))

(defn random-color []
  (float (/ (rand-int 1000) 1000)))

;; If this is ever an optimization issue, use subvec to avoid vec -> list -> vec
(defn take-latest-5 [col]
  (into [] (take-last 5 col)))

(defn colors []
  {:r (random-color)
   :g (random-color)
   :b (random-color)})

(defn i-red-scarf []
  {:back {:png "32b-red-scarf" :color (colors)}
   :default {:png "32-red-scarf-front" :color (colors)}})

(defn i-tunic []
  {:back {:png "32-tunic" :color (colors)}
   :default {:png "32-tunic" :color (colors)}})

(defn i-boots []
  {:back {:png "32-boots" :color (colors)}
   :default {:png "32-boots" :color (colors)}})

(defn coord []
  (int (rand 10)))

(defn get-valid-spawn-coords [p]
  (if (valid-coords? p) p
      (get-valid-spawn-coords (conj p {:x (coord) :y (coord)}))))

(defn random-items [col]
  (->> col (take (+ 1 (int (rand 4)))) (into [])))

(defn player [name]
  (let [p {:name name
           :chat "..."
           :animation_event {}
           :was_hit false
           :feedback ["You have joined the world."]
           :stance "attack"
           :stance_preferred (mob-ai-stance)
           :xp 1
           :hp 50
           :hpm 50
           :atk 5
           :def 5
           :x (coord)
           :y (coord)
           :dir "S"
           :gear (random-items [(i-tunic) (i-red-scarf) (i-boots)])}]
    (conj p (get-valid-spawn-coords p))))

;; (def stub
;;   (atom {:name "You" :x 0 :y 0 :gear [i-red-scarf]}))
(defn map-to-vec [col]
  (into [] (map (fn [[k v]] v) col)))

(def world-map
  (atom
   [[0 0 0 0 0]
    ])
  )

(defn my-rand-int [n]
  (int (* (+ 1 n) (rand 1))))

;;  Track what "step" or world cycle we're on.
(def world-step (atom 0))

(def world-map
  (atom nil))

(defn map-into
  "Eagerly maps into a vector the user fn to the col."
  [fn col]
  (into [] (doall (map fn col))))

(def map-size 30)

;; Wow, looks terrible!
(defn world-map-grid []
  (map-into (fn [x] (map-into (fn [y] 0) (range map-size))) (range map-size)))

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

(defn one [n] 1)

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

(defn rand-tile []
  (my-rand-int (- map-size 1)))

;; https://stackoverflow.com/questions/12628286/simple-way-to-replace-nth-element-in-a-vector-in-clojure
;; (assoc [1 2 3] 1 5) => [1 5 3]
;; (update-in [1 2 3] [1] inc) => [1 3 3]
;; We can do this by planting some room seeds that we then connect.
(defn generate-room [col]
  (let [x (rand-tile)
        y (rand-tile)
        size (my-rand-int (int (/ map-size 4)))]
    (def icol (atom col))
    (doseq [ix (range x (+ x size))
            iy (range y (+ y size))]
      (when (and (< ix map-size)
                 (< iy map-size))
        (swap! icol update-in [ix iy] one)))
    (connect-rooms @icol 0 0 x y)))

;; TODO: lol, clean this up - ever hear of a loop before?
(defn generate-world-map []
  (-> (world-map-grid)
      (update-in [0 0] inc)
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
      (connect-rooms 0 0 (rand-tile) (rand-tile))
       generate-room
       generate-room
       generate-room
       generate-room
       generate-room
       generate-room
       generate-room))

(defn set-world-map []
  (reset! world-map (generate-world-map)))

(defn get-world-map []
  (when (not @world-map)
    (set-world-map))
  @world-map)

;; Just some stubbed out player data.
(def world
  (atom
   {}
   ;; {:Test (player "Test")
   ;;  :Test2 (player "Test2")
   ;;  :Test3 (player "Test3")}
   ))

(defn world-to-disk []
  (spit save-file-path
        {:world @world
         :world-map @world-map}))

(defn world-from-disk []
  (let [disk-data (read-string (slurp save-file-path))]
    (reset! world-map (:world-map disk-data))
    (reset! world (:world disk-data))))

(defn world-reset []
  (reset! world
          {
           :Test {:x 3 :y 4}
           :Ttwo {:x 8 :y 8}
           }
          ;; {:Test (player "Test")
          ;;  :Test2 (player "Test2")
          ;;  :Test3 (player "Test3")}
          ))

(defn get-world []
  (map-to-vec @world))

(defn get-world-step [{:keys [step] :as params}]
  (let [min-step (Integer/parseInt (or step 0))]
    ;; User requests their min step (next update cycle).
    ;; If we haven't hit it yet, pause here until we do, so they get
    ;; the freshest response as soon as the world-step is updated.
    (while (> min-step @world-step) (do (Thread/sleep 50)))
    {:step @world-step
     :world (get-world)}))

;; (defn get-world []
;;   [@stub
;;    (player "Test")
;;    (player "Test2")
;;    (player "Test3")])

(defn col-all-but-name [s col]
  (->> col
       (filter #(not (= (:name %) s)))
       (into [])))

(defn col-find-by-name [s col]
  (->> col
       (filter #(= (:name %) s))
       first))

(defn all-but-name [s]
  (col-all-but-name s (get-world)))

(defn find-by-coords [{:keys [x y]}]
  (filter #(and (= x (:x %))
                      (= y (:y %))) (get-world)))

(defn empty-coords? [{:keys [x y] :as m}]
  (not (> (count (find-by-coords m)) 0)))

(defn valid-coords?
  "A value of 0 indicates an obstacle the player cannot walk on."
  [{:keys [x y] :as m}]
  (> (get-in (get-world-map) [x y]) 0))

(defn find-by-name [s]
  ((keyword s) @world))

(defn small-world []
  (map #(select-keys % [:name :x :y :hp :stance]) (get-world)))

(defn update-unit! [name unit]
  (swap! world conj {(keyword name) unit}))

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

(defn move-player
  "Move a unit in the specified direction.
  Expects p to have :x and :y keys."
  [dir p]
  (let [mp ((dir-to-move-fn dir) p)]
    (conj
     mp
     {:feedback
      (take-latest-5
       (conj (:feedback mp)
             (format "You move to %s , %s." (:x mp) (:y mp))))})))

(defn attack-player
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

(defn chat-player [chat p]
  (conj p {:chat chat}))

;; Our useful predicates or various states of things here.
(defn mob? [unit]
  (:mob unit))

(defn player? [unit]
  (not (mob? unit)))

(defn living? [{:keys [hp]}]
  (> hp 0))

(defn handle-move [{:keys [dir name]}]
  (let [player (find-by-name name)
        others (all-but-name name)]
    (when player
      (cond
        (not (living? player))
        (add-feedback-to-player name "Cannot move, you are dead.")

        (not (empty-coords? (move-player dir player)))
        (add-feedback-to-player name "Cannot move there, occupied.")

        (not (valid-coords? (move-player dir player)))
        (add-feedback-to-player name "Cannot move there, something blocks you.")

        :else
        (do
          (update-unit! name (move-player dir player))
          (update-stance! name "move"))))))

(defn update-dir! [name dir]
  (let [p (find-by-name name)]
    (update-unit! name (conj p {:dir dir}))))

(defn update-stance! [name stance]
  (let [p (find-by-name name)]
    (update-unit! name (conj p {:stance stance}))))

(defn update-was-hit! [name was?]
  (let [p (find-by-name name)]
    (update-unit! name (conj p {:was_hit was?}))))

;; TODO: Change pure xp to levels
(defn update-xp! [name n]
  (let [p (find-by-name name)]
    (when (not (:mob p))
      (update-unit! name (conj p {:xp (inc (:xp p))
                                  :hpm (+ (:hpm p) (:xp p))})))))

(defn update-health! [name fn]
  (let [p (find-by-name name)]
    (update-unit!
     name
     (conj p {:hp (min (:hpm p) (fn (:hp p)))}))))

(defn update-event! [name ae]
  (let [p (find-by-name name)]
    (update-unit! name (conj p {:animation_event ae}))))

(defn add-feedback-to-player [n f]
  (let [p (find-by-name n)]
    (update-unit! n (conj p {:feedback (take-latest-5 (conj (:feedback p) f))}))))

(defn msa-attack-scale
  "When two units are comparing stances, see which wins."
  [a-stance d-stance]
  (cond
    (= a-stance d-stance) 1
    (and (= a-stance "magic") (= d-stance "shield")) 2
    (and (= a-stance "shield") (= d-stance "attack")) 2
    (and (= a-stance "attack") (= d-stance "magic")) 2
    (and (= a-stance "magic") (= d-stance "attack")) 0.5
    (and (= a-stance "shield") (= d-stance "magic")) 0.5
    (and (= a-stance "attack") (= d-stance "shield")) 0.5
    :else 1
    ))

(defn msa-attack-scale-message [attacker defender]
  (case (msa-attack-scale (:stance attacker) (:stance defender))
    1 ""
    2 (format "Your %s beats %s! Double damage!\n" (:stance attacker) (:stance defender))
    0.5 (format "Your %s loses to %s! Half damage!\n" (:stance attacker) (:stance defender))
    true))

(defn damage-formula [{:keys [atk xp] :as attacker}
                      {:keys [def] :as defender}]
  (let [scale (msa-attack-scale (:stance attacker) (:stance defender))
        xp-diff (max 1 (- xp (:xp defender)))
        xp-atk (* atk xp-diff 0.5)
        xp-def (* def xp-diff 0.2)]
    (int (* scale (max 1 (- xp-atk xp-def))))))

(defn apply-damage [{:keys [name atk xp] :as attacker}
                    {:keys [hp x y def] :as defender}]
  (let [damage-done (damage-formula attacker defender)]
    (update-event! name {:event "attack" :x x :y y})
    (add-feedback-to-player
     name
     (format "%sYou hit someone for %s damage!"
             (msa-attack-scale-message attacker defender)
             damage-done))
    ;; TODO : Make xp assignment better (dynamic)
    (update-xp! name 1)
    (update-unit! (:name defender) (conj defender {:was_hit true
                                                   :hp (- hp damage-done)}))))

;; TODO: Probably update to use a get-all-on-coords and apply damage via names
;; and the name lookups (slightly slower, but more maintainable).
(defn coordinates-attacked
  "Player p applies an attack to all units in the world w that are on that coordinate."
  [w {:keys [x y] :as p}]
  (doall (map (fn [[k v]]
                {(keyword k)
                 (if (and (= (:x v) x)
                          (= (:y v) y))
                   (apply-damage p v)
                   v)}) w)))

(defn handle-attack [{:keys [dir name stance]}]
  (let [player (find-by-name name)
        others (all-but-name name)]
    (when player
      (cond
        (not (living? player))
        (add-feedback-to-player name "Cannot attack, you are dead.")

        :else
        (do
          ;; We should update player dir for front end animation too.
          (update-dir! name dir)
          (update-stance! name stance)
          ;; At this point, we know attack-player is the map of where he is attacking.
          ;; So, we don't actually update his position, we just use the new x/y coordinates.
          ;; (swap! world coordinates-attacked (attack-player dir player))
          (coordinates-attacked @world (attack-player dir player))))
      )))

(defn handle-chat [{:keys [chat name]}]
  (let [player (find-by-name name)
        others (all-but-name name)]
    (when player
      (update-unit! name (chat-player chat player)))))

(defn process-input
  "Dispatch based on the input action."
  [i]
  (let [{:keys [action]} i]
    (logp action)
    (case action
      "move" (handle-move i)
      "attack" (handle-attack i)
      "chat" (handle-chat i)
      nil)
    (get-world)))

(defn handle-login [{:keys [name]}]
  (when (not (find-by-name name))
    (update-unit! name (player name)))
  {:name name})

(defn random-name [s]
  (format "%s-%s" s (rand-int 10000)))

(defn spawn-mob []
  (let [name (random-name "Mob-")
        p (player name)
        p2 (conj p {:mob true})]
    (update-unit! name p2)))

(defn get-all-mobs []
  (filter #(:mob %) (get-world)))

(defn get-all-players []
  (filter player? (get-world)))

(defn get-all-living-players []
  (filter living? (get-all-players)))

(defn point-to-point-distance [a b]
  (+ (Math/abs (- (:x a) (:x b)))
     (Math/abs (- (:y a) (:y b)))))

(defn ptp-comparator [mob a b]
  (< (point-to-point-distance a mob)
     (point-to-point-distance b mob)))

(defn mob-ai-choose-direction [mob player]
  (let [sx (:x mob)
        sy (:y mob)
        dx (:x player)
        dy (:y player)]
    (cond
      (> dx sx) "E"
      (> dy sy) "S"
      (< dx sx) "W"
      (< dy sy) "N"
      :else nil)))

;; TODO: Have mobs have a preferred stance and maybe not change it.
;; Either at spawn time, or derived from values when we make each skill
;; increase separately from the basic atk skill.
(defn mob-ai-stance []
  (case (rand-int 3)
    0 "magic"
    1 "shield"
    2 "attack"))

(defn mob-ai-preferred-stance [mob]
  (:stance_preferred mob))

;; Assumptions:
;; 0,0 should always be the top-left (upper most) part of map.
;; This makes it a bit easier to handle tracking the player, as
;; we never have to worry about negatives in our calculations.
;; MOB at 2,2 for instance and has players at 0,0 and 3,3 - they
;; should go for the person at 3,3 (unless we add bias factors later),
;; as we can simply use some calculation like x-dist = 1 + y-dist = 1 (2) < 4
(defn mob-ai
  "Try to choose some sensible action to take.  Lets start by
  simply moving towards another player and trying to follow them."
  [{:keys [x y] :as mob}]
  (let [players (get-all-living-players)
        comparator (partial ptp-comparator mob)
        closest (first (sort comparator players))]
    (when closest
      (let [dir (mob-ai-choose-direction mob closest)
            dist (point-to-point-distance mob closest)]
        (cond
          (= 1 dist)
          {:action "attack"
           :dir dir
           :mob true
           :stance (mob-ai-preferred-stance mob)
           :name (:name mob)}
          (> dist 1)
          {:action "move"
           :dir dir
           :mob true
           :name (:name mob)}
          :else nil)))))

(def queue (atom nil))
(def queue-runner-mutex (atom true))

(def fake [{:name "Jon" :x 1} {:name "Jon" :x 2} {:name "Fred" :x 3}])

(defn take-names [col]
  (distinct (map :name col)))

(defn filter-names [s col]
  (->>
   (filter #(= (:name %) s) col)
   reverse
   (take 1)
   (into [])))

(defn dedupe-by-name
  "Deduplicate the map collection col, based on the :name key."
  [col]
  (let [names (take-names col)]
    (reduce (fn [n1 n2]
              (concat n1 (filter-names n2 col)))
            []
            names)))

(defn clear-all-events [col]
  (doall
   (map #(update-event! % {}) (take-names col))))

(defn clear-all-was-hits [col]
  (doall
   (map #(update-was-hit! % false) (take-names col))))

(defn regen-some-health [col]
  (doall (map #(update-health! % inc) (take-names col))))

;; Nice
;; (select-keys {:a 1 :b 2 :c 3} [:a :b])
(defn filter-by-step [step col]
  (filter #(or (= (:step %) step)
               (:mob %)) col))

;; Just adds events into the queue.
(defn handle-input [i]
  (logp "Handle Input: ")
  (logp i)
  (swap! queue conj i)
  (get-world))

(defn process-input-comparator
  "For the player's sake and sanity, put mob actions last.
  Maybe at some point we'll introduce a speed stat and that
  can determine the sort order for processing inputs here."
  [a b]
  (if (and (:mob a) (not (:mob b))) false true))

(defn process-queue
  "Go through all the pending events for action requests, AI movements,
  and persisting the game state to disk."
  []
  (world-to-disk)
  (when (< 3 (count (get-all-mobs)))
    (spawn-mob))
  (when @queue-runner-mutex
    ;; Wipe out all of last round's animation_event
    (clear-all-events (get-world))
    (clear-all-was-hits (get-world))
    (regen-some-health (get-world))
    ;; Give the mobs a chance to do something.
    ;; TODO: May want to plop them in queue with everyone else if we end up sorting
    ;; actions based on speed or something.  We should also always let players resolve
    ;; first in the meantime, as it will be very frustrating if not.
    (doall (map handle-input (doall (map mob-ai (get-all-mobs)))))
    (let [process-worthy (dedupe-by-name (filter-by-step @world-step @queue))]
      (logp "Process worthy events: ")
      (logp process-worthy)
      (doall (map process-input (sort process-input-comparator process-worthy))))
    (logp "yea, Done processing queue, resetting.")
    (doall
     (map (fn [{:keys [name x y]}]
            (logp (format "P: %s X: %s Y: %s" name x y))) (get-world)))
    (reset! queue nil))
  (swap! world-step inc)
  (Thread/sleep 1500))

(defn world-boot []
  (get-world-map)
  (spawn-mob))

(defn maybe-world-resume []
  (if (.exists (clojure.java.io/file save-file-path))
    (world-from-disk)
    (world-boot)))

;; Process over and over
(defn queue-runner []
  (maybe-world-resume)
  (future (while true (do (process-queue)))))

(defn start-queue-runner []
  (reset! queue-runner-mutex true))

(defn stop-queue-runner []
  (reset! queue-runner-mutex false))

;; (queue-runner)
