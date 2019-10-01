from MoneyModel import MoneyModel
import matplotlib.pyplot as plt
import numpy as np


all_wealth = []
#for j in range(100):
model = MoneyModel(50, 10, 10)
for i in range(100):
    model.step()
# Store the results
for agent in model.schedule.agents:
    all_wealth.append(agent.wealth)

"""
Firstly we create an empty numpy array with the same size width and heigth
as the grid. Then we populate this array with zeroes.
"""
agent_counts = np.zeros((model.grid.width, model.grid.height))
# For each cell content in the grid,
for cell in model.grid.coord_iter():
    #cell_content, x and y variables store the content and cell coordinates i.e.
    # returned parameters [content, x coordinate, y coordinate]
    cell_content, x, y = cell
    # agent_count variable is initialised to the length of the cell_content variable.
    agent_count = len(cell_content)
    # Agent_counts variable is a 2D array which contains all the agents.
    agent_counts[x][y] = agent_count


gini = model.datacollector.get_model_vars_dataframe()
# Create a heatmap of the agent counts on each grid cell
plt.imshow(agent_counts, interpolation='nearest')
plt.colorbar()
gini.plot()
plt.show()
