note
	description: "A default business model."
	author: "Jackie Wang"
	date: "$Date$"
	revision: "$Revision$"

class
	WTRACKER

inherit
	ANY
		redefine
			out
		end

create {ETF_MODEL_ACCESS}
	make

feature {NONE} -- Initialization
	make
			-- Initialization for `Current'.
		do
			-- here create all the maps to store the phases as well as material list

			create status.make_empty
			create phases.make (0)
			create containers.make (0)


			create materials.make_empty
			materials.force ("glass", 1)
			materials.force ("metal", 2)
			materials.force ("plastic", 3)
			materials.force ("liquid", 4)

			status:= "ok" -- initialize to okay


			create errors.make

			status:= errors.ok

			i := 0
		end

feature -- model attributes

	status : STRING
	i : INTEGER
	max_phase_rad: VALUE
	max_container_rad: VALUE

	phases: HASH_TABLE[PHASE, STRING]

	containers: HASH_TABLE[WCONTAINER, STRING]

	materials : ARRAY[STRING]

	errors: WERRORS



feature -- model operations
	default_update
			-- Perform update to the model state.
		do
			i := i + 1
		end

	reset
			-- Reset model state.
		do
			make
		end



	new_tracker( mpr: VALUE ; mcr: VALUE)
		do
			if containers.count > 0 then
				status:= errors.e1
			elseif mpr < 0.000 then
				status:= errors.e2
			elseif mcr < 0.000 then
				status:= errors.e3
			elseif mcr > mpr then
				status:= errors.e4
			else
				max_phase_rad := mpr
				max_container_rad := mcr

				status:= errors.ok -- set status to ok
			end

			i := i + 1
		end


	new_phase(pid: STRING ; phase_name: STRING ; capacity: INTEGER_64 ; expected_materials: ARRAY[INTEGER_64])
		local
			np:PHASE
		do
			if containers.count > 0 then
				status:= errors.e1
			elseif not pid.at (1).is_alpha_numeric then
				status:= errors.e5
			elseif phases.has (pid) then
				status:= errors.e6
			elseif not phase_name.at (1).is_alpha_numeric then
				status:= errors.e5
			elseif capacity < 1  then
				status:= errors.e7
			elseif expected_materials.count < 1 then
				status:= errors.e8
			else

				create np.create_phase (pid, phase_name, capacity, expected_materials)
				phases.put(np, pid)

				status:= errors.ok -- set status to ok
			end

			i := i + 1
		end



	new_container(cid: STRING ; c: TUPLE[material: INTEGER_64; radioactivity: VALUE] ; pid: STRING)
		local
			nc:WCONTAINER
		do
			if not cid.at (1).is_alpha_numeric then
				status:= errors.e5
			elseif containers.has (cid)	then
				status:= errors.e10
			elseif not pid.at (1).is_alpha_numeric	then
				status:= errors.e5
			elseif not phases.has (pid)	then
				status:= errors.e9
			elseif c.radioactivity < 0.000	then
				status:= errors.e18
			else

				if attached phases.item (pid) as ph then

					if ph.will_exceed_capacity then
						status:= errors.e11
					elseif c.radioactivity > current.max_container_rad then
						status:= errors.e14
					elseif ph.p_current_radioactivity + c.radioactivity > current.max_phase_rad then
						status:= errors.e12
					elseif not ph.accepts_material(c.material.as_integer_32) then
						status:= errors.e13
					else
						create nc.create_container (cid, c, pid)
						containers.put(nc, cid)
						ph.add_material (c.radioactivity)

						status:= errors.ok -- set status to ok
					end
				end
			end

			i := i + 1
		end


	move_container(cid: STRING ; pid1: STRING ; pid2: STRING)

		do
			if not containers.has (cid) then
				status:= errors.e15
			elseif pid1.is_equal (pid2) then
				status:= errors.e16
			elseif not( phases.has (pid1) and phases.has (pid2) ) then
				status:= errors.e9
			else

				if
					attached phases.item (pid1) as ph1 and
					attached phases.item (pid2) as ph2 and
					attached containers.item (cid) as cn
				then

					if not cn.p_pid.is_equal (pid1) then
						status:= errors.e17
					elseif ph2.will_exceed_capacity then
						status:= errors.e11
					elseif ph2.p_current_radioactivity + cn.c_radioactivity > current.max_phase_rad then
						status:= errors.e12
					elseif not ph2.accepts_material(cn.c_material) then
						status:= errors.e13
					else
						cn.moveToPhase(pid2)
						ph1.remove_material(cn.c_radioactivity)
						ph2.add_material(cn.c_radioactivity)
						status:= errors.ok -- set status to ok
					end

				end

			end
			i := i + 1
		end


	remove_phase(pid: STRING)
		do
			if containers.count > 0 then
				status:= errors.e1
			elseif not phases.has (pid) then
				status:= errors.e9
			else

				phases.remove (pid) -- remove the phase from the hash map
				status:= errors.ok -- set status to ok
			end
			i := i + 1
		end


	remove_container(cid: STRING)
		do
			if not containers.has (cid) then
				status:= errors.e15
			else

				if attached containers.item (cid) as cn then
					if attached phases.item (cn.p_pid) as ph then

						ph.remove_material(cn.c_radioactivity) -- remove container from phase
						containers.remove (cid) -- remove from containers hash map
						status:= errors.ok -- set status to ok
					end
				end
			end
			i := i + 1
		end


feature --

	out : STRING
		do
			create Result.make_from_string ("  state " + i.out + " " + status)
			if status.is_equal (errors.ok) then
				Result.append ("%N")
				Result.append ("  max_phase_radiation: "  +  max_phase_rad.out + ", max_container_radiation: " + max_container_rad.out + "%N")
				Result.append ("  phases: pid->name:capacity,count,radiation" + "%N")
				Result.append (phases_to_String)
				Result.append ("  containers: cid->pid->material,radioactivity")
				Result.append (containers_to_String)

			end


		end

	phases_to_String : STRING
		local

			in:INTEGER
			sl: SORTED_TWO_WAY_LIST[STRING]
			keys:ARRAY[STRING]

		do
			create Result.make_from_string ("")
			create sl.make
			create keys.make_from_array (phases.current_keys)

			-- add keys to sorted list in order to sort them
			from
				in:=1
			until
				in > keys.count
			loop
				sl.extend (keys.at (in))
				in := in + 1
			end


			-- now use sorted list of pids to print the phases
			from
				in:=1
			until
				in > sl.count
			loop
				if
					attached phases.item (sl.at (in)) as ph
				then

					Result.append (ph.out)
					Result.append ("%N")
				end
				in:=in+1
			end
		end


	containers_to_String : STRING
		local
			in:INTEGER
			sl: SORTED_TWO_WAY_LIST[STRING]
			keys:ARRAY[STRING]
		do
			create Result.make_from_string ("")

			if containers.count > 0 then

					Result.append ("%N")

					create sl.make
					create keys.make_from_array (containers.current_keys)

					-- add keys to sorted list in order to sort them
					from
						in:=1
					until
						in > keys.count
					loop
						sl.extend (keys.at (in))
						in := in + 1
					end


					from
						in:=1
					until
						in > sl.count
					loop
						if
							attached containers.item (sl.at (in)) as cn
						then

							Result.append (cn.out)
							if in < sl.count then
							-- Do not print a new line at the end to avoid extra line
								Result.append ("%N")
							end

						end
						in:=in+1
					end
			end

		end

end




