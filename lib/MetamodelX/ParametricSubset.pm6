use v6;
use nqp;
use Kind;
#|[ This implements support for subset parameterization as a parametric role
    to be mixed into a subset's HOW. Parameterizations of this metarole just
    take a routine of some sort, which may take an arbitrary list of parameters
    and returns a refinement for a paremeterized subset, as its only type
    parameter. ]
unit role MetamodelX::ParametricSubset[&body_block];

#|[ Returns the archetypes for a parametric subset. ]
method archetypes(::?CLASS:_: --> Metamodel::Archetypes:D) {
    state Metamodel::Archetypes:D $archetypes .= new:
        nominalizable => 1,
        parametric    => 1;
}

#|[ Given a metaobject, returns the body block this metarole was parameterized
    with. ]
method body_block(::?CLASS:D: Mu $ where Kind[self] --> Callable:D) {
    &body_block
}

#|[ Internal method that sets the parameterizer for the HOW this metarole gets
    mixed into. This simply invokes `produce_parameterization` with the
    arguments given to `parameterize` whenever it gets called. ]
method parameterization_setup(::?CLASS:D: Mu \PS where Kind[self] --> Mu) {
    nqp::setparameterizer(PS, sub SUBSET_PARAMETERIZER(Mu \PS where Kind[self], @parameters) {
        my (@positional, %named) := (@parameters[0...*-2], @parameters[*-1]);
        PS.HOW.produce_parameterization: PS, |@positional, |%named
    })
}

#|[ Internal method that does the actual work for `parameterize`. ]
method produce_parameterization(::?CLASS:D: Mu \PS where Kind[self], |parameters --> Mu) {
    sub name-of(Mu $obj is raw --> Str:D) {
         (do (try $obj.perl) if nqp::hllbool(nqp::can($obj, 'perl')))
      // (do $obj.HOW.name($obj) if nqp::hllbool(nqp::can($obj.HOW, 'name')))
      // '?'
    }

    my Str:D $name       := PS.^name ~ '[' ~ parameters.list.map({ name-of $_ }).join(', ') ~ ']';
    my Mu    $refinee    := PS.^refinee;
    my Mu    $refinement := PS.^body_block.(|parameters);
    self.new_type: :$name, :$refinee, :$refinement
}

#|[ Given a metaobject and an arbitrary list of parameters, produces a
    parameterization of the subset whose HOW this metarole gets mixed into
    using the body block the metarole was parameterized with. This generates
    a refinement for the parameterized subset, which inherits its refinee
    from the original subset. ]
method parameterize(::?CLASS:D: Mu \PS where Kind[self], |parameters --> Mu) {
    my Mu $parameters := nqp::list();
    nqp::push($parameters, $_<>) for parameters.list;
    nqp::push($parameters, $_) given parameters.hash.map({ .key => .value<> }).hash;
    nqp::parameterizetype(PS, $parameters);
}
