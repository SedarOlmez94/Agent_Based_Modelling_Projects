/* The Collector agent is also compulsory and extends the Agent interface in
 * the MLAgents toolkit https://github.com/Unity-Technologies/ml-agents. The 3D cube
 * objects have this class attached to them, it provides the agent with the logic to
 * move, collect point objects, be penalised and/or rewards during the training process
 * this teaches the agent what rewarding behaviours and bad behaviours are.
 */
using System.Text;
using System.IO;
using UnityEngine;
using MLAgents;

public class Collector : Agent
{
	// The academy object declared
	PredatorPreyAcademy myAcademy;
    // The area object declared
    public GameObject area;
    // The Environment object declared.
    PPEnvironment myArea;
    // Agent rigid body declared
    Rigidbody agentRigidBody;
    // Speed of agent rotation.
    public float turnSpeed = 300;
    // Speed of agent movement.
    public float moveSpeed = 2;
    // Material the agent considers as not good nor bad.
    public Material normalMaterial;
    // Bad materials i.e. material attached to badPoint object.
    public Material badMaterial;
    // Good materials i.e. material attached to goodPoint objects.
    public Material goodMaterial;
    // Boolean placeholder for if agent commits an action to be rewarded or bad to be penalised.
    public bool contribute;
    // A boolean indicating if the entity the agent comes across is observable.
    public bool useVectorObs;
    // Variable to track the number of good points and bad points consumed.
	private int goodPointAmount;
	private int badPointAmount;
	// Seen by snatcher number of times the agent is seen by the snatcher.
	private int seenBySnatcher;
	// Touched wall
	private int wallTouch = 0;
	// column titles is set to false
	static private bool column_titles;
    // snatcher agent
    // public GameObject snatcher;
	//----------------
	public float timeToWrite = 1f;
	private float currentTime = 0f;
	//----------------



	// Agent is initialised (constructor)
	public override void InitializeAgent()
    {
        base.InitializeAgent();
        // Get the rigidbody component the agent has and initilize it to agentRigidBody variable.
        agentRigidBody = GetComponent<Rigidbody>();
        // The monitor is set to be 1 cm above the agent.
        Monitor.verticalOffset = 1f;
        // The area game object contains the environment which is initialised to the myArea variable.
        myArea = area.GetComponent<PPEnvironment>();
        // The Academy object is initialised to the myAcademy variable.
        myAcademy = FindObjectOfType<PredatorPreyAcademy>();
		// Snatcher hasn't seen any agents yet.
		 		seenBySnatcher = 0;
        // initilise the snatcher agent.
        // snatcher = GameObject.FindGameObjectWithTag("Snatcher");
        // SetResetParameters method called, this method just sets the size of the agent.
        SetResetParameters();
		// column titles set to false so we can set the column titles for the exported csv.
		column_titles= false;
	}

    /* This method collects observations from the world, this currently is the movement
     * of the agents rigid body. (NOTE TO SELF: I must also collect observations for the
     * snatcher agent character.)
     */
    public override void CollectObservations()
    {

        /* If the Use Vector Obs button is checked in the agent inspector window in Unity,
         * then the velocity of the agent on the x axis and y axis are recorded.
         */

        if (useVectorObs)
        {
            var localVelocity = transform.InverseTransformDirection(agentRigidBody.velocity);

	    		// Snatcher position
				// AddVectorObs(snatcher.transform.position);

	            // Agent speed.
				AddVectorObs(localVelocity.x);
	            AddVectorObs(localVelocity.z);


		}
    }

		public Color32 ToColor(int hexVal)
    {
        var r = (byte)((hexVal >> 16) & 0xFF);
        var g = (byte)((hexVal >> 8) & 0xFF);
        var b = (byte)(hexVal & 0xFF);
        return new Color32(r, g, b, 255);
    }

