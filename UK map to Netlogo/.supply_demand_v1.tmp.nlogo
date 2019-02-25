; GIS tutorial: https://simulatingcomplexity.wordpress.com/2014/08/20/turtles-in-space-integrating-gis-and-netlogo/
; GIS dataset: https://gadm.org/index.html
extensions [ gis ]

breed[searchers searcher] ; to represent the agents that will make the search.
breed[resources resource] ; to represent the resources sent over the links.

globals [
  map-view             ;; GIS dataset/map
  centroid-points      ;; the GIS dataset of geometric center points
  center-x             ;;
  center-y             ;; center of the map
  mean-motion-time     ;; average time turtles stay in motion
  mean-speed           ;; turtles'speed indicator
  number-of-resources
  ID
 ]

patches-own[
  turtles-num       ;; number of turtles on the patch
  destination-name  ;; name of each city/borough
  geocode           ;; the geocode (uniquevalue) for each city/borough
  geolabelw         ;; this is also a unique value, I don't know what though.
  label?            ;; a unique string  for each city/borough
  longitude
  latitude
  centroid-value
  centroid-patch-identity
  resource?
]

turtles-own[
  height_asl
]

searchers-own [
  memory               ; Stores the path from the start node to here
  cost                 ; Stores the real cost from the start
  total-cost           ; Stores the total exepcted cost from Start to the Goal that is being computed
  localisation         ; The node where the searcher is
  active?              ; is the seacrher active? That is, we have reached the node, but
                       ; we must consider it because its neighbors have not been explored
]

resources-own [
  time

]

to setup
  ca
  ask patches [
    set pcolor white
  ]
  setup-map
  draw
  reset-ticks
end

to go

  tick
end

; Adding a dataset from GIS must be a shape file.
to setup-map
  set map-view gis:load-dataset "data/United_Kingdom/infuse_dist_lyr_2011.shp"
  set centroid-points gis:load-dataset "data/United_Kingdom/Export_Output_2.shp"
  ;gis:load-coordinate-system "data/United_Kingdom/infuse_dist_lyr_2011.prj"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of map-view)
                                                (gis:envelope-of centroid-points))
  gis:set-drawing-color black
  gis:draw map-view 1
end

to draw
  clear-drawing
  setup-world-envelope
  gis:set-drawing-color gray + 1  gis:draw map-view 1
  draw-centroids
  draw-turtles
  create_resources
  draw-links
end

to path-draw
  ask links with [color = yellow][set color grey set thickness 0]
  let start one-of turtles
  ;ask start [set color green set size 1]
  let goal one-of turtles with [distance start > max-pxcor]
  ;ask goal [set color green set size 1]
  ; We compute the path with A*
  let path (A* start goal)
  ; if any, we highlight it
  if path != false [highlight-path path]
  ;output
end

to-report heuristic [#Goal]
  report [distance [localisation] of myself] of #Goal
end

to setup-world-envelope
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of map-view)
                                         (gis:envelope-of centroid-points))
  let world gis:world-envelope
  let x0 (item 0 world + item 1 world) / 2  + center-x; center
  let y0 (item 2 world + item 3 world) / 2  + center-y
  let W0 zoom * (item 1 world - item 0 world) / 2 ; half-widths
  let H0 zoom * (item 3 world - item 2 world) / 2
  set world (list (x0 - W0) (x0 + W0) (y0 - H0) (y0 + H0))
  gis:set-world-envelope world
end

to zoom-in  set zoom max list .01 precision (zoom - .1) 2
  draw
end

to zoom-out set zoom min list 1.2 precision (zoom + .1) 2
  draw
end

to zoom-std
  set zoom 0.05
  draw
end

to-report gis-patch-size ;; note: assume width & height same
  let world gis:world-envelope
  report (item 1 world - item 0 world) / (max-pxcor - min-pxcor)
end

to move-right
  set center-x center-x + shift * gis-patch-size
  draw
end

to move-left
  set center-x center-x - shift * gis-patch-size
  draw
end

to move-up
  set center-y center-y + shift * gis-patch-size
  draw
end

to move-down
  set center-y center-y - shift * gis-patch-size
  draw
end

; This method maps the GIS vector data to the patch attributes, we also use centroids to
; focus only on the data within the outlines of the boundary map and not the sea.
to gis-to-map
  foreach gis:feature-list-of map-view [vector-feature ->
    let centroid gis:location-of gis:centroid-of vector-feature
    ask patches gis:intersecting vector-feature [
       set destination-name gis:property-value vector-feature "NAME"
       set geocode gis:property-value vector-feature "GEO_CODE"
       set geolabelw gis:property-value vector-feature "GEO_LABELW"
       set label? gis:property-value vector-feature "LABEL"
       set longitude gis:property-value vector-feature "LONGITUDE"
       set latitude gis:property-value vector-feature "LATITUDE"
       set centroid-value centroid
    ]
  ]
end

to draw-centroids
  foreach gis:feature-list-of centroid-points [ vector-feature ->
    gis:set-drawing-color red
    gis:fill vector-feature 2.0
    ask patches gis:intersecting vector-feature [
      set centroid-patch-identity 1
    ]
    ask n-of random-resources-generator patches gis:intersecting vector-feature [
        set resource? "yes"
    ]
  ]
