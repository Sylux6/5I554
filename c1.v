Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Set Contextual Implicit.

Require Import List.
Import ListNotations.

(** * Induction, inductive types, families & predicates *)

(**

You spent high-school doing "proofs by induction" over natural
numbers. Working in a proof assistant is a bit like going back to
high-school excepted that we shall be reasoning by induction on more
structured objects: inductive types, families and/or predicates.

 *)

(** ** Motivation *)

(** *** Practical limitations *)

(**

In Coq, we can define the following datatype and, for example, a
reversal function:

 *)

Inductive rosetree :=
| rosenode : nat -> list rosetree -> rosetree.

Fixpoint rev_rosetree (t: rosetree): rosetree :=
  match t with
  | rosenode n ts => 
    rosenode n (fold_left 
                  (fun xs t => rev_rosetree t :: xs) ts [])
  end.

Compute (rev_rosetree (rosenode 1 [rosenode 2 []; rosenode 3 []])).

(**

However, the induction principle automatically generated by Coq is
rather unsettling:

 *)

Check rosetree_rect.

(** 

Let us try to use to prove a property of [rev_rosetree]:

*)

Lemma rev_rev_rosetree: 
  forall t, rev_rosetree (rev_rosetree t) = t.
Proof. induction t. (* WTF?! *) Abort.


