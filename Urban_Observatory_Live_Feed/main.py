from mesa_agent_skeleton import MyAgent
from mesa_agent_skeleton import MyModel
from mesa.batchrunner import BatchRunner
from mesa.visualization.modules import CanvasGrid
from mesa.visualization.ModularVisualization import ModularServer


# Parameter to be tested is n_agents where we try 1 to 20 each run.
parameters = {"n_agents": range(1, 20)}

# Agent visualisation on GRID
def agent_portrayal(agent):
    portrayal = {"Shape": "circle",
                "Filled": "true",
                "Layer": 0,
                "Color": "red",
                "r": 0.5}
    return portrayal


grid = CanvasGrid(agent_portrayal, 20, 20, 500, 500)


# The batch runner object
batch_run = BatchRunner(MyModel, parameters, max_steps = 10,
                        model_reporters= {"n_agents": lambda m: m.schedule.get_agent_count()})
'''
max_steps: Upper limit of steps above which each run will be halted
                if it hasn't halted on its own.
'''
server = ModularServer(MyModel,
                        [grid],
                        "My Model",
                        {'n_agents': 10})


batch_run.run_all()

# Once the run is over, we can create a pandas dataframe
batch_df = batch_run.get_model_vars_dataframe()

batch_df

server.launch()
