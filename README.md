[![Build Status](https://travis-ci.com/Kaiepi/ra-Kind-Subset-Parametric.svg?branch=master)](https://travis-ci.com/Kaiepi/ra-Kind-Subset-Parametric)

NAME
====

Kind::Subset::Parametric - Support for generic subsets

SYNOPSIS
========

```perl6
use Kind::Subset::Parametric;

# Arrays don't type their elements by default:
my @untyped = 1, 2, 3;
say @untyped.^name; # OUTPUT: Array

# You can make it so they do by parameterizing Array:
my Int:D @typed = 1, 2, 3;
say @typed.^name; # OUTPUT: Array[Int:D]

# But you can't typecheck untyped arrays using these parameterizations:
say @typed   ~~ Array[Int:D]; # OUTPUT: True
say @untyped ~~ Array[Int:D]; # OUTPUT: False

# So let's make our own array type that handles this using a parametric subset:
subset TypedArray of Array will parameterize -> Mu ::T { Array:_ \array {
    array ~~ Array[T] || (array ~~ Array:D && so array.all ~~ T)
} } where { ... };

# Now they can both be typechecked:
given TypedArray[Int:D] -> \IntArray {
    say @typed        ~~ IntArray; # OUTPUT: True
    say @untyped      ~~ IntArray; # OUTPUT: True
    say <foo bar baz> ~~ IntArray; # OUTPUT: False
}
```

DESCRIPTION
===========

Kind::Subset::Parametric is a library that enhances subsets with support for parameterization. This allows you to easily implement your own generic subsets.

Note: while you can make generic subsets using this library, subsets cannot be parameterized with generics yet. Parameterizations using type captures, such as this, may not work as expected:

```perl6
subset TypeIdentity will parameterize -> Mu ::T { T };

proto sub is-type-id(Mu --> Bool:D)                           {*}
multi sub is-type-id(Mu ::T $ where TypeIdentity[T] --> True) { }
multi sub is-type-id(Mu --> False)                            { }
```

Kind::Subset::Parametric is documented. You can refer to the documentation for its trait and `MetamodelX::ParametricSubset` at any time using `WHY`.

TRAITS
======

will parameterize
-----------------

```perl6
multi sub trait_mod:<will>(Mu \T where Subset, &body_block, :$parameterize!)
```

This trait mixes the `MetamodelX::ParametricSubset` metarole into the metaobject of the type this trait is used with (which may only be a subset of some sort) after parameterizing it with `&body_block`. This makes it possible to use the subset as a parametric type.

The main metamethod of interest this metarole provides is `parameterize`, which handles creating a new subset type upon parameterization given an arbitrary list of parameters. This is created using a name (generated similarly to how the name of a parametric role is generated), the refinee of the parametric subset, and the return value of the body block when invoked with the list of parameters as its refinement.

`MetamodelX::ParametricSubset` also provides a `body_block` metamethod, which returns the body block it was parameterized with given a subset type.

What all this means that the `TypedArray[Int:D]` parameterization from the synopsis generates a subset functionally equivalent to the one this type declaration creates:

```perl6
subset :: of Array where {
    $_ ~~ Array[Int:D] || ($_ ~~ Array:D && so $_.all ~~ Int:D)
};
```

Parametric subsets can still be given a refinement (the value given to `where` in a subset declaration) when this trait is used. This gets used to handle typechecking against the subset when it has not been parameterized. If it's not desirable for a parametric subset to be possible to use without being parameterized, one way you can prevent this from happening is to give it a stubbed refinement:

```perl6
subset Identity will parameterize -> Mu \T {
    T
} where { ... };
```

Refer to `t/02-will.t` for more examples of how to use this trait.

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

