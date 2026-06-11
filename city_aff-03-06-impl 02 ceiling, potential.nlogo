extensions [ palette ]

breed [people person]

patches-own
[
  patch-density
  proximity-to-center
  is-residental?

  patch-Et ;; constant and belongs to patch
  patch-Er ;; depends on rent coeff and patch density, belongs to person or patch?

  patch-satisfied-agent-count
]

people-own
[
  satisfied?
  income
  desired-EIR
  person-EIR

  person-Er
  person-Et
  total-person-expenditure

  transport-cost
]

to setup
  clear-all
  ;;random-seed 12345
  ask patches [set pcolor white]
  ;;draw-grid
  setup-patches
  create-residents;; inside create-residents residents get their default income distribution by normal distribution
  ;;set-income-beta
  ;;set-income-beta-poor;; when I need income to be beta distributed, i first set it via norm and then reassign
  ;;set-income-extreme-beta-poor-0.47

  ;;plots updating code start
  update-distance-income-plot-satisfied
  update-income-distribution-plot
  update-eir-plot
  update-expenditure-plot
  ;;plots updating code end

  reset-ticks
end

to go
  if not any? people with [satisfied? = false][user-message "All people found home (satisfied? = true)" stop] ;; stop simulation if all satisfied

  ;;trying to update code for model flow if satisfied can become searching again

  ask patches with[is-residental? = true and any? people-here with [satisfied? = true]]
  [
    let happy-here count people-here with [satisfied? = true]
    set patch-satisfied-agent-count happy-here

;    if(patch-satisfied-agent-count < 10)
;    [
;      ask people-here with [satisfied? = true]
;      [
;        let current-person-EIR evaluate-person-EIR patch-here
;        if current-person-EIR > desired-EIR [set satisfied? false]
;      ]
;    ]

  ]



  update-patch-color-based-on-density
  show-or-hide-people

  evaluate-EIR-and-find-home

  ;;plots updating code start
  update-distance-density-plot
  update-distance-income-plot-satisfied
  update-eir-plot
  update-expenditure-plot
  ;;plots updating code end

  tick
end

to color-eirwise
  let residential-patches patches with [ is-residental? = true]
  if any? residential-patches
  [
    let agentset-satisfied (people-on residential-patches) with [satisfied? = true]
    let max-d max [person-EIR] of agentset-satisfied
    let min-d min [person-EIR] of agentset-satisfied

    ;; ensures the visualization is done only if there is variation between min and max
    if max-d != min-d
    [
      ask residential-patches
      [
        if any? people-here with [satisfied? = true]
        [
          let EIR-on-patch mean [person-EIR] of people-here
          set pcolor palette:scale-scheme "Sequential" "Reds" 9 EIR-on-patch min-d max-d
          ;;set pcolor scale-color grey EIR-on-patch min-d max-d
        ]

      ]
    ]
  ]
end


to color-incomewise
  let residential-patches patches with [ is-residental? = true]
  if any? residential-patches
  [
    let agentset-satisfied (people-on residential-patches) with [satisfied? = true]
    let max-d max [income] of agentset-satisfied
    let min-d min [income] of agentset-satisfied

    ;; ensures the visualization is done only if there is variation between min and max
    if max-d != min-d
    [
      ask residential-patches
      [
        if any? people-here with [satisfied? = true]
        [
          let income-on-patch mean [income] of people-here with [satisfied? = true]
          set pcolor palette:scale-scheme "Sequential" "Reds" 9 income-on-patch min-d max-d
          ;;set pcolor scale-color grey EIR-on-patch min-d max-d
        ]

      ]
    ]
  ]
end

;; for Income Distribution Density Plot
to update-income-distribution-plot
  set-current-plot "Income Distribution Plot"
  clear-plot

  let sorted-turtles sort-by [[t1 t2] -> [income] of t1 < [income] of t2] turtles
  let i 0
  foreach sorted-turtles [
    t ->
    set i i + 1
    plotxy i [income] of t
  ]
end


