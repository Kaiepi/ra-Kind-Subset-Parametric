use v6.e.PREVIEW;
use Kind:auth<zef:Kaiepi>:api<2>;
use MetamodelX::ParametricSubset;
unit module Kind::Subset::Parametric:ver<1.0.0>:auth<zef:Kaiepi>:api<1>;

#|[ Performs a mixin of MetamodelX::ParametricSubset on a subset. ]
multi sub trait_mod:<will>(Kind[Metamodel::SubsetHOW:D] \T, &body_block, :parameterize($)! --> Nil) is export {
    T.HOW.^mixin: MetamodelX::ParametricSubset unless MetamodelX::ParametricSubset.ACCEPTS: T.HOW;
    T.^set_body_block: &body_block;
}
#=[ Given arbitrary type arguments, the body block should return a refinement
    with which to produce a parameterization for the provided subset. ]
