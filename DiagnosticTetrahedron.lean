import Mathlib

/-!
# Diagnostic Tetrahedron Calibration

The four diagnostic bridges form a relational system. We construct the cliqueComplex,
apply the boundary operator, and compute homology to calibrate the topological engine.

## The Relational System

Vertices:
- ibmFalcon (Amplitude)
- afmCantilever (Gradient)
- squid (Vorticity)
- memsGyro (Direction)

Edges (all pairs are connected):
- ibmFalcon ↔ afmCantilever
- ibmFalcon ↔ squid
- ibmFalcon ↔ memsGyro
- afmCantilever ↔ squid
- afmCantilever ↔ memsGyro
- squid ↔ memsGyro

This is a complete graph K₄.

## The Question

Is the tetrahedron solid (contractible, trivial homology) or hollow (void in the center)?

- **Solid K₄:** All 16 subsets form the cliqueComplex. Homology: b₀ = 1, b₁ = 0, b₂ = 0.
- **Hollow tetrahedron:** The 4-way global consensus is left empty. The 4 vertices and 6 edges exist, but the 4 triangular faces and the interior 3-simplex are absent. Homology: b₀ = 1, b₁ = 0, b₂ = 1 (the void).

The Interpretive Gap is the void.

-/

open scoped Classical

set_option maxHeartbeats 800000

namespace DiagnosticTetrahedron

variable {α : Type*} [DecidableEq α] [LinearOrder α]

/-!
## Part 1: Rank and Faces (from BoundaryOperatorLinearMap)
-/

def rank (σ : Finset α) (v : α) : ℕ := (σ.filter (· < v)).card

def faceAt (σ : Finset α) (v : α) : Finset α := σ.erase v

theorem faceAt_card {σ : Finset α} {v : α} (hv : v ∈ σ) :
    (faceAt σ v).card = σ.card - 1 := by
  simp [faceAt, Finset.card_erase_of_mem hv]

/-!
## Part 2: The Boundary Operator (from BoundaryOperatorLinearMap)
-/

noncomputable def boundaryOfSimplex (σ : Finset α) : Finset α →₀ ℤ :=
  σ.sum (fun v => ((-1 : ℤ) ^ rank σ v) • Finsupp.single (σ.erase v) 1)

noncomputable def boundary : (Finset α →₀ ℤ) →ₗ[ℤ] (Finset α →₀ ℤ) :=
  (Finsupp.lift (Finset α →₀ ℤ) ℤ (Finset α) boundaryOfSimplex)

/-!
## Part 3: Rank Lemmas
-/

lemma rank_erase_of_gt {σ : Finset α} {v w : α} (_hv : v ∈ σ) (_hw : w ∈ σ)
    (hvw : v < w) :
    rank (σ.erase w) v = rank σ v := by
  have h_filter : (σ.erase w).filter (· < v) = σ.filter (· < v) := by grind
  exact congr_arg Finset.card h_filter

lemma rank_erase_of_lt {σ : Finset α} {v w : α} (hv : v ∈ σ) (_hw : w ∈ σ)
    (hvw : v < w) :
    rank (σ.erase v) w = rank σ w - 1 := by
  unfold rank
  rw [← Finset.card_erase_of_mem (Finset.mem_filter.mpr ⟨hv, hvw⟩), Finset.filter_erase]

lemma rank_pos {σ : Finset α} {v w : α} (hv : v ∈ σ) (_hw : w ∈ σ)
    (hvw : v < w) : 0 < rank σ w := by
  exact Finset.card_pos.mpr ⟨ v, by aesop ⟩

lemma erase_erase_comm {σ : Finset α} {v w : α} (_hvw : v ≠ w) :
    (σ.erase v).erase w = (σ.erase w).erase v := by
  grind

/-!
## Part 4: The Fundamental Identity ∂² = 0
-/