;; EIR PLOT
to update-eir-plot
    ;; setting min max and title
  set-current-plot "Distance vs EIR"
  clear-plot
  set-plot-x-range 1  max [proximity-to-center] of patches  ;; set X axis
  let ymax 0.5;;max [person-eir] of people
  if ymax = 0 [set ymax 0.01]
  set ymax precision ymax 2
  set-plot-y-range 0 ymax
  ;; end of setting min and max values


    ;; loop over rings 1 to [proximity-to-center] of patches(14)
  let r 1
  while [r <= 14]
  [
    ;; patches in this ring
    let ring patches with [proximity-to-center = r]

    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)
    if any? ring [
      let all-people-on-ring people-on ring
      let people-on-ring all-people-on-ring with [satisfied? = true]

      let highincome-on-ring people-on-ring with[income > (mean [income] of people)]
      let lowincome-on-ring people-on-ring with[income <= (mean [income] of people)]

      if any? people-on-ring
      [
        let avg-eir mean [person-EIR] of people-on-ring

        set-current-plot-pen "EIR-mean"
        plotxy r avg-eir

        if any? highincome-on-ring
        [
          set-current-plot-pen "EIR-High Income"
          let avg-high mean [person-EIR] of highincome-on-ring
          plotxy r avg-high
        ]


        if any? lowincome-on-ring
        [
          set-current-plot-pen "EIR-Low Income"
          let avg-low mean [person-EIR] of lowincome-on-ring
          plotxy r avg-low
        ]
        ;; this print only handles average per ring
        ;;print (word "r: " r word " average income: " avg-income)
      ]

    ]
    set r r + 1;; incrementing for the next radius
  ]
end


;; Expenditure plot
to update-expenditure-plot
    ;; setting min max and title
  set-current-plot "Distance vs Expenditure"
  clear-plot
  set-plot-x-range 1  max [proximity-to-center] of patches  ;; set X axis
  let ymax 0.5;;max [person-eir] of people
  if ymax = 0 [set ymax 0.01]
  set ymax precision ymax 2
  set-plot-y-range 0 ymax
  ;; end of setting min and max values


    ;; loop over rings 1 to [proximity-to-center] of patches(14)
  let r 1
  while [r <= 14]
  [
    ;; patches in this ring
    let ring patches with [proximity-to-center = r]

    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)
    if any? ring [
      let avg-Et mean [patch-Et] of ring
      set-current-plot-pen "Expenditure on travel"
      plotxy r avg-Et

      if any? people-on ring
      [
        let avg-Er mean [person-Er] of people-on ring
        set-current-plot-pen "Expenditure on rent"
        plotxy r avg-Er

        let avg-total (avg-Er + avg-Et)
        set-current-plot-pen "Total expenditure"
        plotxy r avg-total
        ;; this print only handles average per ring
        ;;print (word "r: " r word " average income: " avg-income)

      ]
    ]
    set r r + 1;; incrementing for the next radius
  ]
end




;;Procedure is used for visualizing and calculating 1st Density output of standard model
;; No changes in this procedure as compared to previos version
to update-distance-density-plot
  ;;clear-plot
  ;; setting min max and title
  set-current-plot "Distance vs Density"
  clear-plot
  set-plot-x-range 1  max [proximity-to-center] of patches  ;; set X axis
  let ymax max [patch-density] of patches
  if ymax = 0 [set ymax 0.01]
  set ymax precision ymax 2
  set-plot-y-range 0 ymax
  ;; end of setting min and max values


    ;; loop over rings 1 to [proximity-to-center] of patches(14)
  let r 1
  while [r <= 14]
  [
    ;; patches in this ring
    let ring patches with [proximity-to-center = r]

    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)
    if any? ring [
      let avg-density mean [patch-density] of ring
      plotxy r avg-density
      ;;print (word "r: " r word " average density: " avg-density)
    ]
    set r r + 1;; incrementing for the next radius
  ]
end

;;Procedure is used for visualizing and calculating 2nd output Income of standard model
;; this is a new procedure based on similar code for 1st Density output
to update-distance-income-plot-satisfied
  ;; setting min max and title
  set-current-plot "Distance vs Income (Satisfied People)"
  clear-plot
  set-plot-x-range 1  max [proximity-to-center] of patches  ;; set X axis
  let ymax 54000 ;;let ymax (max [income] of people)
  ;;print(word "max [income] of people with[satisfied? = true IS: " ymax)
  if ymax = 0 [set ymax 0.01]
  set ymax precision ymax 2
  set-plot-y-range (ymax - 5000) ymax;;set-plot-y-range 0 ymax
  ;; end of setting min and max values

;  ask patches with [is-residental? = true]
;  [
;    let satisfied-people people-here with [satisfied? = true]
;    if any? satisfied-people
;    [
;      let avg-income mean [income] of satisfied-people
;      print(word"average income of satisfied per patch: " avg-income " distance: " proximity-to-center)
;      plotxy proximity-to-center avg-income
;    ]
;  ]
;


    ;; loop over rings 1 to [proximity-to-center] of patches(14)
  let r 1
  while [r <= 14]
  [
    ;; patches in this ring
    let ring patches with [proximity-to-center = r]

    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)
    if any? ring [
      let all-people-on-ring people-on ring
      let people-on-ring all-people-on-ring with [satisfied? = true]
      if any? people-on-ring
      [
        let avg-income mean [income] of people-on-ring
        ;print(word"Plotting income plot, r: " r " . Avg income: " avg-income)
        plotxy r avg-income
        ;; this print only handles average per ring
        ;;print (word "r: " r word " average income: " avg-income)
      ]

    ]
    set r r + 1;; incrementing for the next radius
  ]
