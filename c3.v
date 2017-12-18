(** * Programming in the XXIInd century: effectful programming *)

Require Import Lists.List.
Import ListNotations.
Require Import FunctionalExtensionality.

(** So far, we have mostly used Coq as a theorem prover. However,
    every now and then, we have used it for implementing purely
    functional programs. These programs cannot store data in memory,
    cannot raise exceptions, cannot be non-deterministic, etc.

    The world of Coq programs is a world of mathematical functions. As
    such, and in a first approximation, these functions are _pure_:
    given an input, it always produces the same output. This makes
    reasoning about programs almost trivial: we are merely studying a
    mathematical function. However, this also forbids common idioms,
    such as maintaining some hidden state, or manipulating random
    numbers, or raising runtime errors.

    In a previous lecture, we have used Coq to provide several
    _operational_ semantics to some programming languages. In the
    following, we shall give some _denotational_ semantics to two
    languages embedded in Coq. As a result, we will (re-)discover a
    way to write effectful programs in a pure language. *)

(** ** Stateful computations *)

Module State.

(** *** Enters the _free monad_ *)

(**

As usual, if we want to talk about stateful programs, we need some
syntax for representing these programs. Building on the lesson learned
in Lecture 1, we choose to split our definition in two: we implement a
domain-specific _signature_ [sigma_state] -- which refers to the
stateful operations we are interested in -- and an inductive
definition [state] tying the knot over the signature.

*)

Inductive sigma_state (R : Type): Type :=
| OpGet : unit -> (nat -> R) -> sigma_state R
| OpSet : nat -> (unit -> R) -> sigma_state R.

Inductive state (X : Type): Type :=
| ret : X -> state X
| op : sigma_state (state X) -> state X.

Arguments OpGet [_] tt k.
Arguments OpSet [_] n k.
Arguments ret [_] x.
Arguments op [_] ms.

(** In this (very small) language, we can define the following smart
constructors, whose type should look familiar: *)

Definition get (tt: unit): state nat := op (OpGet tt (fun n => ret n)).
Definition set (n: nat): state unit := op (OpSet n (fun tt => ret tt)).

(** At this point, they are nothing but syntax. Later, we shall make
sure that they acquire their intended semantics: [get] should allow us
to retrieve an integer from local state, while [set] should allow us
to store its argument in memory. *)


(** **** Exercise: 1 star *)
(** As usual, the signature is in fact a _functor_, ie. it comes
    equipped with a transport map: *)

Definition sigma_state_map {A B} (f : A -> B)(xs: sigma_state A) : sigma_state B :=
  match xs with
    | OpGet u k => OpGet u (fun n => f (k n)) 
    | OpSet n k => OpSet n (fun u => f (k u))
  end.


(** By exploiting the above functor, we can implement a form of
_composition_ (some may say _sequencing_!) of stateful programs, whose
intuitive meaning is made obvious by some suitable syntactic sugar. *)

Fixpoint bind {X Y} (mx: state X)(f: X -> state Y): state Y :=
  match mx with
  | ret x => f x
  | op msx => op (sigma_state_map (fun mx => bind mx f) msx)
  end.

Notation "'let!' x ':=' mx 'in' f" := 
  (bind mx (fun x => f)) (at level 50).


(** We can now write some familiar-looking program. Once again, bear
in mind that this is thus syntax at this stage. *)

Example test (n : nat) : state nat :=
  let! _ := set 1 in
  let! m := get tt in
  let! _ := set (m + m) in
  let! k := get tt in
  ret k.

Set Printing All.
Eval compute -[plus] in test.
Unset Printing All.

(**
Check nat_iter.
**)
Fixpoint nat_iterM {A}(n: nat)(rec: A -> state A)(bc: state A): state A :=
  match n with
  | 0 => 
    bc
  | S n => 
    let! a := nat_iterM n rec bc in
    rec a
  end.

Example fact (n : nat): state nat :=
  let! _ := set 1 in
  let! _ := nat_iterM n 
                      (fun k => 
                         let! x := get tt in
                         let! _ := set (x * k) in
                         ret (S k))
                      (ret 1) in
  get tt.

(** *** Monad _laws_ *)

(**

We have equipped the datatype [state] with quite a bit of
_structure_. Before delving further into the the specifics of stateful
computations, we are going to prove 3 general results, called the
_monad laws_, which we expect to hold for any such structure,
irrespectively of its particular semantics.
*)

