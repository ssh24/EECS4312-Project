------------------------------ MODULE tracker ------------------------------
\* Packages
EXTENDS Integers, TLC

\* Constants
CONSTANTS
    N,
    CID, \* set of all possible container identifiers
    PID \* set of all possible phase identifiers
    
ASSUME
    N > 0
    

MATERIAL == {"glass", "metal", "plastic", "liquid"} \* the only materials each container is expected to have
ERROR == {"ok", "E1", "E2", "E3", "E4", "E5", "E6"} \* one error for each action
\* Note:
\* E1: maps to errors from new_tracker action (e1, e2, e3, e4)
\* E2: maps to errors from new_phase action (e1, e5, e6, e7, e8)
\* E3: maps to errors from new_container action (e5, e9, e10, e11, e12, e13, e14, e18)
\* E4: maps to errors from remove_container action (e15)
\* E5: maps to errors from remove_phase action (e1, e9)
\* E6: maps to errors from move_contaier action (e9, e11, e12, e13, e15, e16, e17)

\* set of all phase records
PHASE == [capacity:Int, curr_cont: Int, curr_rad: Int, exp_mats: SUBSET MATERIAL]
CONTAINER == [radioactivity: Int, curr_phase: PID, mat: MATERIAL] \* set of all container records
VALUE == 0 .. N \* used for defining numbers for radioactivity. Abstracting away from decimals

\* Variables
VARIABLES
    cid,   \* set of container ids in the tracker
    containers,  \* set of functions mapping from CID to CONTAINER
    pid,   \* set of phase ids in the tracker
    phases,  \* set of functions mapping from PID to PHASE
    mpr,    \* the maximum radiation allowed in a phase
    mcr,    \* the maximum radiation allowed in a container
    e   \* error message holder
    
\* Helper Functions used for remvoving element from domain and range from function
\* Subtraction on domain of f for set S: This was obtained from Course Forum User amin9 **
DomSub(S, f) == [x \in DOMAIN f \ S |-> f[x]]
\* Subtraction on range of f for set S: This was obtained from Course Forum User amin9 **
RanSub(f, S) == [x \in {y \in DOMAIN f: f[y] \notin S} |-> f[x]]
 




    
\***** INVARIANTS *****

\* type invariant
TypeOK == /\ e \in ERROR
          /\ pid \subseteq PID
          /\ cid \subseteq CID
          /\ phases \in [pid -> PHASE]
          /\ containers \in [cid -> CONTAINER]
          /\ mpr \in Int
          /\ mcr \in Int
    
          
\* checking radioactivity is within limits of tracker
SafeRadioactivity == /\ \A id \in pid: /\ 0 <= phases[id].curr_rad
                                       /\ phases[id].curr_rad <= mpr
                     /\ \A id \in cid: /\ 0 <= containers[id].radioactivity
                                       /\ containers[id].radioactivity <= mcr   
                                       
\* checking that all phases are within capacity in terms of the number containers in them
PhasesNotOverCapacity == \A id \in pid: /\ 0 <= phases[id].curr_cont
                                        /\ phases[id].curr_cont <= phases[id].capacity

\* All containers are in a phase that exists in the tracker
AllContainersInPhase == \A id \in cid: containers[id].curr_phase \in pid 




\***** ACTIONS *****


new_tracker(p,c) ==
    /\ p >= 0 \* max phase radiation is non-negative
    /\ c >= 0 \* max container radiation is non-negative
    /\ p >= c \* max container radiation cannot be greater than max phase radiation
    /\ cid = {} \* there should be no containers in tracker
    \* ____guard ends here____
    /\cid'=cid 
    /\containers'= containers 
    /\pid'=pid
    /\phases'=phases 
    /\mpr'=p \* set the values for maximum phase and container radiation
    /\mcr'=c    
    /\e'="ok"
    /\ Print(<<"new_tracker", p, c>>, TRUE) 
    
    
    
    
    
new_phase(p, cap, mats) ==
    /\ p \notin pid \* phase id must not already exist
    /\ cap > 0 \* capacity must be positive
    /\ mats \subseteq MATERIAL \* check that expected materials is subset of all possible MATERIALs
    /\ cid = {} \* there should be no containers in tracker
    \* ____guard ends here____
    /\cid'=cid 
    /\containers'= containers 
    /\pid'=pid \union {p} \* add new id to set of phase ids and extend phase function with a new record
    /\phases'=phases @@ p:>[capacity |-> cap, curr_cont |-> 0, curr_rad |-> 0, exp_mats |-> mats]  
    /\mpr'=mpr    
    /\mcr'=mcr    
    /\e'="ok"
    /\ Print(<<"new_phase", p, cap>>, TRUE) 
    
