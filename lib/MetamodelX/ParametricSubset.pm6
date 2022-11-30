use v6;
use Kind;
#|[ This implements support for subset parameterization as a parametric role
    to be mixed into a subset's HOW. Parameterizations of this metarole just
    take a routine of some sort, which may take an arbitrary list of parameters
    and returns a refinement for a paremeterized subset, as its only type
    parameter. ]
unit role MetamodelX::ParametricSubset;

has &!body_block;

my $archetyped is default(False);
my $archetypes;
#|[ Returns the archetypes for a parametric subset. ]
method archetypes(::?CLASS:D: Mu $? --> Metamodel::Archetypes:D) {
    use nqp;
    nqp::if(
      nqp::cas($archetyped,False,True),
      nqp::atomicload($archetypes),
      nqp::atomicstore($archetypes,
        nqp::p6bindattrinvres(nqp::clone((callsame)),Metamodel::Archetypes,'$!parametric',1)))
}

#|[ A block to parameterize over. ]
method body_block(::?CLASS:D: Mu --> Callable:D) {
    &!body_block
}

#|[ Sets the block to parameterize over. ]
method set_body_block(::?CLASS:D: Mu, &body_block --> Callable:D) {
    &!body_block := &body_block<>
}

# Surprise! We can cache captures by pointer. This differs from the role
# parameterization in that named arguments don't automatically invalidate any
# cache. We take advantage of the parameterizer's object buffer like a packet:
#
# ┏━━━━━━━━━━━━━━━━━━━━━━━┉
# ┃ O ┃ [ P ]* ┃ [ K | V ]*
# ┗━━━━━━━━━━━━━━━━━━━━━━━┉
#
# Where:
# O: Cached offset of named argument list
# P: Positional argument
# K: Cached named argument name
# V: Named argument value
#
# Positional arguments are flat and should be countable from a capture. Named
# arguments make a map instead, but can be a flat list of transposed keys and
# values on the condition that the keys are cached and sorted lexographically.
my package Jail {
    my $house := Lock.new;
    my %ident;
    my %label;

    sub number(Int:D $id --> Int:D) {
        %ident.AT-KEY: $id
            orelse %ident.BIND-KEY: $id, $id<>
    }

    sub label(Str:D $name --> Str:D) {
        %label.AT-KEY: $name
            orelse %label.BIND-KEY: $name, $name<>
    }

    our sub house(Capture:D $args) is raw {
        my @args := @$args;
        my %args := %$args;
        $house.protect({
            Metamodel::Primitives.parameterize_type:
                $?PACKAGE,
                number(@args.elems.succ),
                |@args,
                |%args.keys.sort(&infix:<leg>).map({ slip label($_), %args.AT-KEY($_) })
        })
    }

    sub parameterize(Mu, Mu $args) {
        my $divider    := $args[0];
        my $obj        := $args[1];
        my $positional := $args[2..^$divider];
        my $named      := Map.new.STORE: $args.skip($divider), :INITIALIZE;
        my $how        := $obj.HOW;
        my $name       := $how.name($obj) ~ '[' ~ $positional.map(&name).join(', ') ~ ']';
        my $refinee    := $how.refinee($obj);
        my $refinement := fun $how.body_block($obj).(|$positional, |$named);
        Metamodel::SubsetHOW.new_type: :$name, :$refinee, :$refinement
    }

    sub name(Mu $obj is raw --> Str:D) {
        use nqp;
        (try $obj.raku if nqp::can($obj, 'raku'))
            orelse ($obj.^name if nqp::can($obj.HOW, 'name'))
            orelse '?'
    }

    # We need to wrap uninvokable refinements to appease Rakudo's internals.
    proto sub fun(Mu) is raw {*}
    multi sub fun(Mu $check is raw) {
        anon sub accepts(Mu $topic is raw) { $check.ACCEPTS: $topic }
    }
    multi sub fun(Code:D $code) {
        $code<>
    }

    BEGIN Metamodel::Primitives.set_parameterizer: $?PACKAGE, &parameterize;
}

#|[ Given a metaobject and arbitrary arguments, produces a parameterization of
    the subset whose HOW this metarole gets mixed into using its body block.
    This generates a refinement for a new subset produced with its refinee. ]
method parameterize(::?CLASS:D: |args) is raw {
    Jail::house(args)
}
