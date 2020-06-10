/* Author: Sedar Olmez
 * The Environment class is also a compulsory object which extends from the MLAgents https://github.com/Unity-Technologies/ml-agents Area
 * interface. This class creates the components of the environment, more specifically,
 * the area in which points are created and agents roam. The Environment class has two methods
 * one will create a number of goodpoints and badpoints at random locations and the second
 * will reset the PointArea each iteration of the training process.
 */

using UnityEngine;
using MLAgents;

// The Environment class inherits the Area class from mlagents package.
public class PPEnvironment : Area
{
    // A goodPoint game object is declared.
	public GameObject goodPoint;
    // A badPoint game object is declared.
	public GameObject badPoint;
    // A predator game object is declared.
    // public GameObject predator;
    // A public integer variable for the number of goodPoints is declared.
	public int numPoint;
    // A public integer variable for the number of badPoints object is declared.
	public int numBadPoint;
    // A public boolean variable for respawning points is declared.
	public bool respawnPoint;
    // A public range variable is declared of type range.
	public float range;

    // The createPoint method creates a number of point objects in the environment.
	void CreatePoint(int num, GameObject type){

        // The algorithm loops to create the exact number of required points objects.
		for (int i = 0; i < num; i++){

            // A game object is created at a random location within the environment bounds.
			GameObject f = Instantiate(type, new Vector3(Random.Range(-range, range), 1f,
				Random.Range(-range, range)) + transform.position,
			Quaternion.Euler(new Vector3(0f, Random.Range(0f, 360f), 90f)));
            // The respawn method in PointLogic is applied to the GameObject whereby respawn is set to true.
			f.GetComponent<PointLogic>().respawn = respawnPoint;
            // The PointLogic myArea variable is set to the current Environment object.
			f.GetComponent<PointLogic>().myArea = this;
		}

	}

    /*The ResetPointArea takes a list of agents and places them around the
     Environment randomly. And creates the number of required good points
     and bad points. The method also moves the predator agent to a random location.
     */
	public void ResetPointArea(GameObject[] agents){

        // For all the Prey, place them at random locations.
        foreach (GameObject agent in agents){
			if(agent.transform.parent == gameObject.transform){
				agent.transform.position = new Vector3(Random.Range(-range, range), 2f,
				Random.Range(-range, range)) + transform.position;
				agent.transform.rotation = Quaternion.Euler(new Vector3(0f, Random.Range(0, 360)));
			}
		}

        // An amount of goodpoints is created.
        CreatePoint(numPoint, goodPoint);
        // An amount of bad point is also created.
		CreatePoint(numBadPoint, badPoint);
	}

	public override void ResetArea(){}
}
