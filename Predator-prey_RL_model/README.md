# Predator-prey model in Unity using ml-agents toolkit


This repository contains the agent-based model outlined in the "Investigating the emergence of complex behaviours in an agent-based model using reinforcement learning" paper. 


## Requirements
- Python programming language: https://www.python.org/downloads/
- Unity version **2018.4.15** can be downloaded via the Unity Hub from here: https://unity3d.com/get-unity/download
- Install **ml-agents** in python: https://github.com/Unity-Technologies/ml-agents/tree/master/ml-agents


## How to access the predator-prey model
ml-agents-master-2
- UnitySDK/
    - Assets/
        - predator-prey/
            - Brains/
              - neural_network_1.nn (This is the brain that was trained in 580,000 steps, referred to as Scenario_1 in the literature)
              - neural_network_2.nn (This is the brain that was trained in 1.000,000 steps, referred to as Scenario_2 in the literature)
              - neural_network_3.nn (This is the brain that was trained in 1.000,000 steps, without the Snatcher present, referred to as Scenario_3 in the literature)
            - Editor/
            - Materials/
            - Prefabs/
                - AgentCube.prefab
                - Environment.prefab
                - Snatcher.prefab
                - badPoint.prefab
                - goodPoint.prefab
            - Scenes/
                - predator_prey_scene.unity **(Double click this file to launch the initial configuration of the model).**
            - Scripts/
                - AISnatcher.cs
                - Collector.cs
                - PPEnvironment.cs
                - PointLogic.cs
                - PredatorPreyAcademy.cs


## Running the model
1. Once the **UnitySDK** folder is launched in Unity, you can navigate to **predator-prey/../Scenes** to launch the initial state of the model.
2. The Unity Prefabs are GameObjects as reusable Assets. We can access the AgentCube object which is the Collector agent. By opening this component you can swap out the Brain which initially is set to **neural_network_1.nn**.
3. By clicking the **play** button in the Unity window you can run the model which includes five **Collectors** and a single **Snatcher**.


## Data and experiment results
        - Access synthetic data from model-runs 1 to 5 in the **Synthetic-data-from-ABM** folder
        - Video of model-run-1 experiment can be found: [here](https://www.dropbox.com/s/c9571is9zz34hbe/Model-run-1.mov?dl=0) (due to a lack of dropbox space, model-runs 2 to 5 were not uploaded, email me for these: solmez@turing.ac.uk)