(** **** Exercise: 2 stars *)
(** 
To do so, we will need to reason by induction over the [state]
datatype.  Unsurprisingly, the induction principle automatically
generated by Coq for the datatype [state] is incorrect. You should
manually implement a working induction principle: 

*)
(**
[[
Fixpoint state_ind_mult
         (X : Type)(P : state X -> Prop)
         (ih_ret : forall x : X, P (ret x)) 
         (ih_get : forall tt k, (forall n, P (k n)) -> P (op (OpGet tt k)))
         (ih_set : forall n k, (forall tt, P (k tt)) -> P (op (OpSet n k)))
         (s : state X): P s.
]]

 *)

Fixpoint state_ind_mult
         (X : Type)(P : state X -> Prop)
         (ih_ret : forall x : X, P (ret x)) 
         (ih_get : forall tt k, (forall n, P (k n)) -> P (op (OpGet tt k)))
         (ih_set : forall n k, (forall tt, P (k tt)) -> P (op (OpSet n k)))
         (s : state X): P s.
Proof.
  induction s; simpl.
  + apply ih_ret.
  + destruct s.
    - apply ih_get.
      intro.
      now apply state_ind_mult.
    - apply ih_set.
      intro.
      now apply state_ind_mult.
Qed.

(**

The monadic laws specify the interaction between [ret] -- which brings
pure values into stateful programs -- and [bind] -- which applies
stateful programs.
*)

(** **** Exercise: 1 star *)
(**
The first law states that applying a stateful program to a pure value
amounts to performing a standard function application or, put
otherwise, [ret] is a left unit for [bind].

*)
(** 

[[
Lemma bind_left_unit {X Y}:
  forall (x: X)(k: X -> state Y),
    (let! y := ret x in k y) = k x.
]]

 *)

Lemma bind_left_unit {X Y}:
  forall (x: X)(k: X -> state Y),
    (let! y := ret x in k y) = k x.
Proof.
  intros.
  simpl.
  reflexivity.
Qed.  

(** **** Exercise: 2 stars *)
(** The second law states that returning a stateful value amounts to
giving the stateful computation itself or, put otherwise, [ret] is a
right unit for [bind]. *)

(**
[[
Lemma bind_right_unit {X}:
  forall (mx: state X),
    let! x := mx in ret x = mx.
]]
 *)

Lemma bind_right_unit {X}:
  forall (mx: state X),
    let! x := mx in ret x = mx.
Proof.
  intros.
  induction mx using state_ind_mult; simpl.
  + reflexivity.
  + repeat f_equal.
    apply functional_extensionality.
    apply H.
  + repeat f_equal.
    apply functional_extensionality.
    apply H.
Qed.
      
(** **** Exercise: 2 stars *)
(** Finally, the third law states that we can always parenthesize
[bind]s from left to right or, put otherwise, [bind] is
associative. *)
(**
[[
Lemma bind_compose {X Y Z}:
  forall (mx: state X)(f: X -> state Y)(g: Y -> state Z),
      (let! y := (let! x := mx in f x) in g y)
      = (let! x := mx in let! y := f x in g y).
]]
*)


(**

There is a familiar object that offers a similar interface: (pure)
function! For which [bind] amounts to composition and [ret] is the
identity function. Monads can be understood as offering "enhanced"
functions, presenting a suitable notion of composition and identity
_as well as_ effectful operations. For the programmer, this means that
we have [let _ := _ in _] for pure functions and [let! _ := _ in _]
for effectful functions, both subject to (morally) the same laws of
function composition.

*)


(** *** Equational theory *)

Reserved Notation "tm1 '~>' tm2" (at level 40).
Reserved Notation "tm1 '~=' tm2" (at level 40).

(**

It is about time to put some semantics on these syntactic objects. We
follow an operational approach, by which we relationally specify the
reduction behavior of our embedded language.

*)

Inductive state_red {X} : state X -> state X -> Prop :=
| state_get_get: forall{k : nat -> nat -> state X},
    
    (let! x := get tt in 
     let! y := get tt in
     k x y)
        ~>
    (let! x := get tt in
     k x x)

| state_set_set: forall {k : state X}{n1 n2},

    (let! _ := set n1 in
     let! _ := set n2 in
     k)
        ~>
    (let! _ := set n2 in k)

| state_set_get: forall {k : nat -> state X} {n},

    (let! _ := set n in
     let! x := get tt in
     k x)
        ~>
    (let! _ := set n in k n)

| state_get_set: forall {k : state X},

    (let! n1 := get tt in
     let! _ := set n1 in
     k)
        ~>
    k
    