end

;; Note! This procedure asks 10% of unsatisfied at a time, but when we  have left 10% unsatisfied people and 90% satisfied, then current code
;; asks all who'se left unsatisfied to search. This logic needs to be compared to gradually increasing how many we ask, not ask all who's left at once
;; to see if the final 10% of population affect the emergent preferential settling pattern depending on how this logic is coded.
to evaluate-EIR-and-find-home
  let tenpercent ceiling ((count people with[satisfied? = false]) / 10)

  if(count people with [satisfied? = false] < (count people) * 0.1)[set tenpercent ceiling (count people with [satisfied? = false])]

  let tenpercentpeople n-of tenpercent people with[satisfied? = false];;let tenpercentpeople n-of tenpercent people with[satisfied? = false]
  ask tenpercentpeople
  [
    if ([patch-satisfied-agent-count] of patch-here >= 10)
    [
      move-to one-of patches with[is-residental? = true and patch-satisfied-agent-count < 10]
    ]

    let num-checks 0
    while[num-checks < 10 and satisfied? = false]
    [
      ;;print(word"who: " who " . Current num-check: " num-checks " . Satisfied? : " satisfied?  )
      let current-value evaluate-person-EIR patch-here
      ;;print(word"who: " who " . Income: " income ". Got EIR: " current-value " . Compare to desired-EIR: " desired-EIR)

      ifelse(current-value <= desired-EIR)
      [
        ;; no move, just stay on this satisfactory patch
        set satisfied? true

        ask patch-here [set patch-satisfied-agent-count patch-satisfied-agent-count + 1]

        ;after agent settles/moves, ask the patch and its neighbours to change their patch-density
        ask patch-here
        [
          reevaluate-patch-density self
          ask neighbors with[is-residental? = true][reevaluate-patch-density self]
        ]
        set patch-Er (rent-coeff * ([patch-density] of patch-here))

        ; This is basically a decision if person-Er should include the new patch density after the agent moves, or the previous one
        set person-Er (rent-coeff * ([patch-density] of patch-here))
        set person-Et (transport-cost * ([proximity-to-center] of patch-here));;set person-Et [patch-Et] of patch-here
        set total-person-expenditure (person-Er + person-Et)

        ;print(word"after change: " person-Er)
        set person-EIR current-value


;        ;;after agent settles/moves, ask the patch and its neighbours to change their patch-density
;        ask patch-here
;        [
;          reevaluate-patch-density self
;          ask neighbors with[is-residental? = true][reevaluate-patch-density self]
;        ]
;        set patch-Er (rent-coeff * ([patch-density] of patch-here))
      ]
      [
;        set desired-EIR desired-EIR + 0.01;; else increase EIR by 0.01
        move-to one-of patches with[is-residental? = true and patch-satisfied-agent-count < 10]
        set num-checks (num-checks + 1)
      ]
    ];;closing the repeat while loop

    if(satisfied? = false)[set desired-EIR desired-EIR + 0.01]    ;; else increase EIR by 0.01
  ]
end


;; Patch and its neighbour patches densities are updated After a satisfied agents moves to it
to reevaluate-patch-density [executing-patch]
  ;; evaluate patch density here + of neighbours of executing patch
  let density-here count (people-on executing-patch) with [satisfied? = true]
  set density-here (density-here / (2 * 10))

  let neighbour-agents people-on ([neighbors] of executing-patch)
  let density-neighbours count neighbour-agents with [satisfied? = true]
  set density-neighbours (density-neighbours / (2 * 80))

  let potential-density (density-here + density-neighbours)
  set patch-density potential-density

  set patch-Et (commuting-coeff * proximity-to-center )
end


to-report evaluate-person-EIR [executing-patch] ;; must be called in context of agents (person)
  ;; evaluate patch density here + of neighbours of executing patch
  let density-here count (people-on executing-patch) with [satisfied? = true]
  set density-here ((density-here + 1) / (2 * 10));; +1 is to include current turtle as potential resident

  let neighbour-agents people-on ([neighbors] of executing-patch)
  let density-neighbours count neighbour-agents with [satisfied? = true]
  set density-neighbours (density-neighbours / (2 * 80))

  let potential-density (density-here + density-neighbours)

;  print(word"----------------")
;  print(word"Executing patch: " executing-patch " with density: " density-here " . Neighbours': " density-neighbours)

  let Er (rent-coeff * potential-density)

  ;;;;;;;;;;;;;
  ;;if (Er < 2000)[set Er 2000]
  ;;;;;;;;;;;;;
 ; print(word"Inside evaluate-person-EIR Er for calculating EIR is: " Er)
