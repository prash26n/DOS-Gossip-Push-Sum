defmodule Top do

  #helper function

  def nearestcube(n, i) when i*i*i < n do
    nearestcube(n, i + 1)
  end

  def nearestcube(_, i) do
    i
  end

  def distancenode(node1, node2) do
    x1 = elem(node1, 1)
    x2 = elem(node2, 1)
    y1 = elem(node1, 2)
    y2 = elem(node2, 2)
    :math.sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2))
  end

  def printnodelist(list) do
    Enum.each list, fn elem -> IO.inspect(elem) end
  end
  #end helper

  ##3D GRID##----------------------------------------------
  #i, n, alg, list of all nodes, adjacency list
  def connect_3D(i, cube, numNodes, nodes) when i < numNodes do

    #link every neighbor based on dimension of cube
    #indexing is based on 0 being top left of cube
    #define conditions when a neighbor is valid
    ncond = [
      {i + cube < numNodes, Enum.at(nodes, i + cube)}, #-z
      {i - cube >= 0, Enum.at(nodes, i - cube)}, #+z
      {rem(i, cube) != 0, Enum.at(nodes, i - 1)}, #-x
      {rem(i + 1, cube) != 0 && i + 1 < numNodes, Enum.at(nodes, i + 1)}, #+x
      {i + cube*cube < numNodes, Enum.at(nodes, i + cube*cube)}, #+y
      {i - cube*cube >= 0, Enum.at(nodes, i - cube*cube)}, #-y
    ]

    #fill adjacency list with valid conditions only
    adj = Enum.reduce(ncond, [], fn
      {true, item}, adj -> [item | adj]
      _, adj -> adj
    end)

      currentnode = Enum.at(nodes, i);
      GenServer.cast(currentnode, {:setnode, adj})
      #^^set actor nodes to adjacency list

    connect_3D(i + 1, cube, numNodes, nodes)
  end

  def connect_3D(_, _, _, nodes) do
    nodes
  end

  def start_3DGrid(numNodes, cube, nodes) do
    connect_3D(0, cube, numNodes, nodes)
  end
  ##END 3D GRID##-----------------------------------------

  ##FULLY CONNECTED##
  def loop_fullConnected(i, numNodes, nodes) when i < numNodes do
    node = Enum.at(nodes, i)

    #filter out self (cant point to self)
    adj = Enum.filter(nodes, fn el -> el != node end)
    GenServer.cast(node, {:setnode, adj})

    loop_fullConnected(i + 1, numNodes, nodes)
  end

  def loop_fullConnected(_, _, nodes) do
    nodes
  end

  def start_fullConnected(numNodes, nodes) do
    loop_fullConnected(0, numNodes, nodes)
  end
  ##END FULLY CONNECTED##

  ##START RANDOM2D##------------------------------------------
  def loop_random2D_closest(me, nodes) do #find all closest nodes

    Enum.each(nodes, fn(n) -> #iterate thru each node and add closest ones

      if (elem(me,0) != elem(n, 0) && distancenode(n, me) < 0.1) do
        GenServer.cast(elem(me,0), {:addnode, elem(n,0)})
      end #end IF
    end #end fn
      )
  end

  #outer loop
  def loop_random2D(i, numNodes, nodes, nodetuple) when i < numNodes do
    node = Enum.at(nodetuple, i)
    loop_random2D_closest(node, nodetuple)
    loop_random2D(i + 1, numNodes, nodes, nodetuple)
  end

  def loop_random2D(_, _, nodes, _) do
    nodes
  end

  def start_random2D(i, numNodes, nodes, nodetuple) when i < numNodes do
    x = :rand.uniform
    y = :rand.uniform
    node_group = {Enum.at(nodes,i), x, y}
    nodetuple = [node_group | nodetuple]
    start_random2D(i + 1, numNodes, nodes, nodetuple)
  end

  def start_random2D(_, numNodes, nodes, nodetuple) do
    loop_random2D(0, numNodes, nodes, nodetuple)
    nodes
  end
  ##END RANDOM2D##------------------------------------------

  ##TORUS##
  def loop_torus(i, numNodes, nodes) when i < numNodes do
    n =  numNodes # total nodes
    l = i # current node

    j = :math.sqrt(n) |> round #number of rows or column
      neighboursListIndex = cond do
          #left node, 2 neighbors [next node and last node]
            rem(l,j) == 0 -> [l+1,l+j-1]
          #right node, 2 neihbors [previous node and first node]
            rem(l+1,j) == 0 -> [l-1,l+1-j]
          #top node, 2 neighbors [below row and end row]
            l-j<0 -> [l+j,n-j+l]
          #bottom node, 2 neighbors [previous row and top row]
            l - (n-j) >= 0 -> [l-j, n-l-j]
          #else
            true -> [l-1,l+1,l-j,l+j]
        end

        #get xth node and make adj list
        neighboursList = Enum.map(neighboursListIndex,
        fn(x) -> Enum.at(nodes,x) end
        )

        #send message with neighboursList
        currentnode = Enum.at(nodes, i)
        GenServer.cast(currentnode, {:setnode, neighboursList})

    loop_torus(i + 1, numNodes, nodes)
  end

  def loop_torus(_,_,nodes) do
    nodes
  end

  def start_torus(numNodes, nodes) do
    loop_torus(0, numNodes, nodes)
  end
  ##END TORUS##

  ##LINE##
  def loop_line(i, numNodes, nodes) when i < numNodes do
   neighboursListIndex =  cond do
          i == 1 -> [i+1]
          i == numNodes -> [i-1]
          true -> [i-1,i+1]
    end

    #get xth node and make adj list
    neighboursList = Enum.map(neighboursListIndex,
    fn(x) -> Enum.at(nodes,x) end
    )

    #send setnode adj
    #send message with neighboursList
    currentnode = Enum.at(nodes, i)
    GenServer.cast(currentnode, {:setnode, neighboursList})

    loop_line(i + 1, numNodes, nodes)
  end

  def loop_line(_,_,nodes) do
    nodes
  end

  def start_line(numNodes, nodes) do
    loop_line(0, numNodes, nodes)
  end
  ##END LINE##

  ##IMPERFECT LINE##
  def loop_impline(i, numNodes, nodes) when i < numNodes do
      neighboursListIndex =  cond do
        i == 1 -> [i+1]
        i == numNodes -> [i-1]
        true -> [i-1,i+1]
      end

      rnd = impLineRand(numNodes, neighboursListIndex, i)
      neighboursListIndex = neighboursListIndex ++ [rnd]

      #get xth node and make adj list
      neighboursList = Enum.map(neighboursListIndex,
      fn(x) -> Enum.at(nodes,x) end
      )

      #send message with neighboursList
      currentnode = Enum.at(nodes, i)
      GenServer.cast(currentnode, {:setnode, neighboursList})

    loop_impline(i + 1, numNodes, nodes)
  end

  def loop_impline(_,_,nodes) do
    nodes
  end

  def start_impline(numNodes, nodes) do
    loop_impline(0, numNodes, nodes)
  end

  ##ADDED RAND UTLITY##
  #utility to generate random other than itslef
  def impLineRand(n, neighbor,l) do
    ran = :rand.uniform(n)
    if ran == l or Enum.member?(neighbor, ran) == true do
        impLineRand(n, neighbor, l)
    else
        ran
    end
  end
  #END RAND UTILITY#

  ##END IMPLINE##