(** **** Exercise: 5 stars (rosetree_ind')  *)
(**

Implement a valid induction principle of [rosetree] and prove the
above lemma.

*)

(** *** Theoretical limitations *)

(**

Why is the following definition rejected?

 *)

Fail Inductive term :=
| App : term -> term -> term
| Abs : (term -> term) -> term.

(* 
Error: Non strictly positive occurrence 
of "term" in "(term -> term) -> term".
*)

(** ** Inductive types *)

(** *** Signatures *)

(**

The (little known) origins of inductive types is rooted in the
mathematical study of (universal) algebra
[http://dx.doi.org/10.1145/321992.321997]. We can therefore establish
a dictionary between the programming world and the mathematical world
and exploit this connection to reason abstractly about datatypes as
programmers manipulate them:

  - an (algebraic) "datatype" corresponds to a "signature"
  - a "constructor" corresponds to an "operation"
  - a "recursive argument" in a constructor corresponds to its "arity"

*)

(** **** Exercise: 1 star (fml) *)
(**

Implement a datatype [Fml] of propositional formulas parameterized
over [P : Set] that implements the following description found in
"Mathematical logic" (Cori & Lascar):

    ``The set [Fml] of propositional formulas over [P] is the
      smallest set that

    - contains [P]
    - contains [¬ F], for every formula [F] it contains
    - contains [F ∧ G], [F ∨ G] and [F ⇒ G], for
      every [F] and [G] it contains''

 *)

Variable P : Type.

Inductive fml : Type :=
  | Simple : P -> fml
  | Not : P -> fml
  | And : P -> P -> fml
  | Or : P -> P -> fml
  | Imply : P -> P -> fml.


(** 

In this section, we consider the familiar datatype of binary trees:

*)

Inductive tree : Type := 
| Leaf : tree
| Node : nat -> tree -> tree -> tree.

(** **** Exercise: 1 star (tree)  *)
(** What is the arity of the [Leaf] constructor? What is the arity of
the [Node] constructor? *)

(**

In fact, given an inductive type, such as [tree] above, we can
_always_ decompose it into a non-recursive signature ([sigma_tree],
below) and a generic fixpoint operator ([tree'], below):

 *)

Inductive sigma_tree (X: Type): Type := 
| OpLeaf : sigma_tree X
| OpNode : nat -> X -> X -> sigma_tree X.

Inductive tree' : Type :=
  | Constr : sigma_tree tree' -> tree' .

(**

The non-recursive definition [sigma_tree] is generally called the
"signature functor" of the inductive type. It is built from a fixed
grammar of type operators: product, sums and functions. Put another
way, algebraic datatypes are said to be defined by "sums of
products". The generic fixpoint operator is said to "tie the knot" by
defining [tree'] through a layer of [sigma_tree] applied to [tree']
itself.

*)

(** **** Exercise: 1 star (iso_tree_tree')  *)

(** Implement a pair of functions [phi : tree -> tree'] and [psi :
tree' -> tree] witnessing the fact that the types [tree'] and [tree]
are isomorphic. *)

Fixpoint phi (t: tree) : tree' :=
  match t with
    | Leaf => Constr OpLeaf
    | Node n l r => Constr (OpNode n (phi l) (phi r))
  end.

Fixpoint psi (t: tree') : tree :=
  match t with
    | Constr t' => match t' with
                    | OpLeaf => Leaf
                    | OpNode n l r => Node n (psi l) (psi r)
                  end
  end.

(** **** Exercise: 2 stars (psi_phi)  *)
(** Prove the following lemma: *)

Lemma psi_phi: forall t, psi (phi t) = t.
Proof.
  intros.
  induction t.
  - simpl.
    reflexivity.
  - simpl.
    rewrite IHt1.
    rewrite IHt2.
    reflexivity.
Qed.

(** **** Exercise: 5 stars (phi_psi)  *)
(** Prove the following lemma: *)

Lemma phi_psi: forall t, phi (psi t) = t.
Proof.
  intros.
  induction t.
Admitted.

(** *** Initiality *)

Section List.

Variable A X: Type.

(** **** Exercise: 2 stars (sigma_list)  *)

(** Decompose the datatype [list A] into a signature [sigma_list] and
its fixpoint [list']. Convince yourself (or prove) that [list A] is
isomorphic to [list']. *)

Inductive sigma_list (X: Type) :=
| ListNil : sigma_list X
| ListCons : A -> X -> sigma_list X.

Inductive list' : Type :=
| ListConstr : sigma_list list' -> list'.

(** We assume that we are given an _algebra_ [alpha] over lists: *)

Variable alpha : sigma_list X -> X.

(** **** Exercise: 3 stars (fold_list)  *)

(** Using [alpha], implement a function [fold_list] of type [list A ->
X]. You may find some inspiration by using [Print] on Coq's
implementation of [fold_right]. *)

Print fold_right.

Fixpoint fold_list (l: list A) : X :=
  match l with
    | [] => alpha ListNil
    | n :: t => alpha (ListCons n (fold_list t))
  end.

Print fold_list.

End List.

(** **** Exercise: 3 stars (fold_length)  *)
(** By defining a suitable algebra [alpha_length], implement the
function [length : list A -> nat] using [fold_list]. *)
  
Fixpoint alpha_length (A: Type) (l: list A) : nat :=
  fold_list l.

Section FoldTree.

Variable X: Type.

(** **** Exercise: 4 stars (fold_tree)  *)
(** Using [alpha], implement a function [fold_tree] of type [tree ->
X]. *)

Fixpoint fold_tree (t: tree) : X :=
  match t with
    | Leaf => alpha OpLeaf
    | Node n l r => alpha OpNode (n (alpha l) (alpha r))
  end.


Axiom fold_tree : forall (alpha : sigma_tree X -> X), tree -> X. (* XXX: implement me! *)


(**

We can show (in meta-mathematics, not in Coq), that every algebra
[alpha : sigma_tree X -> X] induces a unique function [tree -> X]: this
is called the _initial algebra semantics_ of inductive types. This is
the equivalent of a Design Pattern for functional programmers: it is a
general principle for understanding recursion.

*)

End FoldTree.

(** **** Exercise: 3 stars (fold_height)  *)
(** By defining a suitable algebra [alpha_height], implement the
function [height : tree -> nat] using [fold_tree]. *)


(** *** Interlude: visitor pattern *)

(** Object-oriented programmers will recognize a familiar (if more
verbose) pattern in [fold_tree]: *)

(**
<<
interface TreeVisitor {
    void visit(Node n);
    void visit(Leaf l);
}

interface TreeElement {
    void accept(TreeVisitor visitor);
}

class Node implements TreeElement {
    private int x;
    print TreeElement l, r;

    public void accept(TreeVisitor visitor) {
        l.accept(visitor); visitor.visit(this); 
        r.accept(visitor);
    }
    (...)
}
>> 
*)


(** ** Induction over inductive types *)

(** 

Let us consider the skeleton of a high-school proof by induction:

  - Statement:
    "We show by recurrence the following property: ``for all n, P(n)''"
  - Initialization:
    "We show that the property is true for n = 0, ie. P(0)."
  - Heredity:
    "Assume that the property is true at m, ie. P(m). We show that the 
     property is true at P(m+1)."
  - Conclusion:
    "By recurrence, we conclude that the property is true for all n."

In type theory, this translates to:

*)

Section TestInd.

Hypothesis P: nat -> Type.              (** Statement *)
Hypothesis init: P 0.                (** Initialization *)
Hypothesis step: forall m, P m -> P (S m). (** Heredity *)
Check (nat_rect P init step).        (** Conclusion *)

End TestInd.

(**

However, induction is not limited to natural numbers! In particular,
in lecture 2, we shall see that we can perform induction on semantics
judgements (ie. inductively defined relations). To understand
induction more generally, we consider the datatype of trees, whose
induction principle (automatically generated by Coq) is instructive:

*)    

Check tree_rect.
(* tree_rect
     : forall P : tree -> Type,
       P Leaf ->
       (forall (n : nat) (t : tree), P t -> forall t0 : tree, P t0 -> P (Node n t t0)) ->
       forall t : tree, P t
*)

(** This type signature exhibits some similarity with the type
signature of the recursion principle over trees [fold_tree]. To
simplify our study of induction principles, we adopt a _uniform_
treatment of the inductive hypothesis, using a gadget similar to
[sigma_tree]. *)

Section Tree_rect'.

Hypothesis P: tree -> Type.

(** **** Exercise: 3 stars (sigma_ind_tree)  *)
(** Define a non-recursive predicate [sigma_ind_tree : tree -> Type]
that asserts that [P] holds in every subtree of the given tree. Do you
identify any similarity with [sigma_tree]? *) 

Inductive sigma_ind_tree: tree -> Type :=
.

(** [sigma_ind_tree] is called the _predicate lifting_: it applies the
predicate [P] to all subtrees of a given node. *)

(** **** Exercise: 5 stars (tree_rect')  *)
(** Implement the uniform induction principle [tree_rect'] *) 

Definition tree_rect':
 (forall t, sigma_ind_tree t -> P t) -> forall t : tree, P t.
Proof.
  admit.
Defined.


(** The function of type [forall t, sigma_ind_tree t -> P t] required by the
induction principle is genuinely a (uniformly presented) _induction
step_: we must explain how we can transport an invariant [P] holding
on subtrees to an invariant holding on the whole node. *) 

End Tree_rect'.

(** **** Exercise: 4 stars (nat_rect')  *)
(** Following the previous example, implement the uniform induction
principle [nat_rect'] over natural numbers. *) 


(** *** Induction vs. recursion *)

(** There is a striking similarity between the recursion principles *)

Check sigma_tree.
Check fold_tree.

(** and the induction principles. *)

Check sigma_ind_tree.
Check tree_rect'.

(** Unsurprisingly, we can emulate recursion if we have induction. *)

(** **** Exercise: 4 stars (recursion_from_induction)  *)

(** Implement [fold_tree' : forall X : Type, (sigma_tree X -> X) -> tree -> X]
using _only_ [tree_rect'] (in particular, you are not allowed to
[match] on a tree) *)

(* Phantom type, to know where computations come from: *)
Definition fold_tree'_def : tree -> Type -> Type := fun t X => X.

Definition fold_tree' : forall X : Type, (sigma_tree X -> X) -> tree -> X.
intros X IH t.
change X with (fold_tree'_def t X).
induction t using tree_rect'.
  admit.
Defined.

Section TryInd.

Hypothesis P: tree -> Type.
Hypothesis init: P Leaf.
Hypothesis step: forall n l r, P l -> P r -> P (Node n l r).

(** Sadly, the converse is impossible: ``Induction is not derivable in
$\lambda$P2'', [http://repository.tue.nl/661317]. The best we can do
is to define an algebra on _pairs_ of the term and its predicate. *)

(** **** Exercise: 5 stars (dep_algebra)  *)
(** Define an algebra [alg (xs: sigma_tree { t : tree & P t }): { t :
tree & P t }] for which the pseudo-induction principle [tree_ind'] is
"correct" (see next exercise for the meaning of "correctness" in this
case). *)

Axiom alg: sigma_tree { t : tree & P t } -> { t : tree & P t }. (* XXX: implement me! *)


Definition tree_ind' (t: tree): { t : tree & P t } :=
  fold_tree alg t.

(** **** Exercise: 4 stars (induction_from_recursion)  *)
(** Prove that your pseudo-induction principle is correct, ie. that we have: *)
Lemma tree_ind'_correct: forall t, projT1 (tree_ind' t) = t.
Proof.
  admit.
Qed.

End TryInd.

(** ** Inductive families *)

(**

Once we have understood inductive types, their recursion schemes and
their induction principles, inductive families come with no
surprises. In terms of universal algebra, we are merely going from
mono-sorted signatures to multi-sorted signatures. For example, the
definition of well-formed red-black trees below is basically a binary
tree whose operations and arities carry an information about the arity
at which these objects exist/must be:

*)

Unset Implicit Arguments. (* being fully explicit may help see the details *)

Inductive color := red | black.

Inductive rbt: color -> nat -> Type :=
| bleaf: 
    nat -> rbt black 0
| rnode: forall n,
    rbt black n -> rbt black n -> rbt red n
| bnode: forall c1 c2 n,
    rbt c1 n -> rbt c2 n -> rbt black (S n).

(** The induction principle may look slightly intimidating but, in fact,
the same principles govern the definition of the (uniform) induction
principle of red-black trees. *)

Check rbt_rect.
(* rbt_rect:
  forall P : forall c n, rbt c n -> Type,
    (forall n : nat, P black 0 (bleaf n)) ->
    (forall n l r, 
         P black n l -> P black n r 
       -> P red n (rnode n l r)) ->
    (forall c1 c2 n l r,
        P c1 n l -> P c2 n r
      -> P black (S n) (bnode c1 c2 n l r)) ->
    forall c n t, P c n t
*)

Section RBTRect'.

Hypothesis P: forall c n, rbt c n -> Type.

(** **** Exercise: 2 stars (rbt_sigma_ind)  *)
(** Define the predicate lifting of red-black trees: *)
Inductive rbt_sigma_ind : forall c n, rbt c n -> Type :=
.

(** **** Exercise: 4 stars (rbt_rect')  *)
(** Using the predicate lifting, implement the induction principle for
red-black trees: *)
Definition rbt_rect':
  (forall c n t, rbt_sigma_ind c n t -> P c n t) ->
  forall c n (t: rbt c n), P c n t.
Proof.
  admit.
Defined.


End RBTRect'.

Section VecRect'.

Variable A : Type.

(** **** Exercise: 1 star (vect)  *)
(** Define the inductive family [vect : nat -> Type] which is such that
inhabitants of [vect n] are the lists containing [n] elements of [A],
by construction (and only those lists).  *)

Inductive vect : nat -> Type :=
.

Hypothesis P : forall n, vect n -> Type.

(** **** Exercise: 2 star (vect_sigma_ind)  *)
(** Implement the predicate lifting [vect_sigma_ind : forall n, vect n ->
Type] of vectors. *)

Inductive vect_sigma_ind : forall n, vect n -> Type :=
.

(** **** Exercise: 3 star (vect_rect')  *)
(** Deduce its uniform induction principle. *)

Axiom vect_rect' :
         forall (IH: forall n t, vect_sigma_ind n t -> P n t)
         {n} (t: vect n), P n t. (* XXX: implement me! *)

(** ** Mutual induction *)


(** Having developed a good understanding of inductive definitions and
induction, we can revisit the motivation for this lecture, ie. the
inappropriate induction principle generated by Coq for [rosetree]. We
may be tempted to manually unfold the definition of [list rosetree]
into a mutually-inductive definition, without much luck. *)

Reset rosetree.

Inductive rosetree :=
| rosenode: 
    nat -> list_rosetree -> rosetree
with list_rosetree :=
| rosenil: 
    list_rosetree
| rosecons: 
    rosetree -> list_rosetree -> list_rosetree.

Check rosetree_rect.
(* rosetree_rect
     : forall P : rosetree -> Type,
       (forall (n : nat) (l : list_rosetree), P (rosenode n l)) -> forall r : rosetree, P r
*)

Reset rosetree.

(** **** Exercise: 2 star (rosetreeIx)  *)
(** One way to effectively sidestep Coq's limitation is to define an
indexed family [rosetreeIx: bool -> Type] which is equivalent to
[rosetree]. Could this pattern be generalized to any
mutually-inductive definition? *)

Inductive rosetreeIx: bool -> Type :=
.

Check rosetreeIx_rect.

(** Alternatively, the command [Combined Scheme] could have worked as
well. *)

(** ** Strict positivity *) 

Section StrictPositivity.

Variable A : Type.

(** Some inductive definitions, such as the following, are rightfully
rejected by Coq *)

Fail Inductive T :=
| c : (T -> A) -> T.

(** because, if we were to accept such definition, we could write the
following programs that build an inhabitant of _any_ type [A], thus
including [False], which ought to be impossible. *)

(* 
<<
Definition funny (t: T)(x: T): A :=
  match t with
  | c f => f x
  end.

Definition haha (t: T): A := funny t t.

Definition bottom: A := haha (c haha).
>> *)

(** A _strictly positive_ definition admits "no recursion to the left
of an arrow": the intuition is that if we were to allow a recursive
argument to appear on the left of an arrow, we could suddenly encode a
diagonal argument, as we did above in [haha]. Coq only allows you to
write strictly-positive inductive definitions. Being a syntactic
check, it is necessarily conservative: sometimes you may need to
massage your definitions to convince Coq that they are legitimate. *)

End StrictPositivity.

(** ** Conclusion *)

(** Today, you have learned:
      - About Inductive definitions:
        + Non-indexed ⊆ indexed
        + Mutual ≈ indexed
        + Positivity criteria
      - About Induction
        + Induction = recursion + proof
        + Mechanically derivable from signature
        + Not always fully supported by Coq...
*)

(** Take-aways:
      - Recursion: for any inductive type, you are able to
          + define its signature functor
          + switch between uniform and specialized recursion
          + implement a uniform recursion operator

      - Induction: for any inductive type or inductive family, you are able to
          + define its predicate lifting
          + switch between uniform and specialized induction
          + implement a uniform induction operator
*) 