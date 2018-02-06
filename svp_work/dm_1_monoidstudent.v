Require Import Coq.Arith.Arith.
Require Import Coq.Arith.EqNat.
Require Import Coq.Lists.List.
Import ListNotations.

(** Dans cet exercice, nous �tudions la question de l'�galit� dans les
    mono�des. En math�matique (et donc en informatique), un mono�de
    est un ensemble [M] muni d'un �l�ment unit� [unit : M] et d'une
    op�ration de s�quence [seq : M -> M -> M] v�rifiant les �quations
    suivantes:

    [[
       (unit� � gauche:) 
           forall m: M, seq unit m = m

       (unit� � droite:) 
           forall m: M, seq m unit = m

       (associativit�:) 
           forall m n o: M,
               seq m (seq n o) = seq (seq m n) o 
    ]]

    Par exemple, les entiers naturels [nat] forment un mono�de
    (commutatif, de surcro�t) pour l'unit� [0 : nat] et l'addition 
    [+ : nat -> nat -> nat]. *)

Lemma nat_left_unit: forall n: nat, 0 + n = n.
Proof. trivial. Qed.

Lemma nat_right_unit: forall n: nat, n + 0 = n.
Proof. now induction n. Qed.

Lemma nat_assoc: forall m n o: nat, m + (n + o) = (m + n) + o.
Proof. now induction m; auto; simpl; intros; rewrite IHm. Qed.

(** QUESTION [difficult� [*] / longueur [*]]

    Montrer que les listes forment �galement un mono�de (non
    commutatif) pour l'unit� [nil : list A] et la concat�nation
    [++ : list A -> list A -> list A]. *)

Lemma list_left_unit {A}: forall l: list A, [] ++ l = l.
Proof. 
  intros. simpl. reflexivity.
Qed.

Lemma list_right_unit {A}: forall l: list A, l ++ [] = l.
Proof. 
  induction l.
  - reflexivity.
  - simpl. rewrite IHl. reflexivity.
Qed.

Lemma list_assoc {A}: forall (l m n: list A), (l ++ m) ++ n = l ++ (m ++ n).
Proof. 
  induction l.
  - intros. simpl. reflexivity.
  - intros. simpl. rewrite IHl. reflexivity.
Qed.

(** Dans ce sujet, on s'int�resse � la question de savoir si deux
    expressions [e1] et [e2] de type [M] sont �gales. *)

(** QUESTION  [difficult� [*] / longueur [***]]

    Prouver que les deux expressions suivantes, �crites
    dans le mono�de des listes, sont �gales: *)

Example list_eq {A}: forall (x y z: list A),
    (x ++ (y ++ [])) ++ (z ++ [])
        = 
    (x ++ []) ++ ([] ++ y) ++ z.
Proof.
intros. 
  repeat rewrite list_right_unit. repeat rewrite list_left_unit. rewrite list_assoc. reflexivity.
Qed.

