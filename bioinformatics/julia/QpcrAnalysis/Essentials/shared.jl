# constants and functions used by multiple types of analyses


# constants

const JSON_DIGITS = 3 # number of decimal points for floats in JSON output

const JULIA_ENV = ENV["JULIA_ENV"]

const DB_INFO = JSON.parsefile("$MODULE_DIR/database.json", dicttype=OrderedDict)[JULIA_ENV]

const DB_CONN_DICT = OrderedDict(map([
    ("default", DB_INFO["database"]),
    ("t1", "test_1ch"),
    ("t2", "test_2ch")
]) do db_tuple
    db_tuple[1] => mysql_connect(DB_INFO["host"], DB_INFO["username"], DB_INFO["password"], db_tuple[2])
end) # do db_name

# test_df = mysql_execute(DB_CONN_DICT["t1"], "select * from ramps") # doesn't raise error when starting Julia with "sys2_qa.dll"

# ABSENT_IN_REQ values
const calib_info_AIR = 0 # calib_info == ABSENT_IN_REQ. To conform with `calib_info::Union{Integer,OrderedDict}``
const db_name_AIR = "" # db_name == ABSENT_IN_REQ




# functions


# function: check whether a value different from `calib_info_AIR` is passed onto `calib_info`; if not, use `exp_id` to find calibration "experiment_id" in MySQL database and assumes water "step_id"=2, signal "step_id"=4, using FAM to calibrate all the channels.
function ensure_ci(
    db_conn::MySQL.MySQLHandle,
    calib_info::Union{Integer,OrderedDict}=calib_info_AIR,
    exp_id::Integer=calib_info_AIR
    )

    if isa(calib_info, Integer)

        if calib_info == calib_info_AIR
            calib_id = mysql_execute(
                db_conn,
                "SELECT calibration_id FROM experiments WHERE id=$exp_id"
            )[1, :calibration_id]
        else
            calib_id = calib_info
        end

        step_qry = "SELECT step_id FROM fluorescence_data WHERE experiment_id=$calib_id"
        step_ids = sort(unique(mysql_execute(db_conn, step_qry)[:step_id]))

        calib_info = OrderedDict(
            "water" => OrderedDict(
                "calibration_id" => calib_id,
                "step_id" => step_ids[1]
            )
        )

        for i in 2:(length(step_ids))
            calib_info["channel_$(i-1)"] = OrderedDict(
                "calibration_id" => calib_id,
                "step_id" => step_ids[i]
            )
        end # for

        channel_qry = "SELECT channel FROM fluorescence_data WHERE experiment_id=$calib_id"
        channels = sort(unique(mysql_execute(db_conn, channel_qry)[:channel]))

        for channel in channels
            channel_key = "channel_$channel"
            if !(channel_key in keys(calib_info))
                calib_info[channel_key] = OrderedDict(
                    "calibration_id" => calib_id,
                    "step_id" => step_ids[2]
                )
            end # if
        end # for

    end # if isa(calib_info, Integer)

    return calib_info

end # ensure_ci


# finite differencing
function finite_diff(
    X::AbstractVector, Y::AbstractVector; # X and Y must be of same length
    nu::Integer=1, # order of derivative
    method::AbstractString="central"
    )

    dlen = length(X)
    if dlen != length(Y)
        error("X and Y must be of same length.")
    end

    if dlen == 1
        return zeros(1)
    end

    if nu == 1
        if method == "central"
            range1 = 3:dlen+2
            range2 = 1:dlen
        elseif method == "forward"
            range1 = 3:dlen+2
            range2 = 2:dlen+1
        elseif method == "backward"
            range1 = 2:dlen+1
            range2 = 1:dlen
        end

        X_p2, Y_p2 = map((X, Y)) do ori
            vcat(
                ori[2] * 2 - ori[1],
                ori,
                ori[dlen-1] * 2 - ori[dlen]
            )
        end

        return (Y_p2[range1] .- Y_p2[range2]) ./ (X_p2[range1] .- X_p2[range2])

    else
        return finite_diff(
            X,
            finite_diff(X, Y; nu=nu-1, method=method),
            nu=1;
            method=method)
    end # if nu == 1

