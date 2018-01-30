Require Import Coq.Bool.Bool.
Require Import Coq.Arith.Arith.
Require Import Coq.Arith.EqNat.
Require Import Coq.omega.Omega.
Require Import Coq.Lists.List.
Require Import Coq.Logic.FunctionalExtensionality.
Import ListNotations.

Axiom admit: forall {X},  X.

Reserved Notation "c1 '/' st '\\' st'"
                  (at level 40, st at level 39).

(** Dans cet exercice, nous �tendons la s�mantique du langage Imp
    �tudi� en cours, �tendons sa logique de programme et v�rifions la
    correction d'un programme �crit dans ce syst�me. *)

(** * Variables *)

(** Comme en cours, nous mod�lisons les variables du langage par un
    type [id] dont nous nommons (arbitrairement) 3 �l�ments [X], [Y]
    et [Z]. *)

Inductive id : Type :=
  | Id : nat -> id.

Definition X : id := Id 0.
Definition Y : id := Id 1.
Definition Z : id := Id 2.

Definition beq_id x1 x2 :=
  match x1, x2 with
  | Id n1, Id n2 => beq_nat n1 n2
  end.

Theorem beq_id_refl : forall x, beq_id x x = true.
Proof. now intros; destruct x; simpl; rewrite <- beq_nat_refl. Qed.

(** QUESTION [difficult� [*] / longueur [*]]

    [X] et [Y] �tant d�finis, les lemmes suivants sont prouvables par
    simple _calcul_.  *)

Remark rq1: beq_id X X = true.
Proof. 
  admit.
Qed.

Remark rq2: beq_id X Y = false.
Proof.
  admit.
Qed.

(** * M�moire *)

(** Comme en cours, nous mod�lisons la m�moire par une fonction des
    identifiants vers les entiers. On acc�de donc au contenu de la
    m�moire [s] � l'adresse [x] par application [s x]. *)

Definition state := id -> nat.

Definition empty_state: state := fun _ => 0.

Definition update (s: state)(x: id)(n: nat) :=
  fun y => if beq_id x y then n else s y.

(** QUESTION [difficult� [**] / longueur [*]]

    Prouver les identit�s suivantes reliant l'extension de la m�moire
    et l'acc�s � la m�moire: *)

Lemma update_eq : forall s x v,
    update s x v x = v.
Proof. 
  admit.
Qed.

Lemma update_shadow : forall s v1 v2 x,
    update (update s x v1) x v2
  = update s x v2.
Proof.
  intros. unfold update; simpl.
  apply functional_extensionality.
  admit.
Qed.

(** * Expressions bool�ennes *)

(** Les expressions bool�ennes permettent d'�crire des formules
    bool�ennes (avec [BTrue], [BFalse], [BNot] et [BAnd]) ainsi que
    des tests sur le contenu des variables ([BEq] et [BLe]). *)

Inductive bexp : Type :=
  | BTrue  : bexp
  | BFalse : bexp
  | BNot   : bexp -> bexp
  | BAnd   : bexp -> bexp -> bexp
  | BEq    : id -> nat -> bexp
  | BLe    : id -> nat -> bexp.

Fixpoint beval (st: state)(b : bexp) : bool :=
  match b with
  | BTrue      => true
  | BFalse     => false
  | BNot b1    => negb (beval st b1)
  | BAnd b1 b2 => andb (beval st b1) (beval st b2)
  | BEq x n    => beq_nat (st x) n
  | BLe x n    => leb (st x) n
  end.

(** QUESTION [difficult� [*] / longueur [*]]

    D�river le "ou logique" [BOr] � partir de [BNot] et [BAnd]
    (suivant la loi de De Morgan) puis prouver que sa s�mantique est
    conforme � [orb], l'impl�mentation du "ou logique" en Coq.  *)

Definition BOr (b1 b2: bexp): bexp :=
  admit.

Lemma bor_correct: forall st b1 b2, 
    beval st (BOr b1 b2) = orb (beval st b1) (beval st b2).
Proof.
  admit.
Qed.

(** QUESTION [difficult� [**] / longueur [***]]

    Prouver que la s�mantique de [BLe'] d�fini ci-dessous est conforme
    � [leb], l'impl�mentation de la comparaison d'entiers dans Coq. *)

Definition BLe' (m: nat)(x: id): bexp :=
  BOr (BNot (BLe x m)) (BEq x m).

Lemma ble'_correct: forall st m x, beval st (BLe' m x) = leb m (st x).
Proof.
  intros.
  unfold BLe'.
  rewrite bor_correct.
  simpl.
  remember (leb m (st x)).
  destruct b.
  - apply orb_true_iff.
    symmetry in Heqb.
    apply leb_iff, le_lt_or_eq in Heqb.
    destruct Heqb.
    + left.
      now apply negb_true_iff, leb_correct_conv.
    + right.
      now apply beq_nat_true_iff.
  - 
  admit.
Qed.

(** * Commandes *)

(** Nous consid�rons le langage des commandes habituelles ([CSkip],
    [CSeq], [CWhile]) �tendu avec une commande d�cr�mentant une
    variable ([CDecr]). *)

Inductive com : Type :=
  | CSkip : com
  | CSeq : com -> com -> com
  | CWhile : bexp -> com -> com
  | CDecr : id -> com.

Notation "'SKIP'" :=
  CSkip.
Notation "x '--'" :=
  (CDecr x) (at level 60).
Notation "c1 ;; c2" :=
  (CSeq c1 c2) (at level 80, right associativity).
Notation "'WHILE' b 'DO' c 'END'" :=
  (CWhile b c) (at level 80, right associativity).

(** QUESTION [difficult� [***] / longueur [*]]

    Compl�ter la s�mantique du langage de commandes ci-dessous avec la
    s�mantique de [CDecr]. *)

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,

  (*--------------------------------------*)
      SKIP / st \\ st

  | E_Seq : forall c1 c2 st st' st'',

      c1 / st  \\ st' ->
      c2 / st' \\ st'' ->
  (*--------------------------------------*)
      (c1 ;; c2) / st \\ st''
  | E_WhileEnd : forall b st c,

      beval st b = false ->
  (*--------------------------------------*)
      (WHILE b DO c END) / st \\ st
  | E_WhileLoop : forall st st' st'' b c,

      beval st b = true ->
      c / st \\ st' ->
      (WHILE b DO c END) / st' \\ st'' ->
  (*--------------------------------------*)
      (WHILE b DO c END) / st \\ st''


  where "c1 '/' st '\\' st'" := (ceval c1 st st').

(** Dans ce langage, on peut ainsi �crire le programme suivant, qui
    teste la parit� du contenu de la variable [X]: *)

Definition PARITY :=
 WHILE (BLe' 2 X) DO
       X-- ;; X--
 END.

(** QUESTION [difficult� [*] / longueur [*]]

    Prouver que, � partir d'un �tat m�moire o� [X = 4], le r�sultat de la commande [X--]
    retourne un �tat o� [X = 3]. *)

Example Decr_test: 
  X-- / update empty_state X 4 \\ update empty_state X 3.
Proof.
  set (m := update empty_state X 4).
  replace (update empty_state X 3) with (update m X (m X - 1)).
  -
  admit.
  - 
    subst m.
  admit.
Qed.

(** QUESTION [difficult� [**] / longueur [***]]

    Prouver que, � partir d'un �tat m�moire o� [X = 4], le test de
    parit� retourne [X = 0]. *)

Example PARITY_test: 
  PARITY / update empty_state X 4 \\ update empty_state X 0.
Proof.
  admit.
Qed.


(** * Logique de Hoare *)

(** Nous obtenons une logique de programme par la construction
    usuelle. *)

Definition Assertion := state -> Prop.

Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Notation "P ->> Q" := (assert_implies P Q)
                      (at level 80).

Definition hoare_triple
           (P:Assertion) (c:com) (Q:Assertion) : Prop :=
  forall st st',
     c / st \\ st'  ->
     P st  -> Q st'.

Notation "{{ P }}  c  {{ Q }}" := (hoare_triple P c Q)
    (at level 90, c at next level).

(** � partir de ces d�finitions, nous pouvons sp�cifier le
    comportement des commandes gr�ce � la logique de programme. Pour
    [SKIP], [;;] et [WHILE], cela se traduit par les sp�cifications
    suivantes: *)

Axiom hoare_consequence_pre : forall (P P' Q : Assertion) c,
  {{P'}} c {{Q}} -> P ->> P' ->
  {{P}} c {{Q}}.

Axiom hoare_consequence_post : forall (P Q Q' : Assertion) c,
  {{P}} c {{Q'}} -> Q' ->> Q ->
  {{P}} c {{Q}}.

Axiom hoare_skip : forall P,
     {{P}} SKIP {{P}}.

Axiom hoare_seq : forall P Q R c1 c2,
     {{Q}} c2 {{R}} -> {{P}} c1 {{Q}} ->
     {{P}} c1;;c2 {{R}}.

Definition bassn b : Assertion :=
  fun st => (beval st b = true).

Axiom hoare_while : forall P b c,
  {{fun st => P st /\ bassn b st}} c {{P}} ->
  {{P}} WHILE b DO c END {{fun st => P st /\ ~ (bassn b st)}}.

(** QUESTION [difficult� [***] / longueur [*]]

    Sur le mod�le de l'assignation (vu en cours), donner et prouver la
    sp�cification la plus pr�cise possible pour l'op�ration de
    d�cr�mentation. *)

Definition assn_sub X P : Assertion := 
  fun (st : state) => P (update st X (st X - 1)).

Notation "P '[' X '--]'" := (assn_sub X P) (at level 10).

Theorem hoare_decr :
False.
Proof.
  admit.
Qed.

(** * Preuve de correction *)

(** Nous souhaitons d�sormais prouver la correction du programme
    [PARITY] introduit pr�c�demment. Pour cela, il nous faut traduire
    la sp�cification informelle de [PARITY] par une d�finition
    formelle dans Coq. *)

(** QUESTION {BONUS} [difficult� [*] / longueur [*]]

    Impl�menter la fonction [parity] ci-dessous qui doit retourner [0]
    si son argument est pair et [1] si son argument est impaire. *)

Fixpoint parity (x: nat): nat :=
  admit.

(** QUESTION {BONUS} [difficult� [**] / longueur [**]]

    Afin de prouver la correction de [PARITY] vis-�-vis de [parity],
    nous aurons besoin des deux lemmes techniques suivants. *)

Lemma parity_ge_2 : forall x,
  2 <= x ->
  parity (x - 2) = parity x.
Proof.
  admit.
Qed.


Lemma parity_lt_2 : forall x,
  not (2 <= x) ->
  parity x = x.
Proof.
  admit.
Qed.

(** QUESTION {BONUS} [difficult� [***] / longueur [***]]

    � l'aide de ces r�sultats et des op�rations de la logique de
    programme, prouver la correction de [PARITY]. *)

Theorem parity_correct : forall m,
    {{ fun st => st X = m }}
      PARITY
    {{ fun st => st X = parity m }}.
Proof.
  intros.
  apply hoare_consequence_pre 
      with (P' := fun st => parity (st X) = parity m).
  apply hoare_consequence_post
      with (Q' := fun st => parity (st X) = parity m /\ st X < 2).
  - (* Prove: {{ parity X = parity m }} PARITY {{ parity X = parity m /\ X < 2 }} *)
  admit.
  - (* Prove: parity X = parity m /\ X < 2 -> st X = parity m *)    
  admit.
  - (* Prove: X = m -> parity X = parity m *)
  admit.
Qed.
