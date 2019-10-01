from mesa import Agent, Model
from mesa.time import RandomActivation

class MoneyAgent(Agent):
    """ An agent with fixed initial wealth """
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)
        self.wealth = 1

    def step(self):
        # The agent's step will go here. I.e. actions
        pass

class MoneyModel(Model):
    """ A model with some number of agents. """
    def __init__(self, N):
        self.num_agents = N
        self.schedule = RandomActivation(self)
        #Agent creation
        for i in range(self.num_agents):
            a = MoneyAgent(i, self) # initialising the agents in the model.
            self.schedule.add(a) # Add the agents to the schedular

    def step(self):
        """ Advance the model by one step. """
        self.schedule.step() # The schedular is what makes the model run a step.
