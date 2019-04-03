; GIS tutorial: https://simulatingcomplexity.wordpress.com/2014/08/20/turtles-in-space-integrating-gis-and-netlogo/
; GIS dataset: https://gadm.org/index.html
extensions [ gis view2.5d table]


breed[searchers searcher] ; to represent the agents that will make the search.
breed[resources resource] ; to represent the resources sent over the links.
breed [forces force]      ;one agent per police force, stores resourcing information for that police service.
breed [crimes crime]

globals [
  map-view             ;; GIS dataset/map
  centroid-points      ;; the GIS dataset of geometric center points
  police-force-view    ;; the dataset of the police force area for England and Wales.
  center-x             ;;
  center-y             ;; center of the map
  number-of-resources
  crime_units_required_view
  crime-units-required-view-2
  resource-to-subtract-total-view
  resource-to-subtract-total-view-1
  crime_value_ID
 ]

patches-own[
  destination-name          ;; name of each city/borough
  geocode                   ;; the geocode (uniquevalue) for each city/borough
  geolabelw                 ;; this is also a unique value, I don't know what though.
  label?                    ;; a unique string  for each city/borough
  longitude                 ;; the longitude of the UK map corresponding to patch.
  latitude                  ;; the latitude of the UK map corresponding to patch.
  force-longitude           ;; the longitude of the police force.
  force-latitude            ;; the latitude of the police force.
  police-force-name-patch   ;; the name of the police force
  patchworkm                ;; I don't know but it is a floating point value.
  centroid-value            ;; the longitude and latitudee of the centroid
  centroid-patch-identity   ;; we set this temp variable to 1 for all patches that have a centroid, then we draw the centroid then set it back to 0.
  resource?                 ;; does this patch have a resource on it? yes if it has a centroid or no.
  crime?                    ;; does this patch have a crime on it? yes if it has a centroid or no.
  forces?                   ;; does this patch have a force on it? yes if it has a centroid or no.
]


; the forces are like buildings with a number of resources that they can dispatch, and as they leave
; the forces
forces-own[
  police-force-ID                    ; ID of the police force.
  resource-total                     ;total number of resources in police force.
  resourceA-percentage               ;percentage of resources with type A
  resourceB-percentage               ;percentage of resources with type B
  resourceA-total                    ;total number of type A resource
  resourceB-total                    ;total number of type B resource
  resourceA-percentage-public-order  ;percentage of type A resource public order trained
  resourceB-percentage-public-order  ;percentage of type B resource public order trained
  resourceA-public-order-total       ;total number of type A resource public order trained.
  resourceB-public-order-total       ;total number of type B resource public order trained.
  public-order-total                 ;total amount of public order across all types.
  time-to-mobilise                   ;the delay before a resource can be mobilised for force.
  force-name

]

crimes-own [
  units_required                ;; the number of units requied to stop the crime.
  minimise_impact               ;; minimising the impact on a specific resource i.e. A or B
  resources_requirement_cycles  ;; the number of cycles in which the resources must be received.
  crime_number                  ;; the crime identifier, each crime has a unique number.
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
  location
]

to setup
  ca
  ask patches [
    set pcolor white
  ]
  setup-map
  move-down
  gis-to-map
  draw
  ;crime-resource-planner
  reset-ticks
end

to go
  ;move-resources
  crime-resource-planner
  tick
end

; Adding a dataset from GIS must be a shape file.
to setup-map
  set map-view gis:load-dataset "data/United_Kingdom/infuse_dist_lyr_2011.shp"
  set centroid-points gis:load-dataset "data/United_Kingdom/Export_Output_4.shp"
  ;set police-force-view gis:load-dataset "data/United_Kingdom/Export_Output_2.shp"
  ;set police-force-area gis:load-dataset "data/police_force_areas/Police_Force_Areas_December_2016_Full_Clipped_Boundaries_in_England_and_Wales.shp"

  ;gis:load-coordinate-system "data/United_Kingdom/infuse_dist_lyr_2011.prj"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of map-view)
                                                (gis:envelope-of centroid-points))
                                                ;(gis:envelope-of police-force-view))
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
  create_forces
  assign-resources-calibrated
  draw-links
  spawn-crime
end

