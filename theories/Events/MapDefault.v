(** * Mutable map whose lookup operation provides a default value.*)

(* begin hide *)
Set Implicit Arguments.
Set Contextual Implicit.

From ExtLib Require Import
     Core.RelDec.

From ExtLib.Structures Require
     Functor Monoid Maps.

From ITree Require Import
     Basics.Basics
     Basics.CategoryOps
     Core.ITreeDefinition
     Indexed.Sum
     Core.Subevent
     Interp.Interp
     Events.State.

Import ITree.Basics.Basics.Monads.
(* end hide *)

Section Map.

  Variables (K V : Type).

  Variant mapE (d:V) : Type -> Type :=
  | Insert : K -> V -> mapE d unit
  | LookupDef : K -> mapE d V
  | Remove : K -> mapE d unit
  .

  Arguments Insert {d}.
  Arguments LookupDef {d}.
  Arguments Remove {d}.
  
  Definition insert {E d} `{(mapE d) -< E} : K -> V -> itree E unit := embed Insert.
  Definition lookup_def {E d} `{(mapE d) -< E} : K -> itree E V := embed LookupDef.
  Definition remove {E d} `{(mapE d) -< E} : K -> itree E unit := embed Remove.

  Import Structures.Maps.

  Context {map : Type}.
  Context {M : Map K V map}.

  Definition lookup_default {K V} `{Map K V} k d m :=
    match Maps.lookup k m with
    | Some v' => v'
    | None => d
    end.
  
  Definition handle_map {E d} : mapE d ~> stateT map (itree E) :=
    fun _ e env =>
      match e with
      | Insert k v => Ret (Maps.add k v env, tt)
      | LookupDef k => Ret (env, lookup_default k d env)
      | Remove k => Ret (Maps.remove k env, tt)
      end.

  Definition run_map {E d} : itree (mapE d +' E) ~> stateT map (itree E) :=
    interp_state (case_ handle_map pure_state).


  (* The appropriate notation of the equivalence on the state associated with
     the MapDefault effects.  Two maps are  *)
  Definition eq_map (d:V) (m1 m2 : map) : Prop :=
    forall k, lookup_default k d m1 = lookup_default k d m2.
  
End Map.

Arguments mapE {K V} d.
Arguments insert {K V E _}.
Arguments lookup_def {K V E _}.
Arguments remove {K V E _}.
Arguments run_map {K V map M _ _} [T].
Arguments eq_map {K V map M}.
