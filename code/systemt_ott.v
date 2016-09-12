(* generated by Ott 0.25, locally-nameless lngen from: systemt.ott *)
Require Import Metalib.Metatheory.
(** syntax *)
Definition tmvar := var. (*r variables *)

Inductive typ : Set :=  (*r types *)
 | typ_nat : typ (*r Natural numbers *)
 | typ_arr (t1:typ) (t2:typ) (*r Function types *).

Definition env : Set := list ( atom * typ ).

Inductive exp : Set :=  (*r expressions *)
 | var_b (_:nat)
 | var_f (x:tmvar)
 | z : exp
 | s (e:exp)
 | rec (e:exp) (e0:exp) (e1:exp)
 | abs (t:typ) (e:exp)
 | app (e1:exp) (e2:exp).

(* EXPERIMENTAL *)
(** auxiliary functions on the new list types *)
(** library functions *)
(** subrules *)
(** arities *)
(** opening up abstractions *)
Fixpoint open_exp_wrt_exp_rec (k:nat) (e_5:exp) (e__6:exp) {struct e__6}: exp :=
  match e__6 with
  | (var_b nat) => 
      match lt_eq_lt_dec nat k with
        | inleft (left _) => var_b nat
        | inleft (right _) => e_5
        | inright _ => var_b (nat - 1)
      end
  | (var_f x) => var_f x
  | z => z 
  | (s e) => s (open_exp_wrt_exp_rec k e_5 e)
  | (rec e e0 e1) => rec (open_exp_wrt_exp_rec k e_5 e) (open_exp_wrt_exp_rec k e_5 e0) (open_exp_wrt_exp_rec (S k) e_5 e1)
  | (abs t e) => abs t (open_exp_wrt_exp_rec (S k) e_5 e)
  | (app e1 e2) => app (open_exp_wrt_exp_rec k e_5 e1) (open_exp_wrt_exp_rec k e_5 e2)
end.

Definition open_exp_wrt_exp e_5 e__6 := open_exp_wrt_exp_rec 0 e__6 e_5.

(** terms are locally-closed pre-terms *)
(** definitions *)

(* defns LC_exp *)
Inductive lc_exp : exp -> Prop :=    (* defn lc_exp *)
 | lc_var_f : forall (x:tmvar),
     (lc_exp (var_f x))
 | lc_z : 
     (lc_exp z)
 | lc_s : forall (e:exp),
     (lc_exp e) ->
     (lc_exp (s e))
 | lc_rec : forall (e e0 e1:exp),
     (lc_exp e) ->
     (lc_exp e0) ->
      ( forall x , lc_exp  ( open_exp_wrt_exp e1 (var_f x) )  )  ->
     (lc_exp (rec e e0 e1))
 | lc_abs : forall (t:typ) (e:exp),
      ( forall x , lc_exp  ( open_exp_wrt_exp e (var_f x) )  )  ->
     (lc_exp (abs t e))
 | lc_app : forall (e1 e2:exp),
     (lc_exp e1) ->
     (lc_exp e2) ->
     (lc_exp (app e1 e2)).
(** free variables *)
Fixpoint fv_exp (e_5:exp) : vars :=
  match e_5 with
  | (var_b nat) => {}
  | (var_f x) => {{x}}
  | z => {}
  | (s e) => (fv_exp e)
  | (rec e e0 e1) => (fv_exp e) \u (fv_exp e0) \u (fv_exp e1)
  | (abs t e) => (fv_exp e)
  | (app e1 e2) => (fv_exp e1) \u (fv_exp e2)
end.

(** substitutions *)
Fixpoint subst_exp (e_5:exp) (x5:tmvar) (e__6:exp) {struct e__6} : exp :=
  match e__6 with
  | (var_b nat) => var_b nat
  | (var_f x) => (if eq_var x x5 then e_5 else (var_f x))
  | z => z 
  | (s e) => s (subst_exp e_5 x5 e)
  | (rec e e0 e1) => rec (subst_exp e_5 x5 e) (subst_exp e_5 x5 e0) (subst_exp e_5 x5 e1)
  | (abs t e) => abs t (subst_exp e_5 x5 e)
  | (app e1 e2) => app (subst_exp e_5 x5 e1) (subst_exp e_5 x5 e2)
end.


(** definitions *)

(* defns JValue *)
Inductive value : exp -> Prop :=    (* defn value *)
 | val_z : 
     value z
 | val_s : forall (e:exp),
     value e ->
     value (s e)
 | val_abs : forall (t:typ) (e:exp),
     lc_exp (abs t e) ->
     value (abs t e).

(* defns JTyping *)
Inductive typing : env -> exp -> typ -> Prop :=    (* defn typing *)
 | typing_var : forall (G:env) (x:tmvar) (t:typ),
      uniq  G  ->
      binds  x   t   G  ->
     typing G (var_f x) t
 | typing_z : forall (G:env),
      uniq  G  ->
     typing G z typ_nat
 | typing_s : forall (G:env) (e:exp),
     typing G e typ_nat ->
     typing G (s e) typ_nat
 | typing_rec : forall (L:vars) (G:env) (e e0 e1:exp) (t:typ),
     typing G e typ_nat ->
     typing G e0 t ->
      ( forall x , x \notin  L  -> typing  (( x ~  typ_nat ) ++  G )   ( open_exp_wrt_exp e1 (var_f x) )  (typ_arr t t) )  ->
      ( forall x , x \notin  L  -> value  ( open_exp_wrt_exp e1 (var_f x) )  )  ->
     typing G (rec e e0 e1) t
 | typing_abs : forall (L:vars) (G:env) (t1:typ) (e:exp) (t2:typ),
      ( forall x , x \notin  L  -> typing  (( x ~  t1 ) ++  G )   ( open_exp_wrt_exp e (var_f x) )  t2 )  ->
     typing G (abs t1 e) (typ_arr t1 t2)
 | typing_app : forall (G:env) (e1 e2:exp) (t2 t1:typ),
     typing G e1 (typ_arr t1 t2) ->
     typing G e2 t1 ->
     typing G (app e1 e2) t2.

(* defns JDyn *)
Inductive eval : exp -> exp -> Prop :=    (* defn eval *)
 | eval_s : forall (e e':exp),
     eval e e' ->
     eval (s e) (s e')
 | eval_app_left : forall (e1 e2 e1':exp),
     lc_exp e2 ->
     eval e1 e1' ->
     eval (app e1 e2) (app e1' e2)
 | eval_app_right : forall (e1 e2 e2':exp),
     value e1 ->
     eval e2 e2' ->
     eval (app e1 e2) (app e1 e2')
 | eval_beta : forall (t:typ) (e1 e2:exp),
     lc_exp (abs t e1) ->
     value e2 ->
     eval (app  ( (abs t e1) )  e2)  (open_exp_wrt_exp  e1   e2 ) 
 | eval_rec_scrut : forall (e e0 e1 e':exp),
     lc_exp (rec e e0 e1) ->
     lc_exp e0 ->
     eval e e' ->
     eval (rec e e0 e1) (rec e' e0 e1)
 | eval_rec_z : forall (e0 e1:exp),
     lc_exp (rec z e0 e1) ->
     lc_exp e0 ->
     eval (rec z e0 e1) e0
 | eval_rec_s : forall (e e0 e1:exp),
     lc_exp (rec (s e) e0 e1) ->
     lc_exp e0 ->
     value (s e) ->
     eval (rec (s e) e0 e1) (app  (open_exp_wrt_exp  e1   e )   ( (rec e e0 e1) ) ).


(** infrastructure *)
Hint Constructors value typing eval lc_exp.

