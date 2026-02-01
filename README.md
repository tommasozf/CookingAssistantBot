# GLadOS Agent

A conversational agent for recommending recipes using speech interaction.

## Repository Structure

As outlined in the [project deliverables](https://socialrobotics.atlassian.net/wiki/spaces/PCA21/pages/3117780447/Project+Deliverables) section:

- ```main``` "contains the full codebase for inclusion, exclusion and all extensions. It contains the full code we ran during the agent grading session with our TA;
- ```inclusion-only``` contains the codebase with inclusion logic only
- ```inclusion_exclusion``` contains the codebase for inclusion and exclusion logic combined
- ```whisper-on-gpu``` contains our parallel efforts to use whisper instead of google-stt for speech recognition. We ended up using the latter in the final pipeline, but for the record, and to document our efforts, we left this working branch in the repository. Trying to run the agent from this branch will most likely not result in a successful attempt.



## Running the Agent

### Prerequisites

- Conda environment `PCA26` configured

### Start

Follow the instructions [here](https://socialrobotics.atlassian.net/wiki/spaces/PCA21/pages/3117779539/Run+your+Conversational+Agent), or simply:

```bash
./start_all_tmux.sh
```

This launches all components (Redis, Google STT, NLU, Webserver, Framework, EIS) in separate tmux windows.

You will also need to separately run the dialogmngr-pca2026-basic.mas2g file in the Eclipse IDE and go to http://localhost:8080/start.html to interact with the agent.

### Tmux Controls

| Command | Action |
|---------|--------|
| `tmux attach -t sic` | Reattach to session |
| `Ctrl+b` then `0-5` | Switch windows |
| `Ctrl+b` then `n/p` | Next/Previous window |
| `Ctrl+b` then `d` | Detach |
| `Ctrl+b` then `:kill-session` | Stop all |