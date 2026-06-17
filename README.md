# Restaurant Management Utilities — Prolog & Haskell

> A restaurant operations toolkit implemented twice, in two different programming paradigms: **logic programming** (Prolog) for reservations and supply planning, and **functional programming** (Haskell) for delivery scheduling and expense analysis.

![Prolog](https://img.shields.io/badge/Prolog-SWI-EF3D3D)
![Haskell](https://img.shields.io/badge/Haskell-WinHugs%20%2F%20GHC-5e5086?logo=haskell&logoColor=white)
![Paradigms](https://img.shields.io/badge/paradigms-logic%20%2B%20functional-444)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-lightgrey)

---

## Overview

This project builds a set of utilities for a restaurant — managing reservations, planning ingredient deliveries, and analyzing expenses — and implements them across **two declarative paradigms**, highlighting how the same domain is modeled very differently depending on the language:

- **Part 1 — Prolog (logic programming):** uses facts, rules, unification, and backtracking search to schedule reservations under real-world constraints and to compute the ingredients each day requires.
- **Part 2 — Haskell (functional programming):** uses algebraic data types, recursion, and higher-order functions to plan deliveries (accounting for lead times across month boundaries) and to summarize a tree of expenses.

Built for **Concepts of Programming Languages (CSEN/CSIS)** at the German University in Cairo.

---

## Part 1 — Prolog: Reservations & Supplies

`prolog/solution.pl`

The Prolog component reasons over a knowledge base of groups, staff, tables, recipes, and orders. It leans on Prolog's natural strengths — constraint satisfaction through backtracking, and aggregation through `findall`.

**Predicates implemented:**

- **`check_staff(Day, Time, Reservations)`** — succeeds only if, for the given day and time, the number of reserved tables never exceeds the available staff. Counts matching reservations recursively and compares against the staff fact.
- **`schedule_all_reservations(Days, Schedule)`** — generates a valid schedule for *every* group in the KB. Through backtracking it assigns each group a day, a table with enough capacity, and its preferred time, while ensuring no table is double-booked and the staffing constraint holds. Multiple valid schedules can be produced on backtracking.
- **`group_ingredients(GroupName, Ingredients)`** — collects every ingredient a group needs across all the dishes it ordered, preserving repetitions.
- **`needed_ingredients(Reservations, AllIngredients)`** — aggregates the ingredients required per day across all reservations, grouped so each day appears once.
- **`write_reservations_to_csv(File, Schedule)`** — exports a schedule to CSV (`Day,Month,Time,Group,Table`).
- **`write_ingredients_to_csv(File, AllIngredients)`** — exports the per-day ingredient list to CSV (`Day,Month,Ingredients`), ingredients joined by semicolons.

The logic is broken into small helper predicates (`count_res`, `dishes_ingredients`, `days_ingredients`, …) so each rule does one clear job.

---

## Part 2 — Haskell: Deliveries & Expenses

`haskell/Team_123.hs`

The Haskell component models the domain with recursive algebraic data types — a `Recipe` is an ingredient made of other ingredients, and an `Expense` `Category` is a tree of items and sub-categories — and processes them purely functionally.

**Functions implemented:**

- **`calculateDeliveryDates :: Date -> [Ingredient] -> [(Date, (String, Price))]`** — works backwards from the date an ingredient is needed to the date it must be ordered, using each ingredient's lead time. Recipes are flattened into their component ingredients. Correctly rolls back across month and year boundaries (e.g. an item needed in January may need to ship in December).
- **`summarizeAllDeliveries :: [Date] -> [Delivery]`** — looks up each date's shopping list, computes all required deliveries, and merges them: one entry per delivery date, each ingredient appearing once with its total quantity and total price. Output is sorted by date, then alphabetically by ingredient.
- **`getDeliveryExpenses :: [Delivery] -> Expense`** — turns a list of deliveries into a `"Food Supplies"` expense category, one `Item` per supply.
- **`mostPopularDish :: [String] -> [String]`** — returns the most frequently ordered dish(es), returning all of them on a tie and `[]` for empty input.
- **`calculateTotalExpenses :: Expense -> Price`** — sums an entire expense tree, implemented with higher-order functions (`map`/`sum`).
- **`countCategoryItems :: String -> Expense -> Int`** — counts the leaf items under a named category anywhere in the tree.

Custom helpers replace standard-library conveniences for WinHugs compatibility: a month-aware date subtraction (`subtractDays`), a generic insertion sort (`sortWith` built on `foldr`), and duplicate removal (`removeDups`).

---

## Running & Testing

These are the exact queries/calls that reproduce the specification's examples — ideal for verifying the implementation.

### Prolog (SWI-Prolog)

Place `solution.pl` in the same folder as the knowledge base (`sample_KB.pl` or `public_KB.pl`); the file consults `sample_KB.pl` by default — edit the first line to switch KBs. Consult the file in SWI-Prolog, then enter goals at the `?-` prompt (type the goal only, ending with a period — the `?-` is already shown by the prompt). Sample runs and their actual output:

```prolog
% A group's full ingredient list across all its dishes
?- group_ingredients(b, I).
I = [ing5, ing6, ing5, ing6, ing5, ing6, ing5, ing6].

% Staffing constraint violated (two morning tables, not enough staff)
?- check_staff(day(15, 2), morning,
       [res(day(15,2), morning, a, t1), res(day(15,2), morning, c, t2)]).
false.

% A valid schedule for every group across the given days
?- schedule_all_reservations([day(15, 2), day(17, 2)], R).
R = [res(day(17,2), evening, d, t1), res(day(17,2), morning, c, t2),
     res(day(15,2), evening, b, t2), res(day(15,2), morning, a, t1)].

% Ingredients required, grouped per day
?- needed_ingredients([res(day(15,2),morning,a,t1), res(day(15,2),evening,b,t2),
       res(day(17,2),morning,c,t2), res(day(17,2),evening,d,t1)], I).
I = [(day(15,2), [...]), (day(17,2), [...])].

% End-to-end: schedule, compute ingredients, export to CSV
?- schedule_all_reservations([day(15,2), day(17,2)], R),
   needed_ingredients(R, All),
   write_ingredients_to_csv('shopping.csv', All).
```

### Haskell (WinHugs or GHCi)

Open the file (**WinHugs:** File → Open → `Team_123.hs`; **GHCi:** `ghci haskell/Team_123.hs`), then call the functions. Sample runs and their actual output:

```haskell
Main> mostPopularDish ["rice", "soup", "cake", "rice"]
["rice"]

Main> calculateTotalExpenses (Category "Restaurant Expenses"
        [ Category "Food Supplies" [ Item "Vegetables" 450.50 (12, Jan, 2026),
                                     Item "Meat" 890.00 (13, Jan, 2026) ],
          Category "Salaries"      [ Item "Chef" 3500.00 (1, Jan, 2026),
                                     Item "Waiter" 2000.00 (1, Jan, 2026) ] ])
6840.5

Main> countCategoryItems "Salaries" (Category "Restaurant Expenses"
        [ Category "Food Supplies" [ Item "Vegetables" 450.50 (12, Jan, 2026),
                                     Item "Meat" 890.00 (13, Jan, 2026) ],
          Category "Salaries"
            [ Category "Kitchen" [ Item "Chef" 3500.00 (1, Jan, 2026) ],
              Category "Service" [ Item "Waiter" 2000.00 (1, Jan, 2026),
                                   Item "Waiter" 2100.00 (3, Jan, 2026) ] ] ])
3

Main> calculateDeliveryDates (10, Feb, 2026)
        [SimpleIngredient "rice", SimpleIngredient "apples",
         Recipe "dough" [SimpleIngredient "flour", SimpleIngredient "eggs"],
         SimpleIngredient "apples"]
[((21,Jan,2026),("rice",1.2)),((5,Feb,2026),("apples",5.0)),
 ((9,Feb,2026),("flour",0.5)),((9,Feb,2026),("eggs",2.0)),
 ((5,Feb,2026),("apples",5.0))]

Main> summarizeAllDeliveries [(15, Feb, 2026), (17, Feb, 2026)]
[((26,Jan,2026),[("rice",1,1.2)]),((10,Feb,2026),[("sugar",1,6.0)]),
 ((14,Feb,2026),[("butter",1,12.0),("eggs",1,2.0),("flour",1,0.5)]),
 ((16,Feb,2026),[("eggs",1,2.0),("flour",3,1.5)])]

Main> getDeliveryExpenses [((26,Jan,2026),[("rice",1,1.2)]),
                           ((10,Feb,2026),[("sugar",1,6.0)])]
Category "Food Supplies" [Item "rice" 1.2 (26,Jan,2026),
                          Item "sugar" 6.0 (10,Feb,2026)]
```

> All outputs above were produced by running the actual code (SWI-Prolog 7.2.3 and WinHugs / Hugs 98) and match the specification's expected results.

## Repository Structure

```
restaurant-management-prolog-haskell/
├── prolog/
│   └── solution.pl       # Task 1 — reservations & supplies (logic programming)
├── haskell/
│   └── Team_123.hs       # Task 2 — deliveries & expenses (functional programming)
└── README.md
```

> The Prolog file expects a knowledge base (`sample_KB.pl` / `public_KB.pl`) in the same folder; these course-provided files are not included here.

## Concepts Demonstrated

- **Logic programming:** unification, backtracking search, constraint satisfaction, `findall`/aggregation, recursive predicates, file I/O.
- **Functional programming:** algebraic & recursive data types, pattern matching, recursion, higher-order functions (`map`, `foldr`, `filter`, `sum`), and a pure, side-effect-free design.
- **Cross-paradigm modeling:** expressing the same problem domain in two fundamentally different declarative styles.

## Academic Context & Usage

Built for **Concepts of Programming Languages (Spring 2026)** at the German University in Cairo — Task 1 (Prolog) and Task 2 (Haskell).

© 2025. All rights reserved. Shared as a portfolio and demonstration piece. You are welcome to view and run it, but it is **not** licensed for reuse or submission as your own academic work.
