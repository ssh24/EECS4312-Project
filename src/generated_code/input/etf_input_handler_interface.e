note
	description: "Input Handler"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	ETF_INPUT_HANDLER_INTERFACE
inherit
	ETF_TYPE_CONSTRAINTS

feature {NONE}

	make_without_running(etf_input: STRING; a_commands: ETF_ABSTRACT_UI_INTERFACE)
			-- convert an input string into array of commands
	  	do
	  		create on_error
		  	input_string := etf_input
		  	abstract_ui  := a_commands
	  	end

	make(etf_input: STRING; a_commands: ETF_ABSTRACT_UI_INTERFACE)
			-- convert an input string into array of commands
	  	do
	  		make_without_running(etf_input, a_commands)
			parse_and_validate_input_string
	  	end

feature -- auxiliary queries

	etf_evt_out (evt: TUPLE[name: STRING; args: ARRAY[ETF_EVT_ARG]]): STRING
		local
			etf_local_i: INTEGER
			name: STRING
			args: ARRAY[ETF_EVT_ARG]
		do
			name := evt.name
			args := evt.args
			create Result.make_empty
			Result.append (name + "(")
			from
				etf_local_i := args.lower
			until
				etf_local_i > args.upper
			loop
				if args[etf_local_i].src_out.is_empty then
					Result.append (args[etf_local_i].out)
				else
					Result.append (args[etf_local_i].src_out)
				end
				if etf_local_i < args.upper then
					Result.append (", ")
				end
				etf_local_i := etf_local_i + 1
			end
			Result.append (")")
		end

