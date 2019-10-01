### Modelling the supply and demand of UK Police Forces, an Agent Based Modelling approach 03/04/2019

(Note, this project is ongoing. All information regarding the project can be found on its website: [Turing page](https://www.turing.ac.uk/research/research-projects/computational-models-police-demand-dynamics))

To execute the model, you must

- Install `Netlogo` version `6.0.4`, you can install it here: [Netlogo](https://ccl.northwestern.edu/netlogo/download.shtml).
- Download the map dataset: [dataset](https://github.com/SedarOlmez94/police_simulation_project-PSP-/tree/master/project/data)

1) The algorithm developed (Pseudocode):

calculate T for all forces
crime occurs somewhere CRIME_LOCATION

- create list M (array) with all resources with time-to-mobilise <= resources_requirement_cycles
- delete from M all forces where not(minimise_impact) = 0 (no resources of resource to be used i.e. A in this case)
- loop untill units_required = 0 or resources_requirement_cycles = 0:
- find in M resource with min(time-to-mobilise) "smallest time to mobilise" AND max(M(not(minimise_impact))) = 1A "maximum
- value of the resource which is not the one to minimise_impact on stored in M"
- (new list object) X = [1A] (add "1A to X")
- if for all resources in X there exists a time-to-mobilise = 0 then subtract
- 	resource with time-to-mobilise = 0 from units_required
- if units_required <= 0 then [print "crime prevented"
- 	print names of all forces resources pulled and amount of resources pulled. BREAK]
- subtract 1 from all resources time-to-mobilise in X
- M = M - 1A remove the force added to X from the list M.
