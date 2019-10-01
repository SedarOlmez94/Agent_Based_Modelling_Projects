from mesa import Agent, Model


class MoneyAgent(Agent):
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)
        self.wealth = 1


class MoneyModel(Model):
    def __init__(self, N):
        self.num_agents = N
        #Agent creation
        for i in range(self.num_agents):
            a = MoneyAgent(i, self)
