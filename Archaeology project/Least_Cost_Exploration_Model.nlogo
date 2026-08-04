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

