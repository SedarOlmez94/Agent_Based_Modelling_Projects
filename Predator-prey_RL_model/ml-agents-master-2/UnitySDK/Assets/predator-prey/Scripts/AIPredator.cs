/*Author: Sedar Olmez
 * The AIPredator Class is attached to the predator agent, this class allows the predator to
 have a field of view which it can use to see within a given radius 0 to 360. The predator
 is considered an autonomous agent which moves randomly around the environment and if it
 sees a collector, it will chase the collector. This method was inspired
 by: https://github.com/SebLague/Field-of-View and the book Unity AI programming Fourth Edition
 by David Aversa, Aung Sithu Kyaw and Clifford Peters
*/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class AIPredator: MonoBehaviour {

    // The agents array is of type GameObject.
    public GameObject[] agents;
    // View Radius variable declared of type float.
    public float viewRadius;
    /* The viewAngle variable is of type floating point but restricted to a value
     * between 0 and 360*/
	[Range(0,360)]
	public float viewAngle;
	[HideInInspector]
	// In range to check if Collector is in range of predator.
	public bool inRange = false;
    // Rigidbody for the predator agent.
    Rigidbody rb;
    // Velocity is declared as a 3D vector.
    Vector3 velocity;

    // The maincamera is used to detect the mouse on screen.
    Camera viewCamera;

    // Set the move speed to 2
    public float moveSpeed = 20f;

    // A layer mask for target objects
    public LayerMask targetMask;
    // A layer mask for obstacle objects
	public LayerMask obstacleMask;
    // These layer masks are attached to targets and obstacles so the agent
    // knows exactly what a target is and what an obstacle is.

	[HideInInspector]
    // A list of objects initialised called visibleTargets.
	public List<Transform> visibleTargets = new List<Transform>();

    // A floating point variable declared called meshResolution.
	public float meshResolution;
    // A integer variable declared called edgeResolveIterations.
    public int edgeResolveIterations;
    // A floating point variable declared called edgeDstThreshold.
    public float edgeDstThreshold;
    // A floating point variable called maskCutawayDst initialised to 1.
	public float maskCutawayDst = .1f;

    // A MeshFilter object declared, called viewMeshFilter.
	public MeshFilter viewMeshFilter;
    // A Mesh object declared, called viewMesh.
	Mesh viewMesh;
	// Distance to detected target
	float dstToTarget;
	// viewcast angle
	public float viewCastAngle;
	// wall touched
	public int wallTouch = 0;
    // column titles is set to false
    static private bool column_titles = false;
    // A public range variable is declared of type range.
    public float range;


    //27/01/2019
    //---------------
    // The invisible targets position a 3D vector.
    private Vector3 tarPos;
	//---------------

  //----------------
		public float timeToWrite = 1f;
		private float currentTime = 0f;
		//----------------

	// The start method is called once when the object is initilised.
	void Start() {
        // The viewMesh object is initilised to an empty Mesh object.
		viewMesh = new Mesh ();
        // The viewMesh object is given a name "View Mesh"
		viewMesh.name = "View Mesh";
        // The mesh Filter is assighed the viewMesh object.
		viewMeshFilter.mesh = viewMesh;
        /*A coroutine is like a function that has the ability to pause execution
         * and return control to Unity but then to continue where it left off on
         * the following frame. A Coroutine method is called with a name FindTargetsWithDelay
         and a timer of 2 seconds.*/
        StartCoroutine("FindTargetsWithDelay", .2f);
        // Initialise the rigid body of the predator.
		rb = GetComponent<Rigidbody>();
        // Get the next position for an invisible target for the predator to move towards.
		GetNextPosition();
		//---------------

        InvokeRepeating("ViewPosition", 0.8f, 0.4f);
    }


    // A method which adds a delay each time targets can be seen by the predator.
    IEnumerator FindTargetsWithDelay(float delay) {
		while (true) {
            // Wait for a few seconds everytime before calling the FindVisibleTargets.
			yield return new WaitForSeconds (delay);
			FindVisibleTargets ();
		}
	}

	void Update()
	{
    if (currentTime >= timeToWrite){
      updateRecord(this.rb.velocity.magnitude, this.transform.position.x, this.transform.position.z, dstToTarget, viewCastAngle, wallTouch, "/Users/solmez/Desktop/ml-agents-master-2/UnitySDK/Assets/Data/predator_data.csv");
      currentTime = 0f;
    }
    currentTime += Time.deltaTime;
	}

	//A method called LateUpdate that calls the D_FieldOfView() method.
	void LateUpdate()
	{

		//---------------
		// Check if we're near the destination position
		if (Vector3.Distance(tarPos, transform.position) <= 5.0f)
			GetNextPosition(); //generate new random position
							   // Set up quaternion for rotation toward destination
		Quaternion tarRot = Quaternion.LookRotation(tarPos - transform.position);
		// Update rotation and translation
		transform.Translate(new Vector3(0, 0,
		moveSpeed * Time.deltaTime));
		//---------------

		D_FieldOfView();
	}

	void GetNextPosition()
	{
		tarPos = new Vector3(Random.Range(-range, range), 2f,
                Random.Range(-range, range));
	}

	void Awake()
    {
        //rb = GetComponent<Rigidbody>();
    }

    // Randomly look round if no target is detected.
    void ViewPosition()
    {
        Vector3 position = new Vector3(Random.Range(-45, 45), 0, Random.Range(-26, 63));
        transform.LookAt(position + Vector3.up * transform.position.y);
    }

	// Export data to CSV
	public static void updateRecord(float velocity, float x_axis, float z_axis, float distance_tt, float viewCastAng, int wallTouch, string filepath)
	{
		using (System.IO.StreamWriter file = new System.IO.StreamWriter(@filepath, true))
		{
            if(column_titles != true)
            {
                file.WriteLine("predatorVelocity" + "," + "xAxisPos" + "," + "zAxisPos" + "," + "distanceToTarget" + "," + "viewAngle" + "," + "touchedWall" + "," + "date-time");
            }
			file.WriteLine(velocity + "," + x_axis + "," + z_axis + "," + distance_tt +","+ viewCastAng +","+ wallTouch +","+ System.DateTime.UtcNow);
            column_titles = true;
		}
	}

	// The OnCollisionEnter method takes a collision parameter, if the predator collides
	 //with an object, then something happens.
	void OnCollisionEnter(Collision collision)
	{
		if (collision.gameObject.CompareTag("wall"))
		{
			wallTouch += 1;
		}
	}


	/*This method identifies each target that enters the view radius of the predator,
     it then adds these target objects into an array called visibleTargets.*/
	void FindVisibleTargets() {
        // Whenever this method is called, the array is cleared so duplicates don't occur
		visibleTargets.Clear ();
        /* A collider array targetsInViewRadius which is assigned the OverlapSphere
         * method which returns an object within the view radius.*/
        Collider[] targetsInViewRadius = Physics.OverlapSphere (transform.position, viewRadius, targetMask);
        //agents = GameObject.FindGameObjectsWithTag("agent");
        /* For all the targets within the view radius, get their transform variables (position in world)
         * get the direction to the targets, if the current angle contains the target, then get the distance to target
         * if there is no obstacle blocking the predators view to the target, then add the target to the visibleTargets array.
        */
        for (int i = 0; i < targetsInViewRadius.Length; i++) {
			Transform target = targetsInViewRadius [i].transform;
			Vector3 dirToTarget = (target.position - transform.position).normalized;
			if (Vector3.Angle (transform.forward, dirToTarget) < viewAngle / 2) {
				dstToTarget = Vector3.Distance (transform.position, target.position);
                if (!Physics.Raycast(transform.position, dirToTarget, dstToTarget, obstacleMask))
                {
                    //GameObject.gameObject.tag = "Player";
                    visibleTargets.Add(target);
                    inRange = true;
                    Vector3 velocity = (target.position - transform.position).normalized * moveSpeed;
                    rb.velocity += velocity;
                }

			}
		}
	}



    /* The D_FieldOfView method draws the field of view around the predator agent.
     while updating the field of view relative to the position of the predator agent.*/
	void D_FieldOfView() {
        // A stepCount integer variable is equal to viewAngle multiplied by meshResolution rounded to integer.
		int stepCount = Mathf.RoundToInt(viewAngle * meshResolution);
        // The stepAngleSize floating point variable is initilised to the viewAngle divided by the stepCount.
		float stepAngleSize = viewAngle / stepCount;
        // The viewPoints variable contains a list of Vector3 points.
		List<Vector3> viewPoints = new List<Vector3> ();
        // viewCastInformation object created called oldViewCast
		viewCastInformation oldViewCast = new viewCastInformation ();

        // Loop over the number of stepCount.
		for (int i = 0; i <= stepCount; i++) {
            /* Set the angle floating point variable to the Y angle minus viewAngle
             * divided by 2 plut stepAngleSize * the current step count. */
			float angle = transform.eulerAngles.y - viewAngle / 2 + stepAngleSize * i;
            /*newViewCast variable is equal the ViewCast of the current angle of the predator.
             */
			viewCastInformation newViewCast = ViewCast (angle);
            /* If we have greater than 0 stepCounts, we set the edge threshold exeeded
             * variable to the absolute value of the oldViewCast distance minus the
             * newViewCast distance, this is true iff ovc - nvc is greater than the
             * edgeDistanceThreshold.
             */
			if (i > 0) {
				bool edgeThresholdExceeded = Mathf.Abs (oldViewCast.dst - newViewCast.dst) > edgeDstThreshold;
                /* 1. If the oldViewCast hit is not equal the new view cast hit or if both view cast hit and edge threshold exceeded is true*/
				if (oldViewCast.hit != newViewCast.hit || (oldViewCast.hit && newViewCast.hit && edgeThresholdExceeded)) {
                    // 2. Then create an edgeInformation object called edge which finds the edge between the oldVC and newVC.
					edgeInformation edge = FindEdge (oldViewCast, newViewCast);
                    // 3. if the pointA is not equal Vector3[0,0,0] then
					if (edge.pointA != Vector3.zero) {
                        //4. add pointA to the viewPoints.
						viewPoints.Add (edge.pointA);
					}
                    // If point B is not equal Vector3[0,0,0]
					if (edge.pointB != Vector3.zero) {
                        // then add point B to viewPoints.
						viewPoints.Add (edge.pointB);
					}
				}

			}
            // Add the points from newVC (0, 0, 0) to the viewPoints.
            // Debug.Log(newViewCast.point);
            viewPoints.Add (newViewCast.point);
            // The oldVC is updated to the newVC.
			oldViewCast = newViewCast;
		}

        // A variable called v_count is created that holds the vertex count of all the viewpoints.
		int v_count = viewPoints.Count + 1;
        // vertices is a vector 3 object which contains the vertex counts.
		Vector3[] vertices = new Vector3[v_count];
        // triangles is a list of type integer containing the vertex counts-2 multiplied by 3.
		int[] triangles = new int[(v_count-2) * 3];

        // The first vertice is set to a vector3 object filled with zeroes.
		vertices [0] = Vector3.zero;
        /* for the number of vertices, transform their position to local space
         * for each viewPoint plus the forward vector3 multiplied by the CustawayDistance. */
		for (int i = 0; i < v_count - 1; i++) {
			vertices [i + 1] = transform.InverseTransformPoint(viewPoints [i]) + Vector3.forward * maskCutawayDst;
            /* If the current loop index is smaller than the vertex count - 2
             * then set the i * 3 index in triangles to 0, i * 3 + 1 to i + 1
             * and finally i * 3 + 2 index to i + 2.
             */
			if (i < v_count - 2) {
				triangles[i * 3] = 0;
				triangles[i * 3 + 1] = i + 1;
				triangles[i * 3 + 2] = i + 2;
			}
		}

        // Clear the mesh on the predator agent.
		viewMesh.Clear ();
        // set the mesh vertices to the vertices object.
		viewMesh.vertices = vertices;
        // set the mesh triangles to the triangles object.
		viewMesh.triangles = triangles;
        // invoke the RecalculateNormals method on the viewMesh.
        // this method recalculates the normals of the mesh from the triangles and vertices.
		viewMesh.RecalculateNormals ();
	}

    /* The FindEdge method returns an edgeInformation object. It takes the parameters
     minViewCast and maxViewCast. This method takes two ViewCasts and returns the
     edge that lies between the two.*/
	edgeInformation FindEdge(viewCastInformation minViewCast, viewCastInformation maxViewCast) {
        /*Two floating point variables minimumAngle and maximumAngle which are equal
         to the angle from minViewCast and maxViewCast parameters.*/
		float minimumAngle = minViewCast.angle;
		float maximumAngle = maxViewCast.angle;
        /*The minPoint and maxPoint variables are empty 3D vectors*/
		Vector3 minimumPoint = Vector3.zero;
		Vector3 maximumPoint = Vector3.zero;

        // 1. For the number of edgeResolveIterations
		for (int i = 0; i < edgeResolveIterations; i++) {
            //2. Get the angle between minAngle and maxAngle
			float angle = (minimumAngle + maximumAngle) / 2;
            //3. create a new ViewCast object equal the ViewCast of the angle.
			viewCastInformation newViewCast = ViewCast (angle);

            //4. set a boolean variable to see if the edgeThreshold has been exceeded or not
			bool edgeThresholdExceeded = Mathf.Abs (minViewCast.dst - newViewCast.dst) > edgeDstThreshold;
            //5. if the viewCasts both min and max are of the same value and the edgeThreshold has not been exceeded.
			if (newViewCast.hit == minViewCast.hit && !edgeThresholdExceeded) {
                //6. Set the minimumAngle to the current angle. And the minimumPoint to the viewcast point.
				minimumAngle = angle;
				minimumPoint = newViewCast.point;
			} else {
                //7. Else maximumAngle is set to the current angle. And maximumPoint is the viewcast point.
				maximumAngle = angle;
				maximumPoint = newViewCast.point;
			}
		}

        //8. Return the edgeInformation for the minimumPoint and maximumPoint.
		return new edgeInformation (minimumPoint, maximumPoint);
	}

    // The ViewCast method takes a globalAngle floating point value and gets raycast information
    // from that angle in th environment.
   viewCastInformation ViewCast(float globalAngle)
    {
        /*A 3D vector containing the direction from the globalAngle*/
        Vector3 dir = directionFromAngle(globalAngle, true);
        // RaycastHit object declared
        RaycastHit hit;

        // If a raycast hit from an origin position to the direction within the viewRadius occurs
        if (Physics.Raycast(transform.position, dir, out hit, viewRadius, obstacleMask))
        {
			// Return the RayCast information as true hit, the hit distance and the angle.
			viewCastAngle = globalAngle;
			return new viewCastInformation(true, hit.point, hit.distance, globalAngle);
        }
        else
        {
			// else return false for hit and update the viewcast information
			viewCastAngle = globalAngle;
			return new viewCastInformation(false, transform.position + dir * viewRadius, viewRadius, globalAngle);
        }
    }

    /* The direction from angle method takes two parameters an angleInDegrees
     * and a boolean indicating if the angle is global or not. If the angle is not global,
       it converts the angle into a global one. Then returns the 3D vector coordinates
       whereby x = sin(angleInDegrees * Degrees to Radians), y = 0 and finally
       z = cos(angleInDegrees multiplied by Degrees to Radians.)*/
    public Vector3 directionFromAngle(float angleInDegrees, bool angleIsGlobal) {
		if (!angleIsGlobal) {
			angleInDegrees += transform.eulerAngles.y;
		}
		return new Vector3(Mathf.Sin(angleInDegrees * Mathf.Deg2Rad),0,Mathf.Cos(angleInDegrees * Mathf.Deg2Rad));
	}

    // viewCastInformation is a constructor that returns the viewCastInformation object.
	public struct viewCastInformation {
		public bool hit;
		public Vector3 point;
		public float dst;
		public float angle;

		public viewCastInformation(bool _hit, Vector3 _point, float _dst, float _angle) {
			hit = _hit;
			point = _point;
			dst = _dst;
			angle = _angle;
		}
	}
    // The edgeInformation method is also a constructor which constructs the info
    // regarding the points a and b and returns these as a tuple.
	public struct edgeInformation {
		public Vector3 pointA;
		public Vector3 pointB;

		public edgeInformation(Vector3 _pointA, Vector3 _pointB) {
			pointA = _pointA;
			pointB = _pointB;
		}
	}

}