end

defmodule Alg do
  def wirenetwork(list, numNodes, arg2) do

    #match topology argument
    cond do
      arg2 == "3D" ->
        Top.start_3DGrid(numNodes, Top.nearestcube(numNodes, 0), list)
      arg2 == "rand2D" ->
        Top.start_random2D(0, numNodes, list, [])
      arg2 == "full" ->
        Top.start_fullConnected(numNodes, list)
      arg2 == "torus" ->
        Top.start_torus(numNodes, list)
      arg2 == "line" ->
        Top.start_line(numNodes, list)
      arg2 == "imp2D" ->
        Top.start_impline(numNodes, list)
    end
  end

  #generate nodes
  def generate(i, "gossip", numNodes, list, master) when i < numNodes do
    {:ok, id} = GenServer.start_link(Gossip, [0, master, [], nil, 0], name: :"#{i}")

    #save node into storage
    list = [id | list]

    generate(i + 1, "gossip", numNodes, list, master)
  end

  def generate(i, "push-sum", numNodes, list, master) when i < numNodes do
    #pass s, w, count, master, edges, self
    {:ok, id} = GenServer.start_link(PushSum, [i, 1, 0, master, [], nil, 0],
     name: :"#{i}")
     GenServer.cast(id, {:addself, id})

    #save node into storage
    list = [id | list]

    generate(i + 1, "push-sum", numNodes, list, master)
  end

  def generate(_,_,_, list, _) do
    list #return list
  end

end