;    set patch-Er (rent-coeff * patch-density )

  let Et (transport-cost * [proximity-to-center] of executing-patch)
  let individ-eir ((Er + Et) / income)

;  print(word"-----------------")
;  print(word"who: " who ". executing-patch: " executing-patch " . Er : " Er " . Et: " Et " . Income: " income " .  EIR: " individ-eir)
;  print(word"patch-density: " [patch-density] of executing-patch)
;  print(word"-----------------")


;  set person-Er Er
;  ;print(word"EVALUATE PERSON EIR PROCEDURE. Who: " who " . current Er set: " person-Er)
;  set person-EIR individ-eir

  report individ-eir
end

to show-or-hide-people
  ifelse(show-people? = false)[ask people[hide-turtle]]
  [ask people[show-turtle]]
end


to update-patch-color-based-on-density
;  ;ensure color update will be only done if there are any happy agents
;  if(any? people with[satisfied? = true])
;  [
;    let max-d max [ patch-density ] of patches
;    let min-d min [ patch-density ] of patches
;    ask patches with [is-residental?][set pcolor scale-color pink (max-d - patch-density) 0 max-d]
;  ]
;
;  let excluded-patch patch 0 0
;  ask patches with [is-residental? = false and self != excluded-patch]
;  [set pcolor 109]


let residential-patches patches with [ is-residental? = true]
if any? residential-patches [
  let max-d max [patch-density] of residential-patches
  let min-d min [patch-density] of residential-patches

  ;; ensures the visualization is done only if there is variation between min and max
  if max-d != min-d [
    ask residential-patches [
      set pcolor palette:scale-scheme "Sequential" "Reds" 9 patch-density min-d max-d
    ]
  ]
]


;let residential-patches patches with [is-residental?]
;if any? residential-patches [
;  let max-d max [patch-density] of residential-patches
;  let min-d min [patch-density] of residential-patches
;  let value-range max-d - min-d
;
;  ask residential-patches [
;    let norm-density 0
;
;    ;; manual normalization
;    if value-range > 0 [
;      set norm-density (patch-density - min-d) / value-range
;    ]
;
;    ;; invert so max values become darkest
;    set pcolor scale-color red (1 - norm-density) 0 1
;  ]
;]
end


to create-residents
  ;; in author's original model num agents was 3065, thus I add 1 to make parameters as close to original as possible
  ;; Otherwise it should have been 3060 people, meaning original model included central patch in total patch count, which is not right
  let num-people ((count patches with [is-residental? = true]) + 1) * 10 / 2

  create-people num-people
  [
    set shape "circle"
    set color blue
    set size 0.2
    move-to one-of patches with[is-residental? = true]
    place-with-offset
  ]

  ;; assign characteristics below
  ask people
  [
    set satisfied? false

    ;;calling procedure for normal distribution of wealth
    ;;income with min value 10000, sd 12000

    set-income-norm

    ;;print (word "initial income for turtle: " who " is: " income)

    ;;set person-Er 2000
    ;;set person-Er (rent-coeff * ([patch-density] of patch-here))
    set desired-EIR 0.1

    ;;set transport-cost with probability 50%
    ;;only for experiment 3, otherwise it should be picked from commuting-coeff
    ;;set transport-cost one-of [1000 700]
    set transport-cost commuting-coeff
  ]
end

;;normally distribution initial income
to set-income-norm
  set income random-normal mean-income 12000
  if(income < 10000)[set income 10000]
end

;;beta distribution of initial income done after agents firt get their normally distribution income, this reassigns it
to set-income-beta-poor
  random-seed 12345

  let norm-max max [income] of people
  let norm-min min [income] of people

 ;; gini 0.13 through  alpha=beta=5 (symmetric shape of the income distribution curve) or just regular normal distribution
 ;; gini 0.36 through alpha 0.5 beta 1 or 1.7
 ;; gini 0.43 through alpha 0.1 beta 0.8
  let alpha 0.5
  let beta 1

  ask people
  [
    let XX random-gamma alpha 1
    let YY random-gamma beta 1
    let unscaled-income (XX / (XX + YY))
    let scaled-income (norm-min + unscaled-income * (norm-max - norm-min))
    set income scaled-income
    if income < norm-min [set income norm-min]
    if income > norm-max [set income norm-max]
    ;;print(income)
  ]
end

