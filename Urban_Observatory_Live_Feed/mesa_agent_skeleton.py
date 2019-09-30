# MESA.Agent skeleton code


from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.space import MultiGrid


class MyAgent(Agent):
    def __init__(self, name, model):
        super().__init__(name, model)
        self.name = name

    def step(self):
        print("{} activated".format(self.name))
        # Agent actions when it is activated go within the step method.
