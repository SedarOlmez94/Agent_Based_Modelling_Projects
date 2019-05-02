;Code by Leo Sucharyna Thomas. For the Masters Dissertation at Leeds University, 2017.


extensions [ gis ]

globals[

  resistance-dataset ; contains the movement speed values for each patch

    ncols_position
    nrows_position
    xllcorner_position
    yllcorner_position
    cellsize_position
    NODATA_value_position
    header_items
    memory
    unvisited
    visited
]

patches-own [resistance]

breed [migrants migrant]
      migrants-own
      [destination secondary]

to setup
clear-all reset-ticks
; Initialises the GIS made resistance surface as the background.
set resistance-dataset gis:load-dataset "resistance_surface.asc"

print "Dataset Loaded"
  display-resistance-in-patches
print "Dataset Displayed"
  setup-migrants
print "Migrants Ready"

end

; Adapted from 'GIS general examples' internal model
to display-resistance
  gis:paint resistance-dataset 0

end

to display-resistance-in-patches
  ; This is the preferred way of copying values from a raster dataset
  ; into a patch variable in one step, using gis:apply-raster.
  gis:apply-raster resistance-dataset resistance
  ; Now, just to make sure it worked, we'll color each patch by its resistance value.
  ; set min as 0, otherwise will gradiate from the 'NoData value of '-9999'.
  let min-resistance = resistance 0
  ;let max-resistance = resistance 5
  let max-resistance gis:maximum-of resistance-dataset
  ask patches
  [ ; note the use of the "<= 0 or >= 0" technique to filter out
    ; "not a number" values, as discussed in the documentation.
    if (resistance = 0) or (resistance >= 0)
    [ set pcolor scale-color red resistance min-resistance max-resistance ] ]
print "start"
    resize-world 0 234 0 264 ;; this seems to help NetLogo/JVM to better manage space/memory when transitiong to/from large worlds
                 ;; set-patch-size 10.0 ;; this seems to help NetLogo not confuse pixel-to-patch sizing when swithcing maps/world settings
    ; resize-world 0 (item ncols_position header_items - 1) 0 (item nrows_position header_items - 1)
print "finish"
end

; This is a second way of copying values from a raster dataset into
; patches, by asking for a rectangular sample of the raster at each
; patch. This is somewhat slower, but it does produce smoother
; subsampling, which is desirable for some types of data.
to sample-resistance-with-patches
  let min-resistance gis:minimum-of resistance-dataset
  let max-resistance gis:maximum-of resistance-dataset
  ask patches
  [ set resistance gis:raster-sample resistance-dataset self
    if (resistance <= 0) or (resistance >= 0)
    [ set pcolor scale-color red resistance min-resistance max-resistance ] ]
end
; Stopped using the general example..

to setup-migrants
  ;This sets the shape and colour of each agent.
   create-migrants number-of-migrants [
    set shape "person"
    set color blue

; This block allows the user to select the origin point of the agent from the interface.
 ifelse (starting-position = "1. (203)(34)")
 [ setxy (203)(34) ]
   [ifelse (starting-position = "2. (192)(48)")
   [ setxy (192)(48) ]
     [ifelse (starting-position = "3. (186)(27)")
     [ setxy (186)(27) ]
       [ifelse (starting-position = "4. (174)(21)")
       [ setxy (174)(21) ]
         [ifelse (starting-position = "5. (161)(12)")
         [ setxy (161)(12) ]
           [ifelse (starting-position = "6. (144)(7)")
           [ setxy (144)(7) ]
             [ifelse (starting-position = "7. (154)(0)")
             [ setxy (154)(0) ]
               [print "error in choice of map to load!"]
             ]
           ]
         ]
       ]
     ]
   ]

   set memory (list patch-here)
   set visited (list patch-here)
]
  ask migrants

[set destination max-one-of neighbors [resistance] print destination]

print "Destination Set"
end


to move
 set pen-mode "down" ; Enables the pathfinding to be tracked.

; Changes the D8 to move with the agent and remove the option of moving to patches already visited.
  set unvisited neighbors with [not member? self [memory] of myself]
  set destination one-of unvisited with-max [resistance] ; Sets destination as the max value patch that hasn't been visited.

ask migrants

  [ifelse destination = NOBODY ; Refers to the situation when the agent is surrounded by visited or inaccessible patches.
   [move-to one-of neighbors with [member? self [memory] of myself]]
  [ifelse member? destination neighbors ; If a destination is available it will be taken.
    [move-to destination]

  [user-message "Help!"]
 ]
]

set memory lput patch-here memory ; Adds the patch that was moved to to the agent memory.
end

to go
ask migrants
  [move]
tick
end

to patches-white
  ask patches
  [set  pcolor white]
end

to export
  export-world "movement.csv"
end
@#$#@#$#@
GRAPHICS-WINDOW
161
10
876
836
-1
-1
3.0
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
234
0
264
0
0
1
ticks
30.0

SLIDER
-2
122
161
155
number-of-migrants
number-of-migrants
1
10
1
1
1
NIL
HORIZONTAL

BUTTON
0
10
161
43
Initialise resistance surface
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
0
43
162
76
Run 2 week exploration
if (ticks < 9800) [go]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
0
77
105
122
Movement iterations
ticks
0
1
11

BUTTON
106
77
161
122
Whiteout
patches-white
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
-1
155
161
200
starting-position
starting-position
"1. (203)(34)" "2. (192)(48)" "3. (186)(27)" "4. (174)(21)" "5. (161)(12)" "6. (144)(7)" "7. (154)(0)"
0

@#$#@#$#@
## WHAT IS IT?

This model imports a GIS-built resistance surface and provides an agent with a least-cost movement behaviour. This will simulate the Mesolithic exploration of an area of Orkney, by attempting to understand the pathways forged through the landscape.

## HOW IT WORKS

The model works having the agent identify the patch in their D8 vision with the highest potential movement speed available. If the maximum speed patch has already been visited, then the agent will move to the next highest. In the event of the agent becoming surrounded by visited patches, the agent will move randomly through them in an attempt to find an unvisited patch to continue the exploration phase.

## HOW TO USE IT

This model is simple to use as it is a proof-of-concept tool.

Firstly, select the prefered starting point.
Secondly, select the number of migrants wanted for the simulation.
Thirly, begin the simulation by clicking the initialise button. This will launch a two week exploration from the entry point selected and stop the agent moving when the 9800 iterations that represents the two weeks, concludes.
Finally, you may export the final map with the resistance surface, or use the whiteout button to export only the forged path of the explorers.

## THINGS TO NOTICE

Note should be taken of frequently utilised areas, as they could be used to target investigative fieldwork aiming to identify Mesolithic archaeological remains.

It must also be understood, that the simple movement dynamic and limiting nature of the study area, can lead to the agent getting stuck and producing misleading results.

## THINGS TO TRY

Altering the starting position of the Mesolithic migrants can lead to a more complex understanding of the emergent pathways.

## EXTENDING THE MODEL

This model can be furthered by including a greater level of detail to the memory, which would allow for the agent to move towards a remembered area to further the path when stuck rather than using the unfavourable random-walk principle.

## CREDITS AND REFERENCES

Thanks are given to Andy Turner for the assistance in model creation and to Eric Russell, who developed the NetLogo GIS Extensions.
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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-migrants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export</final>
    <timeLimit steps="5000"/>
    <enumeratedValueSet variable="number-of-migrants">
      <value value="1"/>
    </enumeratedValueSet>
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
0
@#$#@#$#@