(** Plut�t que de faire une telle preuve � chaque probl�me, nous
    allons construire une _proc�dure de d�cision_ r�solvant le
    probl�me de l'�galit� pour n'importe quelle �quation et sur
    n'importe quel mono�de. *)

(** * Expressions *)

(** Pour cela, la premi�re �tape consiste � d�crire, dans Coq, la
    syntaxe de telles �quations. Pour repr�senter les variables de ces
    �quations, nous utilisons des identifiants : *)

Inductive id : Type :=
  | Id : nat -> id.

Definition beq_id x1 x2 :=
  match x1, x2 with
  | Id n1, Id n2 => beq_nat n1 n2
  end.

(** Par exemple, on d�fini (arbitrairement) les variables [U] � [Z] de
    la fa�on suivante: *)

Definition U : id := Id 0.
Definition V : id := Id 1.
Definition W : id := Id 2.
Definition X : id := Id 3.
Definition Y : id := Id 4.
Definition Z : id := Id 5.

(** On peut associer des valeurs Coq � des identifiants par le moyen
    d'un _environnement_ : *)

Definition env (A: Type) := id -> A.

Definition update {A}(e: env A)(x: id)(v: A): env A := 
  fun y => if beq_id x y then v else e y.

Notation "m [ x |-> v ]" := (update m x v) 
                              (at level 10, x, v at next level).

(** Une expression dans un mono�de correspond alors � une variable
    [AId], � l'unit� [Unit] du mono�de ou � la s�quence [Seq] du
    mono�de. *)

Inductive exp: Type :=
| AId: id -> exp
| Unit: exp
| Seq: exp -> exp -> exp.

(** On note [e1 # e2] la s�quence [Seq e1 e2] et [`X] le terme [AId X]. *)

Infix "#" := Seq 
               (right associativity, at level 60, only parsing).
Notation "` X" := (AId X) 
               (at level 5, only parsing).
Reserved Notation "e1 '~' e2" (at level 65).

(** Deux expressions [e1] et [e2] sont �gales, suivant les �quations
du mono�de, si et seulement ils satisfont la relation d'�quivalence
suivante, ie. si l'on peut construire une preuve de [e1 ~ e2]: *)

Inductive eq: exp -> exp -> Prop :=
| mon_left_id: forall e, Unit # e ~ e
| mon_right_id: forall e, e # Unit ~ e
| mon_assoc: forall e f g, (e # f) # g ~ e # (f # g)

| mon_refl: forall e, e ~ e
| mon_sym: forall e f, e ~ f -> f ~ e
| mon_trans: forall e f g, e ~ f -> f ~ g -> e ~ g
| mon_congr: forall e f g h, e ~ g -> f ~ h -> e # f ~ g # h

where "e1 '~' e2" := (eq e1 e2).

(** QUESTION  [difficult� [*] / longueur [***]]

    Prouver l'�quivalence suivante: *)

Example mon_exp_eq:
    (`X # (`Y # Unit)) # (`Z # Unit)
        ~ 
    (`X # Unit) # (Unit # `Y) # `Z.
Proof.
  eapply mon_trans.
  apply mon_assoc.
  apply mon_congr.
  - apply mon_sym. apply mon_right_id.
  - apply mon_congr.
    + eapply mon_trans.
      apply mon_right_id.
      apply mon_sym.
      eapply mon_trans.
      apply mon_left_id.
      apply mon_refl.
    + eapply mon_trans.
      apply mon_right_id.
      apply mon_refl.
Qed.

(** Le type [exp] nous permet ainsi de repr�senter une expression
    quelconque d'un mono�de tandis que [~] capture pr�cisement les
    �quations que v�rifie ce mono�de. La preuve [mon_exp_eq] ci-dessus
    s'applique ainsi � _tous_ les mono�des concevables: il s'agit
    d'une preuve "g�n�rique".  *)

(** Cependant, la preuve en elle-m�me consiste � cr�er un t�moin de
    l'�quivalence par le truchement des constructeurs du type [~]:
    pour des preuves non-triviales, cela n�cessitera de construire des
    t�moins de preuves en m�moire, ralentissant voir rendant
    impossible l'effort de preuve. *)

(** * Normalisation par �valuation *)

(** Nous allons remplacer la construction manuelle de ces t�moins de
    preuves par un _programme_ calculant ces t�moins. En prouvant la
    correction de ce programme, on obtient alors la correction de
    notre proc�dure de d�cision. *)

(** On remarque que nos expressions s'interpr�tent naturellement dans
    le mono�de des fonctions de domaine [exp] et de co-domaine [exp],
    o� l'unit� correspond � la fonction identit� et o� la s�quence
    correspond � la composition de fonctions: *)

Definition sem_exp := exp -> exp.

Notation sem_exp_unit := (fun x => x) 
                           (only parsing).
Notation sem_exp_seq e1 e2 := (fun x => e1 (e2 x))
                           (only parsing).

Fixpoint eval (c: exp): sem_exp :=
  match c with
  | Unit => sem_exp_unit
  | Seq e1 e2 => sem_exp_seq (eval e1) (eval e2)
  | AId i => fun e => `i # e
  end.


(** �tant donn� un [sem_exp], on obtient une expression [exp] par
    application � l'unit�. Par composition de l'�valuation et de la
    r�ification, on obtient une proc�dure de normalisation des
    expressions. *)

Definition reify (f: sem_exp): exp := f Unit.

Definition norm (e: exp): exp := reify (eval e).

(** Il s'agit de prouver que les termes ainsi obtenus sont
    effectivement des formes normales. Formellement, il s'agit de
    prouver la correction de notre proc�dure, ie. si deux expressions
    sont identifi�es par [norm] alors elles sont �quivalentes par
    l'�quivalence [~]:

    [[
    Lemma soundness:
          forall e1 e2, norm e1 = norm e2 -> e1 ~ e2.
    ]] 

    et, inversement, il s'agit aussi de prouver la compl�tude de notre
    proc�dure, ie. si deux expressions sont �quivalentes par [~] alors
    elles sont identifi�es par [norm]: 

    [[
    Lemma completeness:
          forall e1 e2, e1 ~ e2 -> norm e1 = norm e2.
    ]]
    *)

(** QUESTION  [difficult� [**] / longueur [**]]

    � cette fin, prouvez les trois lemmes techniques suivants: *)

Lemma yoneda: 
  forall e e', e # e' ~ eval e e'.
Proof.
  induction e, e'.
  - constructor.
  - constructor.
  - constructor.
  - constructor.
  - constructor.
  - constructor.
  - eapply mon_trans. apply mon_assoc. eapply mon_trans. apply mon_congr. constructor. constructor.
    simpl. apply mon_sym. eapply mon_trans. eapply mon_sym in IHe1. apply IHe1. apply mon_congr. apply mon_refl.
    eapply mon_trans. eapply mon_sym in IHe2. apply IHe2. apply mon_refl.
  - eapply mon_trans. apply mon_assoc. eapply mon_trans. apply mon_congr. constructor. constructor.
    simpl. apply mon_sym. eapply mon_trans. eapply mon_sym in IHe1. apply IHe1. apply mon_congr. apply mon_refl.
    eapply mon_trans. eapply mon_sym in IHe2. apply IHe2. eapply mon_trans. apply mon_right_id. apply mon_refl.
  - eapply mon_trans. apply mon_assoc. eapply mon_trans. apply mon_congr. constructor. constructor.
    simpl. apply mon_sym. eapply mon_trans. eapply mon_sym in IHe1. apply IHe1. apply mon_congr. apply mon_refl.
    eapply mon_trans. eapply mon_sym in IHe2. apply IHe2. eapply mon_trans. apply mon_congr. constructor. constructor. apply mon_refl.
Qed.

Lemma pre_soundness: 
  forall e, e ~ norm e.
Proof.
  intro e.
  eapply mon_trans.
  eapply mon_sym. eapply mon_right_id.
  unfold norm.
  unfold reify.
  apply yoneda.
Qed.

Lemma pre_completeness: 
  forall e1 e2, e1 ~ e2 -> forall e', eval e1 e' = eval e2 e'.
Proof.
  intros.
  generalize dependent e'.
  induction H; intros; try reflexivity.
  - rewrite IHeq. reflexivity.
  - rewrite IHeq1. rewrite IHeq2. reflexivity.
  - simpl. rewrite IHeq1. rewrite IHeq2. reflexivity.
Qed.

(** QUESTION [difficult� [***] / longueur [*]]

    � partir des r�sultats techniques ci-dessus, compl�tez
    les th�or�mes suivants: *)

Theorem soundness:
  forall e1 e2, norm e1 = norm e2 -> e1 ~ e2.
Proof.
  intros.
  induction e1.
  - induction e2.
    + simpl in H. inversion H. apply mon_refl.
    + simpl in H. inversion H.
    + simpl in H. simpl in IHe2_1. simpl in IHe2_2. rewrite H in IHe2_1. rewrite H in IHe2_2. 
Admitted.      


Theorem completeness: 
  forall e1 e2, e1 ~ e2 -> norm e1 = norm e2.
Proof.
  intros.
  induction H.
  - induction e;
      try (unfold norm; compute; reflexivity).
  - induction e;
      try (unfold norm; compute; reflexivity).
  - induction e;
      try (unfold norm; compute; reflexivity).
  - induction e;
      try (unfold norm; compute; reflexivity).
  - induction e; rewrite IHeq; reflexivity.
  - induction e; rewrite IHeq1; rewrite IHeq2; reflexivity.
  - eapply pre_completeness in H0. eapply pre_completeness in H. unfold norm, reify. simpl. rewrite H. rewrite H0. reflexivity.
Qed.


(** QUESTION [difficult� [***] / longueur [*]]

    Ces r�sultats ne servent pas seulement � s'assurer de la validit�
    de notre programme, ils nous permettent de donner une preuve
    triviale � des probl�mes d'�galit�. Par exemple, prouvez le lemme
    suivant de fa�on concise: *)

Example non_trivial_equality:
  Seq (`U # Unit) 
       (Seq (Unit # `V)
            (`W # 
                 (Seq (`X # `Y)
                      (`Z # Unit))))
    ~
  (Seq (AId U) 
       (Seq (Seq (Seq (AId V) Unit)
                 (Seq (AId W) Unit)) 
            (Seq (AId X) (Seq (AId Y) (AId Z))))).
Proof.
  apply soundness. compute. reflexivity.
Qed.
(** * Preuve par r�flection *)

Variable A : Type.

(** Dans la section pr�c�dente, nous avons d�velopp� une proc�dure de
    d�cision v�rifi�e pour d�cider l'�galit� d'expressions sur un
    mono�de quelconque. Nous allons d�sormais exploiter cet outil pour
    d�cider de l'�galit� dans le cas particulier du mono�de des
    listes. *)

(** � cette fin, nous donnons une interpr�tation des expressions vers
    les listes, o� l'unit� est traduite vers [nil], la s�quence est
    traduite vers la concat�nation [++] et l'interpr�tation des
    variables est donn�e par l'environnement. *)

Fixpoint interp (m: env (list A))(e: exp): list A :=
  match e with
  | Unit => []
  | Seq a b => interp m a ++ interp m b
  | AId x => m x
  end.

(** Cette fonction d'interpr�tation nous permet de remplacer (de fa�on
    calculatoirement transparente) des expressions Coq portant sur le
    mono�de des listes vers des expressions [exp] portant sur un
    mono�de quelconque. *)

Definition empty: env (list A) := fun _ => [].

Remark trivial_eq: forall (x y z: list A),
    let m := empty [ X |-> x ][ Y |-> y ][ Z |-> z ] in

    (x ++ (y ++ [])) ++ (z ++ [])
       = 
    interp m ((`X # (`Y # Unit)) # (`Z # Unit)).

Proof. reflexivity. Qed.


(** QUESTION [difficult� [**] / longueur [**]]

    L'interpr�tation [interp] est _correcte_ si elle respecte les
    �galit�s des mono�des. Prouvez que c'est effectivement le cas. *)

Lemma interp_proper: forall m e e', e ~ e' -> interp m e = interp m e'.
Proof.
  intros. induction H; simpl; try reflexivity.
  - apply app_nil_r.
  - rewrite app_assoc. reflexivity.
  - rewrite IHeq. reflexivity.
  - rewrite IHeq1. rewrite IHeq2. reflexivity.
  - rewrite IHeq1. rewrite IHeq2. reflexivity.
Qed.

(** QUESTION [difficult� [***] / longueur [**]]

    En exploitant le lemme [interp_proper] et la correction de la
    proc�dure de d�cision, donnez des preuves concises des �galit�s
    suivantes. *)

Example list_eq2: forall (x y z: list A),
    (x ++ (y ++ [])) ++ (z ++ [])
        = 
    (x ++ []) ++ ([] ++ y) ++ z.
Proof.
  intros.
  set (m := empty [ X |-> x ][ Y |-> y ][ Z |-> z]).
  change ((x ++ (y ++ [])) ++ (z ++ [])) 
  with (interp m ((`X # (`Y # Unit)) # (`Z # Unit))).
  change ((x ++ []) ++ ([] ++ y) ++ z)
  with (interp m ((`X # Unit) # (Unit # `Y) # `Z)).
  apply interp_proper. apply soundness. compute. reflexivity.
Qed.

Example list_eq3 : forall (u: list A) v w x y z, 
    u ++ ([] ++ v ++ []) ++ w ++ x ++ (y ++ []) ++ z
      = 
    u ++ ((v ++ [] ++ w) ++ x ++ y) ++ (z ++ []) ++ [].
Proof.
  intros.
  set (m := empty [ U |-> u ][ V |-> v ][ W |-> w][ X |-> x ][ Y |-> y ][ Z |-> z ]).
  change ((u ++ ([] ++ v ++ []) ++ w ++ x ++ (y ++ []) ++ z))
    with (interp m ((`U # (Unit # `V # Unit) # `W # `X # (`Y # Unit) # `Z))).
  change ((u ++ ((v ++ [] ++ w) ++ x ++ y) ++ (z ++ []) ++ []))
    with (interp m ((`U # ((`V # Unit # `W) # `X # `Y) # (`Z # Unit) # Unit))).
  apply interp_proper. apply soundness. compute. reflexivity.
Qed.