defmodule MasterActor do
  use GenServer

  def init(msg) do
    {:ok, msg}
  end

  #======casts=========================#
  def handle_cast({:settimer, timer}, data) do
    data = List.replace_at(data, 3, timer)
    {:noreply, data}
  end

  def handle_cast({:setoffline}, data) do
    nodes = Enum.at(data, 0)
    count = Enum.at(data, 1) + 1
    f = Enum.at(data, 2)
    t = Enum.at(data,3)

    #IO.puts("#{count} / #{length(nodes)} finished")

    {:noreply, [nodes,count,f,t]}
  end

  def handle_cast({:setnodes, list}, data) do
    count = Enum.at(data, 1) #add nodes list
    f = Enum.at(data, 2)
    t = Enum.at(data, 3)

    {:noreply, [list,count,f,t]}
  end

  def handle_cast({:first}, data) do
    nodes = Enum.at(data, 0)
    count = Enum.at(data, 1)
    f = Enum.at(data,2)
    f = if (f < length(nodes)) do f + 1 else f end

    if (f == length(nodes) - 1) do
      time = System.system_time(:millisecond) - Enum.at(data, 3)
      IO.puts("time = #{time}")
    end

    t = Enum.at(data, 3)

    {:noreply, [nodes,count, f, t]}
  end

  def handle_cast({:tick}, data) do
    nodes = Enum.at(data, 0)

    #IO.puts("#{Enum.at(data,2)} / #{length(nodes)} heard a rumor or were visited")

    {:noreply, data}
  end

  def handle_cast({:reviveme, node}, data) do
    GenServer.cast(node, {:wakeup})
    {:noreply, data}
  end
  #======calls=========================#

  def handle_call({:numdone}, _, data) do
    #send count back
    {:reply, Enum.at(data,1), data}
  end

end

defmodule Gossip do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(msg) do
    {:ok, msg}
  end

  def handle_cast({:killme}, data) do
     data = List.replace_at(data, 4, 1) #set dead flag
     {:noreply, data}
  end

  def handle_cast({:wakeup}, data) do
    data = List.replace_at(data, 4, 0) #set dead flag
    {:noreply, data}
  end

  def handle_cast({:addnode, node}, data) do
    rumorcount = Enum.at(data,0) #update rumor count
    master = Enum.at(data,1)
    edges = Enum.at(data,2)
    me = Enum.at(data,3)
    dead = Enum.at(data,4)

    edges = [node | edges]

    {:noreply, [rumorcount, master, edges, me, dead]}
  end

  #receives message with adj list
  def handle_cast({:setnode, list}, data) do
    data = List.replace_at(data, 2, list)
    {:noreply, data} #update data
  end

  def handle_cast({:addself, me}, data) do #update ptr 2 self
    data = List.replace_at(data, 3, me)
    {:noreply, data} #update
  end

  #gossip procedure
  def handle_cast({:msg}, data) do
    rumorcount = Enum.at(data,0) + 1 #update rumor count
    master = Enum.at(data,1)
    edges = Enum.at(data,2)
    me = Enum.at(data,3)
    dead = Enum.at(data,4)

    if (rumorcount == 1 && dead == 0) do #rumor  first time
      GenServer.cast(master, {:first})
    end

    len = length(edges) - 1

    #protect against 1-length lists
    neighbor = cond do
          len < 0 -> nil
          len == 0 -> Enum.at(edges, 0)
        #else
          true -> Enum.at(edges, :rand.uniform(len) )
      end

    #terminate upon this amount
    if (rumorcount == 10) do
      #do nothing significant
       GenServer.cast(master, {:setoffline})
    else #if not keep going
      if (neighbor != nil && dead == 0) do
        Gossip.add_message(neighbor)
      end
    end

    {:noreply, [rumorcount, master, edges, me, dead]} #update
  end

  def add_message(pid) do
    GenServer.cast(pid, {:msg})
  end
end #end module

defmodule PushSum do
  use GenServer

 def start_link do
   GenServer.start_link(__MODULE__, [])
 end

 def init(msg) do
   {:ok, msg}
 end

 def handle_cast({:killme}, data) do
    data = List.replace_at(data, 6, 1) #set dead flag
    {:noreply, data}
 end

 def handle_cast({:wakeup}, data) do
   data = List.replace_at(data, 6, 0) #set dead flag
   {:noreply, data}
 end

 def handle_cast({:addnode, node}, data) do
   myS = Enum.at(data,0)
   myW = Enum.at(data,1)
   count = Enum.at(data,2)
   master = Enum.at(data,3)
   edges = Enum.at(data,4)
   me = Enum.at(data,5)
   dead = Enum.at(data,6)

   edges = [node | edges]

   {:noreply, [myS, myW, count, master, edges, me, dead]}
 end