where "tm1 '~>' tm2" := (@state_red _ tm1 tm2).

(**

We obtain a notion of _program equivalence_ by considering the
reflexive, symmetric and transitive closure of the reduction relation.

 *)

Inductive state_equiv {X} : state X -> state X -> Prop :=
| state_inc : forall {p1 p2 : state X},

    p1 ~> p2 -> 
  (*--------*)
    p1 ~= p2

| state_sym: forall{p1 p2 : state X},

    p1 ~= p2 ->
  (*--------*)
    p2 ~= p1

| state_trans: forall{p1 p2 p3 : state X},

    p1 ~= p2 -> 
    p2 ~= p3 ->
  (*--------*)
    p1 ~= p3

| state_refl: forall{p : state X},

  (*--------*)
    p ~= p

| state_congr: forall{Y}{p1 p2 : state Y}{k1 k2 : Y -> state X},
    
    p1 ~= p2 ->                 (forall x, k1 x ~= k2 x) ->
  (*------------------------------------------------*)
    (let! x := p1 in k1 x) ~= (let! x := p2 in k2 x)
    
where "tm1 '~=' tm2" := (@state_equiv _ tm1 tm2).

(** We can now formally reason about the equivalence of programs. As
mentioned in the previous lecture, this is not only of formal
interest: this is also at the heart of compiler optimizations, code
refactoring, etc. *)

Example prog1 := 
  let! x := get tt in
  let! _ := set (1 + x) in
  let! y := get tt in
  let! _ := set (2 + x) in
  let! z := get tt in
  let! _ := set (3 + y) in
  ret y.

Example prog2 :=
  let! x := get tt in
  let! _ := set (4 + x) in
  ret (1 + x).

Example prog_equiv1: prog1 ~= prog2.
Proof.
unfold prog1, prog2.
apply state_congr. constructor(now auto).
intro n.
eapply state_trans; [ constructor(now apply state_set_get) | ]. 
eapply state_trans; [ constructor(now apply state_set_set) | ].
eapply state_trans; [ constructor(now apply state_set_get) | ].
eapply state_trans; [ constructor(now apply state_set_set) | ]. 
apply state_refl.
Show Proof.
Qed.

(** *** Evaluation *)

(**

When we look at [state_red] right in the eyes, we notice that every
[state X] program can be equivalently written as 

[[
let! x := get tt in 
let! _ := set (f x) in
ret! (g x)
]]

where [f : nat -> nat] and [g : nat -> X]. Put otherwise, every
stateful program reduces to a normal form which is entirely
characterized by a function of type [nat -> nat * X].

*)

Definition sem_state (X: Type) := nat -> nat * X.

Definition reify {X} (f: sem_state X): state X :=
  let! x := get tt in
  let! _ := set (fst (f x)) in
  ret (snd (f x)).

(** **** Exercise: 2 stars *)
(**

In fact, we can compute this normal form within Coq itself: we obtain
an evaluation function! Following Lecture 1, we should do so by defining
a semantic-specific algebra and generically tying-the-knot on the side.

[[
Definition sigma_state_alg {X} (ms: sigma_state (sem_state X)): sem_state X := 
   (...).

Fixpoint eval {X}(ms: state X) : sem_state X := 
   (...).
]]

 *)

Fixpoint eval {X}(ms: state X) : sem_state X.
refine (match ms with
          | ret x => fun n => (n, x)
          | op (OpGet tt k) => fun n => eval _ (k n) n
          | op (OpSet n k) => fun m => eval _ (k tt) n
        end).
unfold sem_state.
Print sigma_state.


(** **** Exercise: 1 star *)
(**

We can unit-proof our evaluation function by showing the following two
lemmas specifying the desired behavior of this function.

[[
Remark unfold_get {X}: forall tt (k : nat -> state X) n,

    eval (let! x := get tt in k x) n = eval (k n) n.

Remark unfold_set {X}: forall n (k : unit -> state X) m,

    eval (let! _ := set n in k tt) m = eval (k tt) n.
]]
*)


(**

By composing the evaluation and reification functions, we hope to
obtain a _normalization_ function: [eval] computes the extensional
semantics of a stateful computation while [reify] brings it back into
the world of syntax.

 *)

Definition norm {X}(ms: state X): state X := reify (eval ms).

(** *** Monads strike back *)

(**

Looking closely at the [eval] function, we notice that we _map_
syntactic objects -- of type [state X] -- to semantics objects -- of
type [sem_state X]. The natural question to ask is whether all the
structure defined over [state X] carries over to [sem_state X], ie. is
there a semantical counterpart to [ret], [get], [set] and [bind]?
*)

