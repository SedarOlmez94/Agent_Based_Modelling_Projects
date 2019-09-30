# MESA.Agent skeleton code


from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.space import MultiGrid
from mesa.datacollection import DataCollector


class MyAgent(Agent):
    def __init__(self, name, model):
        super().__init__(name, model)
        self.name = name

    def step(self):
        print("{} activated".format(self.name))
        # Agent actions when it is activated go within the step method.


class MyModel(Model):
    def __init__(self, n_agents):
        super().__init__()
        self.schedule = RandomActivation(self)
        self.grid = MultiGrid(10, 10, torus = True)
        for i in range(n_agents):
            a = MyAgent(i, self)
            self.schedule.add(a) # Add agent(s) to schedular
            coords = (self.random.randrange(0, 10), self.random.randrange(0, 10))
            # The coordinates which are randomly generated for each agent.
            self.grid.place_agent(a, coords)
        self.dc = DataCollector(model_reporters = {"agent_count" :
                                        lambda m: m.schedule.get_agent_count()},
                                        agent_reporters = {"name": lambda a: a.name})
        # Data collected is agent counts from the model and
        # Name from the agents.

    def step(self):
        self.schedule.step()
        self.dc.collect(self)
