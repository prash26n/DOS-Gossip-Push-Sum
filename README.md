### Group Members
- Brandon Nunez (_UFID_: **05399493**) ([nunezb@ufl.edu](mailto:nunezb@ufl.edu))
- Prashant Singh (_UFID_: **29611035**) ([prash26n@ufl.edu](mailto:prash26n@ufl.edu))

### Execution Instructions
Traditional [mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) structure is maintained. Execution script can be found at lib\proj2.exs

To execute, traverse to the directory containing _mix.exs_ file and execute `mix run lib\project2.ex numNodes topology algorithm`.

For bonus use this command: `mix run lib\project2.ex numNodes topology algorithm <optional_parameter>` 

The parameter must be between 0.0 and 1.0 

The output is the time until convergence (a timer is started at the beginning of the node communication and stopped at the end). If there is no output, the network never converges or changes after 10 seconds.


### Implementation
Convergence of **Gossip** and **Push-Sum** Algorithm for all topologies
> Full<br />
> Line<br />
> Imperfect line<br />
> Random 2D<br />
> 3D<br />
> Torus<br />


### Largest Network: 
##### Gossip and Push-Sum:

> 9000 nodes for all toplogies