def handle_cast({:addself, me}, data) do
  data = List.replace_at(data, 5, me)
  {:noreply, data}
end

#receives message with adj list
def handle_cast({:setnode, edges}, data) do
  data = List.replace_at(data, 4, edges)
  {:noreply, data} #update data
end

 #push sum procedure
 def handle_cast({:msg, [otherS, otherW]}, data) do
   myS = Enum.at(data,0)
   myW = Enum.at(data,1)
   count = Enum.at(data,2)
   master = Enum.at(data,3)
   edges = Enum.at(data,4)
   me = Enum.at(data,5)
   dead = Enum.at(data, 6)

   ns = myS + otherS
   nw = myW + otherW

   curSW = myS/myW
   newSW = ns/nw

   if (myW == 1 && dead == 0) do #rumor  first time
     GenServer.cast(master, {:first})
   end

   count = if (dead == 0 && Kernel.abs(curSW - newSW) < 0.000000001) do
     count + 1
   else
     count
   end

   newdata = if (dead == 0) do
     [ns/2, nw/2, count, master, edges, me, dead]
   else
     [myS, myW, count, master, edges, me, dead] #cant change since offline
   end

   len = length(edges) - 1

   #protect against 1-length lists
   neighbor = cond do
         len < 0 -> nil
         len == 0 -> Enum.at(edges, 0)
       #else
         true -> Enum.at(edges, :rand.uniform(len) )
     end

   if (count >= 3 && dead == 0) do #done
     GenServer.cast(master, {:setoffline})
   else
     #send message to neighbor
     if (neighbor != nil && dead == 0) do
       PushSum.add_message(neighbor, [ns/2, nw/2])
     end
   end

   {:noreply, newdata} #update
 end

  def add_message(pid, [s,w]) do
    GenServer.cast(pid, {:msg, [s,w]})
  end
end #end module

defmodule Project2 do
use Application

  def launch(nodes, master, [x, i, p, b]) do

    if (b == 0 && p > 0.0) do
    #--bonus--# if (rand < p) shut down node for small time
    xx = Enum.filter(nodes, fn(_) -> :rand.uniform < p end)

      Enum.each xx, fn n -> GenServer.cast(n, {:killme}) end
      :timer.sleep(10)
      Enum.each xx, fn n -> GenServer.cast(n, {:wakeup}) end

    end

    #expect callback, so use call and not cast
    numdone = GenServer.call(master, {:numdone})

    :timer.sleep(1000)

    i = if (numdone == x) do i + 1 else 0 end #if system hasnt changed, ++
    x = numdone

    if (i < 5) do #keep going
      launch(nodes, master, [x, i, p, 1])
    else
      #after some time stop (system hasnt changed)
      GenServer.cast(master, {:tick}) #check stats
      :timer.sleep(100)
      System.halt(0)
    end #end if

  end #end launch

  def init([arg1,arg2,arg3,arg4]) do

    #input validation======================
    if (arg3 != "gossip" && arg3 != "push-sum") do
      IO.puts("Algorithm argument invalid")
      System.halt(0)
    end
    #======================================

    #numnodes
    numNodes = String.to_integer(arg1)

    if (numNodes < 2) do
      IO.puts("Must have 2 or more nodes")
      System.halt(0)
    end

    #topology handled at generation

    #param p
    p = String.to_float(arg4)

    if (p > 1.0 || p < 0.0) do
      IO.puts("parameter illegal value: 0.0 <= p <= 1.0")
      System.halt(0)
    end

    #start network
    {:ok, master} = GenServer.start_link(MasterActor, [[],0,0,p], name: :master)

    list = Alg.generate(0, arg3, numNodes, [], master)

    timer = System.system_time(:millisecond)

    #give master node list in case we want to analyze them over time
    GenServer.cast(master, {:setnodes, list})

    #set up topology
    Alg.wirenetwork(list, numNodes, arg2)

    #randomly select a starting node
    startnode = Enum.at(list,:rand.uniform(length(list) - 1) )

    #record time
    GenServer.cast(master, {:settimer, timer})

    #set algorithm
    if (arg3 == "gossip") do
      Gossip.add_message(startnode) #launch gossip procedure
    else
      PushSum.add_message(startnode, [0,0]) #launch pushsum procedure
    end

    launch(list,master,[0,0,p,0])
  end

  def init([arg1,arg2,arg3]) do
    init([arg1,arg2,arg3,"0.0"])
  end

  def start(_,_) do
      [numN, topology, algorithm] = System.argv()
      init([numN,topology,algorithm])
  end

end