    // Uncomment if you wish to download synthetic data from the model.
 //  void Update()
	//{
	//	if (currentTime >= timeToWrite){
	//			updateRecord(this.GetInstanceID(), goodPointAmount, badPointAmount, this.agentRigidBody.velocity.magnitude, this.transform.position.x, this.transform.position.z, this.seenBySnatcher, this.wallTouch, myAcademy.totalScore, "/Users/solmez/Desktop/ml-agents-master-2/UnitySDK/Assets/Data/collector_data.csv");
	//			currentTime = 0f;
	//		}

	//		currentTime += Time.deltaTime;
	//}

	// Export data to CSV
	public static void updateRecord(int ID, int goodPoint, int badPoint, float velocity, float x_axis, float z_axis, int seenBySnatcher, int touchedWall, int academyScore,  string filepath)
	{
        using (System.IO.StreamWriter file = new System.IO.StreamWriter(@filepath, true))
		{
            if(column_titles != true)
			{
				file.WriteLine("AgentID" + "," + "GoodPointAmount" + "," + "BadPointAmount" + "," + "Velocity" + "," + "xAxisPos" + "," + "zAxisPos" + "," + "seenBySnatcher" + "," + "touchedWall" + "," +"academyScore" +","+ "date-time");
			}
			file.WriteLine(ID + "," + goodPoint + "," + badPoint + "," + velocity +","+ x_axis + "," + z_axis +","+ seenBySnatcher +"," + touchedWall +","+ academyScore +","+ System.DateTime.UtcNow);
			column_titles = true;
		}
	}

    // Method which outlines logic behind the movement of agents. The method
    // takes a floating point act array.
    public void MoveAgent(float[] act)
    {   // The direction to go is set to a 3D vector with zeroes.
        var directionToGo = Vector3.zero;
        // The rotation direction is also set to 3D vector with zeroes.
        var rotateDirection = Vector3.zero;
        // The forward axis is cast to integer type and is the first value in the act array.
        var forwardAxis = (int)act[0];
        // The right axis is cast to integer type and is the second value in the act array.
        var rightAxis = (int)act[1];
        // The rotate axis is cast to integer type and is the third value in the act array.
        var rotateAxis = (int)act[2];

            /* The forward axis value can be only 1 of two numbers, if it is 1 then,
             * the directionToGo variable is initialised to the Z axis. I.e. the agent should move in the
             * direction of the Z axis. and if it is 2, the agent should go the opposite direction.
             */


            switch (forwardAxis)
            {
                case 1:
                    directionToGo = transform.forward;
                    break;
                case 2:
                    directionToGo = -transform.forward;
                    break;
            }
            // Same logic as above but this time the focus is on the X axis.
            switch (rightAxis)
            {
                case 1:
                    directionToGo = transform.right;
                    break;
                case 2:
                    directionToGo = -transform.right;
                    break;
            }
            // Finally the Y axis.
            switch (rotateAxis)
            {
                case 1:
                    rotateDirection = -transform.up;
                    break;
                case 2:
                    rotateDirection = transform.up;
                    break;
            }

            /* Force is applied to the agents rigid body direction * movespeed
             * ForceMode adds an instant velocity change to the rigid body
             * ignoring the mass this makes the agent move.
             */
            agentRigidBody.AddForce(directionToGo * moveSpeed, ForceMode.VelocityChange);

            /* The transform object which contains the agents positon, rotation and scale
             * is taken and its rotation is changed to the 3D vector direction the agent has
             * moved and the angle of that movement over time * speed of rotation.
            */
            transform.Rotate(rotateDirection, Time.fixedDeltaTime * turnSpeed);

        // If the square length of the velocity of the agent is greater than 25
        // then we slow the agent down.
        if (agentRigidBody.velocity.sqrMagnitude > 25f) // slow it down
        {
            // The agents velocity is then multiplied by 0.95 just increasing the speed a tiny bit.
            agentRigidBody.velocity *= 0.95f;
        }
    }

