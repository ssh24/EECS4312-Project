note
	description: "Summary description for {WCONTAINER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	WCONTAINER

inherit
	COMPARABLE
		redefine
			out
		end

create
	create_container

feature {NONE} -- Initialization

	create_container(cid: STRING ; c: TUPLE[material: INTEGER_64; radioactivity: VALUE] ; pid: STRING)
			-- Initialization for `Current'.
		do

			create c_cid.make_from_string (cid)
			c_material:= c.material.as_integer_32
			c_radioactivity:= c.radioactivity
			create p_pid.make_from_string (pid)

			create materials.make_empty
			materials.force ("glass", 1)
			materials.force ("metal", 2)
			materials.force ("plastic", 3)
			materials.force ("liquid", 4)

		end


feature {ANY}

	getCurrentPhaseID() : STRING
		do
			create Result.make_from_string(p_pid)
		end

	getMaterial() : STRING
		do
			create Result.make_from_string(materials.at (c_material))
		end

	moveToPhase(p:STRING)
		do
			p_pid:= p
		end

	c_cid : STRING
	c_material: INTEGER
	c_radioactivity: VALUE
	p_pid:STRING
	materials : ARRAY[STRING]

	out : STRING
		do
--			containers: cid->pid->material,radioactivity
			create Result.make_from_string ("    " + c_cid.out + "->" + p_pid.out + "->" + materials.at (c_material)  + "," + c_radioactivity.out)

		end

	infix "<" (other: like Current): BOOLEAN
		do
			Result:= current.c_cid.is_less (other.c_cid)
		end

end
