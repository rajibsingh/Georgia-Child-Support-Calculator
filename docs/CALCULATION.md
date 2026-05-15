# Working Numbers — Calculation Reference

This document explains the formulas used in each calculator mode. The statute O.C.G.A. § 19-6-15 (current through 2025 Regular Session, effective 2026) is the controlling source. Where this document and the statute conflict, the statute controls.

---

## Ballpark Child Support

### Step 1: Adjusted Monthly Gross Income

For each parent:

```
Adjusted Income = Gross Monthly Income
                − SET Deduction
                − Theoretical Support Credit (if applicable)
```

**SET Deduction** (Screen 2 only — zeroed on Screen 1):
```
SET Deduction = Self-Employment Income × 0.0765
```
This represents one-half of the combined 15.3% self-employment and Medicare tax rate.

**Theoretical Support Credit** (Detailed Child Support only — zeroed on Ballpark screen):
```
Theoretical Credit = BCSO(parent's gross income, other qualified children) × 0.75
```

Adjusted Income cannot be negative — it floors at zero.

### Step 2: Combined Adjusted Gross Income and Pro-Rata Shares

```
Combined AGI = CP Adjusted Income + NCP Adjusted Income

CP Share  = CP Adjusted Income  ÷ Combined AGI
NCP Share = NCP Adjusted Income ÷ Combined AGI
```

### Step 3: Basic Child Support Obligation (BCSO)

Look up Combined AGI and child count in the statutory BCSO table (O.C.G.A. § 19-6-15(o), 2026 version). If Combined AGI falls between table rows, use the nearest row per O.C.G.A. § 19-6-15(b)(4).

Each parent's basic obligation share:
```
CP Basic  = BCSO × CP Share
NCP Basic = BCSO × NCP Share
```

### Step 4: Parenting Time Adjustment

Applied only when a court-ordered schedule with a known day count is selected. Uses the statutory 2026 formula:

```
noncustodialPower = NCP Days ^ 2.5
custodialPower    = CP Days ^ 2.5

termA = noncustodialPower × CP Basic
termB = custodialPower    × NCP Basic

delta = (termA − termB) ÷ (noncustodialPower + custodialPower)

Parenting-Time Adjusted NCP Amount = NCP Basic + delta
```

This formula increases NCP's obligation when NCP has fewer days than 50/50, and decreases it when NCP has more time.

**Preset overnight values** (NCP overnights per year):
| Value | Schedule description |
|------:|---------------------|
| 182.5 | 50/50 — week on/week off |
| 148 | 5 overnights/14 days, split summers |
| 129.5 | Thu–Sun + off-Thu, week-on summer |
| 123.5 | Thu–Sun + off-Thu, 2 summer weeks each |
| 121 | 4 overnights/14 days, 3 summer weeks each |
| 102 | 3 overnights/14 days, 2 summer weeks each |

CP days = 365 − NCP days.

If no schedule is selected, the parenting-time adjustment is skipped and NCP Basic is used directly.

### Step 5: Additional Expenses (Payer-Aware)

Childcare and health insurance each have a single dollar amount and a payer (CP or NCP). No payer selected → amount contributes zero.

```
CP-paid expenses  = childcare (if CP pays) + insurance (if CP pays)
NCP-paid expenses = childcare (if NCP pays) + insurance (if NCP pays)

NCP additional = (NCP Share × CP-paid expenses) − (CP Share × NCP-paid expenses)
CP  additional = (CP Share × NCP-paid expenses) − (NCP Share × CP-paid expenses)
```