    // The AgentAction is inherited from the Agent class from mlagents and is overrided.
    // The method takes an array of floating point values called vectorAction.
    public override void AgentAction(float[] vectorAction)
    {
        // The values are then passed to the MoveAgent method to move the agent.
        MoveAgent(vectorAction);

	}


    // The Heuristic method provides the modeller with the ability to control agents
    // using the keyboard keys A, W, S, D.
    public override float[] Heuristic()
    {
        // The local action variable is set to an array of 4 floating point values.
        var action = new float[4];
        // If the modeller presses the D key then, the corresponding third value in
        // the action array is set to 2.
        if (Input.GetKey(KeyCode.D))
        {
            action[2] = 2f;
        }
        // If the user presses W, the first value is set to 1.
        if (Input.GetKey(KeyCode.W))
        {
            action[0] = 1f;
        }
        if (Input.GetKey(KeyCode.A))
        {
            action[2] = 1f;
        }
        if (Input.GetKey(KeyCode.S))
        {
            action[0] = 2f;
        }

        // Return the action performed.
        return action;
    }

    // Reset the agents velocity, its position in the 3D world and its rotation.
    public override void AgentReset()
    {
        // The rigidbody velocity is set to zero.
        agentRigidBody.velocity = Vector3.zero;
		// The agents position is set to a random location within the bounds of the Environment
		transform.position = new Vector3(Random.Range(-myArea.range, myArea.range),
            2f, Random.Range(-myArea.range, myArea.range))
            + area.transform.position;

        // The agent is rotated randomly to a range between 0 to 360 using the Euler method,
        // the Euler method returns a rotation that rotates each axis by its degrees i.e. Z degrees by Z axis...
        transform.rotation = Quaternion.Euler(new Vector3(0f, Random.Range(0, 360)));

		//-----------------------
		goodPointAmount = 0;
		badPointAmount = 0;
        //-----------------------

        // The SetResetParameters() method is called.
        SetResetParameters();
	}


    // The OnCollisionEnter method takes a collision parameter, if the agent collides
    // with a point then the point is eaten using the OnEaten() method from the PointLogic.cs script.
    // NOTE TO SELF: THIS IS WHERE THE LOGIC FOR PENALISING THE AGENT WHEN IT IS SEEN BY THE SNATCHER MUST OCCUR.
    void OnCollisionEnter(Collision collision)
	{
        if (collision.gameObject.CompareTag("goodPoint"))
		{

			collision.gameObject.GetComponent<PointLogic>().OnEaten();
	// A reward of 1 is added if the agent collides with goodpoint.
	AddReward(1.0f);

	// We increment the goodPoint amount by 1
	goodPointAmount += 1;
			
			if (contribute)
			{
				myAcademy.totalScore += 1.0;
			}

		}
		// If the agent collides with a badPoint object, then reward it a score of -0.2.
		if (collision.gameObject.CompareTag("badPoint"))
		{

			collision.gameObject.GetComponent<PointLogic>().OnEaten();

            AddReward(-0.2f);

            badPointAmount += 1;

			if (contribute)
			{
				myAcademy.totalScore -= 0.2;
			}


		}

        if (collision.gameObject.CompareTag("Snatcher"))
        {

            //Debug.Log("SEEN BY SNATCHER!");
            seenBySnatcher += 1;

            AddReward(-1.0f);
            if (contribute)
            {
                myAcademy.totalScore -= 1.0;
            }

        }
        if (collision.gameObject.CompareTag("wall"))
		{
			wallTouch += 1;
		}
    }

	// Override the AgentOnDone method.
	public override void AgentOnDone()
	{
	}


	// Agents scale is set to [1, 1, 1]
	public void SetAgentScale()
    {
        float agentScale = myAcademy.FloatProperties.GetPropertyWithDefault("agent_scale", 1.0f);
        gameObject.transform.localScale = new Vector3(agentScale, agentScale, agentScale);
    }

    // SetResetParameters method resets the agent scale.
    public void SetResetParameters()
    {
        SetAgentScale();
    }


}