to path-draw
  ask links with [color = yellow][set color grey set thickness 0]
  let start one-of resources
  ;ask start [set color green set size 1]
  let goal one-of crimes
  ;ask goal [set color green set size 1]
  ; We compute the path with A*
  let path (A* start goal)
  ; if any, we highlight it
  if path != false [highlight-path path]
  ;output
end

to setup-forces
  ;; Populate the table with random data, then we fill it with data from assign-resources-calibrated function.
  ask forces[
    set force-name [destination-name] of patch-here
    set resource-total (random 20 + 1) * 100
    set resourceA-percentage random-float 1
    set resourceB-percentage 1 - resourceA-percentage
    set resourceA-total (resource-total * resourceA-percentage)
    set resourceB-total (resource-total * resourceB-percentage)
    set resourceA-percentage-public-order random-float 0.1
    set resourceB-percentage-public-order random-float 0.1
    set resourceA-public-order-total floor (resourceA-total * resourceA-percentage-public-order)
    set resourceB-public-order-total floor (resourceB-total * resourceB-percentage-public-order)
    set public-order-total (resourceA-public-order-total + resourceB-public-order-total)
    set time-to-mobilise random 11
    set police-force-ID (police-force-ID + 1)
  ]
end

; Testing a method of combining dictionary with table
;to create-table
;;  let testlist []
;;  set testlist fput "1" testlist
;;  set testlist fput "3" testlist
;;  set testlist fput "7" testlist
;;  let dict table:make
;;  table:put dict "turtle" testlist
;;  print dict
;;  print table:get dict "turtle"
;;  print item 0 table:get dict "turtle"
;end