new_container(c, rad, p, m) == 
    /\ c \notin cid \* container id must not already exist
    /\ p \in pid \* make sure the phase exists
    /\ rad >= 0 /\ rad <= mcr \* radiation must be within limits of tracker
    /\ phases[p].curr_rad + rad <= mpr \* make sure the phase radiation won't exceed
    /\ phases[p].curr_cont + 1 <= phases[p].capacity \* and capacity won't exceed
    /\ m \in MATERIAL /\ m \in phases[p].exp_mats \* check phase accepts this material
    \* ____guard ends here____
    /\cid'=cid \union {c} \* add new id to set of ids and extend container function with new record
    /\containers'= containers @@ c:>[radioactivity |-> rad, curr_phase |-> p, mat |-> m]  
    /\pid'=pid \* update the phase by adding new container to it. That is update the radiation and count
    /\phases'=[phases EXCEPT ![p].curr_rad = @ + rad, ![p].curr_cont = @ + 1] 
    /\mpr'=mpr    
    /\mcr'=mcr    
    /\e'="ok"
    /\ Print(<<"new_container", c, rad, p>>, TRUE) 
    
remove_container(c) ==
    /\ c \in cid \* this container must exist
    \* ____guard ends here____
    /\pid'=pid \* update phase by removing container from it
    /\phases'=[phases EXCEPT 
                ![containers[c].curr_phase].curr_rad = @ - containers[c].radioactivity, 
                ![containers[c].curr_phase].curr_cont = @ - 1]
    /\cid'=cid \ {c} \* remove id from set of container ids and also remove the id from the
    /\containers = RanSub(containers, {c}) \* domain and the record from the range
    /\containers'= DomSub({c}, containers) \* of containers function
    /\mpr'=mpr    
    /\mcr'=mcr    
    /\e'="ok" /\ Print(<<"remove_container", c>>, TRUE) 

remove_phase(p) ==
    /\ p \in pid \* this phase must exist
    /\ cid = {} \* cannot remove phase when there are containers currently in tracker
    \* ____guard ends here____
    /\cid'=cid 
    /\containers'= containers 
    /\pid'=pid \ {p} \* remove id from set of phase ids
    /\phases = RanSub(phases, {p}) \* remove id from domain and record from range
    /\phases'=DomSub({p}, phases) \* of phases function
    /\mpr'=mpr    
    /\mcr'=mcr    
    /\e'="ok"
    /\ Print(<<"remove_phase", p>>, TRUE)

move_container(c, p1, p2) ==
    /\ c \in cid \* check container exists
    /\ p1 \in pid /\ p2 \in pid \* check phases exist
    /\ p1 /= p2 \* source and destination phases must be different
    /\ containers[c].curr_phase = p1 \* container should be in source phase
    /\ phases[p2].curr_rad + containers[c].radioactivity <= mpr \* safe radiation
    /\ phases[p2].curr_cont + 1 <= phases[p2].capacity \* and capacity on destination should not exceed 
    /\ containers[c].mat \in phases[p2].exp_mats \* check destination phase accepts container material
    \* ____guard ends here____
    /\cid'=cid \* update record of container with the new phase it is in
    /\containers'=[containers EXCEPT ![c].curr_phase=p2]
    /\pid'=pid \* update phase records by removing container from p1 and adding it to p2
    /\phases'=[phases EXCEPT 
                ![p1].curr_rad = @ - containers[c].radioactivity, 
                ![p1].curr_cont = @ - 1,
                ![p2].curr_rad = @ + containers[c].radioactivity, 
                ![p2].curr_cont = @ + 1]
    /\mpr'=mpr    
    /\mcr'=mcr    
    /\e'="ok"
    /\ Print(<<"move_container", c, p1, p2>>, TRUE)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
\* ******** Defining INIT and NEXT ********

Init == /\ e = "ok" \* initialize error ok
        /\ mpr = 0 \* max phase radiation is 0
        /\ mcr = 0 \* max container radiation is 0
        /\ cid = {} \* empty set of container ids 
        /\ containers = <<>> \* make empty set of function from cid -> CONTAINER
        /\ pid = {} \* make emtpy set
        /\ phases = <<>> \* make empty set of function from pid -> PHASE
     
Next == \/ (\E p, c \in VALUE: new_tracker(p, c))
        \/ (\E p \in PID, cap \in VALUE, mats \in SUBSET MATERIAL: new_phase(p, cap, mats))
        \/ (\E c \in CID, rad \in VALUE, p \in PID, mat \in MATERIAL: new_container(c, rad, p, mat))
        \/ (\E c \in CID: remove_container(c))
        \/ (\E p \in PID: remove_phase(p))
        \/ (\E c \in CID, p1,p2 \in PID: move_container(c, p1, p2))

=============================================================================
