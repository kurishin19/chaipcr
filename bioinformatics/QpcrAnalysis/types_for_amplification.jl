## types_for_amp.jl

import DataStructures.OrderedDict


const Ct_VAL_DomainError = -100 # should be a value that cannot be obtained by normal calculation of Ct
const DEFAULT_cyc_nums = Vector{Int}()
const KWDICT_RC_SYMBOLS = Dict(
    "min_fluomax"   => :max_bsf_lb,
    "min_D1max"     => :max_dr1_lb,
    "min_D1max"     => :max_dr2_lb)
const KWDICT_PA1_KEYWORDS =
    ["min_reliable_cyc", "baseline_cyc_bounds", "cq_method", "ctrl_well_dict"]

abstract type AbstractAmpFitted end
struct EmptyAmpFitted <: AbstractAmpFitted end

mutable struct AmpStepRampProperties
    step_or_ramp    ::Symbol
    id              ::Int
    cyc_nums        ::Vector{Int} # accomodating non-continuous sequences of cycles
end

## `mod_bl_q` output
struct MbqOutput
    fitted_prebl    ::AbstractAmpFitted
    bl_notes        ::Vector{String}
    blsub_fluos     ::Vector{Float64}
    fitted_postbl   ::AbstractAmpFitted
    postbl_status   ::Symbol
    coefs           ::Vector{Float64}
    d0              ::AbstractFloat
    blsub_fitted    ::Vector{Float64}
    dr1_pred        ::Vector{Float64}
    dr2_pred        ::Vector{Float64}
    max_dr1         ::AbstractFloat
    max_dr2         ::AbstractFloat
    cyc_vals_4cq    ::OrderedDict{String,Float64}
    eff_vals_4cq    ::OrderedDict{String,Float64}
    cq_raw          ::Float64
    cq              ::Float64
    eff             ::Float64
    cq_fluo         ::Float64
end

## amplification output format per step or ramp
mutable struct AmpStepRampOutput
    ## computed in `process_amp_1sr`
    fr_ary3         ::Array{Float64,3}
    mw_ary3         ::Array{Float64,3}
    k4dcv           ::K4Deconv
    dcvd_ary3       ::Array{Float64,3}
    wva_data        ::OrderedDict{Symbol,OrderedDict{Int,Vector{Float64}}}
    rbbs_ary3       ::Array{Float64,3}
    fluo_well_nums  ::Vector{Int}
    channel_nums    ::Vector{Int}
    cq_method       ::String
    # computed by `mod_bl_q` as part of `MbqOutput` and arranged in arrays in `process_amp_1sr`
    fitted_prebl ::Array{AbstractAmpFitted,2}
    bl_notes ::Array{Array{String,1},2}
    blsub_fluos ::Array{Float64,3}
    fitted_postbl ::Array{AbstractAmpFitted,2}
    postbl_status ::Array{Symbol,2}
    coefs ::Array{Float64,3}
    d0 ::Array{Float64,2}
    blsub_fitted ::Array{Float64,3}
    dr1_pred ::Array{Float64,3}
    dr2_pred ::Array{Float64,3}
    max_dr1 ::Array{Float64,2}
    max_dr2 ::Array{Float64,2}
    cyc_vals_4cq ::Array{OrderedDict{String,Float64},2}
    eff_vals_4cq ::Array{OrderedDict{String,Float64},2}
    cq_raw ::Array{Float64,2}
    cq ::Array{Float64,2}
    eff ::Array{Float64,2}
    cq_fluo ::Array{Float64,2}
    # computed in `process_amp_1sr` from `MbqOutput`
    qt_fluos ::Array{Float64,2}
    max_qt_fluo ::Float64
    # computed by `report_cq!` and arranged in arrays in `process_amp_1sr`
    max_bsf ::Array{Float64,2}
    scld_max_bsf ::Array{Float64,2}
    scld_max_dr1 ::Array{Float64,2}
    scld_max_dr2 ::Array{Float64,2}
    why_NaN ::Array{String,2}
    # for ct method
    ct_fluos ::Vector{Float64}
    # allelic discrimination
    assignments_adj_labels_dict ::OrderedDict{String,Vector{String}}
    agr_dict ::OrderedDict{String,AssignGenosResult}
end # type AmpStepRampOutput

struct AmpStepRampOutput2Bjson
    rbbs_ary3 ::Array{Float64,3} # fluorescence after deconvolution and adjusting well-to-well variation
    blsub_fluos ::Array{Float64,3} # fluorescence after baseline subtraction
    dr1_pred ::Array{Float64,3} # dF/dc
    dr2_pred ::Array{Float64,3} # d2F/dc2
    cq ::Array{Float64,2} # cq values, applicable to sigmoid models but not to MAK models
    d0 ::Array{Float64,2} # starting quantity from absolute quanitification
    ct_fluos ::Vector{Float64} # fluorescence thresholds (one value per channel) for Ct method
    assignments_adj_labels_dict ::OrderedDict{String,Vector{String}} # assigned genotypes from allelic discrimination, keyed by type of data (see `AD_DATA_CATEG` in "allelic_discrimination.jl")
end