to assign-resources-calibrated
  let dict table:make
  let temp-list []
  ;; Information for https://en.wikipedia.org/wiki/List_of_police_forces_of_the_United_Kingdom
  ask forces[
    if force-name = "St Albans"[
      set resource-total 1953
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1953 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "St Albans" temp-list
    ]
    if force-name = "Rushcliffe"[
      set temp-list []
      set resource-total 2095
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2095 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Rushcliffe" temp-list
    ]
    if force-name = "Oldham"[
      set temp-list []
      set resource-total 6979
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 6979 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Oldham" temp-list
    ]
    if force-name = "Wiltshire"[
      set temp-list []
      set resource-total 966
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 966 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Wiltshire" temp-list
    ]
    if force-name = "Braintree"[
      set temp-list []
      set resource-total 2902
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2902 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Braintree" temp-list
    ]
    if force-name = "South Hams"[
      ;Devon and Cornwall Police
      set temp-list []
      set resource-total 3082
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 3082 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "South Hams" temp-list
    ]
    if force-name = "Solihull"[
      ;Westmidlands
      set temp-list []
      set resource-total 6656
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 6656 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Solihull" temp-list
    ]
    if force-name = "Maidstone"[
      ;Kent
      set temp-list []
      set resource-total 3333
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 3333 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Maidstone" temp-list
    ]
    if force-name = "Ceredigion"[
      set temp-list []
      set resource-total 1159
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1159 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Ceredigion" temp-list
    ]
    if force-name = "Stockton-on-Tees"[
      set temp-list []
      set resource-total 1274
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1274 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Stockton-on-Tees" temp-list
    ]
    if force-name = "Malvern Hills"[
      ;West Mercia
      set temp-list []
      set resource-total 2367
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2367 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Malvern Hills" temp-list
    ]
    if force-name = "Preston"[
      ;Lancashire
      set temp-list []
      set resource-total 2910
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2910 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Preston" temp-list
    ]
    if force-name = "Hambleton"[
      ;North yorkshire police
      set temp-list []
      set resource-total 1370
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1370 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Hambleton" temp-list
    ]
    if force-name = "Surrey Heath"[
      ; Surrey
      set temp-list []
      set resource-total 2009
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2009 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Surrey Heath" temp-list
    ]
    if force-name = "Eastleigh"[
      ;Hampshire
      set temp-list []
      set resource-total 2861
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2861 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Eastleigh" temp-list
    ]
    if force-name = "Leeds"[
      ; West yorkshire
      set temp-list []
      set resource-total 4826
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 4826 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Leeds" temp-list
    ]
    if force-name = "Wirral"[
      ; Merseyside
      set temp-list []
      set resource-total 3484
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 3484 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Wirral" temp-list
    ]
    if force-name = "Eden"[
      ; Cumbria
      set temp-list []
      set resource-total 1108
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1108 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Eden" temp-list
    ]
    if force-name = "Croydon"[
      ; Metropolitan police
      set temp-list []
      set resource-total 30871
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 30871 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Croydon" temp-list
    ]
    if force-name = "Oadby and Wigston"[
      ; Leicestershire
      set temp-list []
      set resource-total 1772
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1772 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Oadby and Wigston" temp-list
    ]
    if force-name = "Northumberland"[
      set temp-list []
      set resource-total 3245
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 3245 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Northumberland" temp-list
    ]
    if force-name = "Amber Valley"[
      ; Derbyshire
      set temp-list []
      set resource-total 1740
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1740 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Amber Valley" temp-list
    ]
    if force-name = "Neath Port Talbot"[
      set temp-list []
      set resource-total 2890
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2890 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Neath Port Talbot" temp-list
    ]
    if force-name = "Denbighshire"[
      ; North wales
      set temp-list []
      set resource-total 1487
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1487 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Denbighshire" temp-list
    ]
    if force-name = "Sheffield"[
      ; south yorkshire
      set temp-list []
      set resource-total 2472
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2472 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Sheffield" temp-list
    ]
    if force-name = "East Dorset"[
      ; Dorset
      set temp-list []
      set resource-total 1276
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1276 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "East Dorset" temp-list
    ]
    if force-name = "Bath and North East Somerset"[
      ; Avon and Somerset Constabulary
      set temp-list []
      set resource-total 2630
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2630 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Bath and North East Somerset" temp-list
    ]
    if force-name = "Lichfield"[
      ; Staffordshire
      set temp-list []
      set resource-total 1595
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1595 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Lichfield" temp-list
    ]
    if force-name = "Oxford"[
      ; Thames Valley Police
      set temp-list []
      set resource-total 4077
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 4077 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Oxford" temp-list
    ]
    if force-name = "Forest of Dean"[
      ;Gloucestershire Constabulary
      set temp-list []
      set resource-total 1055
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1055 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Forest of Dean" temp-list
    ]
    if force-name = "East Cambridgeshire"[
      ; Cambridgeshire Constabulary
      set temp-list []
      set resource-total 1332
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1332 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "East Cambridgeshire" temp-list
    ]
    if force-name = "Birmingham"[
      ; West Midlands
      set temp-list []
      set resource-total 6535
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 6535 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Birmingham" temp-list
    ]
    if force-name = "Milton Keynes"[
      ;Thames Valley
      set temp-list []
      set resource-total 4077
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 4077 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Milton Keynes" temp-list
    ]
    if force-name = "Northampton"[
      ;Northamptonshire Police
      set temp-list []
      set resource-total 1178
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1178 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Northampton" temp-list
    ]
    if force-name = "Brighton and Hove"[
      ; Sussex police
      set temp-list []
      set resource-total 2550
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2550 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Brighton and Hove" temp-list
    ]
    if force-name = "Cheshire East"[
      ; Cheshire Constabulary
      set temp-list []
      set resource-total 2010
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 2010 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Cheshire East" temp-list
    ]
    if force-name = "St Edmundsbury"[
      ; Suffolk
      set temp-list []
      set resource-total 1096
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1096 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "St Edmundsbury" temp-list
    ]
    if force-name = "North Kesteven"[
      ; Lincolnshire
      set temp-list []
      set resource-total 1665
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1665 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "North Kesteven" temp-list
    ]
    if force-name = "County Durham"[
      set temp-list []
      set resource-total 1138
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1138 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "County Durham" temp-list
    ]
    if force-name = "Kingston upon Hull, City of"[
      set temp-list []
      set resource-total 1665
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1665 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Kingston upon Hull, City of" temp-list
    ]
    if force-name = "Broadland"[
      ; Norfolk
      set temp-list []
      set resource-total 1519
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1519 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Broadland" temp-list
    ]
    if force-name = "Monmouthshire"[
      set temp-list []
      set resource-total 1154
      set resourceA-total (resource-total * resourceA-percentage)
      set resourceB-total (resource-total * resourceB-percentage)
      set resourceA-percentage random-float 1
      set resourceB-percentage 1 - resourceA-percentage
      set resourceA-public-order-total (resourceA-total * resourceA-percentage-public-order)
      set resourceB-public-order-total (resourceB-total * resourceB-percentage-public-order)
      set public-order-total (resourceA-public-order-total + resourceB-public-order-total)

      set temp-list lput 1154 temp-list
      set temp-list lput (resource-total * resourceA-percentage) temp-list
      set temp-list lput (resource-total * resourceB-percentage) temp-list
      set temp-list lput floor (resourceA-total * resourceA-percentage-public-order) temp-list
      set temp-list lput floor (resourceB-total * resourceB-percentage-public-order) temp-list
      set temp-list lput (resourceA-public-order-total + resourceB-public-order-total) temp-list
      table:put dict "Monmouthshire" temp-list
    ]
  ]
  ;show dict
