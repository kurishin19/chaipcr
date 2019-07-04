## normalization.jl
##
## normalize variation between wells in absolute fluorescence values

import DataStructures.OrderedDict
import Memento: debug, error


## constants >>
const NORMALIZATION_SCALING_FACTOR  = 3.7           ## used: 9e5, 1e5, 1.2e6, 3.0

## function definitions >>

## Top-level function: normalize variation between wells in absolute fluorescence values (normalize).
## each dye only has data for its target channel;
## calibration/calib/oc - used for `deconvolute` and `normalize`,
## each dye has data for both target and non-target channels.
## Input `fluo` and output: dim2 indexed by well and dim1 indexed by unit,
## which can be cycle (amplification) or temperature point (melt curve).
## Output does not include the automatically created column at index 1
## from rownames of input array as R does
function normalize(
    fluo2btp                        ::Array{<: Real,2},
    normalized_data                 ::Associative,
    matched_well_idc                ::AbstractVector,
    channel                         ::Integer;
    minus_water                     ::Bool =false,
    normalization_scaling_factor    ::Real =NORMALIZATION_SCALING_FACTOR
)
    debug(logger, "at normalize()")

    ## devectorized code avoids transposing data matrix
    if minus_water == false
        const swd = normalized_data[:signal][channel][matched_well_idc]
        return ([
            normalization_scaling_factor * mean(swd) *
                fluo2btp[i,w] / swd[w]
                    for i in 1:size(fluo2btp, 1),
                        w in 1:size(fluo2btp, 2)]) ## w = well
    end

    ## minus_water == true
    const normalized_water = normalized_data[:water][channel][matched_well_idc]
    const swd =
        normalized_data[:signal][channel][matched_well_idc] .-
            normalized_data[:water][channel][matched_well_idc]
    return ([
        normalization_scaling_factor * mean(swd) *
            (fluo2btp[i,w] - normalized_water[w]) / swd[w]
                for i in 1:size(fluo2btp, 1),
                    w in 1:size(fluo2btp, 2)]) ## w = well
end ## normalize


## function: check whether the data in optical calibration experiment is valid
function prep_normalize(
    calibration_data    ::Associative,
    well_nums           ::AbstractVector,
    dye_in              ::Symbol = :FAM,
    dyes_to_be_filled   ::AbstractVector =[]
)
    debug(logger, "at prep_normalize()")
    ## issue:
    ## using the current format for the request body there is no well_num information
    ## associated with the calibration data
    signal_data_dict = OrderedDict{Int,Vector{Float_T}}() ## use type of calibration data
    water_data_dict  = OrderedDict{Int,Vector{Float_T}}() ## use type of calibration data
    stop_msgs  = Vector{String}()
    for channel in 1:num_channels(calibration_data[WATER_KEY][FLUORESCENCE_VALUE_KEY])
        key = CHANNEL_KEY * "_" * string(channel)
        try
            water_data_dict[channel]  = calibration_data[WATER_KEY][FLUORESCENCE_VALUE_KEY][channel]
        catch
            push!(stop_msgs, "Cannot access water calibration data for channel $channel")
        end ## try
        try
            signal_data_dict[channel] = calibration_data[key][FLUORESCENCE_VALUE_KEY][channel]
        catch
            push!(stop_msgs, "Cannot access signal calibration data for channel $channel")
        end ## try
        if length(water_data_dict[channel]) != length(signal_data_dict[channel])
            push!(stop_msgs, "Calibration data lengths are not equal for channel $channel")
        end
    end ## next channel
    (length(stop_msgs) > 0) && throw(DomainError(join(stop_msgs, "; ")))
    #
    const (channels_in_water, channels_in_signal) =
        map(get_ordered_keys, (water_data_dict, signal_data_dict))
    ## assume without checking that there are no missing wells anywhere
    const signal_well_nums = collect(1:length(signal_data_dict[1]))
    ## check whether signal fluorescence > water fluorescence
    for channel in channels_in_signal
        const norm_invalid_idc = find(signal_data_dict[channel] .<= water_data_dict[channel])
        if length(norm_invalid_idc) > 0
            const failed_well_nums_str = join(signal_well_nums[norm_invalid_idc], ", ")
            push!(stop_msgs, "invalid well-to-well variation data in channel $channel: " *
                "fluorescence value of water is greater than or equal to that of dye " *
                "in the following well(s) - $failed_well_nums_str")
        end ## if invalid
    end ## next channel
    (length(stop_msgs) > 0) && throw(DomainError(join(stop_msgs, "; ")))
    #
    ## issue:
    ## this feature has been temporarily disabled while
    ## removing MySql dependency in get_wva_data because
    ## using the current format for the request body
    ## we cannot subset the calibration data by step_id
    # if length(dyes_to_be_filled) > 0 ## extrapolate well-to-well variation data for missing channels
    #     println("Preset well-to-well variation data is used to extrapolate calibration data for missing channels.")
    #     channels_missing = setdiff(channels_in_water, channels_in_signal)
    #     dyes_dyes_to_be_filled_channels = map(dye -> DYE2CHST[dye]["channel"], dyes_to_be_filled) ## DYE2CHST is defined in module scope
    #     check_subset(
    #         Ccsc(channels_missing, "Channels missing well-to-well variation data"),
    #         Ccsc(dyes_dyes_to_be_filled_channels, "channels corresponding to the dyes of which well-to-well variation data is needed")
    #     )
    #     # process preset calibration data
    #     preset_step_ids = OrderedDict([
    #         dye => DYE2CHST[dye]["step_id"]
    #         for dye in keys(DYE2CHST)
    #     ])
    #     preset_signal_data_dict, dyes_in_preset = get_wva_data(PRESET_calib_ids["signal"], preset_step_ids, db_conn, "dye") ## `well_nums` is not passed on
    #     pivot_preset = preset_signal_data_dict[dye_in]
    #     pivot_in = signal_data_dict[DYE2CHST[dye_in]["channel"]]
    #     in2preset = pivot_in ./ pivot_preset
    #     for dye in dyes_to_be_filled
    #         signal_data_dict[DYE2CHST[dye]["channel"]] = preset_signal_data_dict[dye] .* in2preset
    #     end
    # end ## if

    ## water_data and signal_data are OrderedDict objects keyed by channels,
    ## to accommodate the situation where calibration data has more channels
    ## than experiment data, so that calibration data needs to be easily
    ## subsetted by channel.
    const normalizable = OrderedDict(
        :water  => water_data_dict,
        :signal => signal_data_dict)
    return (normalizable, signal_well_nums)
end ## prep_normalize
