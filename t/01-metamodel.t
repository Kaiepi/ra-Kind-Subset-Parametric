use v6;
use MetamodelX::ParametricSubset;
use Test;

plan 8;

subset SpeedLimit of Numeric where 0..110;

lives-ok {
    my &body_block = { 0..$_ };
    SpeedLimit.HOW.^mixin: MetamodelX::ParametricSubset;
    SpeedLimit.^set_body_block: &body_block;
}, 'can mark a subset as being parametric';

cmp-ok SpeedLimit.^refinee, '=:=', Numeric,
  'parametric subsets keep their original refinee';
is SpeedLimit.^name, 'SpeedLimit',
  'parametric subsets keep their original name';

my \SlowDownBuddy = SpeedLimit.^parameterize: 1_000_000;
cmp-ok SlowDownBuddy.^refinee, '=:=', SpeedLimit.^refinee,
  'parameterized subsets keep their original refinee';
cmp-ok (0..1_000_000), &[~~], SlowDownBuddy.^refinement,
  'parameterized subsets have an appropriate refinement';
is SlowDownBuddy.^name, SpeedLimit.^name ~ '[' ~ 1_000_000.raku ~ ']',
  'parameterized subsets have an appropriate name';

cmp-ok 1, &[~~], SlowDownBuddy,
  'can typecheck appropriate values against parameterized subsets';
cmp-ok -1, &[!~~], SlowDownBuddy,
  'cannot typecheck inappropriate values against parameterized subsets';

# vim: ft=raku sw=4 ts=4 sts=4 et
