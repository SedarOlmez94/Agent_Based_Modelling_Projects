/*
 * Author: Sedar Olmez
 * The academy is part of the MLAgents toolkit https://github.com/Unity-Technologies/ml-agents and
 * is required if the model is to be trained using RL algorithms. The academy defines the parameters
 * of the model and resets the model to an initial state every iteration of the training process.
 * This class extends the Academy class in the MLAgents SDK and is compulsory. 
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine;
using MLAgents;

public class PredatorPreyAcademy : Academy
{   // Both the agents and listArea variables are not visible in the inspector.
    [HideInInspector]
    // The agents array is of type GameObject.
    public GameObject[] agents;
	[HideInInspector]
    // The listArea variable is an array of type Environment.
	public PPEnvironment[] listArea;

	// Total score integer variable.
	public double totalScore;
    // Score text variable of type Text.
	public Text scoreText;

	// Resetting the environment to initial state.
	public override void AcademyReset()
	{
        // All point objects are cleared from the scene.
		ClearObjects(GameObject.FindGameObjectsWithTag("goodPoint"));
		ClearObjects(GameObject.FindGameObjectsWithTag("badPoint"));
        /* The agents variable is inisitalised to contain all objects with
         * tag "agent" being all agents.
         */
		agents = GameObject.FindGameObjectsWithTag("agent");
		

        // The listArea variable is initialised to contain the Environment object.
		listArea = FindObjectsOfType<PPEnvironment>();

        /* For all the elements in the Environment, reset their point by
         * using the ResetPointArea method in the Environment.cs script.
        */
		foreach(var fa in listArea){
			fa.ResetPointArea(agents);

		}


        // Set the totalScore to 0;
        totalScore = 0;

	}

    // Simple method ClearObjects removes all the point in the environment.
	void ClearObjects(GameObject[] objects){
		foreach (var points in objects){
			Destroy(points);
		}
	}

    // Each step of the training process the total score is displayed.
	public override void AcademyStep(){
		scoreText.text = string.Format(@"Score: {0}", totalScore);
		//Debug.Log("TOTAL SCORE during training; " + " " + totalScore);
	}

}
