note
	description: "Summary description for {PHASE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PHASE

inherit
	COMPARABLE
		redefine
			out
		end
--	ANY
--		redefine
--			out
--		end	

create
	create_phase

feature {NONE} -- Initialization

	create_phase(pid: STRING ; phase_name: STRING ; capacity: INTEGER_64 ; expected_materials: ARRAY[INTEGER_64])
	local
		in:INTEGER
		in2:INTEGER
		do
			create p_pid.make_from_string (pid)
			create p_phase_name.make_from_string (phase_name)
			p_capacity := capacity.as_integer_32
			p_current_containers_in_phase := 0

			create p_expected_materials.make_empty
			from
				in:= 1
				in2:=1
			until
				in>expected_materials.count
			loop
				if not p_expected_materials.has (expected_materials.at (in)) then
					p_expected_materials.force (expected_materials.at (in), in2)
					in2:=in2+1
				end
				in:=in+1
			end


			create materials.make_empty
			materials.force ("glass", 1)
			materials.force ("metal", 2)
			materials.force ("plastic", 3)
			materials.force ("liquid", 4)

		end




feature {ANY}

	p_pid: STRING
	p_phase_name: STRING
	p_expected_materials: ARRAY[INTEGER_64]
	p_capacity: INTEGER
	p_current_containers_in_phase: INTEGER
	p_current_radioactivity: VALUE
	materials : ARRAY[STRING]

	accepts_material(material: INTEGER) : BOOLEAN
		do
			Result := p_expected_materials.has (material)
		end


    add_material(radioactivity:VALUE)
    	do
			p_current_radioactivity := p_current_radioactivity + radioactivity
			p_current_containers_in_phase := p_current_containers_in_phase + 1

    	end

    remove_material(radioactivity:VALUE)
    	do
    		p_current_radioactivity := p_current_radioactivity - radioactivity
			p_current_containers_in_phase := p_current_containers_in_phase - 1

    	end

    will_exceed_capacity() : BOOLEAN
    	do
    		Result:= (1 + current.p_current_containers_in_phase) > current.p_capacity
    	end

feature
	out : STRING
		do
--			phases: pid->name:capacity,count,radiation
			create Result.make_from_string ("    " + p_pid + "->" + p_phase_name  + ":")
			Result.append (p_capacity.out + "," + p_current_containers_in_phase.out + "," + p_current_radioactivity.out + "," + list_of_materials)

		end

	list_of_materials : STRING
		local
			i:INTEGER
		do
			create Result.make_from_string ("{")

			Result.append (materials.at (p_expected_materials.at (1).as_integer_32).out)
			from
				i:= 2
			until
				i>p_expected_materials.count
			loop
				Result.append ( "," + materials.at (p_expected_materials.at (i).as_integer_32).out )
				i := i + 1
			end
			Result.append ("}")

		end

	infix "<" (other: like Current): BOOLEAN
	do
		Result:= current.p_pid.is_less (other.p_pid)
	end


end