(**

The semantical versions of [ret], [get] and [set] are already given by
[eval]:

 *)

Definition sem_ret {X} (x: X): sem_state X := eval (ret x).
Definition sem_get (tt: unit): sem_state nat := eval (get tt).
Definition sem_set (n: nat): sem_state unit := eval (set n).
Reset sem_ret.

(** **** Exercise: 1 star *)
(**

But we can also define it directly, using types to guide us:

[[
Definition sem_ret {X} (x: X): sem_state X := (..).
Definition sem_get (tt: unit): sem_state nat := (..).
Definition sem_set (n: nat): sem_state unit := (..).
]]

*)



(**

You should unit-proof your definition:

[[
Lemma unit_ret {X}: forall x : X, eval (ret x) = sem_ret x.
Lemma unit_get: forall n, eval (get tt) n = sem_get tt n.
Lemma unit_set: forall m n, eval (set m) n = sem_set m n.
]]

 *)


(** **** Exercise: 2 stars *)
(** 

Similarly, there is a [bind] over semantical states:

[[
Definition sem_bind {X Y}
           (mx : sem_state X)(k : X -> sem_state Y): sem_state Y
]]

 *)


Notation "'let!S' x ':=' mx 'in' f" := (sem_bind mx (fun x => f)) 
                                       (at level 50).

(**

whose unit-proof is:


[[
Lemma eval_compose {X Y}: forall (p1 : state X)(k : X -> state Y) n,

    eval (let!x := p1 in k x) n = (let!S x := eval p1 in eval (k x)) n.
]]

*)


(**

Note: in conclusion, we have been able to transport _all_ the
syntactic structure of [state X] to [sem_state X]. In fact, we could
be so bold as to directly work in [sem_state]: this is what most
functional programmers do.

 *)

(** *** Normalization by evaluation *)

(**

We have thus implemented two semantics: an operational presentation --
[state_equiv] -- and a denotational one -- [eval]. We should prove
that they are indeed equivalent.

We have also claimed to have identified the normal form of stateful
programs. We should prove that this is indeed the case.

Both aspects are intrinsically linked: as we shall see below, showing
one amounts to showing the other. To understand how, let us write the
most precise specification for [norm], ie. for each stateful program,
it computes an equivalent stateful program in normal form and any
other equivalent program has the exact same normal form:

 *)


Definition norm_correct {X}:
  forall (ms: state X),
      exists nf : state X,
               ms ~= nf 
             /\ forall ms', ms ~= ms' -> nf = norm ms'.
intro ms. exists (norm ms).
split.
- admit.
- admit.
Abort.

(** **** Exercise: 5 stars *)
(**

This proof gives rise to two interesting proof obligations that are
worth proving independently:

[[
Lemma pre_complete {X}: 
    forall {p q : state X}, p ~= q -> forall {s}, eval p s = eval q s.

Lemma pre_sound {X}: 
    forall (p : state X), p ~= norm p.
]]
*)


(** **** Exercise: 2 stars *)
(**

We can massage [pre_sound] to show that the normal forms respect the
congruence [~=], which amounts to the _soundness_ of this procedure:

[[
Theorem sound : forall {X} (p1 p2 : state X), norm p1 = norm p2 -> p1 ~= p2.
]]
*)

(**

while massaging [pre_complete] allows us to show that this procedure
is _complete_, ie. if two programs are semantically equivalent then
there normal forms are the same:

[[
Theorem complete : forall {X} (p1 p2 : state X), p1 ~= p2 -> norm p1 = norm p2.
]]

 *)



(** **** Exercise: 1 star *)
(** Using these results, we can conclude the proof aborted above and
justify our earlier statement: [eval] indeed computes the normal form
of stateful programs. *)



(**

We can exploit soundness of our decision procedure to prove
equivalences of programs _by (computational) reflection_. This is a
very important (and beautiful!) proof technique in type theory.

 *)

Example prog_equiv1': prog1 ~= prog2.
Proof. apply sound. compute. reflexivity. Show Proof. Qed.

(** We can also actually [run] our programs, provided some initial
state: *)

Definition run {X}(mx: state X)(init: nat): X := snd (eval mx init). 

Remark unit_proof_fact0: run (fact 0) 0 = 1.
Proof. reflexivity. Qed.

Remark unit_proof_fact1: run (fact 1) 0 = 1.
Proof. reflexivity. Qed.