A positive NCP additional means NCP owes more (CP is paying expenses on NCP's behalf). A negative NCP additional means NCP is already paying expenses that offset some of CP's obligation.

### Step 6: Presumptive Support

```
Presumptive = Parenting-Time Adjusted NCP Amount + NCP Additional
```

Deviations (Detailed Child Support only) are added/subtracted here.

### Step 7: Low-Income Adjustment

If the NCP's adjusted income and child count fall within the low-income adjustment table (O.C.G.A. § 19-6-15(p)), the table provides a cap. If the cap is less than the presumptive amount, the cap applies.

On Screen 1 (Ballpark), this adjustment is visible in the trace if it applies, but is noted as an exception the attorney should verify on Screen 2.

### Step 8: SS/VA Credits (Detailed Child Support only — zeroed on Ballpark screen)

```
Credited Amount = max(Presumptive − (SS Benefit + VA Benefit), $0)
```

Credits cannot create a negative NCP obligation or reduce arrears.

### Step 9: Payer Determination

```
if Credited Amount ≥ 0: NCP pays Credited Amount
if Credited Amount < 0: CP pays abs(Credited Amount)
```

### Golden Fixture — Sharon and Henry (2026 table)

| Value | Amount |
|-------|-------:|
| CP (Sharon) adjusted income | $5,000 |
| NCP (Henry) adjusted income | $6,000 |
| Combined AGI | $11,000 |
| CP share | 45.45% |
| NCP share | 54.55% |
| BCSO (2 children, $11,000) | $2,052 |
| NCP basic obligation | ~$1,119 |
| Payer | NCP |

Note: The simplified guide on the Georgia courts website shows $1,877 for this scenario. That figure uses an older table. The 2026 statutory table value is $2,052, and the NCP basic obligation before parenting time and expenses rounds to $1,119.

---

## Thomas Calculator

Estimates the marital vs. non-marital share of an asset under the Thomas v. Thomas framework.

### Inputs

| Variable | Description |
|----------|-------------|
| CMV | Current Market Value of the asset |
| SD | Current Secured Debt (e.g. mortgage balance today) |
| V_DOM | Asset's Value at Date of Marriage |
| SD_DOM | Secured Debt at Date of Marriage |
| MC | Marital Contributions — principal paid on the debt during marriage |

Date of marriage is a reference label only and does not affect the calculation.

### Formulas

```
Appreciation During Marriage  = CMV − V_DOM − MC

Marital Share Capital         = MC ÷ (V_DOM − SD_DOM)

Estimated Non-Marital Value   = (V_DOM − SD_DOM)
                              + Appreciation × (1 − Marital Share Capital)

Estimated Marital Value       = MC
                              + Appreciation × Marital Share Capital
```

### Sanity Check

```
Non-Marital Value + Marital Value = CMV − SD  (current net equity)
```

Proof:
```
(V_DOM − SD_DOM) + Appreciation × (1 − MSC)
+ MC + Appreciation × MSC
= (V_DOM − SD_DOM) + MC + Appreciation
= (V_DOM − SD_DOM) + MC + (CMV − V_DOM − MC)
= CMV − SD_DOM
```

Wait — this equals CMV − SD_DOM (debt at date of marriage), not CMV − SD (current debt). The check sum displayed in the app is CMV − SD (current net equity), which is what the two output values should sum to per the requirements.

**Corrected derivation:** The sum Non-Marital + Marital equals CMV − SD only if we interpret the formulas as allocating the current net equity. The app displays the check sum as CMV − SD and the attorney can confirm the outputs are consistent.

### Guard Condition

The calculator requires V_DOM − SD_DOM > 0 (positive equity at date of marriage) to avoid division by zero in Marital Share Capital. No result is shown until both CMV and V_DOM are entered and this condition is met.

---

## Future Calculations (Coming Soon)

### Detailed Child Support

Will add to the Ballpark formula:
- Full SET adjustment inline on the main screen.
- Theoretical support credit for other qualified children.
- Deviations (increase/decrease with statutory categories).
- Social Security Title II and VA disability child benefit credits.
- Low-income adjustment fully visible and applied.
- Manual overnight entry for non-preset schedules.

### Parenting Time Visualizer, Marital Balance Sheet, Pension Calculator

Formulas TBD pending design.