end

to setup-crime
  set units_required (random 20 + 1) * 10
  set minimise_impact one-of ["A" "B"]
  set resources_requirement_cycles random 11
  set crime_number crime_value_ID
end

to crime-resource-planner
;create list M (array) with all resources with time-to-mobilise <= resources_requirement_cycles
  ;let time_to_mobilise_list [time-to-mobilise] of forces
  let target_resource_1 0                                                    ; the placeholder for the resource we wish to target
  let target_resource_2 0
  let M_1 []                                                                 ; the M_1 list which contains all resources with time-to-mobilise <= the number of cycles to tackle crime 2.
  let M_2 []                                                                 ; the M_2 list which contains all resources with time-to-mobilise <= the number of cycles to tackle crime 1.
  let M_resources []                                                         ; list contains the number of resources which are not 0
  let M_resources_2 []
  let M_3 []                                                                 ; list contains the time-to-mobilise of the resources which are not the ones to minimise and which are not 0
  let M_3_1 []
  let X []                                                                   ; contains the resources we can use each time tick (main list)
  let X_1 []
  let M_not_minimise_impact 0                                                ; list contains only the resources which we dont have to minimise impact on
  let M_not_minimise_impact_2 0                                              ; list contains only the resources which we dont have to minimise impact on for incident 2
  let crime_units_required_1 (item 0 ([units_required] of crimes with [crime_number = 3]))             ; the number of units required for the first crime instance.
  let crime_units_required_2 (item 0 ([units_required] of crimes with [crime_number = 4]))
  let resource_cycles (item 0 ([resources_requirement_cycles] of crimes with [crime_number = 3]))    ; the number of time cycles the first crime has.
  let resource_cycles_2 (item 0 ([resources_requirement_cycles] of crimes with [crime_number = 4]))
  let list_of_units_potentially_used []
  let list_of_units_potentially_used_2 []
  let forces_resources_pulled []
  let resource-to-subtract-total []

  set target_resource_1 set_target_resource target_resource_1 3 ; returns the resource type we wish to target for crime 1, the negation of the resource we wish to minimise (opposite)
  set target_resource_2 set_target_resource target_resource_1 4 ; returns the resource type we wish to target for crime 2, the negation of the resource we wish to minimise (opposite)
  print (word "Minimise impact on: "target_resource_1 word" for incident 1 and for incident 2: "target_resource_2) ; print the letter of the resource type we wish to target.

  ;; All the forces with time-to-mobilise smaller than or equal to the resources_requirement_cycles time.
  ;print (word "all forces with time-to-mobilise <= resource_requirement_cycles time " M)
  set M_1 [ time-to-mobilise ] of (forces with [ time-to-mobilise <= [resources_requirement_cycles] of one-of crimes with [crime_number = 3]]) ; LINE 1 from algorithm.txt
  set M_2 [ time-to-mobilise ] of (forces with [ time-to-mobilise <= [resources_requirement_cycles] of one-of crimes with [crime_number = 4]]) ; LINE 1 from algorithm.txt