Remark unit_proof_fact5: run (fact 5) 0 = 120.
Proof. reflexivity. Qed.

End State.

(** ** Error-prone computations *)


Module Failure.

(**

Let us now consider another effect: signaling an error (which, unlike
exceptions, cannot be caught). We are going to "skip the middleman"
and work directly with semantics here.

The first step consists in defining a type that supports such partial
functions. This is precisely what the [option] type offers.

 *)

Definition failure_sem X := option X.

Definition error {X} (tt: unit): failure_sem X := None.

(** **** Exercise: 2 stars *)
(**

We then make sure that we have a monadic structure:

[[
Definition ret {X} (x: X): failure_sem X := (..).

Definition bind {X Y} (mx : failure_sem X)
    (f : X -> failure_sem Y): failure_sem Y := (..).
]]

*)


Notation "'let!' x ':=' mx 'in' f" := (bind mx (fun x => f)) 
                                       (at level 50).

(**

As usual, we write a unit-proof to make sure that our implementation
matches its desired behavior:

[[
Remark unit_proof_fail {X}: forall k,  let! _ := @error X tt in k = @error X tt.
]]

 *)


(** And we can actually run these programs and observe the desired
short-cutting mechanism: *)

Axiom impossible : nat -> nat.

Definition may_shortcut (b : bool) := 
  let! n := if b then error tt else ret 15 in
  if b then
    ret (impossible n)
  else
    ret n.

Remark unit_proof_shortcut1: may_shortcut true = None.
Proof. reflexivity. Qed.

Remark unit_proof_shortcut2: may_shortcut false = ret 15.
Proof. reflexivity. Qed.

End Failure.

(** *** Exercise: 5 stars, optional *)
(** Following the syntactic approach outlined for the state
monad, give a syntactic and equational presentation of the failure
monad. Show that your equational theory is sound and complete with
respect to the one above. Use soundness to show that the program

[[
Axiom long_computation : nat -> nat.
Definition prog1 := let! x := error tt in
                    ret (long_computation x).
]]

is equivalent to

[[
Definition prog2 := let! x := (error tt : failure nat) in 
                    ret 0.
]]
*)


(** ** Stateful & error-prone computations *)

Module StateFailure.

(**

Let us now suppose that we would like to write a stateful and
error-prone program: we need to _combine_ both effects. At the
syntactic level, this is straightforward: we just need to take the
union of both signatures.

[[
Inductive sigma_state_failure (R : Type): Type :=
| OpState : ??? -> sigma_state_failure R
| OpFailure : ??? -> sigma_state_failure R.
]]

 *)


(**

We must then define the semantics of the resulting system. Since we
have followed an algebraic approach, we can in fact combine the
semantics of state and failure -- defined earlier -- to specify the
semantics of stateful effects.

 *)

(** **** Exercise: 5 stars, optional *)
(** Work out one possible semantics for stateful, error-prone
programs, including its equational theory, an evaluation function and
its soundness proof. *)

End StateFailure.

(** ** Conclusion *)

(** We have seen how we can _model_ and therefore _implement_ some
    effects in a pure and total functional language. We have only
    touched at the tip of the iceberg: there are many effects, such as
    logging, non-determinism, non-termination, or exceptions that can
    be modelled through monads. For more examples, see for example
    Xavier Leroy's #<a
    href="http://gallium.inria.fr/~xleroy/mpri/2-4/">lecture</a># on
    the topic. *)

(** Monads are much more than an implementation trick for pure
    languages. We observe that, thanks to monads, we can read the
    potential effects of a function off its type: in the 90's, such
    _type-and-effect_ systems were extremely fashionable and even
    became mainstream in Java, with the "checked exceptions"
    mechanism. *)

(** By decoupling the syntax of effects from its semantics, we also
    open a new form of generic programming: _effect-generic_
    programming. By implementing several interpretation functions, we
    can interpret a single effectful program in various manners. *)


(** Note that we have never actually _run_ a single program in this
    file.  Instead, we have extensively relied on "unit-proofs" to
    check that our definitions had their intended meaning. If it
    type-checks, it is correct: why would you run it?! *)


(** *** Lessons learned *)

(** 
- monad = return + bind + operations
- type theory = syntax + semantics
- [refine] is your friend when programming with dependent types
 *)

(** *** Take away *)

(**
- you can: specify and implement the [return] and [bind] operations
- you can: check the monad laws 
- you can: exploit normalization-by-evaluation to optimize proofs
 *)

(** ** Next week *)

(** Come with c2.v finished and compiled! *)