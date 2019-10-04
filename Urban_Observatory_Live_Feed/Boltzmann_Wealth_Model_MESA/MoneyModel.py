from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.space import MultiGrid
from mesa.datacollection import DataCollector
from mesa.batchrunner import BatchRunner
import matplotlib.pyplot as plt
import random
import pandas as pd


def compute_gini(model):
    # The Gini Coefficient formula computed in python.
    agent_wealths = [agent.wealth for agent in model.schedule.agents]
    # All the wealth variable values for agents.
    x = sorted(agent_wealths)
    # x is the sorted wealth i.e. lowest to highest
    N = model.num_agents
    # N is the number of agents.
    B = sum( xi * (N-i) for i, xi in enumerate(x) ) / (N * sum(x))
    return (1 + (1/N) - 2 * B)

def richer_agents(model):
    agent_wealths = [agent.wealth for agent in model.schedule.agents]
    for i in range(len(agent_wealths)):
        agent_wealths[i] += agent_wealths[i] + random.randint(10, 50)

    return agent_wealths
def batch_runner(width, height, iterations, max_steps, start, stop, range_):

    fixed_params = {
        "width": width,
        "height": height
    }

    variable_params = {"N": range(start, stop, range_)}

    # The variables parameters will be invoke along with the fixed parameters allowing for either or both to be honored.
    batch_run = BatchRunner(
        MoneyModel,
        variable_params,
        fixed_params,
        iterations=iterations,
        max_steps=max_steps,
        model_reporters={"Gini": compute_gini}
    )

    batch_run.run_all()
    batch_run_graph(batch_run)

def batch_run_graph(batch_run):
    run_data = batch_run.get_model_vars_dataframe()
    run_data.to_csv("results/monte_carlo_sim.csv")
    plt.scatter(run_data.N, run_data.Gini)
    plt.show()

def get_data_import(directory):
    dataframe = pd.read_csv(directory)
    return dataframe



class MoneyAgent(Agent):


    """ An agent with fixed initial wealth """
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)
        self.wealth = 1


    def move(self):
        possible_steps = self.model.grid.get_neighborhood(
            self.pos, # The first argument is the position of the moving agent
            moore = True, # Moore set to true means the agent can move diagonal
            include_center = False # Include the cell in which the agent is currently on.
        )
        # The new position is a randomly chosen position out of the possible_steps.
        new_position = self.random.choice(possible_steps)
        #
        self.model.grid.move_agent(self, new_position)


    def give_money(self):
        #Get the agents that are in the same grid cell as the selected agent
        cellmates = self.model.grid.get_cell_list_contents([self.pos])
        # If the number of agents in the gridcell is more than 1 then
        if len(cellmates) > 1:
            # Select one of the other agents at random and add 1 to its wealth
            other = self.random.choice(cellmates)
            other.wealth += 1
            # Subtract 1 from the selected agents wealth.
            self.wealth -= 1


    def step(self):
        # The agent's step will go here. I.e. actions
        self.move()
        if self.wealth > 0:
            self.give_money()

class MoneyModel(Model):


    """ A model with some number of agents. """
    def __init__(self, N, width, height):
        self.num_agents = N
        self.grid = MultiGrid(width, height, True)
        self.schedule = RandomActivation(self)
        self.running = True # Indefinite execution of the model.

        #Agent creation
        for i in range(self.num_agents):
            a = MoneyAgent(i, self) # initialising the agents in the model.
            self.schedule.add(a) # Add the agents to the schedular

            # Add the agent to a random grid cell
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)
            self.grid.place_agent(a, (x, y))

        self.datacollector = DataCollector(
            model_reporters = {"Gini": compute_gini}, #compute_gini function
            agent_reporters = {"Wealth": "wealth"} # wealth variable
        )


    def step(self):
        """ Advance the model by one step. """
        self.datacollector.collect(self)
        self.schedule.step() # The schedular is what makes the model run a step.

#                   5 iterations of 100 simulations = 5000 simulations.
batch_runner(10, 10, 5, 100, 10, 500, 10)