end

to draw-turtles
  clear-turtles
  ask patches with [centroid-patch-identity > 0][
    sprout 1
  ]
  ask patches [
    set centroid-patch-identity 0
  ]
  ask turtles [
    set size .4
    set shape "person police"
  ]
end


to create_resources
  ask patches with [resource? = "yes"][
    sprout-resources 1[
      ;set time
      set shape "truck"
      set size .8
      set color 15
    ]
  ]
end

to draw-links
    ask turtles [
    create-links-with other turtles in-radius radius
  ]
end

to print-dataset
  print (word "MAP: " gis:feature-list-of map-view)
  print (word "CENTROID: " gis:feature-list-of centroid-points)
end

to print-labels
  print (word "MAP: " gis:property-names map-view)
  print (word "CENTROID: " gis:property-names centroid-points)
end

to-report number_of_resources_produced
  set number-of-resources (10 + random 1000)
  report number-of-resources
end

to-report A* [#Start #Goal]
  ; Create a searcher for the Start node
  ask #Start
  [
    hatch-searchers 1
    [
      node-description
      set memory (list localisation) ; the partial path will have only this node at the beginning
      set cost 0
      set total-cost cost + heuristic #Goal ; Compute the expected cost
     ]
  ]

  while [not any? searchers with [localisation = #Goal] and any? searchers with [active?]]
  [
    ask min-one-of (searchers with [active?]) [total-cost]
    [
      set active? false
      let this-searcher self
      let Lorig localisation
      ask ([link-neighbors] of Lorig)
      [
        let connection link-with Lorig
        ; The cost to reach the neighbor in this path is the previous cost plus the lenght of the link
        let c ([cost] of this-searcher) + [link-length] of connection
        ; Maybe in this node there are other searchers (comming from other nodes).
        ; If this new path is better than the other, then we put a new searcher and remove the old ones
        if not any? searchers-in-loc with [cost < c]
        [
          hatch-searchers 1
          [
            node-description
            set total-cost cost + heuristic #Goal ; Compute the expected cost
            set memory lput localisation ([memory] of this-searcher) ; the path is built from the
                                                                     ; original searcher
            set cost c   ; real cost to reach this node
            ask other searchers-in-loc [die] ; Remove other seacrhers in this node
          ]
        ]
      ]
    ]
  ]
  ; When the loop has finished, we have two options: no path, or a searcher has reached the goal
  ; By default the return will be false (no path)
  let res false
  ; But if it is the second option
  if any? searchers with [localisation = #Goal]
  [
    ; we will return the path located in the memory of the searcher that reached the goal
    let lucky-searcher one-of searchers with [localisation = #Goal]
    set res [memory] of lucky-searcher
  ]
  ; Remove the searchers
  ask searchers [die]
  ; and report the result
  report res
end

to-report searchers-in-loc
  report searchers with [localisation = myself]
end

to node-description
      set shape "circle"
      set color red
      set localisation myself
      set active? true ; It is active, because we didn't calculate its neighbors yet
end

to highlight-path [path]
  let a reduce highlight path
end

to-report highlight [x y]
  ask x
  [
    ask link-with y [set color yellow set thickness .4]
  ]
  report y
end
@#$#@#$#@
GRAPHICS-WINDOW
32
10
629
608
-1
-1
19.0
1
10
1
1
1
0
0
0
1
-15
15
-15
15
0
0
1
ticks
30.0

BUTTON
271
616
334
649
setup
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
352
616
415
649
go
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

BUTTON
647
35
732
68
zoom-in
zoom-in
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
738
35
832
68
zoom-out
zoom-out
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
740
73
832
106
zoom
zoom
.01
1.2
0.37
.01
1
NIL
HORIZONTAL

BUTTON
648
73
732
106
zoom-std
zoom-std
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
753
393
840
426
NIL
draw
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
686
253
792
286
shift
shift
0
30
6.0
1
1
NIL
HORIZONTAL

BUTTON
737
178
839
211
move-right
move-right
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
640
178
732
211
move-left
move-left
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
694
141
782
174
move-up
move-up
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
685
215
790
248
move-down
move-down
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
652
393
748
426
load patch data
gis-to-map
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
650
320
731
353
print dataset
print-dataset
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
735
320
816
353
print labels
print-labels
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
697
17
813
35
ZOOM CONTROLS
11
0.0
1

TEXTBOX
711
119
773
137
CONTROLS
11
0.0
1

TEXTBOX
680
296
819
314
DATASET INFORMATION
11
0.0
1

TEXTBOX
695
367
793
385
MAP CONTROLS
11
0.0
1

TEXTBOX
653
435
803
487
1) click <load patch data> to merge the dataset (polygon average) = centroid with the patch variables
10
0.0
1

SLIDER
656
529
828
562
radius
radius
0.0
10.0
2.4
0.1
1
NIL
HORIZONTAL

BUTTON
688
583
784
616
NIL
path-draw
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
690
622
784
667
Resources #
number-of-resources
17
1
11

SLIDER
578
688
817
721
random-resources-generator
random-resources-generator
0
961
215.0
1
1
NIL
HORIZONTAL

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

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

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
NetLogo 6.0.4
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