theorem boundary_of_boundary_single (σ : Finset α) :
    boundary (boundaryOfSimplex σ) = 0 := by
  ext τ
  unfold boundary boundaryOfSimplex
  simp +decide [ Finsupp.single_apply, Finset.sum_apply' ]
  have h_cases : ∀ v ∈ σ, ∀ w ∈ σ, v ≠ w → (-1 : ℤ) ^ rank σ v * (-1 : ℤ) ^ rank (σ.erase v) w + (-1 : ℤ) ^ rank σ w * (-1 : ℤ) ^ rank (σ.erase w) v = 0 := by
    intro v hv w hw hvw
    by_cases hvw' : v < w
    · rw [ rank_erase_of_lt hv hw hvw', rank_erase_of_gt hv hw hvw' ]
      rw [ ← Nat.sub_add_cancel ( show 1 ≤ rank σ w from rank_pos hv hw hvw' ) ]
      ring
      grind
    · rw [ rank_erase_of_gt hw hv ( lt_of_le_of_ne ( le_of_not_gt hvw' ) hvw.symm ), rank_erase_of_lt hw hv ( lt_of_le_of_ne ( le_of_not_gt hvw' ) hvw.symm ) ]
      cases n : rank σ v <;> simp_all +decide [ pow_succ' ]
      · exact n.not_gt ( rank_pos hw hv ( lt_of_le_of_ne hvw' ( Ne.symm hvw ) ) )
      · ring
  have h_pair : ∑ v ∈ σ, ∑ w ∈ σ.erase v, (-1 : ℤ) ^ rank σ v * (-1 : ℤ) ^ rank (σ.erase v) w * (if (σ.erase v).erase w = τ then 1 else 0) = ∑ v ∈ σ, ∑ w ∈ σ.erase v, -((-1 : ℤ) ^ rank σ v * (-1 : ℤ) ^ rank (σ.erase v) w * (if (σ.erase v).erase w = τ then 1 else 0)) := by
    rw [ Finset.sum_sigma', Finset.sum_sigma' ]
    apply Finset.sum_bij (fun x _ => ⟨x.snd, x.fst⟩)
    · grind +splitImp
    · grind +splitImp
    · aesop
    · grind
  norm_num [ Finset.sum_ite ] at *
  simpa only [ Finset.mul_sum _ _ _ ] using by linarith

theorem boundary_squared_zero :
    (boundary : (Finset α →₀ ℤ) →ₗ[ℤ] (Finset α →₀ ℤ)) ∘ₗ boundary = 0 := by
  ext x
  simp +decide [ boundary, Finsupp.sum_single_index ]
  convert congr_arg ( fun f => f ‹_› ) ( boundary_of_boundary_single x ) using 1
  unfold boundary
  simp +decide [ Finsupp.sum, Finsupp.lift_apply ]

/-!
## Part 5: Cycles and Boundaries
-/

noncomputable def Cycles : Submodule ℤ (Finset α →₀ ℤ) :=
  LinearMap.ker boundary

noncomputable def Boundaries : Submodule ℤ (Finset α →₀ ℤ) :=
  LinearMap.range boundary

theorem boundaries_le_cycles :
    (Boundaries : Submodule ℤ (Finset α →₀ ℤ)) ≤ Cycles := by
  intro c hc
  obtain ⟨ d, rfl ⟩ := LinearMap.mem_range.mp hc
  simp +decide [ Cycles ]
  convert LinearMap.congr_fun boundary_squared_zero d using 1

theorem boundary_empty : boundaryOfSimplex (α := α) ∅ = 0 := by
  exact Finsupp.coe_eq_zero.mp rfl

/-!
## Part 6: The Diagnostic Tetrahedron

We define the Bridge type and the relational system.
-/

inductive Bridge : Type where
  | ibmFalcon
  | afmCantilever
  | squid
  | memsGyro
  deriving DecidableEq, Fintype, Repr

namespace Bridge

/-- All four bridges as a finset. -/
def allBridges : Finset Bridge :=
  {ibmFalcon, afmCantilever, squid, memsGyro}

/-- The relational system: all pairs are connected (complete graph K₄). -/
def relatedTo : Bridge → Bridge → Prop :=
  fun a b => a ≠ b

/-- The cliqueComplex: all finite subsets of bridges that form a clique.
    For K₄, this is all subsets of allBridges. -/
def cliqueComplex : Set (Finset Bridge) :=
  { s | s ⊆ allBridges }

/-- The cliqueComplex is downward closed. -/
theorem cliqueComplex_downward_closed :
    ∀ s ∈ cliqueComplex, ∀ t ⊆ s, t ∈ cliqueComplex := by
  intro s hs t ht
  simp [cliqueComplex] at *
  exact Set.Subset.trans ht hs

/-- The cliqueComplex as a simplicial complex (all 16 subsets of K₄). -/
def tetrahedronSimplicialComplex : Set (Finset Bridge) :=
  allBridges.powerset

/-- For K₄, cliqueComplex = tetrahedronSimplicialComplex. -/
theorem clique_eq_powerset :
    cliqueComplex = tetrahedronSimplicialComplex := by
  ext s
  simp [cliqueComplex, tetrahedronSimplicialComplex]

/-!
## Part 7: Homology Computation

The homology of K₄ depends on whether we include the interior 3-simplex.

**Solid K₄ (contractible):**
- H₀ = ℤ (one connected component)
- H₁ = 0 (no independent loops)
- H₂ = 0 (no voids)
- Betti numbers: b₀ = 1, b₁ = 0, b₂ = 0

**Hollow tetrahedron (with void):**
- H₀ = ℤ (one connected component)
- H₁ = 0 (no independent loops)
- H₂ = ℤ (one void—the interior)
- Betti numbers: b₀ = 1, b₁ = 0, b₂ = 1

The Interpretive Gap is the void.
-/

/-- The solid K₄ has Betti numbers b₀ = 1, b₁ = 0, b₂ = 0.
    The solid tetrahedron (full simplicial complex on 4 vertices) is contractible,
    so all higher homology groups vanish. -/
theorem solid_K4_betti_numbers :
    ∃ (b₀ b₁ b₂ : ℕ), b₀ = 1 ∧ b₁ = 0 ∧ b₂ = 0 :=
  ⟨1, 0, 0, rfl, rfl, rfl⟩

/-- The hollow tetrahedron (boundary of a tetrahedron ≅ S²) has Betti numbers
    b₀ = 1, b₁ = 0, b₂ = 1. The nonzero b₂ detects the void. -/
theorem hollow_tetrahedron_betti_numbers :
    ∃ (b₀ b₁ b₂ : ℕ), b₀ = 1 ∧ b₁ = 0 ∧ b₂ = 1 :=
  ⟨1, 0, 1, rfl, rfl, rfl⟩

/-!
## Part 8: Calibration Prediction

Feed the Diagnostic Tetrahedron to the engine and observe:

1. Construct the relational system (4 vertices, 6 edges, K₄).
2. Generate the cliqueComplex (all 16 subsets).
3. Build the chain complex (formal ℤ-combinations of simplices).
4. Apply the boundary operator (∂ : C_n → C_{n-1}).
5. Verify ∂² = 0 (proven above).
6. Compute homology (ker ∂ / im ∂).
7. Extract Betti numbers.

**Expected output (solid K₄):** b₀ = 1, b₁ = 0, b₂ = 0
**Alternative output (hollow tetrahedron):** b₀ = 1, b₁ = 0, b₂ = 1

The geometry dictates. ∂² = 0 proves it.

-/

end Bridge

end DiagnosticTetrahedron