;delete from M all forces where not(minimise_impact) = 0 (no quantity of resource to be used i.e. A or B in this case) LINE 2 from algorithm.txt
  ask forces [
    ifelse target_resource_1 = "A"[
      set M_resources [ resourceA-public-order-total ] of (forces with [resourceA-public-order-total != 0])
    ][
      set M_resources [ resourceB-public-order-total ] of (forces with [resourceB-public-order-total != 0])
    ]
  ]
  ask forces [
    ifelse target_resource_2 = "A"[
      set M_resources_2 [ resourceA-public-order-total ] of (forces with [resourceA-public-order-total != 0])
    ][
      set M_resources_2 [ resourceB-public-order-total ] of (forces with [resourceB-public-order-total != 0])
    ]
  ]

  ;; all the resources which are not 0 and are not the ones to minimise_impact on
  ;; we now need to create a list of all the forces which satisfy both M  and M_resources
  ;print (word "all resources which are not 0 and are not the ones to minimise impact on (ones we can use) " M_resources)
  ask forces [
    foreach M_resources [ res ->
      foreach M_1 [ time ->
        if res = resourceA-public-order-total or res = resourceB-public-order-total [
          if time = time-to-mobilise [
            set M_3 fput time-to-mobilise M_3
          ]
        ]
      ]
    ]
    foreach M_resources_2 [ res ->
      foreach M_2 [ time ->
        if res = resourceA-public-order-total or res = resourceB-public-order-total [
          if time = time-to-mobilise [
            set M_3_1 fput time-to-mobilise M_3_1
          ]
        ]
      ]
    ]
  ]

  ;; this list contains the time to mobilise for all forces <= cycles required and where we target
  ;; resource which are not to be minimised the impact on.
  ;print (word "All time-to-mobilise where TTM  <= resource_requirement_cycle and only forces where the opposite of minimise_impact is != 0 " M_3)
  set M_not_minimise_impact time_to_mobilise_for_all_forces M_3 M_resources M_1 3
  set M_not_minimise_impact_2 time_to_mobilise_for_all_forces M_3_1 M_resources_2 M_2 4
  ; For testing purposes, I set M_not_minimise_impact list to the resources we can target.
  set crime_units_required_view crime_units_required_1
  set crime-units-required-view-2 crime_units_required_2
  ;loop untill units_required = 0 or resources_requirement_cycles = 0: LINE 3 from algorithm.txt
  while [resource_cycles != 0 or resource_cycles_2 != 0]
  [
    print (word "crime_units_required_1: "crime_units_required_1)
    print (word "crime_units_required_2: "crime_units_required_2)
    ; in the algorithm finds the resource with the min-to-mobilise.
    ; Added the time-to-mobilise which we want to X.

    ;(new list object) X = [1A] (add "1A to X")
    set X fput min-max M_3 M_not_minimise_impact list_of_units_potentially_used X ;LINES 4, 5, 6 from algorithm.txt
    ;set X_1 fput min-max M_3_1 M_not_minimise_impact_2 list_of_units_potentially_used_2 X_1
    set X fput min-max M_3_1 M_not_minimise_impact_2 list_of_units_potentially_used_2 X
    let first_x item 0 X

    ;let first_x_2 item 0 X_1

    if member? 0 X [ ;LINES 7 and 8 from algorithm.txt
      ;if for all resources in X there exists a time-to-mobilise = 0 then subtract
      ;resource with time-to-mobilise = 0 from units_required
      set crime_units_required_1 time-to-mobilise-in-X X M_not_minimise_impact crime_units_required_1 resource_cycles 3
      set crime_units_required_2 time-to-mobilise-in-X X M_not_minimise_impact_2 crime_units_required_2 resource_cycles_2 4
      ;set resource-to-subtract-total-view resource-to-subtract-total-view + time-to-mobilise-in-X X M_not_minimise_impact crime_units_required_1
    ]
;  	if member? 0 X_1 [
;      set crime_units_required_2 time-to-mobilise-in-X X_1 M_not_minimise_impact_2 crime_units_required_2 resource_cycles_2 4
;    ]
  	;if units_required <= 0 then [print "crime prevented" LINES 9 and 10 from algorithm.txt
   	    ;print names of all forces resources pulled and amount of resources pulled. BREAK]
    ;set forces_resources_pulled check-crime-prevented X M_not_minimise_impact crime_units_required_1 forces_resources_pulled ; this function is only invoked if the units_required (crime_units_required_1) is 0 or smaller than 0

    if crime_units_required_1 <= 0 [
      print (word "INCIDENT 1 PREVENTED, all resources pulled")
      stop
    ]
    if crime_units_required_2 <= 0 [
      print (word "INCIDENT 2 PREVENTED, all resources pulled")
      stop
    ]


  	; subtract 1 from all resources time-to-mobilise in X i.e. subtract 1 from each resource time-to-mobilise that
    ; exists in X. LINE 11 from algorithm.txt
    show subtract-from-X X
    ;show subtract-from-X X_1

  	;M_3 = M_3 - 1A remove the force added to X from the list M == M_3. LINE 12 from algorithm.txt
    set M_3 remove first_x M_3
    set M_3_1 remove first_x M_3_1

    ; we subtract one from the units required and resource cycles each iteration to see if the computation is finished and plus a time tick has passed.
    ; remember the crime_units_required_1 list contains the time-to-mobilise of all the resources we wish to use so naturally as ticks occur the resource time
    ; also reduces.
    set resource_cycles (resource_cycles - 1)
    set resource_cycles_2 (resource_cycles_2 - 1)
    print(word "CRIME_UNITS: " crime_units_required_1)
    if resource_cycles = 0 or resource_cycles_2 = 0[
      ; we print out the number of units we were able to aquire
      print (word "units provided for incident 1: " crime_units_required_1 word " units provided for incident 2: " crime_units_required_2)
      ; we print out the current state of the number of cycles left, that would obviously be 0 which would end the computation. the units provided
      ; are the number of resources we were able to get to the force which has the crime.
      print (word "resources requirement cycles for incident 1: " resource_cycles word " resources requirement cycles for incident 2: " resource_cycles_2)
      stop
    ]
  ]