end


function dictvec2df(dict_keys::AbstractVector, dict_vec::AbstractVector) # `dict_keys` need to be a vector of strings to construct DataFrame column indice correctly
    df = DataFrame()
    for dict_key in dict_keys
        df[parse(dict_key)] = map(dict_ele -> dict_ele[dict_key], dict_vec)
    end
    return df
end


# generate a boolean vector indicating whether each element of a collection in question is equal to the target value
function get_bool_vec(target, collection)
    Vector{Bool}(map(
        element -> element == target,
        collection
    ))
end


function get_mysql_data_well(
    well_nums::AbstractVector, # must be sorted in ascending order
    qry_2b::AbstractString, # must select "well_num" column
    db_conn::MySQL.MySQLHandle,
    verbose::Bool,
    )

    well_nums_str = join(well_nums, ',')
    print_v(println, verbose, "well_nums: $well_nums_str")

    well_constraint = (well_nums_str == "") ? "" : "AND well_num in ($well_nums_str)"
    qry = replace(qry_2b, "well_constraint", well_constraint)
    df = mysql_execute(db_conn, qry)

    found_well_nums = sort(unique(df[:well_num]))

    return (df, found_well_nums)

end


function get_ordered_keys(dict::Dict)
    sort(collect(keys(dict)))
end
function get_ordered_keys(ordered_dict::OrderedDict)
    collect(keys(ordered_dict))
end


# functions to get indices in span.
    # x_mp_i = index of middle point in selected data points from X
    # sel_idc = selected indices

function giis_even(dlen::Integer, i::Integer, span_dp::Integer)
    start_idx = i > span_dp ? i - span_dp : 1
    end_idx = i < dlen - span_dp ? i + span_dp : dlen
    return start_idx:end_idx
end

function giis_uneven(
    X::AbstractVector,
    i::Integer, span_x::Real)
    return find(X) do x_dp
        X[i] - span_x <= x_dp <= X[i] + span_x # dp = data point
    end # do x_dp
end


# mutate duplicated elements in a numeric vector so that all the elements become unique
function mutate_dups(vec_2mut::AbstractVector, frac2add::Real=0.01)

    vec_len = length(vec_2mut)
    vec_uniq = sort(unique(vec_2mut))
    vec_uniq_len = length(vec_uniq)

    if vec_len == vec_uniq_len
        return vec_2mut
    else
        order_to = sortperm(vec_2mut)
        order_back = sortperm(order_to)
        vec_sorted = (vec_2mut + .0)[order_to]
        vec_sorted_prev = vcat(vec_sorted[1]-1, vec_sorted[1:vec_len-1])
        dups = (1:vec_len)[map(1:vec_len) do i
            vec_sorted[i] == vec_sorted_prev[i]
        end]

        add1 = frac2add * median(map(2:vec_uniq_len) do i
            vec_uniq[i] - vec_uniq[i-1]
        end)

        for dup_i in 1:length(dups)
            dup_i_moveup = dup_i
            rank = 1
            while dup_i_moveup > 1 && dups[dup_i_moveup] - dups[dup_i_moveup-1] == 1
                dup_i_moveup -= 1
                rank += 1
            end
            vec_sorted[dups[dup_i]] += add1 * rank
        end

        return vec_sorted[order_back]
    end

end


# parse AbstractFloat on BBB
function parse_af{T<:AbstractFloat}(::Type{T}, strval::AbstractString)
    str_parts = split(strval, '.')
    float_parts = map(str_part -> parse(Int32, str_part), str_parts)
    return float_parts[1] + float_parts[2] / 10^length(str_parts[2])
end


# print with verbose control
function print_v(print_func::Function, verbose::Bool, args...; kwargs...)
    if verbose
        print_func(args...; kwargs...)
    end
    return nothing
end




#