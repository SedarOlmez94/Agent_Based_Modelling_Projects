from mesa_agent_skeleton import MyAgent
from mesa_agent_skeleton import MyModel
from mesa.batchrunner import BatchRunner

parameters = {"n_agents": range(1, 20)}

batch_run = BatchRunner(MyModel, parameters, max_steps = 10,
                        model_reporters= {"n_agents": lambda m: m.schedule.get_agent_count()})


batch_run.run_all()
