globals
[
  valid_patch   ; Valid Patches for moving not wall)
  Start         ; Starting patch
  Cost          ; The cost of the path given by A*
]

patches-own
[
  father     ; Previous patch in this partial path
  Cost-path  ; Stores the cost of the path to the current patch
  visited?
  active?
]


to setup
  ca
  ; Initial values of patches for A*
  ask patches
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]
  ; Obstacles
  ask n-of obstacles patches
  [
    set pcolor red
    ask patches in-radius random radius-obstacles [set pcolor red]
  ]
  ; Se the valid patches (not wall)
  set valid_patch patches with [pcolor != red]
  ; Create a random start
  set Start one-of valid_patch
  ask Start [
    set pcolor white

  ]
  ; Create a turtle to draw the path (when found)
  crt 1
  [
    set size 1.5
    set pen-size 1.5
    set shape "square"
  ]
end

; Patch report to estimate the total expected cost of the path starting from
; in Start, passing through it, and reaching the #Goal
to-report Total-expected-cost [#Goal]
  report Cost-path + Heuristic #Goal
end

; Patch report to reurtn the heuristic (expected length) from the current patch
; to the #Goal
to-report Heuristic [#Goal]
  report distance #Goal
end


to-report A* [#Start #Goal #valid-map]
  ; clear all the information in the agents
  ask #valid-map with [visited?]
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]

  ask #Start
  [
    set father self
    set visited? true
    set active? true
  ]

  let exists? true

  while [not [visited?] of #Goal and exists?]
  [

    let options #valid-map with [active?]

    ifelse any? options
    [

      ask min-one-of options [Total-expected-cost #Goal]
      [

        let Cost-path-father Cost-path

        set active? false

        let valid-neighbors neighbors with [member? self #valid-map]
        ask valid-neighbors
        [

          let t ifelse-value visited? [ Total-expected-cost #Goal] [2 ^ 20]

          if t > (Cost-path-father + distance myself + Heuristic #Goal)
          [

            set father myself
            set visited? true
            set active? true
            set Cost-path Cost-path-father + distance father
            set cost precision Cost-path 3
          ]
        ]
      ]
    ]

    [
      set exists? false
    ]
  ]

  ifelse exists?
  [

    let current #Goal
    set cost (precision [Cost-path] of #Goal 3)
    let rep (list current)
    While [current != #Start]
    [
      set current [father] of current
      set rep fput current rep
    ]
    report rep
  ]
  [
    report false
  ]
end


to Look-for-Goal
  ; Take one random Goal
  let Goal one-of valid_patch
  ; Compute the path between Start and Goal
  let path  A* Start Goal valid_patch
  ; If any...
  if path != false [
    ; Take a random color to the drawer turtle
    ask turtle 0 [set color (lput 150 (n-values 3 [100 + random 155]))]
    ; Move the turtle on the path stamping its shape in every patch
    foreach path [ ?1 ->
      ask turtle 0 [
        move-to ?1
        stamp] ]
    ; Set the Goal and the new Start point
    set Start Goal
  ]
end

; Auxiliary procedure to clear the paths in the world
to clean
  cd
  ask patches with [pcolor != black and pcolor != brown] [set pcolor black]
  ask Start [set pcolor white]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
622
423
-1
-1
4.0
1
10
1
1
1
0
0
0
1
0
100
0
100
0
0
1
ticks
30.0

BUTTON
15
10
105
43
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
110
10
195
43
Next
Look-for-Goal
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
15
45
195
78
Clean Paths
clean
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
85
195
118
obstacles
obstacles
0
100
61.0
1
1
NIL
HORIZONTAL

SLIDER
15
120
195
153
radius-obstacles
radius-obstacles
0
30
6.0
1
1
NIL
HORIZONTAL

MONITOR
15
170
92
215
Cost-path
Cost
17
1
11

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

square
true
0
Rectangle -7500403 true true 0 0 300 300
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="15" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>Look-for-Goal</go>
    <timeLimit steps="1"/>
    <metric>p-valids</metric>
    <metric>Start</metric>
    <metric>Final-Cost</metric>
  </experiment>
</experiments>
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
1
@#$#@#$#@