end

to-report get_force_links [force_used resource_cycles]
  let police_force_to_target []
  let total_length 0
  let length_of_link 0
  ask forces with [police-force-ID = force_used] [
    ask my-links[
      set police_force_to_target fput link-length police_force_to_target
    ]
  ]
  set total_length sum police_force_to_target
  report (total_length + resource_cycles)
end

to-report merge_lists [list1 list2]
  foreach list1 [ I ->
    set list2 lput I list2
  ]
  report list2
end

to-report subtract-from-X [X]
  ask forces [
    foreach X [ I ->
      if I = time-to-mobilise [
        set time-to-mobilise time-to-mobilise - 1
      ]
    ]
  ]
  set X map [i -> i - 1] X
  print (word "X: " X)
  report X
end


to-report time-to-mobilise-in-X [X M_not_minimise_impact crime_units_required_1 resource_cycles incident]
  let resource_to_sub 0
  let police_force 0
  let police_force_list []
  ;let reporter_choice CHOICE

  ask forces [
    foreach X [ I ->
      foreach M_not_minimise_impact [ M ->
        ifelse (I = time-to-mobilise) and (M = resourceA-public-order-total)[
          set resource_to_sub resourceA-public-order-total
          set police_force police-force-ID

        ][
          if (I = time-to-mobilise) and (M = resourceB-public-order-total)[
            set resource_to_sub resourceB-public-order-total
            set police_force police-force-ID

          ]
        ]
      ]
    ]
  ]



  set police_force_list fput police_force police_force_list

  ifelse incident = 3 [
    print(word "FOR INCIDENT 1 RESOURCE TO SUBTRACT: " resource_to_sub word
      " FROM POLICE FORCE: " police_force " TIME IT TAKES FOR RESOURCES TO REACH DESTINATION: " get_force_links police_force resource_cycles)
    set resource-to-subtract-total-view resource-to-subtract-total-view + resource_to_sub
  ][
    if incident = 4 [
      print(word "FOR INCIDENT 2 RESOURCE TO SUBTRACT: " resource_to_sub word
        " FROM POLICE FORCE: " police_force " TIME IT TAKES FOR RESOURCES TO REACH DESTINATION: " get_force_links police_force resource_cycles)
      set resource-to-subtract-total-view-1 resource-to-subtract-total-view-1 + resource_to_sub
    ]
  ]
  ;set resource-to-subtract-total fput resource_to_sub resource-to-subtract-total
  ;print(word "TOTAL RESOURCES TO SUBTRACT: "sum resource-to-subtract-total)
  set crime_units_required_1 crime_units_required_1 - resource_to_sub
  report crime_units_required_1
end


to-report set_target_resource [target_resource crime_number_argument]
  ;; here we set the target_resource to the resource type we want to target not the one to minimise.
  ask crimes with [crime_number = crime_number_argument]
      [ifelse minimise_impact = "A"[
        set target_resource "B"

      ][
        set target_resource "A"
        ]
  ]
  report target_resource