;;this is used to generate beta income distribution for gini 0.446 with majority very poor and few very rich
to set-income-extreme-beta-poor-0.47
  random-seed 12345

  let norm-max max [income] of people
  let norm-min min [income] of people

 ;; gini 0.13 through  alpha=beta=5 (symmetric shape of the income distribution curve) or just regular normal distribution
 ;; gini 0.36 through alpha 0.5 beta 1 or 1.7
  ;; gini 0.47 0.1 and 0.456
  let alpha 0.12
  let beta 0.456

  ask people
  [
    let XX random-gamma alpha 1
    let YY random-gamma beta 1
    let unscaled-income (XX / (XX + YY))
    let scaled-income (norm-min + unscaled-income * (norm-max - norm-min))
    set income scaled-income
    if income < norm-min [set income norm-min]
    if income > norm-max [set income norm-max]
    ;;print(income)
  ]

;  let norm-max max [income] of people
;  let norm-min min [income] of people
;
;;  let alpha 0.8
;;  let beta 4
;  let alpha 2
;  let beta 4
;
;  ask people [
;  ifelse random-float 1.0 < 0.05 [
;    ;; Rich tail
;    let u random-float 1
;    ;; Pareto with xm=1, alpha=1.5
;    let income_tail 1 / (u ^ (1 / 1.5))
;
;    set income (norm-min + income_tail * (norm-max - norm-min))
;    ;print(income)
;  ] [
;    ;; Majority - Beta
;    let XX random-gamma alpha 1
;    let YY random-gamma beta 1
;    let unscaled-income (XX / (XX + YY))
;    set income (norm-min + unscaled-income * (norm-max - norm-min))
;    ;print(income)
;  ]
;]

end

;;this beta is for both poor and rich people gives gini 0.36
to set-income-beta
  random-seed 12345

  let norm-max max [income] of people
  let norm-min min [income] of people

  let alpha 1
  let beta 4

  ask people
  [
  ifelse random-float 1.0 < 0.12 [
    ;; Rich tail
    let u random-float 1
    ;; Pareto with xm=1, alpha=1.5
    let income_tail 1 / (u ^ (1 / 1.5))

    set income (norm-min + income_tail * (norm-max - norm-min))
    ;print(word"heavy income tail: " income)
  ]
    [

    let XX random-gamma alpha 1
    let YY random-gamma beta 1
    let unscaled-income (XX / (XX + YY))
    let scaled-income (norm-min + unscaled-income * (norm-max - norm-min))

    set income scaled-income

    ;print(income)
    ]
    if income < norm-min [set income norm-min]
    if income > norm-max [set income norm-max]
  ]
end


to place-with-offset
  let n count people-here
  let i who mod n
  let angle 360 * i / n
  setxy (pxcor + 0.3 * cos angle)
      (pycor + 0.3 * sin angle)
end


;; Even setups up patch-Et as its constant and doesnt change
to setup-patches
  ask patches [set is-residental? false]
  set-patch-size 10

  ask patch 0 0
  [
    ask patches in-radius 14
    [
      set pcolor red
      set proximity-to-center (ceiling distance patch 0 0)


      set  is-residental? true
      set patch-density 0

      set patch-Et (commuting-coeff * proximity-to-center )

      ;;set patch-Er 2000

      set patch-satisfied-agent-count 0
    ]
  ]


  ask patch 0 0
  [
    set pcolor yellow
    set is-residental? false
    set patch-Et 0
  ]

end

