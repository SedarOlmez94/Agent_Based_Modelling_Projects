from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.space import MultiGrid



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

        #Agent creation
        for i in range(self.num_agents):
            a = MoneyAgent(i, self) # initialising the agents in the model.
            self.schedule.add(a) # Add the agents to the schedular

            # Add the agent to a random grid cell
            x = self.random.randrange(self.grid.width)
            y = self.random.randrange(self.grid.height)
            self.grid.place_agent(a, (x, y))


    def step(self):
        """ Advance the model by one step. """
        self.schedule.step() # The schedular is what makes the model run a step.
