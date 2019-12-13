use v6;
use Kind;
use MetamodelX::ParametricSubset;
unit module Kind::Subset::Parametric:ver<0.0.1>:auth<github:Kaiepi>:api<0>;

my constant Subset = Kind[Metamodel::SubsetHOW];

#|[ Given an additional body block argument, mixes in the
    MetamodelX::ParametricSubset role parameterized with said body block to
    a subset of some sort to mark it as being parametric. ]
multi sub trait_mod:<will>(Mu \T where Subset, &body_block, :$parameterize!) is export {
    T.HOW.^mixin: MetamodelX::ParametricSubset.^parameterize: &body_block;
    T.^parameterization_setup;
}
#=[ Given type parameters of some sort (which may be an arbitrary number of
    positional or named parameters), the body block should return the
    refinement used to produce a parameterization of the subset this trait
    marks as being parametric. The parameterized subset produced will inherit
    its refinement from the parametric subset (which is also used for
    typechecking against the unparameterized parametric subset). ]