to draw-grid ;; this procedure uses new turtles just for drawing a grid
  ask patches[
      sprout 1[
      set color grey
      setxy (pxcor - 0.5) (pycor + 0.5) ;; defines starting point so that turtles get inside the grid, not in between graphically
      set heading 0
      forward .5
      pen-down
      repeat 4 [forward .5 right 90 forward .5]
      die
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
179
10
517
349
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
1
10
56
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
62
10
117
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
2
47
136
80
show-people?
show-people?
1
1
-1000

SLIDER
6
165
169
198
mean-income
mean-income
10000
100000
50000.0
5000
1
NIL
HORIZONTAL

MONITOR
521
12
702
57
N of people in current simulation
count people
17
1
11

MONITOR
521
58
702
103
mean distance from center
mean [ proximity-to-center ] of patches
17
1
11

SLIDER
6
201
170
234
rent-coeff
rent-coeff
10000
60000
30000.0
5000
1
NIL
HORIZONTAL

SLIDER
6
238
170
271
commuting-coeff
commuting-coeff
100
1500
700.0
50
1
NIL
HORIZONTAL

SLIDER
6
275
170
308
min-expenditure-rent
min-expenditure-rent
500
4000
2000.0
500
1
NIL
HORIZONTAL

SLIDER
6
313
172
346
min-expenditure-commuting
min-expenditure-commuting
100
1500
700.0
100
1
NIL
HORIZONTAL

MONITOR
521
105
702
150
max [ patch-density ]
max [ patch-density ] of patches with[is-residental? = true]
4
1
11

MONITOR
521
152
702
197
min [ patch-density ]
min [ patch-density ] of patches with [is-residental? = true]
4
1
11

MONITOR
521
199
638
244
count satisfied people
count people with [satisfied?]
17
1
11

MONITOR
639
199
702
244
% satisfied
(count people with [satisfied?]) * 100 / count people
4
1
11

PLOT
5
350
323
546
Distance vs Density
Distance from city center
Patch density
0.0
100.0
0.0
100.0
true
false
";; this graph is controlled from procedure to update-distance-density-plot\n" ""
PENS
"distancedensity" 1.0 0 -14985354 true "" "\n"

MONITOR
330
350
517
395
Density-MEAN of residental patches
;;mean [patch-density] of patches with [any? people-here with [satisfied? =  true]]\nmean [patch-density] of patches with [is-residental? = true]
4
1
11

MONITOR
330
399
517
444
Density-MIN of residental patches
;;min [patch-density] of patches with [any? people-here with [satisfied? =  true]]\nmin [patch-density] of patches with [is-residental? = true]
4
1
11

MONITOR
330
452
517
497
Density-MAX of residental patches
;;max [patch-density] of patches with [any? people-here with [satisfied? =  true]]\nmax [patch-density] of patches with [is-residental? = true]
4
1
11

MONITOR
330
501
517
546
Density-CV of residental patches
;;(standard-deviation [patch-density] of patches with [any? people-here with [satisfied? = true]]) / (mean [patch-density] of patches with [any? turtles-here with [satisfied? =  true]])\n(standard-deviation [patch-density] of patches with [is-residental? = true]) / (mean [patch-density] of patches with [is-residental? = true])
4
1
11

TEXTBOX
250
551
400
576
DENSITY
20
0.0
1

BUTTON
160
576
375
609
ask all patches show distance and density
ask patches with [proximity-to-center > 0][print (word \"distance: \" proximity-to-center word \" density: \" patch-density)]\n\n;;ask patches with [any? turtles-here with [satisfied? = true]][print (word \"distance: \" proximity-to-center word \" density: \" patch-density)]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
520
350
813
545
Distance vs Income (Satisfied People)
Distance from city center
Income
0.0
10.0
40000.0
60000.0
true
false
"" ""
PENS
"distanceincome" 1.0 0 -14454117 true "" ""

BUTTON
120
11
175
44
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
708
548
922
668
Income Distribution Plot
People
Income
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

BUTTON
578
574
702
607
Income per patch
  ask patches with [is-residental? = true and proximity-to-center > 0]\n  [\n    let satisfied-people people-here with [satisfied? = true]\n    if any? satisfied-people\n    [      \n      print(word\"distance \" proximity-to-center \" income per patch \" mean [income] of people-here)\n      ;;let avg-income mean [income] of satisfied-people\n      ;;print(word\"average income of satisfied per patch: \" avg-income \" distance: \" proximity-to-center)\n      ;;plotxy proximity-to-center avg-income\n    ]\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
963
111
1117
144
Show income per d from center
\n    ;; loop over rings 1 to [proximity-to-center] of patches(14)\n  let r 1\n  while [r <= 14]\n  [\n    ;; patches in this ring\n    let ring patches with [proximity-to-center = r]\n\n    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)\n    if any? ring [\n      let all-people-on-ring people-on ring\n      let people-on-ring all-people-on-ring with [satisfied? = true]\n      if any? people-on-ring\n      [\n        let avg-income mean [income] of people-on-ring\n        print (word \"distance: \" r word \" average income: \" avg-income)\n      ]\n      ;;print(word\"all on ring: \" count all-people-on-ring \" . Satisfied: \" count people-on-ring)\n    ]\n    set r r + 1;; incrementing for the next radius\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
610
551
690
576
INCOME
20
0.0
1

MONITOR
816
352
920
397
EIR mean
mean [person-EIR] of people
4
1
11

MONITOR
816
401
921
446
EIR min
min [person-EIR] of people with [satisfied? =  true]
4
1
11

MONITOR
815
450
921
495
EIR max
max [person-EIR] of people ;;with [satisfied? =  true]\n;;max [desired-EIR] of people with [satisfied? =  true]
4
1
11

MONITOR
815
499
921
544
EIR CV
(standard-deviation [person-EIR] of people with [satisfied? =  true]) / (mean [person-EIR] of people with [satisfied? =  true])
4
1
11

PLOT
957
352
1278
545
Distance vs EIR
Distance from city center
EIR
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"EIR-mean" 1.0 0 -14454117 true "" ""
"EIR-High Income" 1.0 0 -3844592 true "" ""
"EIR-Low Income" 1.0 0 -7500403 true "" ""

MONITOR
1283
352
1336
397
Er mean
mean [person-Er] of people
4
1
11

MONITOR
1284
401
1336
446
Er min
min [person-Er] of people with [satisfied? = true]
10
1
11

MONITOR
1284
450
1337
495
Er max
max [person-Er] of people
4
1
11

MONITOR
1284
499
1338
544
Er CV
(standard-deviation [person-Er] of people) / (mean [person-Er] of people)
4
1
11

MONITOR
1341
352
1413
397
Et mean
mean [patch-Et] of patches with [is-residental? =  true]
4
1
11

MONITOR
1341
400
1413
445
Et min
min [patch-Et] of patches with [is-residental? =  true]\n;;min [person-Et] of people with [satisfied? =  true]
4
1
11

MONITOR
1341
449
1414
494
Et max
max [patch-Et] of patches with [is-residental? =  true]\n;;max [person-Et] of people with [satisfied? =  true]
4
1
11

MONITOR
1342
498
1415
543
Et CV
(standard-deviation [patch-Et] of patches with [is-residental? =  true]) / (mean [patch-Et] of patches with [is-residental? =  true])\n;;(standard-deviation [person-Et] of people with [satisfied? =  true]) / (mean [person-Et] of people with [satisfied? =  true])
4
1
11

MONITOR
815
285
952
330
currently unsatisfied
count people with[satisfied? = false]
6
1
11

PLOT
961
148
1397
344
Distance vs Expenditure
Distance from city center
Expenditure
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Expenditure on rent" 1.0 0 -14454117 true "" ""
"Total expenditure" 1.0 0 -7500403 true "" ""
"Expenditure on travel" 1.0 0 -3844592 true "" ""

MONITOR
1399
148
1507
193
Expenditure mean
;;mean [person-Er] of people + mean [patch-Et] of patches with [is-residental? = true]\nmean [total-person-expenditure] of people with[satisfied? = true]
4
1
11

MONITOR
1400
197
1507
242
Expenditure min
;;min [person-Er] of people + min [patch-Et] of patches with [is-residental? = true]\nmin [total-person-expenditure] of people with[satisfied? = true]
4
1
11

MONITOR
1400
246
1507
291
Expenditure max
;;max [person-Er] of people + max [patch-Et] of patches with [is-residental? = true]\nmax [total-person-expenditure] of people with[satisfied? = true]
4
1
11

MONITOR
1402
296
1508
341
Expenditure CV
;;(standard-deviation [person-Er] of people + [patch-Et] of patches with [is-residental? = true]) / (mean [person-Er] of people + mean [patch-Et] of patches with [is-residental? = true])\n;;mean [person-Er] of people + mean [patch-Et] of patches with [is-residental? = true]\n;;(standard-deviation (sentence [person-Er] of people [patch-Et] of patches with [is-residental?])) / mean (sentence [person-Er] of people [patch-Et] of patches with [is-residental?])\n\n(standard-deviation [total-person-expenditure] of people with[satisfied? = true]) / (mean [total-person-expenditure] of people with[satisfied? = true])
4
1
11

TEXTBOX
964
10
1499
96
Note! In this implementation I REMOVED manual adjustment of min Er to 2000. The adjustment was in creating people, which doesnt matter much and 2 places: \n1) evaluate-person EIR 2) evaluate-EIR-and-find-home\nEr-min can be 0 as in the begining of simulation many patches have density 0 and agents move there as EIR allows, but  person-Er = 0 doesnt update after settling.
14
94.0
1

BUTTON
1
120
78
153
color EIR-wise
color-eirwise
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
82
120
175
153
color income-wise
color-incomewise
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1
84
173
117
default color patch-densitywise
update-patch-color-based-on-density
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
160
618
450
651
ask patches who distance and av density per ring
show mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 1]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 2]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 3]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 4]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 5]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 6]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 7]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 8]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 9]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 10]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 11]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 12]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 13]\nshow mean [patch-density] of patches with[is-residental? = true and proximity-to-center = 14]\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
816
10
956
55
mean-EIR of low incomes
;;mean [person-EIR] of people with [income < mean-income]\nmean [person-EIR] of people with [income < mean [income] of people]
4
1
11

