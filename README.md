[![Build Status](https://github.com/Kaiepi/ra-Kind-Subset-Parametric/actions/workflows/test.yml/badge.svg)](https://github.com/Kaiepi/ra-Kind-Subset-Parametric/actions/workflows/test.yml)

NAME
====

Kind::Subset::Parametric - Support for generic subsets

SYNOPSIS
========

```raku
use Kind::Subset::Parametric;

# Arrays don't type their elements by default:
my @untyped = 1, 2, 3;
say @untyped.^name; # OUTPUT: Array

# You can make it so they do by parameterizing Array:
my Int:D @typed = 1, 2, 3;
say @typed.^name; # OUTPUT: Array[Int:D]

# But you can't typecheck untyped arrays using these parameterizations:
say @typed ~~ Array[Int:D];   # OUTPUT: True
say @untyped ~~ Array[Int:D]; # OUTPUT: False

# So let's make our own array type that handles this using a parametric subset:
subset TypedArray of Array will parameterize -> ::T {
    proto sub check(Array) {*}
    multi sub check(Array[T] --> True) { }
    multi sub check(Array:U --> False) { }
    multi sub check(Array:D $topic) { so $topic.all ~~ T }
    &check
} where { !!! };

# Now they can both be typechecked:
given TypedArray[Int:D] -> \IntArray {
    say @typed ~~ IntArray;        # OUTPUT: True
    say @untyped ~~ IntArray;      # OUTPUT: True
    say <foo bar baz> ~~ IntArray; # OUTPUT: False
}
```

DESCRIPTION
===========

`Kind::Subset::Parametric` enhances subsets with support for parameterization. This allows you to write subsets with generic `where` clauses.

`Kind::Subset::Parametric` is documented. You can refer to the documentation for its trait and `MetamodelX::ParametricSubset` at any time using `WHY`.

TRAITS
======

will parameterize
-----------------

```raku
multi sub trait_mod:<will>(Mu \T where Subset, &body_block, :parameterize($)!)
```

This trait mixes the `MetamodelX::ParametricSubset` metarole into the HOW of the type it is applied to, which may only be a subset of some sort. Afterwards, the subset will be instantiated with its `&body_block`, which is what makes it possible to parameterize the subset.

The main metamethod of interest this metarole provides is `parameterize`, which accepts arbitrary type argumentss. This is created using a name (generated similarly to how the name of a parametric role is generated), the refinee of the parametric subset (the value of `of`), and the return value of the body block when invoked with the arguments as its refinement (the value of `where`).

For example, given an identity type:

```raku
subset Identity will parameterize { $_ } where { !!! };
```

`Identity[Any]` may be written to produce:

```raku
subset ::('Identity[Any]') where Any;
```

Note the stubbed `where` clause. Parametric subsets can still be given a refinement when this trait is applied, which handles typechecking against the subset when it has not been parameterized. If it's not desirable for a parametric subset to typecheck without being parameterized, the `!!!` stub will throw. Historically, `...` was used, but failures don't necessarily sink when the typechecker's nqp is involved.

The body block may be introspected with the `body_block` metamethod, which returns the body block it was parameterized with given a subset type. `set_body_block` must be called after being instantiated either by mixin on a HOW or by `&trait_mod:<does>` in order to replace this.

Refer to `t/02-will.t` for more examples of how to use this trait.

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