feature -- attributes

	etf_error: BOOLEAN

	input_string: STRING -- list of commands to execute

	abstract_ui: ETF_ABSTRACT_UI_INTERFACE
		-- output generated by `parse_string'

feature -- error reporting

	on_error: ETF_EVENT [TUPLE[STRING]]

feature -- error messages

	input_cmds_syntax_err_msg : STRING =
		"Syntax Error: specification of command executions cannot be parsed"

	input_cmds_type_err_msg : STRING =
		"Type Error: specification of command executions is not type-correct"

feature -- parsing

	parse_and_validate_input_string
	  local
		trace_parser : ETF_EVT_TRACE_PARSER
		cmd : ETF_COMMAND_INTERFACE
		invalid_cmds: STRING
	  do
		create trace_parser.make (evt_param_types_list, enum_items)
		trace_parser.parse_string (input_string)

	    if trace_parser.last_error.is_empty then
	  	  invalid_cmds := find_invalid_evt_trace (
		    	trace_parser.event_trace)
		  if invalid_cmds.is_empty then
		    across trace_parser.event_trace
		    as evt
		    loop
		      cmd := evt_to_cmd (evt.item)
		      abstract_ui.put (cmd)
		    end
		  else
		    etf_error := TRUE
		    on_error.notify (
		  	  input_cmds_type_err_msg + "%N" + invalid_cmds)
		  end
	    else
	      etf_error := TRUE
	      on_error.notify (
		    input_cmds_syntax_err_msg + "%N" + trace_parser.last_error)
	    end
	end

	evt_to_cmd (evt : TUPLE[name: STRING; args: ARRAY[ETF_EVT_ARG]]) : ETF_COMMAND_INTERFACE
		local
			cmd_name : STRING
			args : ARRAY[ETF_EVT_ARG]
			dummy_cmd : ETF_DUMMY
		do
			cmd_name := evt.name
			args := evt.args
			create dummy_cmd.make("dummy", [], abstract_ui)

			if cmd_name ~ "new_tracker" then 
				 if attached {ETF_VALUE_ARG} args[1] as max_phase_radiation and then TRUE and then attached {ETF_VALUE_ARG} args[2] as max_container_radiation and then TRUE then 
					 create {ETF_NEW_TRACKER} Result.make ("new_tracker", [create {VALUE}.make_from_string (max_phase_radiation.src_out) , create {VALUE}.make_from_string (max_container_radiation.src_out)], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 

			elseif cmd_name ~ "new_phase" then 
				 if attached {ETF_STR_ARG} args[1] as pid and then TRUE and then attached {ETF_STR_ARG} args[2] as phase_name and then TRUE and then attached {ETF_INT_ARG} args[3] as capacity and then TRUE and then (attached {ETF_ARRAY_ARG} args[4] as expected_materials and then across expected_materials.value as member all attached {ETF_ENUM_INT_ARG} member.item as tup  and then (tup.value = glass or else tup.value = metal or else tup.value = plastic or else tup.value = liquid) and then TRUE end) then 
					 create {ETF_NEW_PHASE} Result.make ("new_phase", [pid.value , phase_name.value , capacity.value , expected_materials.to_int_val_array_from_enum_array], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 

			elseif cmd_name ~ "remove_phase" then 
				 if attached {ETF_STR_ARG} args[1] as pid and then TRUE then 
					 create {ETF_REMOVE_PHASE} Result.make ("remove_phase", [pid.value], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 

			elseif cmd_name ~ "new_container" then 
				 if attached {ETF_STR_ARG} args[1] as cid and then TRUE and then (attached {ETF_TUPLE_ARG} args[2] as c) and then c.value.count = 2 and then (attached {ETF_ENUM_INT_ARG} c.value[1] as c_material) and then (attached {ETF_VALUE_ARG} c.value[2] as c_radioactivity) and then (c_material.value = glass or else c_material.value = metal or else c_material.value = plastic or else c_material.value = liquid) and then TRUE and then attached {ETF_STR_ARG} args[3] as pid and then TRUE then 
					 create {ETF_NEW_CONTAINER} Result.make ("new_container", [cid.value , [c_material.value, create {VALUE}.make_from_string (c_radioactivity.src_out)] , pid.value], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 

			elseif cmd_name ~ "remove_container" then 
				 if attached {ETF_STR_ARG} args[1] as cid and then TRUE then 
					 create {ETF_REMOVE_CONTAINER} Result.make ("remove_container", [cid.value], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 

			elseif cmd_name ~ "move_container" then 
				 if attached {ETF_STR_ARG} args[1] as cid and then TRUE and then attached {ETF_STR_ARG} args[2] as pid1 and then TRUE and then attached {ETF_STR_ARG} args[3] as pid2 and then TRUE then 
					 create {ETF_MOVE_CONTAINER} Result.make ("move_container", [cid.value , pid1.value , pid2.value], abstract_ui) 
				 else 
					 Result := dummy_cmd 
				 end 
			else 
				 Result := dummy_cmd 
			end 
		end

	find_invalid_evt_trace (
		event_trace: ARRAY[TUPLE[name: STRING; args: ARRAY[ETF_EVT_ARG]]])
	: STRING
	local
		loop_counter: INTEGER
		evt: TUPLE[name: STRING; args: ARRAY[ETF_EVT_ARG]]
		cmd_name: STRING
		args: ARRAY[ETF_EVT_ARG]
		evt_out_str: STRING
	do
		create Result.make_empty
		from
			loop_counter := event_trace.lower
		until
			loop_counter > event_trace.upper
		loop
			evt := event_trace[loop_counter]
			evt_out_str := etf_evt_out (evt)

			cmd_name := evt.name
			args := evt.args

			if cmd_name ~ "new_tracker" then 
				if NOT( ( args.count = 2 ) AND THEN attached {ETF_VALUE_ARG} args[1] as max_phase_radiation and then TRUE and then attached {ETF_VALUE_ARG} args[2] as max_container_radiation and then TRUE) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"new_tracker(max_phase_radiation: VALUE ; max_container_radiation: VALUE)")
				end

			elseif cmd_name ~ "new_phase" then 
				if NOT( ( args.count = 4 ) AND THEN attached {ETF_STR_ARG} args[1] as pid and then TRUE and then attached {ETF_STR_ARG} args[2] as phase_name and then TRUE and then attached {ETF_INT_ARG} args[3] as capacity and then TRUE and then (attached {ETF_ARRAY_ARG} args[4] as expected_materials and then across expected_materials.value as member all attached {ETF_ENUM_INT_ARG} member.item as tup  and then (tup.value = glass or else tup.value = metal or else tup.value = plastic or else tup.value = liquid) and then TRUE end)) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"new_phase(pid: PID = STRING ; phase_name: STRING ; capacity: INTEGER_64 ; expected_materials: ARRAY[MATERIAL = {glass, metal, plastic, liquid}])")
				end

			elseif cmd_name ~ "remove_phase" then 
				if NOT( ( args.count = 1 ) AND THEN attached {ETF_STR_ARG} args[1] as pid and then TRUE) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"remove_phase(pid: PID = STRING)")
				end

			elseif cmd_name ~ "new_container" then 
				if NOT( ( args.count = 3 ) AND THEN attached {ETF_STR_ARG} args[1] as cid and then TRUE and then (attached {ETF_TUPLE_ARG} args[2] as c) and then c.value.count = 2 and then (attached {ETF_ENUM_INT_ARG} c.value[1] as c_material) and then (attached {ETF_VALUE_ARG} c.value[2] as c_radioactivity) and then (c_material.value = glass or else c_material.value = metal or else c_material.value = plastic or else c_material.value = liquid) and then TRUE and then attached {ETF_STR_ARG} args[3] as pid and then TRUE) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"new_container(cid: CID = STRING ; c: CONTAINER = TUPLE[material: MATERIAL = {glass, metal, plastic, liquid}; radioactivity: VALUE] ; pid: PID = STRING)")
				end

			elseif cmd_name ~ "remove_container" then 
				if NOT( ( args.count = 1 ) AND THEN attached {ETF_STR_ARG} args[1] as cid and then TRUE) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"remove_container(cid: CID = STRING)")
				end

			elseif cmd_name ~ "move_container" then 
				if NOT( ( args.count = 3 ) AND THEN attached {ETF_STR_ARG} args[1] as cid and then TRUE and then attached {ETF_STR_ARG} args[2] as pid1 and then TRUE and then attached {ETF_STR_ARG} args[3] as pid2 and then TRUE) then 
					if NOT Result.is_empty then
						Result.append ("%N")
					end
					Result.append (evt_out_str + " does not conform to declaration " +
							"move_container(cid: CID = STRING ; pid1: PID = STRING ; pid2: PID = STRING)")
				end
			else
				if NOT Result.is_empty then
					Result.append ("%N")
				end
				Result.append ("Error: unknown event name " + cmd_name)
			end
			loop_counter := loop_counter + 1
		end
	end
end
