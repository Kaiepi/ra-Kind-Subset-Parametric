use v6;
use Kind::Subset::Parametric;
use Test;

plan 4;

subtest 'identity', {
    my subset Identity will parameterize -> Mu \T {
        T
    } where { !!! };

    plan 3;

    dies-ok { Any ~~ Identity },
      'typechecking with an unparameterized Identity throws';

    given Identity[Int] -> \IntIdentity {
        cmp-ok Int, &[~~],  IntIdentity,
          'can typecheck the parameter of Identity';
        cmp-ok Any, &[!~~], IntIdentity,
          'cannot typecheck anything else';
    }
};

subtest 'typed arrays', {
    my subset TypedArray of Array will parameterize -> Mu ::T { -> Array \array {
        array ~~ Array[T] || (array ~~ Array:D && so array.all ~~ T)
    } } where { !!! };

    plan 5;

    dies-ok { Array ~~ TypedArray },
      'typechecking with an unparameterized TypedArray throws';

    given TypedArray[Int] -> \IntArray {
        my Int @int = [1, 2, 3];
        cmp-ok @int, &[~~], IntArray,
          'can typecheck Array[Int]';
        cmp-ok (my @ = @int), &[~~], IntArray,
          'can typecheck Array:D as well if it contains only Int';

        my Str @str = <foo bar baz>;
        cmp-ok @str, &[!~~], IntArray,
          'cannot typecheck Array parameterized with a type invariant to Int';
        cmp-ok (my @ = @str), &[!~~], IntArray,
          'cannot typecheck Array:D either if it contains any value of a type invariant to Int';
    }
};

subtest 'failable', {
    my subset Failable will parameterize -> Mu \T {
        T | Failure:D
    } where { !!! };

    plan 4;

    dies-ok { Any ~~ Failable },
      'typechecking with an unparameterized Failable throws';

    sub compile-on-second-try(--> Str:D) {
        once { fail '*%@$' }
        return "i've been waiting my whole life for this";
    }

    given Failable[Str] -> \FailableStr {
        cmp-ok compile-on-second-try, &[~~], FailableStr,
          'can typecheck Failure:D';
        cmp-ok compile-on-second-try, &[~~], FailableStr,
          'can typecheck the parameter of Failable';
        cmp-ok Any, &[!~~], FailableStr,
          'cannot typecheck anything else';
    }
};

subtest 'contravariance', {
    my subset Contravariant will parameterize -> Mu ::T { -> Mu ::U {
        Metamodel::Primitives.is_type: T, U
    } } where { !!! };

    my class Animal {
        proto method in-group(::?CLASS:_: Mu --> Bool:D)                 {*}
        multi method in-group(::T: Mu $ where Contravariant[T] --> True) { }
        multi method in-group(::?CLASS:_: Mu --> False)                  { }
    }

    my class Mammal is Animal { }

    my class Raccoon is Mammal { }

    my class Cat is Mammal { }

    my class RussianBlue is Cat { }

    plan 7;

    dies-ok { Any ~~ Contravariant },
      'typechecking with an unparameterized Contravariant throws';

    if $*RAKU.compiler.version < v2022.12 {
        skip-rest 'generics support required NYI';
    } else {
        nok Mammal.in-group(Raccoon),
          'mammals are not always raccoons...';
        nok Mammal.in-group(Cat),
          '...or cats...';
        ok Cat.in-group(Mammal),
          '...but cats are mammals...';
        ok Raccoon.in-group(Mammal),
          '...alongside raccoons...';
        ok RussianBlue.in-group(Cat),
          '...and Russian blue cats are cats...';
        nok RussianBlue.in-group(Raccoon),
          '...but not raccoons';
    }
};

# vim: ft=raku sw=4 ts=4 sts=4 et
