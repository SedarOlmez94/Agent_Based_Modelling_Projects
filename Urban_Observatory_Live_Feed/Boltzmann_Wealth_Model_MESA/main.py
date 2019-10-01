from MoneyModel import MoneyModel
import matplotlib.pyplot as plt

all_wealth = []
for j in range(100):
    model = MoneyModel(50, 10, 10)
    for i in range(20):
        model.step()

    # Store the results
    for agent in model.schedule.agents:
        all_wealth.append(agent.wealth)

plt.hist(all_wealth, bins = range(max(all_wealth) + 1))
plt.show()
