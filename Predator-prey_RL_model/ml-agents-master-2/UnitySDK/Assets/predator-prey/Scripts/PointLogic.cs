/* Author: Sedar Olmez
 * The PointLogic class contains a single method which distributes point objects that
 * have been consumed. The method could be in two states, it can either be at
 * a random location in the environment, or it is destroyed because it's come into
 * contact with a Prey.
 */

using UnityEngine;

// A PointLogic class is created.
public class PointLogic : MonoBehaviour
{
    // Public boolean variable called respawn 
    public bool respawn;
    // A public Environment variable called myArea 
    public PPEnvironment myArea;

    /* The OnEaten() method checks to see if respawn is set to true, if so it
     * places a point object at a random location on the Environment myArea.
     * Else it destroys the gameObject the pointlogic component is attached to. That being
     * the goodPoint and badPoint objects (prefab).
    */
    public void OnEaten(){
    	if (respawn){
    		transform.position = new Vector3(Random.Range(-myArea.range, myArea.range),
    			3f, Random.Range(-myArea.range, myArea.range)) + myArea.transform.position;
    	}
    	else{
    		Destroy(gameObject);
    	}
    }
}