end

to-report time_to_mobilise_for_all_forces [M_3 M_resources M_1 incident]
  let M_not_minimise_impact []

  ask forces [
    if member? time-to-mobilise M_3[
      ifelse member? resourceA-public-order-total M_resources[
        set M_not_minimise_impact fput resourceA-public-order-total M_not_minimise_impact
      ][
        if member? resourceB-public-order-total M_resources[
          set M_not_minimise_impact fput resourceB-public-order-total M_not_minimise_impact
        ]
      ]
    ]
  ]
  ifelse incident = 3 [
    print (word "All the resources we can use for incident 1: " M_not_minimise_impact
      word " and all their times to mobilise " M_1)
  ][
    if incident = 4 [
      print (word "All the resources we can use for incident 2: " M_not_minimise_impact
        word " and all their times to mobilise " M_1)
    ]
  ]

  report M_not_minimise_impact
end


to-report min-max [M_3 M_not_minimise_impact list_of_units_potentially_used]
  let min_resource_time_1 min M_3
  ask forces [
    if min_resource_time_1 = time-to-mobilise[
      set list_of_units_potentially_used fput time-to-mobilise list_of_units_potentially_used
    ]
  ]
  report item 0 list_of_units_potentially_used
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
  setup
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
  foreach gis:feature-list-of map-view [ vector-feature ->
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
  foreach gis:feature-list-of centroid-points [ vector-feature ->
    let centroid gis:location-of gis:centroid-of vector-feature
    ask patches gis:intersecting vector-feature [
      set police-force-name-patch gis:property-value vector-feature "NAME"
      set patchworkm gis:property-value vector-feature "PATCHWORKM"
      set force-longitude gis:property-value vector-feature "LONGITUDE"
      set force-latitude gis:property-value vector-feature "LATITUDE"
    ]
  ]
end

to draw-centroids
  foreach gis:feature-list-of centroid-points [ vector-feature ->
    gis:set-drawing-color red
    gis:fill vector-feature 2.0

    ask patches gis:intersecting vector-feature [
      set centroid-patch-identity 1
      set forces? "yes"
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
      set location patch-here
      set shape "truck"
      set size .8
      set color 15
    ]
  ]
  ask patches [
    set resource? 0
  ]
  ask resources [
    ;set amount random 50
  ]
end

to create_forces
  ask patches with [forces? = "yes"][
    sprout-forces 1 [ ; we wrote piece of code on a train
      setup-forces ; we wrote piece of code on a train
      set size .5
      set color black
      set shape "house"
    ]
  ]
  ask patches [
    set forces? 0
  ]
end

to spawn-crime
  repeat number_of_crimes [
    ask one-of turtles[
      ; one crime spawns for now, once our algorithm works we can try multiple crimes.
      hatch-crimes 1[
        set shape "circle"
        set size .10
        set color 15
        set crime_value_ID crime_value_ID + 1
        setup-crime
      ]
    ]
  ]
end

to move-resources
  ask links [set thickness 0]
  ask resources [
    let new-location one-of [link-neighbors] of location
    ask [link-with new-location] of location [set thickness 0.5]
    face new-location
    set location new-location
  ]
end

to draw-links
    ask forces [
    create-links-with other forces in-radius 4.0
  ]
  ask forces with [xcor = -4 and ycor = -15] [
    create-links-with forces with [xcor = 1 and ycor = -11]
    create-links-with forces with [xcor = 3 and ycor = -14]
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
113
615
176
648
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
187
615
250
648
go
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
0.5
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
688
393
775
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
687
495
779
528
radius
radius
0.0
10.0
4.0
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
404
674
651
719
units of resource required for crime 1
crime_units_required_view
17
1
11

BUTTON
260
615
347
648
watch crime
watch one-of crimes\n\n
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
354
615
457
648
reset perspective
rp
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
658
674
832
719
total resources provided
resource-to-subtract-total-view
17
1
11

CHOOSER
678
533
787
578
number_of_crimes
number_of_crimes
1 2
1

MONITOR
404
723
651
768
units of resource required for incident 2
crime-units-required-view-2
17
1
11

MONITOR
659
724
831
769
total resources provided
resource-to-subtract-total-view-1
17
1
11

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
