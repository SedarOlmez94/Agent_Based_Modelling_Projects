from mesa_agent_skeleton import MyAgent
from mesa_agent_skeleton import MyModel


model = MyModel(5)
for t in range(10):
    model.step()
    #Here we create two variables which store dataframes of the collected data.
model_df = model.dc.get_model_vars_dataframe()
agent_df = model.dc.get_agent_vars_dataframe()