MONITOR
815
56
955
101
mean-EIR of high incomes
;;mean [person-EIR] of people with [income > mean-income]\nmean [person-EIR] of people with [income > mean [income] of people]
4
1
11

BUTTON
814
214
952
247
print mean EIR of low
let low-mean-EIR mean [person-EIR] of people with [income < mean [income] of people]\nprint low-mean-EIR\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
814
249
952
282
print mean EIR of high
let high-mean-EIR mean [person-EIR] of people with [income > mean [income] of people]\nprint high-mean-EIR
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
814
177
954
210
ask people print income
ask people [print income]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
816
103
956
148
mean income
mean [income] of people
4
1
11

BUTTON
1181
112
1283
145
percent public users
  print(word\"Distance PercentPublic\" )\n  ;; loop over rings 1 to [proximity-to-center] of patches(14)\n  let r 1\n  while [r <= 14]\n  [\n    ;; patches in this ring\n    let ring patches with [proximity-to-center = r]\n\n    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)\n    if any? ring [\n      let all-people-on-ring people-on ring\n      let people-on-ring all-people-on-ring with [satisfied? = true]\n      let public-people-on-ring people-on-ring with [transport-cost = 1000]\n      if any? public-people-on-ring\n      [\n        let percent ((count public-people-on-ring) / (count people with [transport-cost = 1000]) * 100)\n        ;;print (word \"distance: \" r word \" . Percent public: \" percent)\n        print (word \"\" r word \" \" percent)\n      ]\n      ;;print(word\"all on ring: \" count all-people-on-ring \" . Satisfied: \" count people-on-ring)\n    ]\n    set r r + 1;; incrementing for the next radius\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1288
112
1394
145
percent private users
  print(word\"Distance PercentPrivate\" )\n  ;; loop over rings 1 to [proximity-to-center] of patches(14)\n  let r 1\n  while [r <= 14]\n  [\n    ;; patches in this ring\n    let ring patches with [proximity-to-center = r]\n\n    ;; if any patches in the ring set, plot their mean density (density of patches with the same proximity to cente)\n    if any? ring [\n      let all-people-on-ring people-on ring\n      let people-on-ring all-people-on-ring with [satisfied? = true]\n      let public-people-on-ring people-on-ring with [transport-cost = 700]\n      if any? public-people-on-ring\n      [\n        let percent ((count public-people-on-ring) / (count people with [transport-cost = 700]) * 100)\n        ;;print (word \"distance: \" r word \" . Percent public: \" percent)\n        print (word \"\" r word \" \" percent)\n      ]\n      ;;print(word\"all on ring: \" count all-people-on-ring \" . Satisfied: \" count people-on-ring)\n    ]\n    set r r + 1;; incrementing for the next radius\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1417
351
1509
396
person-Et mean
mean [person-Et] of people
4
1
11

MONITOR
1416
401
1509
446
person-Et min
min [person-Et] of people
17
1
11

MONITOR
1417
449
1509
494
person-Et max
max [person-Et] of people
4
1
11

MONITOR
1419
497
1507
542
person-Et CV
(standard-deviation [person-Et] of people) / (mean [person-Et] of people)
4
1
11

BUTTON
960
551
1152
584
show patch count per distance
show count patches with [proximity-to-center = 1 and is-residental? = true]\nshow count patches with [proximity-to-center = 2 and is-residental? = true]\nshow count patches with [proximity-to-center = 3 and is-residental? = true]\nshow count patches with [proximity-to-center = 4 and is-residental? = true]\nshow count patches with [proximity-to-center = 5 and is-residental? = true]\nshow count patches with [proximity-to-center = 6 and is-residental? = true]\nshow count patches with [proximity-to-center = 7 and is-residental? = true]\nshow count patches with [proximity-to-center = 8 and is-residental? = true]\nshow count patches with [proximity-to-center = 9 and is-residental? = true]\nshow count patches with [proximity-to-center = 10 and is-residental? = true]\nshow count patches with [proximity-to-center = 11 and is-residental? = true]\nshow count patches with [proximity-to-center = 12 and is-residental? = true]\nshow count patches with [proximity-to-center = 13 and is-residental? = true]\nshow count patches with [proximity-to-center = 14 and is-residental? = true]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1285
549
1382
594
patch-Er mean
mean [patch-Er] of patches with [is-residental? = true]
4
1
11

BUTTON
1408
111
1542
144
num people on ring
show count people-on patches with [proximity-to-center = 1]\nshow count people-on patches with [proximity-to-center = 2]\nshow count people-on patches with [proximity-to-center = 3]\nshow count people-on patches with [proximity-to-center = 4]\nshow count people-on patches with [proximity-to-center = 5]\nshow count people-on patches with [proximity-to-center = 6]\nshow count people-on patches with [proximity-to-center = 7]\nshow count people-on patches with [proximity-to-center = 8]\nshow count people-on patches with [proximity-to-center = 9]\nshow count people-on patches with [proximity-to-center = 10]\nshow count people-on patches with [proximity-to-center = 11]\nshow count people-on patches with [proximity-to-center = 12]\nshow count people-on patches with [proximity-to-center = 13]\nshow count people-on patches with [proximity-to-center = 14]\n\n\n\n\n\n\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
